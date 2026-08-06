extends Node2D

@onready var deck_panel: Panel = $CanvasLayer/DeckPanel
@onready var card_grid: GridContainer = $CanvasLayer/DeckPanel/ScrollContainer/CardGrid
@onready var deck_count_label: Label = $CanvasLayer/DeckPanel/DeckCountLabel
@onready var deck_button: Button = $CanvasLayer/DeckButton
@onready var close_button: Button = $CanvasLayer/DeckPanel/CloseButton
@onready var event_panel: Panel = $CanvasLayer/EventPanel
@onready var event_title: Label = $CanvasLayer/EventPanel/TitleLabel
@onready var event_desc: Label = $CanvasLayer/EventPanel/DescLabel
@onready var event_options: VBoxContainer = $CanvasLayer/EventPanel/OptionsContainer
@onready var event_continue: Button = $CanvasLayer/EventPanel/ContinueButton
@onready var hp_label: Label = $CanvasLayer/StatusBar/HPLabel
@onready var gold_label: Label = $CanvasLayer/StatusBar/GoldLabel
@onready var shop_panel: Panel = $CanvasLayer/ShopPanel
@onready var shop_gold_label: Label = $CanvasLayer/ShopPanel/GoldLabel
@onready var shop_items: VBoxContainer = $CanvasLayer/ShopPanel/ItemsContainer
@onready var shop_leave: Button = $CanvasLayer/ShopPanel/LeaveButton

var current_shop_items: Array[Dictionary] = []  # 记录当前商店商品
const MAP_COLS = 3
const MAP_ROWS = 9

var player_pos: Vector2i

func _ready():
	if not GameManager.in_run:
		_new_run()
	else:
		_load_run()
	_render_map()
	_update_reachable()
	_update_status_bar()
	deck_button.pressed.connect(_on_deck_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	event_continue.pressed.connect(_on_event_continue)
	shop_leave.pressed.connect(_on_leave_shop)
		
func _new_run():
	GameManager.in_run = true
	player_pos = Vector2i(0, 0)
	GameManager.player_map_pos = player_pos
	GameManager.map_data = []
	for c in range(MAP_COLS):
		var col = []
		for r in range(MAP_ROWS):
			var type = _random_type()
			col.append({"type": type, "visited": false})
		GameManager.map_data.append(col)
	# 起点标记已访问
	GameManager.map_data[0][0].visited = true

func _load_run():
	player_pos = GameManager.player_map_pos

func _random_type() -> String:
	var roll = randf()
	if roll < 0.50:
		return "combat"
	elif roll < 0.75:
		return "event"
	elif roll < 0.85:
		return "shop"       # ← 新增：商店格
	else:
		return "empty"

func _render_map():
	# 清除旧的地图节点
	for child in get_children():
		if child.is_in_group("map_node"):
			child.queue_free()
	
	for c in range(MAP_COLS):
		for r in range(MAP_ROWS):
			var btn = Button.new()
			btn.add_to_group("map_node")
			btn.custom_minimum_size = Vector2(80, 80)
			btn.size = Vector2(80, 80)
			
			var data = GameManager.map_data[c][r]
			
			# 外观
			btn.custom_minimum_size = Vector2(80, 80)
			btn.size = Vector2(80, 80)
			
			# 动态居中位置
			var col_gap = 95
			var row_gap = 70
			var grid_width = 3 * 80 + 2 * (col_gap - 80)
			var grid_height = 9 * 60 + 8 * (row_gap - 60)
			var start_x = (1280 - grid_width) / 2
			var start_y = 600
			
			btn.position = Vector2(start_x + c * col_gap, start_y + r * row_gap)
			
			# 格子背景
			# 用 StyleBoxFlat 代替 StyleBoxTexture，支持边框
			var cell_style = StyleBoxFlat.new()
			cell_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)  # 半透明深色背景
			cell_style.border_width_left = 2
			cell_style.border_width_top = 2
			cell_style.border_width_right = 2
			cell_style.border_width_bottom = 2
			cell_style.border_color = Color(0.4, 0.4, 0.5)     # 灰蓝边框
			cell_style.corner_radius_top_left = 4              # 圆角（可选）
			cell_style.corner_radius_top_right = 4
			cell_style.corner_radius_bottom_left = 4
			cell_style.corner_radius_bottom_right = 4
			btn.add_theme_stylebox_override("normal", cell_style)
			
			# 图标
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# 图标颜色（只影响图标）
			match data.type:
				"combat":
					btn.icon = load("res://assets/icons/icon_combat.png")
					btn.modulate = Color(1, 0.6, 0.6)  # 淡红
				"event":
					btn.icon = load("res://assets/icons/icon_event.png")
					btn.modulate = Color(1, 1, 0.6)     # 淡黄
				"shop":
					btn.icon = load("res://assets/icons/icon_shop.png")
					btn.modulate = Color(0.6, 1, 0.6)   # 淡绿
				_:
					btn.modulate = Color(0.7, 0.7, 0.7)
								
			btn.position = Vector2(start_x + c * col_gap, start_y - r * row_gap)
			# 保存坐标到按钮
			btn.set_meta("col", c)
			btn.set_meta("row", r)
			
			btn.pressed.connect(_on_node_pressed.bind(c, r))
			add_child(btn)
	
	# 玩家位置标记（绿色小方块）
	var marker = ColorRect.new()
	marker.add_to_group("map_node")
	marker.size = Vector2(20, 20)
	marker.color = Color.GREEN
	marker.position = Vector2(
		510 + player_pos.x * 95 + 30,
		600 - player_pos.y * 70 + 30
	)
	add_child(marker)

func _on_node_pressed(c: int, r: int):
	if not _is_reachable(c, r):
		return
	
	player_pos = Vector2i(c, r)
	GameManager.player_map_pos = player_pos
	GameManager.map_data[c][r].visited = true
	
	var type = GameManager.map_data[c][r].type
	match type:
		"combat":
			get_tree().change_scene_to_file("res://scenes/combat/CombatMain.tscn")
		"event":
			player_pos = Vector2i(c, r)
			GameManager.player_map_pos = player_pos
			GameManager.map_data[c][r].visited = true
			_show_event()
		"shop":
			player_pos = Vector2i(c, r)
			GameManager.player_map_pos = player_pos
			GameManager.map_data[c][r].visited = true
			_show_shop()	
		"empty":
			# 直接走过去，不产生交互
			_render_map()
			_update_reachable()

func _is_reachable(c: int, r: int) -> bool:
	var data = GameManager.map_data[c][r]
	if data.visited:
		return false
	if r < player_pos.y:
		return false  # 不能向后（向下走）
	# 曼哈顿距离为1（上下左右相邻）
	var dist = abs(c - player_pos.x) + abs(r - player_pos.y)
	return dist == 1

func _update_reachable():
	for child in get_children():
		if child.is_in_group("map_node") and child is Button:
			var c = child.get_meta("col")
			var r = child.get_meta("row")
			var data = GameManager.map_data[c][r]
			
			if data.visited:
				child.modulate = Color(0.3, 0.3, 0.3)
				child.disabled = true
			elif _is_reachable(c, r):
				child.modulate = Color.WHITE
				child.disabled = false
			else:
				child.modulate = Color(0.2, 0.2, 0.2, 0.3)
				child.disabled = true
				
			
func _on_deck_button_pressed() -> void:
	_show_deck()

func _on_close_button_pressed() -> void:
	deck_panel.hide()

func _show_deck() -> void:
	# 清空旧内容
	for child in card_grid.get_children():
		child.queue_free()
	
	# 加载并显示所有卡牌
	var total_cards := 0
	for path in GameManager.player_deck:
		var card_data = load(path) as CardData
		if card_data:
			var card_preview = _create_card_preview(card_data)
			card_grid.add_child(card_preview)
			total_cards += 1
	
	deck_count_label.text = "共 %d 张" % total_cards
	deck_panel.show()

func _create_card_preview(card_data: CardData) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(140, 180)
	
	# 背景用 ColorRect，颜色亮一点
	var bg = ColorRect.new()
	bg.color = Color(0.35, 0.35, 0.4)   # ← 改亮一点，原来是 0.2
	bg.size = Vector2(140, 180)
	panel.add_child(bg)
	
	# 卡牌名 - 白色文字
	var name_label = Label.new()
	name_label.text = card_data.card_name
	name_label.position = Vector2(10, 10)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)  # ← 强制白色
	panel.add_child(name_label)
	
	# 费用
	var cost_label = Label.new()
	cost_label.text = "费用:%d" % card_data.cost
	cost_label.position = Vector2(10, 40)
	cost_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))  # ← 金黄色
	panel.add_child(cost_label)
	
	# 效果描述
	var desc = ""
	if card_data.base_damage > 0:
		desc += "伤害:%d\n" % card_data.get_damage()
	if card_data.block > 0:
		desc += "格挡:%d\n" % card_data.block
	if card_data.draw > 0:
		desc += "抽牌:%d" % card_data.draw
	
	var desc_label = Label.new()
	desc_label.text = desc if desc != "" else "无效果"
	desc_label.position = Vector2(10, 70)
	desc_label.size = Vector2(120, 80)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))  # ← 浅灰
	panel.add_child(desc_label)
	
	return panel		
	
func _show_event() -> void:
	# 动态扫描 events 文件夹下的所有 .tres
	var event_files: Array[String] = []
	var dir = DirAccess.open("res://resources/events/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				event_files.append("res://resources/events/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# 保底：如果文件夹为空，用默认事件
	if event_files.is_empty():
		push_warning("events 文件夹为空！使用默认事件")
		_show_default_event()
		return
	
	# 随机选一个事件
	var random_path = event_files[randi() % event_files.size()]
	var event_data = load(random_path) as EventData
	
	if not event_data:
		push_error("无法加载事件: " + random_path)
		_show_default_event()
		return
	
	# 显示事件
	event_title.text = event_data.event_name
	event_desc.text = event_data.description
	
	# 清空旧选项
	for child in event_options.get_children():
		child.queue_free()
	
	# 创建选项按钮
	for i in range(event_data.option_texts.size()):
		var btn = Button.new()
		btn.text = event_data.option_texts[i]
		btn.custom_minimum_size = Vector2(400, 50)
		btn.pressed.connect(_on_event_option_selected.bind(event_data.option_effects[i]))
		event_options.add_child(btn)
	
	event_continue.hide()
	event_panel.show()

func _show_default_event() -> void:
	# 当没有事件文件时的保底
	event_title.text = "空房间"
	event_desc.text = "这里什么都没有..."
	
	for child in event_options.get_children():
		child.queue_free()
	
	var btn = Button.new()
	btn.text = "离开"
	btn.pressed.connect(_on_event_option_selected.bind("none"))
	event_options.add_child(btn)
	
	event_continue.hide()
	event_panel.show()
	
func _on_event_option_selected(effect_str: String) -> void:
	# 执行效果并获取结果文本
	var result_text = _apply_event_effects(effect_str)
	
	# 清空选项按钮
	for child in event_options.get_children():
		child.queue_free()
	
	event_desc.text = "你做出了选择。结果已经显现...\n" + result_text
	event_continue.show()
	
	# 检查死亡
	if GameManager.player_hp <= 0:
		print("玩家死于事件！")
		event_continue.text = "游戏结束"

func _on_event_continue() -> void:
	event_panel.hide()
	event_continue.text = "继续"
	_update_status_bar()
	_render_map()
	_update_reachable()

func _apply_event_effects(effect_str: String) -> String:
	if effect_str == "none":
		print("什么也没发生...")
		return "什么也没发生..."
	
	var effects = effect_str.split(",")
	var result_lines: Array[String] = []
	for eff in effects:
		var parts = eff.split(":")
		var type = parts[0]
		var value = parts[1] if parts.size() > 1 else ""
		
		match type:
			"heal":
				var amount = int(value)
				GameManager.player_hp = min(GameManager.player_max_hp, GameManager.player_hp + amount)
				var line = "回复了 %d 点生命，当前HP: %d" % [amount, GameManager.player_hp]
				print(line)
				result_lines.append(line)
			
			"damage":
				var amount = int(value)
				GameManager.player_hp -= amount
				var line = "受到了 %d 点伤害，当前HP: %d" % [amount, GameManager.player_hp]
				print(line)
				result_lines.append(line)
			
			"gold":
				var amount = int(value)
				GameManager.gold += amount
				var line = "获得了 %d 金币" % amount
				print(line)
				result_lines.append(line)
			
			"gold_cost":
				var amount = int(value)
				GameManager.gold -= amount
				var line = "失去了 %d 金币" % amount
				print(line)
				result_lines.append(line)
			
			"relic":
				if value == "iron_ring":
					var relic = load("res://resources/relics/common/iron_ring.tres") as RelicData
					if relic:
						GameManager.add_relic(relic)
						var line = "获得了遗物：%s" % relic.relic_name
						print(line)
						result_lines.append(line)
			
			"card":
				if value == "random":
					var card_name = GameManager.add_random_card_to_deck()
					var line = "获得了卡牌：%s" % card_name
					print(line)
					result_lines.append(line)

	return "\n".join(result_lines)
	
func _update_status_bar() -> void:
	hp_label.text = "HP: %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	gold_label.text = "金币: %d" % [GameManager.gold]


	
func _get_available_relics() -> Array[String]:
	var result: Array[String] = []
	var folders: Array[String] = ["common"]
	
	# 加入职业专属文件夹
	if GameManager.current_class:
		match GameManager.current_class.job_id:
			"rogue":
				folders.append("rogue")
			"warrior":
				folders.append("warrior")
			"mage":
				folders.append("mage")
	
	# 扫描所有对应文件夹
	for folder in folders:
		var path = "res://resources/relics/%s/" % folder
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.ends_with(".tres"):
					result.append(path + file)
				file = dir.get_next()
			dir.list_dir_end()
	
	return result
	
func _show_shop() -> void:
	# 生成随机商品
	current_shop_items.clear()
	
	# 商品1：随机卡牌，50金币
	var card_pool = GameManager.get_available_card_pool()  # 复用奖励池
	if card_pool.size() > 0:
		var path1 = card_pool[randi() % card_pool.size()]
		current_shop_items.append({
			"type": "card",
			"path": path1,
			"price": 50,
			"sold": false
		})
	
	# 商品2：另一张随机卡牌，80金币
	if card_pool.size() > 1:
		var path2 = card_pool[randi() % card_pool.size()]
		while path2 == current_shop_items[0].path:
			path2 = card_pool[randi() % card_pool.size()]
		current_shop_items.append({
			"type": "card",
			"path": path2,
			"price": 80,
			"sold": false
		})
	
	# 商品3：随机遗物（通用 + 职业专属）
	var relic_pool = _get_available_relics()
	if not relic_pool.is_empty():
		var random_relic = relic_pool[randi() % relic_pool.size()]
		current_shop_items.append({
			"type": "relic",
			"relic_path": random_relic,
			"price": 120,
			"sold": false
		})
	
	_refresh_shop_ui()

func _refresh_shop_ui() -> void:
	shop_gold_label.text = "金币: %d" % GameManager.gold
	
	# 清空旧按钮
	for child in shop_items.get_children():
		child.queue_free()
	
	for i in range(current_shop_items.size()):
		var item = current_shop_items[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(500, 60)
		
		if item.sold:
			btn.text = "【已售罄】"
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
		else:
			var name_str = ""
			if item.type == "card":
				var card_data = load(item.path) as CardData
				name_str = card_data.card_name if card_data else "未知卡牌"
			else:
				var relic_data = load(item.relic_path) as RelicData
				name_str = relic_data.relic_name if relic_data else "未知遗物"
			
			btn.text = "%s  ——  %d 金币" % [name_str, item.price]
			btn.pressed.connect(_on_buy_item.bind(i))
		
		shop_items.add_child(btn)
	
	shop_panel.show()

func _on_buy_item(index: int) -> void:
	var item = current_shop_items[index]
	if item.sold:
		return
	if GameManager.gold < item.price:
		print("金币不足！")
		return
	
	# 扣钱
	GameManager.gold -= item.price
	print("花费 %d 金币购买了商品" % item.price)
	
	# 给货
	if item.type == "card":
		GameManager.player_deck.append(item.path)
		var card_data = load(item.path) as CardData
		print("获得卡牌：【%s】" % (card_data.card_name if card_data else "?"))
	else:
		var relic = load(item.relic_path) as RelicData
		if relic:
			GameManager.add_relic(relic)
	
	# 标记已售
	item.sold = true
	_refresh_shop_ui()
	_update_status_bar()  # 刷新左上角金币显示

func _on_leave_shop() -> void:
	shop_panel.hide()
	_render_map()
	_update_reachable()
