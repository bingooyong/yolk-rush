extends Node
class_name StatsSystem
## 属性系统 - 管理 5 大属性和加成计算

signal stats_changed(stats: Dictionary)
signal stat_points_changed(points: int)

enum StatType {
	STR,  # 力量
	AGI,  # 敏捷
	VIT,  # 体质
	INT,  # 智力
	LUK   # 幸运
}

var base_stats: Dictionary = {
	"str": 10,
	"agi": 10,
	"vit": 10,
	"int": 10,
	"luk": 10
}

var stat_points: int = 0

## 属性加成公式配置
const STAT_BONUSES := {
	"str": {"physical_damage": 2.0},
	"agi": {"attack_speed": 0.005, "evasion": 0.003},
	"vit": {"max_health": 10.0},
	"int": {"skill_damage_mult": 0.03},
	"luk": {"crit_chance": 0.005, "drop_rate": 0.002}
}

@onready var player_ref: Node3D = null

func _ready() -> void:
	print("[StatsSystem] Initialized")

## 设置玩家引用
func set_player(player: Node3D) -> void:
	player_ref = player
	_apply_stats_to_player()
	print("[StatsSystem] Player reference set")

## 添加属性点
func add_stat_points(amount: int) -> void:
	stat_points += amount
	stat_points_changed.emit(stat_points)
	print("[StatsSystem] +%d stat points (total: %d)" % [amount, stat_points])

## 分配属性点
func allocate_stat(stat_name: String, amount: int = 1) -> bool:
	if stat_points < amount:
		push_warning("[StatsSystem] Not enough stat points (%d < %d)" % [stat_points, amount])
		return false

	if not base_stats.has(stat_name):
		push_error("[StatsSystem] Invalid stat name: %s" % stat_name)
		return false

	base_stats[stat_name] += amount
	stat_points -= amount

	print("[StatsSystem] Allocated %d to %s (new value: %d)" % [amount, stat_name, base_stats[stat_name]])

	stat_points_changed.emit(stat_points)
	stats_changed.emit(base_stats)

	# 更新角色数值
	_apply_stats_to_player()

	return true

## 重置属性（消耗金币）
func reset_stats(cost: int = 1000) -> bool:
	# TODO: 集成货币系统后实现
	# if not CurrencySystem.has_gold(cost):
	#     return false
	# CurrencySystem.spend_gold(cost)

	# 计算总投入点数
	var total_points := 0
	for stat_name in base_stats.keys():
		total_points += base_stats[stat_name] - 10  # 初始每项 10

	# 重置为初始值
	base_stats = {
		"str": 10,
		"agi": 10,
		"vit": 10,
		"int": 10,
		"luk": 10
	}

	stat_points = total_points

	print("[StatsSystem] Stats reset - returned %d points" % total_points)

	stats_changed.emit(base_stats)
	stat_points_changed.emit(stat_points)
	_apply_stats_to_player()

	return true

## 计算属性加成
func calculate_stat_bonus(stat_name: String, bonus_type: String) -> float:
	if not STAT_BONUSES.has(stat_name):
		return 0.0

	var bonuses: Dictionary = STAT_BONUSES[stat_name]
	if not bonuses.has(bonus_type):
		return 0.0

	var stat_value: int = base_stats.get(stat_name, 0)
	var multiplier: float = bonuses[bonus_type]

	return stat_value * multiplier

## 获取所有加成
func get_all_bonuses() -> Dictionary:
	var bonuses := {
		"physical_damage": 0.0,
		"attack_speed": 0.0,
		"evasion": 0.0,
		"max_health": 0.0,
		"skill_damage_mult": 0.0,
		"crit_chance": 0.0,
		"drop_rate": 0.0
	}

	# STR
	bonuses["physical_damage"] += calculate_stat_bonus("str", "physical_damage")

	# AGI
	bonuses["attack_speed"] += calculate_stat_bonus("agi", "attack_speed")
	bonuses["evasion"] += calculate_stat_bonus("agi", "evasion")

	# VIT
	bonuses["max_health"] += calculate_stat_bonus("vit", "max_health")

	# INT
	bonuses["skill_damage_mult"] += calculate_stat_bonus("int", "skill_damage_mult")

	# LUK
	bonuses["crit_chance"] += calculate_stat_bonus("luk", "crit_chance")
	bonuses["drop_rate"] += calculate_stat_bonus("luk", "drop_rate")

	return bonuses

## 应用属性到玩家
func _apply_stats_to_player() -> void:
	if not player_ref:
		return

	var bonuses := get_all_bonuses()

	# 更新最大生命值
	if player_ref.has_node("HealthComponent"):
		var health = player_ref.get_node("HealthComponent")
		if health.has_method("set_max_health_bonus"):
			health.set_max_health_bonus(bonuses["max_health"])

	# 更新攻击力
	if player_ref.has_node("CombatComponent"):
		var combat = player_ref.get_node("CombatComponent")
		if combat.has_method("set_physical_damage_bonus"):
			combat.set_physical_damage_bonus(bonuses["physical_damage"])

		# 更新攻击速度
		if combat.has_method("set_attack_speed_multiplier"):
			combat.set_attack_speed_multiplier(1.0 + bonuses["attack_speed"])

		# 更新暴击率
		if combat.has_method("set_crit_chance_bonus"):
			combat.set_crit_chance_bonus(bonuses["crit_chance"])

	# 更新技能伤害
	if player_ref.has_node("SkillSystem"):
		var skills = player_ref.get_node("SkillSystem")
		if skills.has_method("set_skill_damage_multiplier"):
			skills.set_skill_damage_multiplier(1.0 + bonuses["skill_damage_mult"])

	print("[StatsSystem] Applied stats to player")

## 获取属性详情（用于 UI）
func get_stat_details(stat_name: String) -> Dictionary:
	var value: int = base_stats.get(stat_name, 0)
	var bonuses_dict := STAT_BONUSES.get(stat_name, {})

	var details := {
		"name": _get_stat_display_name(stat_name),
		"value": value,
		"bonuses": []
	}

	for bonus_type in bonuses_dict.keys():
		var bonus_value := calculate_stat_bonus(stat_name, bonus_type)
		details["bonuses"].append({
			"type": _get_bonus_display_name(bonus_type),
			"value": bonus_value
		})

	return details

## 获取所有属性详情
func get_all_stats_details() -> Array:
	var all_details := []
	for stat_name in base_stats.keys():
		all_details.append(get_stat_details(stat_name))
	return all_details

func _get_stat_display_name(stat_name: String) -> String:
	match stat_name:
		"str": return "力量"
		"agi": return "敏捷"
		"vit": return "体质"
		"int": return "智力"
		"luk": return "幸运"
		_: return stat_name

func _get_bonus_display_name(bonus_type: String) -> String:
	match bonus_type:
		"physical_damage": return "物理攻击"
		"attack_speed": return "攻击速度"
		"evasion": return "闪避率"
		"max_health": return "最大生命值"
		"skill_damage_mult": return "技能伤害"
		"crit_chance": return "暴击率"
		"drop_rate": return "掉落率"
		_: return bonus_type

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"stats": base_stats.duplicate(),
		"stat_points": stat_points
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	base_stats = data.get("stats", {
		"str": 10,
		"agi": 10,
		"vit": 10,
		"int": 10,
		"luk": 10
	})
	stat_points = data.get("stat_points", 0)

	print("[StatsSystem] Loaded save - %d stat points" % stat_points)

	stats_changed.emit(base_stats)
	stat_points_changed.emit(stat_points)
	_apply_stats_to_player()

## 调试：添加属性点
func _debug_add_stat_points(amount: int) -> void:
	add_stat_points(amount)
	print("[StatsSystem] DEBUG: Added %d stat points" % amount)
