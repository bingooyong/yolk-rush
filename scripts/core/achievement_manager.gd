extends Node
class_name AchievementManager
## 成就系统管理器
## 负责追踪和解锁游戏成就

## 信号
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: float)
signal statistics_updated(stat_name: String, value: Variant)

## 成就数据
var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}

## 统计数据
var statistics: Dictionary = {}

## 配置
const ACHIEVEMENTS_CONFIG_PATH = "res://data/achievements/achievements.json"

func _ready() -> void:
	load_achievements()
	load_progress()
	print("[AchievementManager] Initialized")

## 加载成就配置
func load_achievements() -> bool:
	var file = FileAccess.open(ACHIEVEMENTS_CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("[AchievementManager] Failed to load achievements")
		return false

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("[AchievementManager] Failed to parse achievements")
		return false

	var data = json.data

	# 加载成就列表
	if data.has("achievements"):
		for achievement in data.achievements:
			achievements[achievement.id] = achievement
			achievement_progress[achievement.id] = 0.0

	# 加载统计数据模板
	if data.has("statistics"):
		statistics = data.statistics.duplicate()

	print("[AchievementManager] Loaded %d achievements" % achievements.size())
	return true

## 加载进度（从保存系统）
func load_progress() -> void:
	# 尝试从SaveManager加载
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		if save_manager.has_method("get_achievement_data"):
			var save_data = save_manager.get_achievement_data()
			if save_data.has("unlocked"):
				unlocked_achievements = save_data.unlocked.duplicate()
			if save_data.has("statistics"):
				statistics.merge(save_data.statistics, true)
			if save_data.has("progress"):
				achievement_progress.merge(save_data.progress, true)

## 保存进度
func save_progress() -> void:
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		if save_manager.has_method("save_achievement_data"):
			save_manager.save_achievement_data({
				"unlocked": unlocked_achievements.duplicate(),
				"statistics": statistics.duplicate(),
				"progress": achievement_progress.duplicate()
			})

## 检查成就解锁
func check_achievement(achievement_id: String) -> bool:
	if not achievements.has(achievement_id):
		return false

	if achievement_id in unlocked_achievements:
		return false  # 已解锁

	var achievement = achievements[achievement_id]
	var requirements = achievement.requirements

	var unlocked = false

	match achievement.type:
		"level_complete":
			unlocked = _check_level_complete(requirements)
		"level_time":
			unlocked = _check_level_time(requirements)
		"level_no_damage":
			unlocked = _check_no_damage(requirements)
		"cumulative":
			unlocked = _check_cumulative(requirements)
		"stars":
			unlocked = _check_stars(requirements)
		"streak":
			unlocked = _check_streak(requirements)
		"single_game":
			unlocked = _check_single_game(requirements)
		"all_levels":
			unlocked = _check_all_levels(requirements)

	if unlocked:
		unlock_achievement(achievement_id)

	return unlocked

## 解锁成就
func unlock_achievement(achievement_id: String) -> void:
	if achievement_id in unlocked_achievements:
		return

	unlocked_achievements.append(achievement_id)
	var achievement = achievements[achievement_id]

	print("[AchievementManager] Achievement unlocked: %s" % achievement.name)

	# 应用奖励
	if achievement.has("rewards"):
		_apply_rewards(achievement.rewards)

	# 保存进度
	save_progress()

	# 发送信号
	achievement_unlocked.emit(achievement_id, achievement)

## 更新统计
func update_stat(stat_name: String, value: Variant, mode: String = "set") -> void:
	if not statistics.has(stat_name):
		statistics[stat_name] = value
	else:
		match mode:
			"set":
				statistics[stat_name] = value
			"add":
				statistics[stat_name] += value
			"max":
				statistics[stat_name] = max(statistics[stat_name], value)
			"min":
				statistics[stat_name] = min(statistics[stat_name], value)

	statistics_updated.emit(stat_name, statistics[stat_name])

	# 检查相关成就
	_check_stat_related_achievements(stat_name)

## 记录关卡完成
func record_level_complete(level_id: int, stats: Dictionary) -> void:
	update_stat("levels_completed", 1, "add")

	# 检查无伤
	if stats.get("damage_taken", 0) == 0:
		update_stat("perfect_clears", 1, "add")

	# 检查三星
	if stats.get("stars", 0) == 3:
		update_stat("three_star_clears", 1, "add")

	# 检查连续通关
	update_stat("consecutive_clears", 1, "add")

	# 更新其他统计
	update_stat("total_coins_collected", stats.get("items_collected", 0), "add")
	update_stat("total_enemies_defeated", stats.get("enemies_defeated", 0), "add")
	update_stat("total_play_time", stats.get("play_time", 0), "add")

	# 检查相关成就
	check_achievement("first_steps")
	check_achievement("boss_slayer")
	check_achievement("perfectionist")
	check_achievement("three_star_master")
	check_achievement("survivor")
	check_achievement("completionist")

	# 检查速度成就
	if stats.get("play_time", 999) < 180:
		check_achievement("speed_demon")
	if stats.get("play_time", 999) < 300:
		check_achievement("speed_runner")

## 记录敌人击败
func record_enemy_defeated(with_skill: bool = false) -> void:
	update_stat("total_enemies_defeated", 1, "add")

	if with_skill:
		update_stat("skill_kills", 1, "add")

	check_achievement("enemy_slayer")
	check_achievement("skill_master")

## 记录道具收集
func record_item_collected() -> void:
	update_stat("total_items_collected", 1, "add")
	check_achievement("coin_collector")

## 记录技能使用
func record_skill_used() -> void:
	update_stat("total_skills_used", 1, "add")

## 记录死亡
func record_death() -> void:
	update_stat("total_deaths", 1, "add")
	update_stat("consecutive_clears", 0, "set")  # 重置连续通关

## 获取成就列表
func get_all_achievements() -> Array:
	var result: Array = []
	for achievement_id in achievements.keys():
		var achievement = achievements[achievement_id].duplicate()
		achievement["unlocked"] = achievement_id in unlocked_achievements
		achievement["progress"] = achievement_progress.get(achievement_id, 0.0)
		result.append(achievement)
	return result

## 获取已解锁成就
func get_unlocked_achievements() -> Array:
	var result: Array = []
	for achievement_id in unlocked_achievements:
		if achievements.has(achievement_id):
			result.append(achievements[achievement_id].duplicate())
	return result

## 获取成就进度百分比
func get_completion_percentage() -> float:
	if achievements.size() == 0:
		return 0.0
	return float(unlocked_achievements.size()) / achievements.size() * 100.0

## 获取总成就点数
func get_total_points() -> int:
	var points = 0
	for achievement_id in unlocked_achievements:
		if achievements.has(achievement_id):
			points += achievements[achievement_id].get("points", 0)
	return points

## 获取统计数据
func get_statistics() -> Dictionary:
	return statistics.duplicate()

## 检查关卡完成条件
func _check_level_complete(requirements: Dictionary) -> bool:
	if requirements.has("level_id"):
		var level_id = requirements.level_id
		# 检查GameConfig
		if has_node("/root/GameConfig"):
			var game_config = get_node("/root/GameConfig")
			if game_config.has_method("is_level_completed"):
				return game_config.is_level_completed(level_id)
	return false

## 检查关卡时间条件
func _check_level_time(requirements: Dictionary) -> bool:
	# 这个在record_level_complete中检查
	return false

## 检查无伤条件
func _check_no_damage(requirements: Dictionary) -> bool:
	return statistics.get("perfect_clears", 0) > 0

## 检查累积条件
func _check_cumulative(requirements: Dictionary) -> bool:
	for key in requirements.keys():
		var stat_key = key
		var required_value = requirements[key]

		if not statistics.has(stat_key):
			return false

		if statistics[stat_key] < required_value:
			return false

	return true

## 检查星级条件
func _check_stars(requirements: Dictionary) -> bool:
	if requirements.has("all_levels_three_stars"):
		# 检查所有关卡是否都是三星
		return statistics.get("three_star_clears", 0) >= 3  # 假设有3个关卡

	return false

## 检查连击条件
func _check_streak(requirements: Dictionary) -> bool:
	if requirements.has("consecutive_clears"):
		return statistics.get("consecutive_clears", 0) >= requirements.consecutive_clears

	return false

## 检查单局条件
func _check_single_game(requirements: Dictionary) -> bool:
	# 这个在游戏结束时检查
	return false

## 检查全关卡条件
func _check_all_levels(requirements: Dictionary) -> bool:
	if requirements.has("all_levels_completed"):
		return statistics.get("levels_completed", 0) >= 3  # 假设有3个关卡

	return false

## 检查统计相关成就
func _check_stat_related_achievements(stat_name: String) -> void:
	match stat_name:
		"total_coins_collected":
			check_achievement("coin_collector")
		"total_enemies_defeated":
			check_achievement("enemy_slayer")
		"skill_kills":
			check_achievement("skill_master")
		"consecutive_clears":
			check_achievement("survivor")
		"three_star_clears":
			check_achievement("three_star_master")
		"levels_completed":
			check_achievement("completionist")

## 应用奖励
func _apply_rewards(rewards: Dictionary) -> void:
	if rewards.has("coins"):
		# 应用金币奖励（通过GameConfig或其他系统）
		print("[AchievementManager] Reward: %d coins" % rewards.coins)
