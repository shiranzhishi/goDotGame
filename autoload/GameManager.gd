extends Node

# ===== 玩家基础属性 =====
var player_max_hp: int = 50
var player_hp: int = 50
var gold: int = 100
var player_block: int = 0
var player_weakness: int = 0   # 虚弱层数：每层使玩家伤害-1（最低到1）
var current_class: ClassData = null

# ===== 永久牌库（初始10张）=====
var player_deck: Array[String] = []
# 各职业初始牌库（可扩展）
var class_decks := {
	"rogue": [
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/common/quick_draw.tres",
		"res://resources/card/rogue/trap_snare.tres",
		"res://resources/card/rogue/trap_bomb.tres",
		"res://resources/card/rogue/trap_shadow.tres",
		"res://resources/card/rogue/bleed_slash.tres",
		"res://resources/card/rogue/bleed_blade.tres",
		"res://resources/card/rogue/bleed_rip.tres",
		"res://resources/card/rogue/bleed_sacrifice.tres",
		"res://resources/card/rogue/bleed_mist.tres",
		"res://resources/card/rogue/trap_chain.tres",
		"res://resources/card/rogue/trap_master.tres",
		"res://resources/card/rogue/trap_detonate.tres",
		"res://resources/card/rogue/bleed_coagulate.tres",
		"res://resources/card/rogue/bleed_thousand.tres",
		"res://resources/card/rogue/trap_caltrops.tres",
		"res://resources/card/rogue/trap_tripwire.tres",
	],
	"warrior": [
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/warrior/blood_rage.tres",
		"res://resources/card/warrior/blood_sacrifice.tres",
		"res://resources/card/warrior/blood_unyielding.tres",
		"res://resources/card/warrior/blood_bath.tres",
		"res://resources/card/warrior/blood_berserk.tres",
		"res://resources/card/warrior/blood_for_blood.tres",
		"res://resources/card/warrior/blood_desperation.tres",
		"res://resources/card/warrior/blood_shield.tres",
		"res://resources/card/warrior/shield_iron.tres",
		"res://resources/card/warrior/shield_bash.tres",
		"res://resources/card/warrior/shield_reflect.tres",
		"res://resources/card/warrior/shield_wall.tres",
		"res://resources/card/warrior/shield_offense.tres",
		"res://resources/card/warrior/shield_absolute.tres",
		"res://resources/card/warrior/shield_counter.tres",
		"res://resources/card/warrior/blood_frenzy.tres",
	],
	"mage": [
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/strike.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/common/defend.tres",
		"res://resources/card/mage/fire_ball.tres",
		"res://resources/card/mage/fire_big.tres",
		"res://resources/card/mage/ice_bolt.tres",
		"res://resources/card/mage/ice_blizzard.tres",
		"res://resources/card/mage/ice_spike.tres",
		"res://resources/card/mage/fire_burn.tres",
		"res://resources/card/mage/fire_storm.tres",
		"res://resources/card/mage/ice_armor.tres",
		"res://resources/card/mage/ice_field.tres",
		"res://resources/card/mage/ice_shatter.tres",
		"res://resources/card/mage/fire_inferno.tres",
		"res://resources/card/mage/fire_overload.tres",
		"res://resources/card/mage/ice_lance.tres",
		"res://resources/card/mage/fire_meteor.tres",
		"res://resources/card/mage/ice_deep.tres",
		"res://resources/card/mage/ice_eternal.tres",
		"res://resources/card/mage/fire_phoenix.tres",
		"res://resources/card/mage/fire_armor.tres",
	],
}
# ===== 地图状态 =====
var in_run: bool = false
var map_data: Array = []
var player_map_pos: Vector2i = Vector2i(0, 0)

# ===== 遗物系统 =====
var relics: Array[RelicData] = []

func get_bonus_damage_for_card(card_id: String) -> int:
	var total = 0
	for r in relics:
		# 遗物指定了目标卡牌，且不是这张卡 → 跳过
		if r.target_card_id != "" and r.target_card_id != card_id:
			continue
		total += r.bonus_damage
	return total

func get_trap_bonus() -> int:
	var total = 0
	for r in relics:
		total += r.trap_bonus
	return total

func get_bleed_bonus() -> int:
	var total = 0
	for r in relics:
		total += r.bleed_bonus
	return total

func get_fire_bonus() -> int:
	var total = 0
	for r in relics:
		total += r.fire_bonus
	return total

func get_ice_bonus() -> int:
	var total = 0
	for r in relics:
		total += r.ice_bonus
	return total

func add_relic(relic: RelicData) -> void:
	relics.append(relic)
	print("获得遗物: ", relic.relic_name)

func take_damage(amount: int) -> void:
	if player_block > 0:
		if player_block >= amount:
			player_block -= amount
			amount = 0
			print("格挡抵消了全部伤害！")
		else:
			amount -= player_block
			player_block = 0
			print("格挡破裂！剩余伤害: ", amount)
	player_hp -= amount
	player_hp = max(0, player_hp)

func get_card_rewards() -> Array[String]:
	var pool := get_available_card_pool()
	pool.shuffle()
	
	var unique: Array[String] = []
	for path in pool:
		if not path in unique:
			unique.append(path)
		if unique.size() >= 3:
			break
	
	# 保底：如果不足3个，用 strike 补
	while unique.size() < 3:
		unique.append("res://resources/card/strike.tres")
	
	unique.shuffle()
	return unique
	
func add_random_card_to_deck() -> String:
	var pool := get_available_card_pool()
	if pool.is_empty():
		pool = ["res://resources/card/strike.tres"]
	
	var random_path = pool[randi() % pool.size()]
	player_deck.append(random_path)
	
	var card_data = load(random_path) as CardData
	var card_name = card_data.card_name if card_data else "未知卡牌"
	print("获得了新卡牌：【", card_name, "】！当前牌库数量: ", player_deck.size())
	return card_name

func init_with_class(class_data: ClassData) -> void:
	current_class = class_data
	player_max_hp = class_data.max_hp
	player_hp = class_data.max_hp
	gold = class_data.start_gold
	player_block = 0
	relics.clear()
	in_run = false
	map_data.clear()
	player_map_pos = Vector2i(0, 0)
	
	# 加载职业专属牌库
	var deck_key := class_data.job_id
	if class_decks.has(deck_key):
		player_deck.assign(class_decks[deck_key])
	else:
		# fallback 通用牌库
		player_deck = []
	
	print("选择了【%s】" % class_data.job_name)
	print("初始HP: %d | 金币: %d | 能量上限: %d" % [player_max_hp, gold, class_data.max_energy])
	
func get_available_card_pool() -> Array[String]:
	var folders = [
		"res://resources/card/common/",
		"res://resources/card/rogue/",
		"res://resources/card/warrior/",
		"res://resources/card/mage/",
	]
	
	var all_cards: Array[String] = []
	for folder in folders:
		var dir = DirAccess.open(folder)
		if not dir:
			continue
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				all_cards.append(folder + file)
			file = dir.get_next()
		dir.list_dir_end()
	
	var filtered: Array[String] = []
	var current_job_id := current_class.job_id if current_class else ""
	for path in all_cards:
		var card = load(path) as CardData
		if not card:
			continue
		if card.job_class == "" or card.job_class == current_job_id:
			filtered.append(path)
	return filtered
