extends Node
class_name GameConfig
## 游戏配置系统
## 管理关卡数据、难度配置、数值平衡和奖励系统

## 关卡配置列表
var levels: Array[Dictionary] = []

## 难度配置
var difficulty_configs: Dictionary = {
	"easy": {
		"enemy_health_multiplier": 0.7,
		"enemy_damage_multiplier": 0.7,
		"player_health_multiplier": 1.3,
		"item_spawn_rate_multiplier": 1.5,
		"time_limit_multiplier": 1.5
	},
	"normal": {
		"enemy_health_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"player_health_multiplier": 1.0,
		"item_spawn_rate_multiplier": 1.0,
		"time_limit_multiplier": 1.0
	},
	"hard": {
		"enemy_health_multiplier": 1.5,
		"enemy_damage_multiplier": 1.3,
		"player_health_multiplier": 0.8,
		"item_spawn_rate_multiplier": 0.7,
		"time_limit_multiplier": 0.8
	}
}

## 当前难度
var current_difficulty: String = "normal"

## 数值平衡配置
var balance_config: Dictionary = {
	"player": {
		"base_health": 100.0,
		"base_speed": 5.0,
		"base_jump_force": 8.0,
		"dash_cooldown": 1.0,
		"skill_cooldown": 3.0
	},
	"enemy": {
		"base_health": 50.0,
		"base_damage": 10.0,
		"chase_range": 15.0,
		"attack_range": 2.0,
		"attack_cooldown": 2.0
	},
	"items": {
		"health_restore": 25.0,
		"speed_boost_duration": 5.0,
		"speed_boost_multiplier": 1.5,
		"shield_duration": 8.0,
		"coin_value": 10
	},
	"skills": {
		"fireball_damage": 30.0,
		"ice_blast_damage": 25.0,
		"ice_blast_slow_duration": 3.0,
		"dash_attack_damage": 20.0,
		"heal_amount": 40.0
	}
}

## 奖励配置
var reward_config: Dictionary = {
	"completion_bonus": 1000,
	"speed_bonus_threshold": 60.0,  # 秒
	"speed_bonus": 500,
	"no_damage_bonus": 300,
	"all_items_bonus": 200,
	"per_enemy_defeated": 50,
	"per_item_collected": 20
}

func _ready() -> void:
	_load_levels()
	print("[GameConfig] Initialized with %d levels" % levels.size())

## 加载关卡配置
func _load_levels() -> void:
	# 关卡 1: 新手教程
	levels.append({
		"id": 0,
		"name": "新手训练场",
		"description": "学习基本操作和技能",
		"scene_path": "res://scenes/levels/tutorial_level.tscn",
		"time_limit": 180.0,  # 3分钟
		"unlocked": true,
		"objectives": [
			{
				"id": "collect_coins",
				"type": "collect",
				"description": "收集 5 个金币",
				"target": 5,
				"optional": false
			},
			{
				"id": "defeat_enemies",
				"type": "defeat",
				"description": "击败 3 个敌人",
				"target": 3,
				"optional": false
			},
			{
				"id": "reach_finish",
				"type": "reach",
				"description": "到达终点",
				"target": 1,
				"optional": false
			}
		],
		"enemy_spawn_config": {
			"max_enemies": 5,
			"spawn_interval": 10.0,
			"enemy_types": ["basic"]
		},
		"item_spawn_config": {
			"coins": 10,
			"health_packs": 3,
			"power_ups": 2
		}
	})

	# 关卡 2: 障碍挑战
	levels.append({
		"id": 1,
		"name": "障碍竞速",
		"description": "躲避障碍物，快速通关",
		"scene_path": "res://scenes/levels/obstacle_course.tscn",
		"time_limit": 120.0,  # 2分钟
		"unlocked": false,
		"objectives": [
			{
				"id": "reach_finish",
				"type": "reach",
				"description": "到达终点",
				"target": 1,
				"optional": false
			},
			{
				"id": "collect_coins",
				"type": "collect",
				"description": "收集 10 个金币",
				"target": 10,
				"optional": true
			}
		],
		"enemy_spawn_config": {
			"max_enemies": 8,
			"spawn_interval": 8.0,
			"enemy_types": ["basic", "fast"]
		},
		"item_spawn_config": {
			"coins": 15,
			"health_packs": 2,
			"power_ups": 3
		}
	})

	# 关卡 3: Boss 战
	levels.append({
		"id": 2,
		"name": "终极挑战",
		"description": "击败 Boss，证明你的实力",
		"scene_path": "res://scenes/levels/boss_level.tscn",
		"time_limit": 300.0,  # 5分钟
		"unlocked": false,
		"objectives": [
			{
				"id": "defeat_boss",
				"type": "defeat",
				"description": "击败 Boss",
				"target": 1,
				"optional": false
			},
			{
				"id": "survive",
				"type": "survive",
				"description": "保持血量超过 50%",
				"target": 1,
				"optional": true
			}
		],
		"enemy_spawn_config": {
			"max_enemies": 3,
			"spawn_interval": 15.0,
			"enemy_types": ["basic", "fast", "tank"]
		},
		"item_spawn_config": {
			"coins": 20,
			"health_packs": 5,
			"power_ups": 4
		},
		"boss_config": {
			"boss_type": "mega_yolk",
			"health": 500.0,
			"phases": 3
		}
	})

## 获取关卡配置
func get_level_config(level_id: int) -> Dictionary:
	if level_id < 0 or level_id >= levels.size():
		return {}

	return levels[level_id]

## 获取关卡数量
func get_level_count() -> int:
	return levels.size()

## 解锁关卡
func unlock_level(level_id: int) -> void:
	if level_id < 0 or level_id >= levels.size():
		return

	levels[level_id].unlocked = true
	print("[GameConfig] Level %d unlocked" % level_id)

## 关卡是否解锁
func is_level_unlocked(level_id: int) -> bool:
	if level_id < 0 or level_id >= levels.size():
		return false

	return levels[level_id].unlocked

## 设置难度
func set_difficulty(difficulty: String) -> void:
	if not difficulty_configs.has(difficulty):
		push_warning("[GameConfig] Unknown difficulty: %s" % difficulty)
		return

	current_difficulty = difficulty
	print("[GameConfig] Difficulty set to: %s" % difficulty)

## 获取难度配置
func get_difficulty_config() -> Dictionary:
	return difficulty_configs.get(current_difficulty, difficulty_configs["normal"])

## 获取数值（应用难度修正）
func get_stat(category: String, stat_name: String) -> float:
	if not balance_config.has(category):
		return 0.0

	var base_value = balance_config[category].get(stat_name, 0.0)
	var difficulty = get_difficulty_config()

	# 应用难度修正
	match category:
		"player":
			if stat_name == "base_health":
				return base_value * difficulty.get("player_health_multiplier", 1.0)
		"enemy":
			if stat_name == "base_health":
				return base_value * difficulty.get("enemy_health_multiplier", 1.0)
			elif stat_name == "base_damage":
				return base_value * difficulty.get("enemy_damage_multiplier", 1.0)

	return base_value

## 计算关卡奖励
func calculate_level_reward(level_id: int, stats: Dictionary) -> Dictionary:
	var reward = {
		"total_score": 0,
		"breakdown": {}
	}

	# 完成奖励
	reward.breakdown["completion"] = reward_config.completion_bonus
	reward.total_score += reward.breakdown["completion"]

	# 速度奖励
	var play_time = stats.get("play_time", 999.0)
	if play_time <= reward_config.speed_bonus_threshold:
		reward.breakdown["speed_bonus"] = reward_config.speed_bonus
		reward.total_score += reward.breakdown["speed_bonus"]

	# 无伤奖励
	var damage_taken = stats.get("damage_taken", 999.0)
	if damage_taken == 0:
		reward.breakdown["no_damage"] = reward_config.no_damage_bonus
		reward.total_score += reward.breakdown["no_damage"]

	# 敌人击败奖励
	var enemies_defeated = stats.get("enemies_defeated", 0)
	reward.breakdown["enemies"] = enemies_defeated * reward_config.per_enemy_defeated
	reward.total_score += reward.breakdown["enemies"]

	# 道具收集奖励
	var items_collected = stats.get("items_collected", 0)
	reward.breakdown["items"] = items_collected * reward_config.per_item_collected
	reward.total_score += reward.breakdown["items"]

	return reward

## 获取下一个未解锁关卡
func get_next_unlocked_level() -> int:
	for i in range(levels.size()):
		if levels[i].unlocked:
			return i

	return 0

## 获取所有已解锁关卡
func get_unlocked_levels() -> Array[int]:
	var result: Array[int] = []
	for i in range(levels.size()):
		if levels[i].unlocked:
			result.append(i)

	return result
