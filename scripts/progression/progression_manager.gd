extends Node
class_name ProgressionManager
## 进度管理器 - 统一管理所有进度系统

@onready var level_system: LevelSystem = null
@onready var stats_system: StatsSystem = null

func _ready() -> void:
	# 获取 Autoload 单例
	if has_node("/root/LevelSystem"):
		level_system = get_node("/root/LevelSystem")
	if has_node("/root/StatsSystem"):
		stats_system = get_node("/root/StatsSystem")

	print("[ProgressionManager] Initialized")

## 初始化玩家进度系统
func initialize_player(player: Node3D) -> void:
	if level_system:
		level_system.set_player(player)
	if stats_system:
		stats_system.set_player(player)

	print("[ProgressionManager] Player progression initialized")

## 敌人死亡奖励
func on_enemy_killed(enemy_type: String, enemy_level: int) -> void:
	if not level_system:
		return

	# 基础经验值计算：敌人等级 * 10
	var base_exp := enemy_level * 10

	# 根据敌人类型调整
	var exp_multiplier := 1.0
	match enemy_type:
		"boss":
			exp_multiplier = 5.0
		"elite":
			exp_multiplier = 2.0
		"normal":
			exp_multiplier = 1.0

	var final_exp := int(base_exp * exp_multiplier)
	level_system.add_exp(final_exp)

	print("[ProgressionManager] Enemy killed - granted %d EXP" % final_exp)

## 获取完整进度数据（用于存档）
func get_all_progression_data() -> Dictionary:
	var data := {}

	if level_system:
		data["level"] = level_system.get_save_data()
	if stats_system:
		data["stats"] = stats_system.get_save_data()

	return data

## 加载完整进度数据（从存档）
func load_all_progression_data(data: Dictionary) -> void:
	if level_system and data.has("level"):
		level_system.load_save_data(data["level"])
	if stats_system and data.has("stats"):
		stats_system.load_save_data(data["stats"])

	print("[ProgressionManager] All progression data loaded")

## 重置所有进度（新游戏）
func reset_all_progression() -> void:
	if level_system:
		level_system.load_save_data({"level": 1, "exp": 0})
	if stats_system:
		stats_system.load_save_data({
			"stats": {"str": 10, "agi": 10, "vit": 10, "int": 10, "luk": 10},
			"stat_points": 0
		})

	print("[ProgressionManager] All progression reset to default")
