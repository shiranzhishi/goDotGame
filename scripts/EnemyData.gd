class_name EnemyData
extends Resource

@export var enemy_name: String = "敌人"
@export var max_hp: int = 30
@export var attack_damage: int = 5
@export var color: Color = Color.RED
@export var intents: Array = []   # ← 直接用外部类
