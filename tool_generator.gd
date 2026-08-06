extends Node

func _ready() -> void:
	print("=== 开始批量生成资源 ===")
	
	_ensure_dir("res://resources/card/common")
	_ensure_dir("res://resources/card/rogue")
	_ensure_dir("res://resources/card/warrior")
	_ensure_dir("res://resources/card/mage")
	_ensure_dir("res://resources/enemies")
	_ensure_dir("res://resources/events")
	_ensure_dir("res://resources/classes")
	_ensure_dir("res://resources/relics/common")
	_ensure_dir("res://resources/relics/rogue")
	_ensure_dir("res://resources/relics/warrior")
	_ensure_dir("res://resources/relics/mage")
	
	_generate_cards()
	_generate_enemies()
	_generate_events()
	_generate_classes()
	_generate_relics()
	
	print("\n=== 全部生成完毕！===")
	print("生成完成后可以删除 ToolGenerator.tscn")

func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

func _save_resource(res: Resource, path: String) -> void:
	var err = ResourceSaver.save(res, path)
	if err == OK:
		print("  ✓ ", path.get_file())
	else:
		push_error("  ✗ 保存失败: " + path)

func _card(d: Dictionary) -> void:
	var c := CardData.new()
	c.id = d.get("id", "")
	c.card_name = d.get("name", "")
	c.cost = d.get("cost", 1)
	c.description = d.get("desc", "")
	c.base_damage = d.get("dmg", 0)
	c.block = d.get("blk", 0)
	c.draw = d.get("draw", 0)
	c.is_aoe = d.get("aoe", false)
	c.bleed_stacks = d.get("bleed", 0)
	c.trap_delay = d.get("trap_delay", 0)
	c.trap_damage = d.get("trap_d", 0)
	c.trap_aoe = d.get("trap_aoe", false)
	c.self_damage = d.get("self_dmg", 0)
	c.retain_block = d.get("retain", 0)
	c.chill_stacks = d.get("chill", 0)
	c.apply_freeze = d.get("freeze", false)
	c.burn_damage = d.get("burn", 0)
	c.next_turn_draw = d.get("nt_draw", 0)
	c.next_turn_energy = d.get("nt_energy", 0)
	c.job_class = d.get("folder", "") if d.get("folder", "") != "common" else ""
	
	_save_resource(c, "res://resources/card/%s/%s.tres" % [d.folder, d.id])

func _relic(d: Dictionary) -> void:
	var r := RelicData.new()
	r.id = d.get("id", "")
	r.relic_name = d.get("name", "")
	r.description = d.get("desc", "")
	r.bonus_damage = d.get("bonus", 0)
	r.trap_bonus = d.get("trap", 0)
	r.bleed_bonus = d.get("bleed", 0)
	r.fire_bonus = d.get("fire", 0)
	r.ice_bonus = d.get("ice", 0)
	r.start_block = d.get("start_blk", 0)
	r.start_energy = d.get("start_eng", 0)
	r.hp_threshold_damage = d.get("hp_thresh", 0)
	r.retain_block_all = d.get("retain", false)
	r.job_class = d.get("folder", "") if d.get("folder", "") != "common" else ""
	
	_save_resource(r, "res://resources/relics/%s/%s.tres" % [d.folder, d.id])

func _generate_cards() -> void:
	print("\n--- 生成通用卡牌 ---")
	_card({"folder":"common", "id":"strike", "name":"打击", "cost":1, "desc":"造成6点伤害", "dmg":6})
	_card({"folder":"common", "id":"defend", "name":"防御", "cost":1, "desc":"获得5点格挡", "blk":5})
	_card({"folder":"common", "id":"cleave", "name":"顺劈斩", "cost":2, "desc":"对所有敌人造成5点伤害", "dmg":5, "aoe":true})
	_card({"folder":"common", "id":"meditate", "name":"冥想", "cost":1, "desc":"下回合抽1张牌并获得1点能量", "nt_draw":1, "nt_energy":1})
	_card({"folder":"common", "id":"quick_draw", "name":"快速抽牌", "cost":1, "desc":"抽2张牌", "draw":2})
	
	print("\n--- 生成盗贼-陷阱流 ---")
	_card({"folder":"rogue", "id":"trap_snare", "name":"捕兽夹", "cost":1, "desc":"1回合后对单体造成15伤害", "trap_delay":1, "trap_d":15})
	_card({"folder":"rogue", "id":"trap_poison", "name":"毒雾陷阱", "cost":2, "desc":"2回合后全体中毒8", "trap_delay":2, "trap_d":8, "trap_aoe":true})
	_card({"folder":"rogue", "id":"trap_bomb", "name":"延时炸药", "cost":2, "desc":"2回合后全体10伤", "trap_delay":2, "trap_d":10, "trap_aoe":true})
	_card({"folder":"rogue", "id":"trap_tripwire", "name":"绊索", "cost":1, "desc":"下回合敌人意图失效", "trap_delay":1})
	_card({"folder":"rogue", "id":"trap_chain", "name":"连环陷阱", "cost":2, "desc":"本局每用过1张陷阱，伤害+3", "dmg":6})
	_card({"folder":"rogue", "id":"trap_master", "name":"陷阱精通", "cost":1, "desc":"能力：每放置1个陷阱抽1牌", "draw":1})
	_card({"folder":"rogue", "id":"trap_detonate", "name":"紧急引爆", "cost":0, "desc":"立即触发所有活跃陷阱"})
	_card({"folder":"rogue", "id":"trap_shadow", "name":"暗影陷阱", "cost":2, "desc":"2回合后造成18伤，获得5格挡", "trap_delay":2, "trap_d":18, "blk":5})
	_card({"folder":"rogue", "id":"trap_caltrops", "name":"铁蒺藜", "cost":1, "desc":"3回合后全体8伤", "trap_delay":3, "trap_d":8, "trap_aoe":true})
	_card({"folder":"rogue", "id":"trap_reset", "name":"重置机关", "cost":1, "desc":"抽2张陷阱牌", "draw":2})
	
	print("\n--- 生成盗贼-流血流 ---")
	_card({"folder":"rogue", "id":"bleed_slash", "name":"割喉", "cost":1, "desc":"造成4伤，给予3流血", "dmg":4, "bleed":3})
	_card({"folder":"rogue", "id":"bleed_blade", "name":"血刃", "cost":2, "desc":"造成7伤，给予5流血", "dmg":7, "bleed":5})
	_card({"folder":"rogue", "id":"bleed_rip", "name":"撕裂", "cost":1, "desc":"给予4流血，抽1牌", "bleed":4, "draw":1})
	_card({"folder":"rogue", "id":"bleed_frenzy", "name":"血之狂暴", "cost":2, "desc":"能力：敌人流血死亡时回复5血"})
	_card({"folder":"rogue", "id":"bleed_sacrifice", "name":"放血", "cost":0, "desc":"自己受到3伤，给予敌人8流血", "self_dmg":3, "bleed":8})
	_card({"folder":"rogue", "id":"bleed_mist", "name":"血雾", "cost":2, "desc":"全体给予3流血", "bleed":3, "aoe":true})
	_card({"folder":"rogue", "id":"bleed_coagulate", "name":"凝血", "cost":1, "desc":"将敌人流血层数翻倍"})
	_card({"folder":"rogue", "id":"bleed_thousand", "name":"千刃", "cost":3, "desc":"造成10伤，给予10流血", "dmg":10, "bleed":10})
	_card({"folder":"rogue", "id":"bleed_leech", "name":"吸血刃", "cost":2, "desc":"造成6伤，敌人每有1层流血伤害+1", "dmg":6, "bleed":2})
	_card({"folder":"rogue", "id":"bleed_epidemic", "name":"血疫", "cost":2, "desc":"转移所有流血到另一敌人", "bleed":5})
	
	print("\n--- 生成战士-烧血流 ---")
	_card({"folder":"warrior", "id":"blood_rage", "name":"狂暴打击", "cost":1, "desc":"造成6伤，自己受到2伤", "dmg":6, "self_dmg":2})
	_card({"folder":"warrior", "id":"blood_sacrifice", "name":"血祭", "cost":0, "desc":"受到5伤，获得2能量", "self_dmg":5, "nt_energy":2})
	_card({"folder":"warrior", "id":"blood_unyielding", "name":"不屈", "cost":2, "desc":"生命低于50%时获得12格挡", "blk":6})
	_card({"folder":"warrior", "id":"blood_bath", "name":"浴血", "cost":1, "desc":"造成8伤，生命越低伤害越高", "dmg":8})
	_card({"folder":"warrior", "id":"blood_berserk", "name":"狂战士之怒", "cost":2, "desc":"能力：生命低于50%时伤害+3"})
	_card({"folder":"warrior", "id":"blood_for_blood", "name":"以血换血", "cost":1, "desc":"受到4伤，造成12伤", "self_dmg":4, "dmg":12})
	_card({"folder":"warrior", "id":"blood_desperation", "name":"绝境反击", "cost":2, "desc":"生命低于30%时造成20伤", "dmg":10})
	_card({"folder":"warrior", "id":"blood_shield", "name":"鲜血护盾", "cost":1, "desc":"失去5生命，获得12格挡", "self_dmg":5, "blk":12})
	_card({"folder":"warrior", "id":"blood_frenzy", "name":"嗜血", "cost":2, "desc":"造成8伤，回复造成伤害一半的生命", "dmg":8})
	_card({"folder":"warrior", "id":"blood_last", "name":"殊死一搏", "cost":3, "desc":"造成15伤，生命低于25%时造成30伤", "dmg":15})
	
	print("\n--- 生成战士-格挡流 ---")
	_card({"folder":"warrior", "id":"shield_iron", "name":"铁壁", "cost":2, "desc":"获得10格挡", "blk":10})
	_card({"folder":"warrior", "id":"shield_bash", "name":"盾击", "cost":1, "desc":"有格挡时造成8伤", "dmg":4})
	_card({"folder":"warrior", "id":"shield_reflect", "name":"反射", "cost":2, "desc":"获得6格挡，下回合保留3格挡", "blk":6, "retain":3})
	_card({"folder":"warrior", "id":"shield_wall", "name":"盾墙", "cost":3, "desc":"获得15格挡", "blk":15})
	_card({"folder":"warrior", "id":"shield_offense", "name":"以守为攻", "cost":1, "desc":"获得4格挡，造成4伤", "blk":4, "dmg":4})
	_card({"folder":"warrior", "id":"shield_absolute", "name":"绝对防御", "cost":2, "desc":"获得8格挡，下回合获得4格挡", "blk":8, "retain":4})
	_card({"folder":"warrior", "id":"shield_counter", "name":"盾反", "cost":1, "desc":"获得3格挡，敌人攻击你时受到3伤", "blk":3})
	_card({"folder":"warrior", "id":"shield_spike", "name":"尖刺盾", "cost":2, "desc":"获得5格挡，对攻击者造成5伤", "blk":5})
	_card({"folder":"warrior", "id":"shield_fortress", "name":"堡垒", "cost":3, "desc":"获得20格挡，下回合保留10格挡", "blk":20, "retain":10})
	_card({"folder":"warrior", "id":"shield_momentum", "name":"动量盾", "cost":1, "desc":"获得3格挡，抽1牌", "blk":3, "draw":1})
	
	print("\n--- 生成法师-冰流 ---")
	_card({"folder":"mage", "id":"ice_bolt", "name":"寒冰箭", "cost":1, "desc":"造成4伤，给予2冻伤", "dmg":4, "chill":2})
	_card({"folder":"mage", "id":"ice_blizzard", "name":"暴风雪", "cost":2, "desc":"全体3伤，给予2冻伤", "dmg":3, "aoe":true, "chill":2})
	_card({"folder":"mage", "id":"ice_deep", "name":"深寒", "cost":1, "desc":"给予4冻伤", "chill":4})
	_card({"folder":"mage", "id":"ice_spike", "name":"冰锥术", "cost":2, "desc":"造成6伤，若目标有冻伤则冻结", "dmg":6, "freeze":true})
	_card({"folder":"mage", "id":"ice_armor", "name":"冰霜护甲", "cost":1, "desc":"获得5格挡，给予攻击者2冻伤", "blk":5, "chill":2})
	_card({"folder":"mage", "id":"ice_field", "name":"极寒领域", "cost":3, "desc":"全体给予3冻伤，抽2牌", "aoe":true, "chill":3, "draw":2})
	_card({"folder":"mage", "id":"ice_shatter", "name":"碎冰", "cost":1, "desc":"对冻结敌人造成15伤", "dmg":8})
	_card({"folder":"mage", "id":"ice_eternal", "name":"永冻", "cost":2, "desc":"能力：敌人冻伤层数不减少"})
	_card({"folder":"mage", "id":"ice_lance", "name":"冰枪术", "cost":2, "desc":"造成8伤，冻结目标", "dmg":8, "freeze":true})
	_card({"folder":"mage", "id":"ice_zero", "name":"绝对零度", "cost":3, "desc":"全体5伤，给予4冻伤", "dmg":5, "aoe":true, "chill":4})
	
	print("\n--- 生成法师-火流 ---")
	_card({"folder":"mage", "id":"fire_ball", "name":"火球术", "cost":2, "desc":"造成12伤", "dmg":12})
	_card({"folder":"mage", "id":"fire_big", "name":"大火球", "cost":3, "desc":"造成20伤", "dmg":20})
	_card({"folder":"mage", "id":"fire_inferno", "name":"炎爆术", "cost":4, "desc":"造成30伤", "dmg":30})
	_card({"folder":"mage", "id":"fire_blast", "name":"火焰冲击", "cost":1, "desc":"造成6伤", "dmg":6})
	_card({"folder":"mage", "id":"fire_burn", "name":"燃烧", "cost":2, "desc":"造成8伤，下回合再造成8伤", "dmg":8, "burn":8})
	_card({"folder":"mage", "id":"fire_storm", "name":"烈焰风暴", "cost":3, "desc":"全体15伤", "dmg":15, "aoe":true})
	_card({"folder":"mage", "id":"fire_armor", "name":"火焰护甲", "cost":2, "desc":"获得5格挡，对攻击者造成5伤", "blk":5})
	_card({"folder":"mage", "id":"fire_overload", "name":"过载", "cost":0, "desc":"下回合能量+2，受到3伤", "self_dmg":3, "nt_energy":2})
	_card({"folder":"mage", "id":"fire_phoenix", "name":"凤凰火", "cost":3, "desc":"造成15伤，回复5生命", "dmg":15})
	_card({"folder":"mage", "id":"fire_meteor", "name":"陨石术", "cost":5, "desc":"全体25伤", "dmg":25, "aoe":true})

func _generate_relics() -> void:
	print("\n--- 生成通用遗物 ---")
	_relic({"folder":"common", "id":"iron_ring", "name":"铁指环", "desc":"打击伤害+1", "bonus":1})
	_relic({"folder":"common", "id":"lucky_coin", "name":"幸运币", "desc":"战斗开始时额外抽1张牌", "start_eng":1})
	
	print("\n--- 生成盗贼遗物 ---")
	_relic({"folder":"rogue", "id":"trap_bag", "name":"陷阱背包", "desc":"陷阱触发伤害+5", "trap":5})
	_relic({"folder":"rogue", "id":"bleed_dagger", "name":"流血匕首", "desc":"攻击给予1额外流血", "bleed":1})
	_relic({"folder":"rogue", "id":"shadow_cloak", "name":"暗影斗篷", "desc":"每回合开始获得1能量", "start_eng":1})
	_relic({"folder":"rogue", "id":"poison_vial", "name":"毒液瓶", "desc":"敌人流血层数减少时额外受到1伤"})
	_relic({"folder":"rogue", "id":"lucky_dice", "name":"幸运骰子", "desc":"抽牌时20%概率再抽1张", "start_eng":1})
	
	print("\n--- 生成战士遗物 ---")
	_relic({"folder":"warrior", "id":"berserker_axe", "name":"狂战斧", "desc":"生命低于50%时伤害+2", "hp_thresh":2})
	_relic({"folder":"warrior", "id":"tower_shield", "name":"塔盾", "desc":"战斗开始获得5格挡", "start_blk":5})
	_relic({"folder":"warrior", "id":"blood_ring", "name":"嗜血戒指", "desc":"击败敌人回复5生命"})
	_relic({"folder":"warrior", "id":"iron_armor", "name":"铁甲", "desc":"格挡不随回合清空", "retain":true})
	_relic({"folder":"warrior", "id":"will_unyielding", "name":"不屈意志", "desc":"受到致命伤害时保留1生命（每场1次）"})
	
	print("\n--- 生成法师遗物 ---")
	_relic({"folder":"mage", "id":"fire_staff", "name":"火焰法杖", "desc":"火系卡牌伤害+3", "fire":3})
	_relic({"folder":"mage", "id":"ice_staff", "name":"寒冰法杖", "desc":"冻伤额外+1层", "ice":1})
	_relic({"folder":"mage", "id":"mana_spring", "name":"魔力源泉", "desc":"每回合开始50%概率能量+1", "start_eng":1})
	_relic({"folder":"mage", "id":"spell_scroll", "name":"法术卷轴", "desc":"首回合抽牌+2", "start_eng":1})
	_relic({"folder":"mage", "id":"element_resonance", "name":"元素共鸣", "desc":"使用火牌后下张冰牌费用-1，反之亦然"})

func _generate_enemies() -> void:
	print("\n--- 生成敌人 ---")
	var enemies := [
		{"name":"史莱姆", "hp":30, "dmg":5, "color":Color(0.9, 0.3, 0.3), "intents":[
			{"name":"撞击","type":"attack","value":5,"target":"player"},
			{"name":"分裂","type":"defend","value":5,"target":"self"}]},
		{"name":"铁甲兽", "hp":50, "dmg":3, "color":Color(0.3, 0.5, 0.9), "intents":[
			{"name":"撞击","type":"attack","value":3,"target":"player"},
			{"name":"硬化","type":"defend","value":8,"target":"self"},
			{"name":"蓄力","type":"buff","value":2,"target":"self"}]},
		{"name":"刺客", "hp":20, "dmg":7, "color":Color(0.7, 0.2, 0.8), "intents":[
			{"name":"突刺","type":"attack","value":7,"target":"player"},
			{"name":"毒刃","type":"debuff","value":2,"target":"player"}]},
		{"name":"哥布林", "hp":25, "dmg":4, "color":Color(0.2, 0.7, 0.3), "intents":[
			{"name":"棍击","type":"attack","value":4,"target":"player"},
			{"name":"嚎叫","type":"buff","value":3,"target":"self"}]},
		{"name":"暗影狼", "hp":35, "dmg":6, "color":Color(0.2, 0.2, 0.3), "intents":[
			{"name":"撕咬","type":"attack","value":6,"target":"player"},
			{"name":"影遁","type":"defend","value":6,"target":"self"}]},
	]
	
	for e in enemies:
		var data := EnemyData.new()
		data.enemy_name = e.name
		data.max_hp = e.hp
		data.attack_damage = e.dmg
		data.color = e.color
		
		for i_info in e.intents:
			var intent := IntentData.new()
			intent.intent_name = i_info.name
			intent.intent_type = i_info.type
			intent.value = i_info.value
			intent.target = i_info.target
			data.intents.append(intent)
		
		var filename = e.name.to_lower().replace(" ", "_")
		_save_resource(data, "res://resources/enemies/%s.tres" % filename)

func _generate_events() -> void:
	print("\n--- 生成事件 ---")
	var events := [
		{"name":"古老祭坛","desc":"你在一座古老祭坛前停下脚步...","options":["献上血液","献上金币","转身离开"],"effects":["damage:5,relic:iron_ring","gold_cost:30,heal:15","none"]},
		{"name":"神秘泉水","desc":"你发现了一汪清澈的泉水...","options":["痛饮一番","装满水袋","离开"],"effects":["heal:10","heal:5,card:random","none"]},
		{"name":"流浪商人","desc":"一个披着斗篷的商人拦住你...","options":["购买卡牌（50金）","购买生命（30金）","抢劫他","离开"],"effects":["gold_cost:50,card:random","gold_cost:30,heal:20","damage:8,gold:100","none"]},
		{"name":"陷阱房间","desc":"你走进一个阴暗的房间，地板突然塌陷！","options":["奋力跳跃","硬抗伤害","使用工具"],"effects":["damage:3","damage:8","gold_cost:10"]},
	]
	
	for e in events:
		var data := EventData.new()
		data.event_name = e.name
		data.description = e.desc
		data.option_texts = e.options
		data.option_effects = e.effects
		
		var filename = e.name.to_lower().replace(" ", "_")
		_save_resource(data, "res://resources/events/%s.tres" % filename)

func _generate_classes() -> void:
	print("\n--- 生成职业 ---")
	var classes := [
		{"id":"rogue","name":"盗贼","hp":50,"gold":150,"energy":3,"desc":"初始金币更多，善于获取资源"},
		{"id":"warrior","name":"战士","hp":70,"gold":100,"energy":3,"desc":"生命值更高，皮糙肉厚"},
		{"id":"mage","name":"法师","hp":50,"gold":100,"energy":4,"desc":"能量上限更高，法术连绵"},
	]
	
	for c in classes:
		var data := ClassData.new()
		data.job_id = c.id
		data.job_name = c.name
		data.max_hp = c.hp
		data.start_gold = c.gold
		data.max_energy = c.energy
		data.description = c.desc
		
		_save_resource(data, "res://resources/classes/%s.tres" % c.id)
