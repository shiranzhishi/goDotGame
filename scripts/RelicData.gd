class_name RelicData
extends Resource

@export var id: String = ""
@export var relic_name: String = "遗物"
@export var description: String = ""
@export var bonus_damage: int = 0
@export var job_class: String = ""

# 流派加成
@export var trap_bonus: int = 0
@export var bleed_bonus: int = 0
@export var fire_bonus: int = 0
@export var ice_bonus: int = 0
@export var start_block: int = 0
@export var start_energy: int = 0
@export var hp_threshold_damage: int = 0
@export var retain_block_all: bool = false
