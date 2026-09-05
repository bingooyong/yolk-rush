extends Node
class_name BalanceManager
## 游戏数值平衡管理器
## 负责加载和应用游戏平衡配置

## 信号
signal balance_loaded()
signal difficulty_changed(difficulty: String)

## 平衡配置数据
var balance_config: Dictionary = {}

## 当前难度
var current_difficulty: String = "normal"

## 配置文件路径
const BALANCE_CONFIG_PATH = "res://data/balance/game_balance.json"

func _ready() -> void:
	load_balance_config()

## 加载平衡配置
func load_balance_config() -> bool:
	var file = FileAccess.open(BALANCE_CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("[BalanceManager] Failed to load balance config from: %s" % BALANCE_CONFIG_PATH)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[BalanceManager] Failed to parse balance config: %s" % json.get_error_message())
		return false

	balance_config = json.data
	print("[BalanceManager] Balance config loaded successfully")
	balance_loaded.emit()
	return true

## 获取玩家配置
func get_player_config() -> Dictionary:
	if not balance_config.has("player"):
		return {}

	var config = balance_config.player.duplicate()

	# 应用难度修正
	var difficulty_mod = get_difficulty_modifiers()
	if difficulty_mod.has("player_health_multiplier"):
		config.base_health *= difficulty_mod.player_health_multiplier
	if difficulty_mod.has("player_damage_multiplier"):
		config.damage_multiplier = difficulty_mod.player_damage_multiplier

	return config

## 获取关卡配置
func get_level_config(level_id: int) -> Dictionary:
	if not balance_config.has("levels"):
		return {}

	var level_key = _get_level_key(level_id)
	if not balance_config.levels.has(level_key):
		return {}

	var config = balance_config.levels[level_key].duplicate()

	# 应用难度修正
	var difficulty_mod = get_difficulty_modifiers()
	if difficulty_mod.has("enemy_health_multiplier"):
		config.enemy_health_multiplier *= difficulty_mod.enemy_health_multiplier
	if difficulty_mod.has("enemy_damage_multiplier"):
		config.enemy_damage_multiplier *= difficulty_mod.enemy_damage_multiplier
	if difficulty_mod.has("time_limit_multiplier"):
		config.time_limit *= difficulty_mod.time_limit_multiplier

	return config

## 获取敌人配置
func get_enemy_config(enemy_type: String) -> Dictionary:
	if not balance_config.has("enemies"):
		return {}

	if not balance_config.enemies.has(enemy_type):
		return {}

	return balance_config.enemies[enemy_type].duplicate()

## 获取道具配置
func get_item_config(item_type: String) -> Dictionary:
	if not balance_config.has("items"):
		return {}

	if not balance_config.items.has(item_type):
		return {}

	return balance_config.items[item_type].duplicate()

## 获取技能配置
func get_skill_config(skill_name: String) -> Dictionary:
	if not balance_config.has("skills"):
		return {}

	if not balance_config.skills.has(skill_name):
		return {}

	return balance_config.skills[skill_name].duplicate()

## 获取奖励配置
func get_reward_config() -> Dictionary:
	if not balance_config.has("rewards"):
		return {}

	return balance_config.rewards.duplicate()

## 获取难度修正值
func get_difficulty_modifiers() -> Dictionary:
	if not balance_config.has("difficulty_modifiers"):
		return {}

	if not balance_config.difficulty_modifiers.has(current_difficulty):
		return {}

	return balance_config.difficulty_modifiers[current_difficulty].duplicate()

## 设置难度
func set_difficulty(difficulty: String) -> void:
	if difficulty in ["easy", "normal", "hard"]:
		current_difficulty = difficulty
		print("[BalanceManager] Difficulty set to: %s" % difficulty)
		difficulty_changed.emit(difficulty)
	else:
		push_warning("[BalanceManager] Invalid difficulty: %s" % difficulty)

## 获取当前难度
func get_difficulty() -> String:
	return current_difficulty

## 计算关卡奖励
func calculate_level_reward(level_id: int, stats: Dictionary) -> Dictionary:
	var reward_config = get_reward_config()
	var level_config = get_level_config(level_id)

	var reward = {
		"base_score": 0,
		"time_bonus": 0,
		"no_damage_bonus": 0,
		"perfect_clear_bonus": 0,
		"coin_bonus": 0,
		"total_score": 0,
		"stars": 0
	}

	# 基础分数（完成目标）
	reward.base_score = 1000

	# 时间奖励
	if stats.has("play_time") and level_config.has("time_limit"):
		var time_saved = level_config.time_limit - stats.play_time
		if time_saved > 0:
			reward.time_bonus = int(time_saved * reward_config.get("time_bonus_per_second", 10))

	# 无伤奖励
	if stats.get("damage_taken", 0) == 0:
		reward.no_damage_bonus = reward_config.get("no_damage_bonus", 500)

	# 完美通关奖励（所有目标达成 + 无伤）
	if reward.no_damage_bonus > 0:
		reward.perfect_clear_bonus = reward_config.get("perfect_clear_bonus", 1000)

	# 金币奖励
	if stats.has("items_collected"):
		reward.coin_bonus = stats.items_collected * level_config.get("coin_value", 10)

	# 总分
	reward.total_score = (
		reward.base_score +
		reward.time_bonus +
		reward.no_damage_bonus +
		reward.perfect_clear_bonus +
		reward.coin_bonus
	)

	# 计算星级
	var max_possible_score = (
		reward.base_score +
		level_config.get("time_limit", 300) * reward_config.get("time_bonus_per_second", 10) +
		reward_config.get("no_damage_bonus", 500) +
		reward_config.get("perfect_clear_bonus", 1000) +
		level_config.get("min_coins", 10) * level_config.get("coin_value", 10)
	)

	var score_ratio = float(reward.total_score) / max_possible_score
	var star_thresholds = reward_config.get("star_thresholds", {"3_star": 0.9, "2_star": 0.7, "1_star": 0.5})

	if score_ratio >= star_thresholds.get("3_star", 0.9):
		reward.stars = 3
	elif score_ratio >= star_thresholds.get("2_star", 0.7):
		reward.stars = 2
	elif score_ratio >= star_thresholds.get("1_star", 0.5):
		reward.stars = 1

	return reward

## 应用敌人平衡到实体
func apply_enemy_balance(enemy: Node, enemy_type: String) -> void:
	var config = get_enemy_config(enemy_type)
	if config.is_empty():
		return

	# 应用关卡难度修正
	if enemy.has_method("set_health"):
		enemy.set_health(config.get("health", 50))

	if enemy.has_method("set_damage"):
		enemy.set_damage(config.get("damage", 10))

	if enemy.has_method("set_speed"):
		enemy.set_speed(config.get("speed", 2.0))

## 获取关卡键名
func _get_level_key(level_id: int) -> String:
	match level_id:
		0: return "tutorial"
		1: return "obstacle_course"
		2: return "boss_challenge"
		_: return ""

## 重新加载配置
func reload_config() -> bool:
	return load_balance_config()

## 导出当前配置
func export_config() -> String:
	return JSON.stringify(balance_config, "\t")

## 获取配置值（调试用）
func get_config_value(path: String) -> Variant:
	var keys = path.split(".")
	var current = balance_config

	for key in keys:
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			return null

	return current
