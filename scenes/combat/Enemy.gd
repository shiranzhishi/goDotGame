extends Node2D

signal died
signal enemy_clicked(enemy)

@export var enemy_data: EnemyData

@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var sprite: Sprite2D = $Sprite2D
@onready var intent_label: Label = $IntentLabel   # 需要在场景里加这个节点

var current_hp: int
var is_dead: bool = false

# 战斗状态
var current_block: int = 0       # 格挡/护甲
var strength: int = 0            # 力量（伤害加成）
var bleed_stacks: int = 0        # 流血层数
var frost_stacks: int = 0       # 冻伤层数
var burn_stacks: int = 0        # 燃烧层数
var frozen: bool = false        # 是否被冻结，下一次受到伤害翻倍
var next_intent: IntentData = null

func _ready() -> void:
	if enemy_data:
		_setup_from_data()
	else:
		current_hp = 30
		health_bar.max_value = 30
		health_bar.value = 30
	
	# 连接 Area2D 点击事件
	$Area2D.input_event.connect(_on_area_input)

	# 选择第一个意图
	_choose_next_intent()
	_update_intent_display()

func _setup_from_data() -> void:
	current_hp = enemy_data.max_hp
	health_bar.max_value = enemy_data.max_hp
	health_bar.value = current_hp
	name_label.text = enemy_data.enemy_name
	sprite.modulate = enemy_data.color

func _choose_next_intent() -> void:
	if enemy_data and enemy_data.intents.size() > 0:
		next_intent = enemy_data.intents[randi() % enemy_data.intents.size()] as IntentData
	else:
		# 保底
		next_intent = IntentData.new()
		next_intent.intent_name = "攻击"
		next_intent.intent_type = "attack"
		next_intent.value = enemy_data.attack_damage if enemy_data else 5
		next_intent.target = "player"

func _update_intent_display() -> void:
	if not next_intent:
		return
	if not has_node("IntentLabel"):
		return
	
	var text := ""
	match next_intent.intent_type:
		"attack":
			var dmg = next_intent.value + strength
			text = "⚔ %d" % dmg
		"defend":
			text = "🛡 %d" % next_intent.value
		"buff":
			text = "💪 %s" % next_intent.intent_name
		"debuff":
			text = "💀 %s" % next_intent.intent_name
		_:
			text = next_intent.intent_name
	
	intent_label.text = text

func take_damage(amount: int) -> void:
	if is_dead:
		return

	if frozen:
		amount *= 2
		frozen = false
		print("%s 被冻结，受到的伤害翻倍！" % enemy_data.enemy_name)

	# 护甲先挡
	if current_block > 0:
		if current_block >= amount:
			current_block -= amount
			amount = 0
			print("%s 的护甲抵消了全部伤害！" % enemy_data.enemy_name)
		else:
			amount -= current_block
			current_block = 0
			print("%s 护甲破裂！" % enemy_data.enemy_name)

	current_hp -= amount
	health_bar.value = current_hp
	if current_hp <= 0:
		is_dead = true
		died.emit()
		queue_free()

func apply_bleed(stacks: int) -> void:
	bleed_stacks += stacks
	print("%s 受到 %d 层流血" % [enemy_data.enemy_name, stacks])

func apply_frost(stacks: int) -> void:
	frost_stacks += stacks
	print("%s 受到 %d 层冻伤" % [enemy_data.enemy_name, stacks])
	if frost_stacks >= 3:
		frozen = true
		frost_stacks = 0
		print("%s 被冻结！下一次受到的伤害翻倍" % enemy_data.enemy_name)

func apply_bleed_damage() -> void:
	if is_dead or bleed_stacks <= 0:
		return

	var damage = bleed_stacks
	bleed_stacks = max(0, bleed_stacks - 1)
	print("%s 受到 %d 点流血伤害，剩余流血: %d" % [enemy_data.enemy_name, damage, bleed_stacks])
	take_damage(damage)

func apply_burn(stacks: int) -> void:
	burn_stacks += stacks
	print("%s 受到 %d 点燃烧" % [enemy_data.enemy_name, stacks])

func apply_burn_damage() -> void:
	if is_dead or burn_stacks <= 0:
		return

	var damage = burn_stacks
	burn_stacks = max(0, burn_stacks - 1)
	print("%s 受到 %d 点燃烧伤害，剩余燃烧: %d" % [enemy_data.enemy_name, damage, burn_stacks])
	take_damage(damage)

func execute_intent() -> void:
	if is_dead or not next_intent:
		return
	
	var name = enemy_data.enemy_name if enemy_data else "敌人"
	
	match next_intent.intent_type:
		"attack":
			var dmg = next_intent.value + strength
			if frost_stacks > 0:
				dmg = max(1, dmg - frost_stacks)
				print("%s 的冻伤削弱了攻击，伤害减少 %d" % [enemy_data.enemy_name, frost_stacks])
			print("%s 使用【%s】造成 %d 伤害！" % [name, next_intent.intent_name, dmg])
			GameManager.take_damage(dmg)
		
		"defend":
			current_block += next_intent.value
			print("%s 使用【%s】获得 %d 点护甲！" % [name, next_intent.intent_name, next_intent.value])
		
		"buff":
			if next_intent.intent_name == "蓄力" or next_intent.intent_name == "嚎叫":
				strength += next_intent.value
				print("%s 使用【%s】，力量+%d（当前伤害+%d）" % [name, next_intent.intent_name, next_intent.value, strength])
			else:
				strength += next_intent.value
				print("%s 获得 %d 点力量！" % [name, next_intent.value])
		
		"debuff":
			# 给玩家上虚弱（降低玩家伤害）
			GameManager.player_weakness += next_intent.value
			print("%s 使用【%s】，你受到 %d 层虚弱（伤害-%d）" % [name, next_intent.intent_name, next_intent.value, GameManager.player_weakness])
	
	# 回合结束，选下回合的意图
	_choose_next_intent()
	_update_intent_display()

func attack_player() -> void:
	# 兼容旧代码，实际走 execute_intent
	execute_intent()

func _on_area_input(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[DEBUG] Enemy Area2D input_event 收到左键点击：", self)
		if not is_dead:
			enemy_clicked.emit(self)
