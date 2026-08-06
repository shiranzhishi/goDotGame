extends Node2D

@onready var rogue_btn: Button = $CanvasLayer/RogueButton
@onready var warrior_btn: Button = $CanvasLayer/WarriorButton
@onready var mage_btn: Button = $CanvasLayer/MageButton
@onready var info_label: Label = $CanvasLayer/InfoLabel

func _ready() -> void:
	rogue_btn.pressed.connect(_select_class.bind("rogue"))
	warrior_btn.pressed.connect(_select_class.bind("warrior"))
	mage_btn.pressed.connect(_select_class.bind("mage"))
	
	# 鼠标悬停显示描述
	rogue_btn.mouse_entered.connect(_show_info.bind("rogue"))
	warrior_btn.mouse_entered.connect(_show_info.bind("warrior"))
	mage_btn.mouse_entered.connect(_show_info.bind("mage"))

func _show_info(class_key: String) -> void:
	var data: ClassData
	match class_key:
		"rogue":
			data = load("res://resources/classes/rogue.tres") as ClassData
		"warrior":
			data = load("res://resources/classes/warrior.tres") as ClassData
		"mage":
			data = load("res://resources/classes/mage.tres") as ClassData
	
	if data:
		info_label.text = "%s\n生命: %d | 金币: %d | 能量: %d\n%s" % [
			data.job_name, data.max_hp, data.start_gold, data.max_energy, data.description
		]

func _select_class(class_key: String) -> void:
	var data: ClassData
	match class_key:
		"rogue":
			data = load("res://resources/classes/rogue.tres") as ClassData
		"warrior":
			data = load("res://resources/classes/warrior.tres") as ClassData
		"mage":
			data = load("res://resources/classes/mage.tres") as ClassData
	
	if data:
		GameManager.init_with_class(data)
		get_tree().change_scene_to_file("res://scenes/map/MapMain.tscn")
