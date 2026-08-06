class_name CardData
extends Resource

@export var id: String = ""
@export var card_name: String = "卡牌"
@export var cost: int = 1
@export var base_damage: int = 0
@export var block: int = 0
@export var draw: int = 0
@export var is_aoe: bool = false
@export var next_turn_draw: int = 0
@export var next_turn_energy: int = 0
@export var job_class: String = ""
@export var description: String = ""

# ===== 盗贼-流血 =====
@export var bleed_stacks: int = 0

# ===== 盗贼-陷阱 =====
@export var trap_delay: int = 0      # 0=无, 1=1回合后, 2=2回合后...
@export var trap_damage: int = 0
@export var trap_aoe: bool = false

# ===== 战士-烧血 =====
@export var self_damage: int = 0     # 自己受到的伤害

# ===== 战士-格挡 =====
@export var retain_block: int = 0    # 下回合保留格挡

# ===== 法师-冰 =====
@export var chill_stacks: int = 0    # 冻伤层数
@export var apply_freeze: bool = false

# ===== 法师-火 =====
@export var burn_damage: int = 0     # 额外燃烧伤害（下回合触发）

func get_damage() -> int:
	var dmg = base_damage + GameManager.get_bonus_damage_for_card(id)
	if GameManager.player_weakness > 0:
		dmg = max(1, dmg - GameManager.player_weakness)
	return dmg
