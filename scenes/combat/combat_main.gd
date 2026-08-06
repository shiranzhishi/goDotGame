extends Node2D

const CARD_UI_SCENE = preload("res://scenes/combat/CardUI.tscn")
const ENEMY_SCENE = preload("res://scenes/combat/Enemy.tscn")

@onready var hand_container: HBoxContainer = $CanvasLayer/HandContainer
@onready var energy_label: Label = $CanvasLayer/EnergyLabel
@onready var hp_label: Label = $CanvasLayer/HPLabel
@onready var block_label: Label = $CanvasLayer/BlockLabel
@onready var end_turn_button: Button = $CanvasLayer/EndTurnButton
@onready var enemy_container: Node2D = $EnemyContainer
@onready var reward_panel: Panel = $CanvasLayer/RewardPanel
@onready var reward_container: HBoxContainer = $CanvasLayer/RewardPanel/RewardContainer
@onready var skip_button: Button = $CanvasLayer/RewardPanel/SkipButton

var current_energy: int = 3
var max_energy: int = 3
var draw_pile: Array[CardData] = []      # 抽牌堆
var discard_pile: Array[CardData] = []   # 弃牌堆
var hand: Array[Control] = []
var combat_active: bool = true
var is_first_turn: bool = true           # 标记是否是首回合
var fatigue_damage: int = 1              # 疲劳伤害，每次抽牌累加
var pending_traps: Array = []
var retained_block: int = 0
var next_turn_bonus_draw: int = 0
var next_turn_bonus_energy: int = 0
var selecting_target: bool = false   # 是否正在选目标
var pending_card: CardData = null    # 待释放的卡牌
var pending_card_ui: Control = null  # 待释放的卡牌UI

func _ready() -> void:
	# 根据职业设置能量上限
	if GameManager.current_class:
		max_energy = GameManager.current_class.max_energy
	else:
		max_energy = 3
	current_energy = max_energy
	
	end_turn_button.pressed.connect(_on_end_turn)
	_init_deck()
	_spawn_enemies()
	_start_turn()
	skip_button.pressed.connect(_on_skip_reward)

func _init_deck() -> void:
	# 从GameManager复制永久牌库到当前战斗的抽牌堆
	draw_pile.clear()
	discard_pile.clear()
	for path in GameManager.player_deck:
		var card = load(path) as CardData
		if card:
			draw_pile.append(card)
	draw_pile.shuffle()
	print("战斗开始，牌库共 ", draw_pile.size(), " 张牌")
	
func _get_available_enemies() -> Array[String]:
	var result: Array[String] = []
	var dir = DirAccess.open("res://resources/enemies/")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				result.append("res://resources/enemies/" + file)
			file = dir.get_next()
		dir.list_dir_end()
	return result
	
func _spawn_enemies() -> void:
	var enemy_pool = _get_available_enemies()
	if enemy_pool.is_empty():
		push_error("敌人文件夹为空！")
		return
	
	# 随机1-3个敌人
	var count = randi_range(1, 3)
	var start_x = 900 - (count - 1) * 75
	
	for i in range(count):
		var random_path = enemy_pool[randi() % enemy_pool.size()]
		var data = load(random_path) as EnemyData
		
		var enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_data = data
		enemy.position = Vector2(start_x + i * 150, 300)
		enemy.died.connect(_on_enemy_died)
		enemy.enemy_clicked.connect(_on_enemy_clicked)   # 如果做了目标选择
		enemy_container.add_child(enemy)
	
	print("遭遇 %d 个敌人！" % count)

func _start_turn() -> void:
	if not combat_active:
		return
	
	GameManager.player_weakness = 0
	current_energy = max_energy

	# ===== 保留格挡 =====
	if retained_block > 0:
		GameManager.player_block = retained_block
		print("保留格挡：", retained_block)
		retained_block = 0
	else:
		GameManager.player_block = 0

	# ===== 应用下回合增益 =====
	if next_turn_bonus_draw > 0:
		print("上回合增益：额外抽 ", next_turn_bonus_draw, " 张牌")
	if next_turn_bonus_energy > 0:
		print("上回合增益：获得 ", next_turn_bonus_energy, " 点能量")
		current_energy += next_turn_bonus_energy
	
	_update_ui()
	_resolve_pending_traps()
	
	# 抽牌
	var draw_count = 5 if is_first_turn else 2
	draw_count += next_turn_bonus_draw
	
	# 用完清零
	next_turn_bonus_draw = 0
	next_turn_bonus_energy = 0
	is_first_turn = false
	
	print("=== 回合开始，抽 ", draw_count, " 张牌 ===")
	for i in range(draw_count):
		_draw_card()

func _draw_card() -> void:
	# 抽牌堆有牌，正常抽
	if not draw_pile.is_empty():
		var card_data = draw_pile.pop_back()
		_add_card_to_hand(card_data)
		return
	
	# 抽牌堆空了，且不再从弃牌堆补充 → 直接疲劳！
	print("!!! 牌库抽空！疲劳伤害: ", fatigue_damage)
	GameManager.player_hp -= fatigue_damage
	fatigue_damage += 1
	print("玩家受到疲劳伤害，剩余HP: ", GameManager.player_hp)
	_update_ui()
	
	if GameManager.player_hp <= 0:
		combat_active = false
		print("玩家死于疲劳...")

func _add_card_to_hand(card_data: CardData) -> void:
	var card_ui = CARD_UI_SCENE.instantiate()
	card_ui.setup(card_data)
	card_ui.card_selected.connect(_on_card_selected)
	hand_container.add_child(card_ui)
	hand.append(card_ui)

# ===== 卡牌被点击（可能是选中，也可能是直接释放）=====
func _on_card_selected(card_data: CardData, card_ui: Control) -> void:
	if not combat_active:
		return
	if current_energy < card_data.cost:
		print("能量不足！")
		return
	
	# 如果已经在选目标状态，先取消
	if selecting_target:
		_cancel_target_selection()
	
	# 不需要选目标的牌：AOE、防御、抽牌、无伤害 → 直接释放
	if card_data.is_aoe or card_data.get_damage() == 0:
		_play_card(card_data, card_ui, null)
		return
	
	# 进入选目标模式
	selecting_target = true
	pending_card = card_data
	pending_card_ui = card_ui
	
	# 高亮所有可选敌人
	_highlight_enemies(true)
	# 高亮选中的卡牌
	card_ui.modulate = Color(1.2, 1.5, 1.2)
	print("[DEBUG] 进入目标选择模式：", card_data.card_name)
	print("请选择攻击目标...（右键取消）")

# ===== 敌人被点击 =====
func _on_enemy_clicked(enemy) -> void:
	print("[DEBUG] 敌人被点击：", enemy)
	if not selecting_target:
		print("[DEBUG] 当前未处于目标选择状态")
		return
	if not is_instance_valid(enemy) or enemy.is_dead:
		print("[DEBUG] 敌人无效或已死亡")
		return
	
	# 对指定敌人释放
	_play_card(pending_card, pending_card_ui, enemy)
	
	# 退出选目标模式
	_cancel_target_selection()

# ===== 取消选目标 =====
func _cancel_target_selection() -> void:
	if not selecting_target:
		return
	selecting_target = false
	_highlight_enemies(false)
	
	# 恢复卡牌颜色
	if pending_card_ui and is_instance_valid(pending_card_ui):
		pending_card_ui.modulate = Color.WHITE
	
	pending_card = null
	pending_card_ui = null

# ===== 通用出牌逻辑 =====
func _play_card(card_data: CardData, card_ui: Control, target_enemy) -> void:
	current_energy -= card_data.cost
	
	# 防御
	if card_data.block > 0:
		GameManager.player_block += card_data.block
		print("获得 ", card_data.block, " 点格挡")
	
	# 抽牌
	if card_data.draw > 0:
		print("抽 ", card_data.draw, " 张牌")
		for i in range(card_data.draw):
			_draw_card()
	
	# 伤害
	if card_data.get_damage() > 0:
		if card_data.is_aoe:
			# 全体攻击
			for child in enemy_container.get_children():
				if is_instance_valid(child) and not child.is_dead:
					child.take_damage(card_data.get_damage())
					var ename = child.enemy_data.enemy_name if child.enemy_data else "敌人"
					print("【AOE】对", ename, "造成", card_data.get_damage(), "伤害")
		else:
			# 单体攻击 → 打指定目标
			if target_enemy and is_instance_valid(target_enemy):
				target_enemy.take_damage(card_data.get_damage())
				var ename = target_enemy.enemy_data.enemy_name if target_enemy.enemy_data else "敌人"
				print("对【", ename, "】造成 ", card_data.get_damage(), " 伤害")
	
	# 卡牌特殊效果
	_apply_card_effect(card_data, target_enemy)

	# 下回合增益
	if card_data.next_turn_draw > 0:
		next_turn_bonus_draw += card_data.next_turn_draw
		print("下回合额外抽 ", card_data.next_turn_draw, " 张")
	if card_data.next_turn_energy > 0:
		next_turn_bonus_energy += card_data.next_turn_energy
		print("下回合额外 ", card_data.next_turn_energy, " 能量")
	
	# 移除手牌
	if card_ui and is_instance_valid(card_ui):
		hand.erase(card_ui)
		discard_pile.append(card_data)
		card_ui.queue_free()
	
	# 检查战斗结束
	_check_all_enemies_dead()
	_update_ui()

func _check_all_enemies_dead() -> void:
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			return
	_end_combat()

func _resolve_pending_traps() -> void:
	if pending_traps.is_empty():
		return
	for trap in pending_traps.duplicate():
		trap.delay -= 1
		if trap.delay <= 0:
			if trap.aoe:
				print("陷阱触发：%s 对所有敌人造成 %d 点伤害" % [trap.name, trap.damage])
				for child in enemy_container.get_children():
					if is_instance_valid(child) and not child.is_dead:
						child.take_damage(trap.damage)
			else:
				var target = _get_random_alive_enemy()
				if target:
					print("陷阱触发：%s 对 %s 造成 %d 点伤害" % [trap.name, target.enemy_data.enemy_name, trap.damage])
					target.take_damage(trap.damage)
			pending_traps.erase(trap)

func _get_random_alive_enemy() -> Node:
	var alive_enemies := []
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			alive_enemies.append(child)
	if alive_enemies.is_empty():
		return null
	return alive_enemies[randi() % alive_enemies.size()]

func _resolve_enemy_statuses() -> void:
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			child.apply_bleed_damage()
			child.apply_burn_damage()

func _apply_card_effect(card_data: CardData, target_enemy) -> void:
	# 自伤效果
	if card_data.self_damage > 0:
		GameManager.take_damage(card_data.self_damage)
		print("使用 %s，自己受到 %d 伤" % [card_data.card_name, card_data.self_damage])

	# 设定延迟陷阱
	if card_data.trap_delay > 0:
		var trap_damage = card_data.trap_damage + GameManager.get_trap_bonus()
		pending_traps.append({
			"delay": card_data.trap_delay,
			"damage": trap_damage,
			"name": card_data.card_name,
			"aoe": card_data.trap_aoe,
		})
		var target_text = "目标敌人"
		if card_data.trap_aoe:
			target_text = "所有敌人"
		print("设置延迟陷阱：%d 回合后对%s造成 %d 点伤害" % [card_data.trap_delay, target_text, trap_damage])

	# 给予流血
	if card_data.bleed_stacks > 0:
		var bleed_amount = card_data.bleed_stacks + GameManager.get_bleed_bonus()
		if card_data.is_aoe or not target_enemy or not is_instance_valid(target_enemy):
			for child in enemy_container.get_children():
				if is_instance_valid(child) and not child.is_dead:
					child.apply_bleed(bleed_amount)
		else:
			target_enemy.apply_bleed(bleed_amount)
		print("%s 给予 %d 层流血" % [card_data.card_name, bleed_amount])

	# 冰伤与冻结
	if card_data.chill_stacks > 0:
		var chill_amount = card_data.chill_stacks + GameManager.get_ice_bonus()
		if card_data.is_aoe or not target_enemy or not is_instance_valid(target_enemy):
			for child in enemy_container.get_children():
				if is_instance_valid(child) and not child.is_dead:
					child.apply_frost(chill_amount)
		else:
			target_enemy.apply_frost(chill_amount)
		print("%s 给予 %d 层冻伤" % [card_data.card_name, chill_amount])

	if card_data.apply_freeze:
		if card_data.is_aoe or not target_enemy or not is_instance_valid(target_enemy):
			for child in enemy_container.get_children():
				if is_instance_valid(child) and not child.is_dead:
					child.frozen = true
					print("%s 冻结了 %s" % [card_data.card_name, child.enemy_data.enemy_name])
		else:
			target_enemy.frozen = true
			print("%s 冻结了 %s" % [card_data.card_name, target_enemy.enemy_data.enemy_name])

	# 火焰灼烧
	if card_data.burn_damage > 0:
		var burn_amount = card_data.burn_damage + GameManager.get_fire_bonus()
		if card_data.is_aoe or not target_enemy or not is_instance_valid(target_enemy):
			for child in enemy_container.get_children():
				if is_instance_valid(child) and not child.is_dead:
					child.apply_burn(burn_amount)
		else:
			target_enemy.apply_burn(burn_amount)
		print("%s 造成 %d 点灼烧" % [card_data.card_name, burn_amount])

	# 保留格挡
	if card_data.retain_block > 0:
		retained_block += card_data.retain_block
		print("下回合保留 %d 点格挡" % card_data.retain_block)

# ===== 高亮/取消高亮敌人 =====
func _highlight_enemies(active: bool) -> void:
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			if active:
				child.modulate = Color(1.3, 1.3, 2.0)  # 发蓝光
			else:
				child.modulate = Color.WHITE

# ===== 右键取消 =====
func _input(event: InputEvent) -> void:
	if selecting_target and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			print("右键取消目标选择")
			_cancel_target_selection()
func _on_end_turn() -> void:
	if not combat_active:
		return
	
	# 每个活着的敌人依次攻击
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			child.attack_player()
	
	if GameManager.player_hp <= 0:
		print("玩家死亡！")
		combat_active = false
		return
	
	_resolve_enemy_statuses()
	_start_turn()

func _update_ui() -> void:
	energy_label.text = "能量: %d/%d" % [current_energy, max_energy]
	hp_label.text = "HP: %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	block_label.text = "格挡: %d" % GameManager.player_block
func _on_enemy_died() -> void:
	# 检查是否还有活着的敌人
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			return
	# 全部死光了
	_end_combat()

func _get_first_alive_enemy() -> Node:
	for child in enemy_container.get_children():
		if is_instance_valid(child) and not child.is_dead:
			return child
	return null
	
	
func _end_combat() -> void:
	combat_active = false
	print("🎉 战斗胜利！")
	
	# ===== 新增：金币奖励 =====
	GameManager.gold += 10
	print("获得 10 金币！当前金币: ", GameManager.gold)
	
	# 禁用所有手牌，防止误点
	for c in hand:
		if c.card_selected.is_connected(_on_card_selected):
			c.card_selected.disconnect(_on_card_selected)
		c.modulate = Color.GRAY
	
	# 显示奖励面板
	_show_reward_panel()

func _show_reward_panel() -> void:
	var rewards = GameManager.get_card_rewards()
	
	# 清空旧按钮
	for child in reward_container.get_children():
		child.queue_free()
	
	for path in rewards:
		var card_data = load(path) as CardData
		if not card_data:
			continue
		
		# 创建选择按钮
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 240)
		
		# 按钮内部用 VBox 布局
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size = Vector2(160, 240)
		
		# 卡牌名
		var name_label = Label.new()
		name_label.text = card_data.card_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(name_label)
		
		# 费用
		var cost_label = Label.new()
		cost_label.text = "费用: %d" % card_data.cost
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(cost_label)
		
		# 效果描述
		var desc_label = Label.new()
		desc_label.text = card_data.description
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(140, 0)
		vbox.add_child(desc_label)
		
		btn.add_child(vbox)
		btn.pressed.connect(_on_reward_selected.bind(path))
		reward_container.add_child(btn)
	
	reward_panel.show()

func _on_reward_selected(card_path: String) -> void:
	var card_data = load(card_path) as CardData
	if card_data:
		GameManager.player_deck.append(card_path)
		print("选择了【%s】加入牌库！当前共 %d 张" % [card_data.card_name, GameManager.player_deck.size()])
	
	# 清理手牌并返回地图
	for c in hand:
		c.queue_free()
	hand.clear()
	
	reward_panel.hide()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/map/MapMain.tscn")

func _on_skip_reward() -> void:
	print("跳过奖励")
	for c in hand:
		c.queue_free()
	hand.clear()
	reward_panel.hide()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/map/MapMain.tscn")	
