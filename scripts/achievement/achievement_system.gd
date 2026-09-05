extends Node
class_name AchievementSystem
## 成就系统

signal achievement_unlocked(achievement)
signal achievement_progress(achievement_id, current, requirement)

var unlocked_achievements = {}  # id -> unlock_timestamp
var progress = {}  # id -> current_value
var achievement_database = null

func _ready() -> void:
	print("[AchievementSystem] Initialized")

## 设置成就数据库
func set_database(db) -> void:
	achievement_database = db
	print("[AchievementSystem] Database set")

## 追踪事件
func track_event(event_type: String, value = 1) -> void:
	if not achievement_database:
		return

	var achievements = achievement_database.get_achievements_by_type(event_type)

	for achievement in achievements:
		if is_unlocked(achievement.id):
			continue

		var current = progress.get(achievement.id, 0)
		current += value
		progress[achievement.id] = current

		achievement_progress.emit(achievement.id, current, achievement.requirement)

		if current >= achievement.requirement:
			unlock_achievement(achievement.id)

## 检查成就是否满足条件（简化版，用于事件触发）
func check_achievement(achievement_id: String) -> void:
	if is_unlocked(achievement_id):
		return

	if not achievement_database:
		return

	var achievement = achievement_database.get_achievement_by_id(achievement_id)
	if not achievement:
		return

	var current = get_progress(achievement_id)
	if current >= achievement.requirement:
		unlock_achievement(achievement_id)

## 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	if is_unlocked(achievement_id):
		return false

	if not achievement_database:
		return false

	var achievement = achievement_database.get_achievement_by_id(achievement_id)
	if not achievement:
		return false

	unlocked_achievements[achievement_id] = Time.get_unix_time_from_system()

	print("[AchievementSystem] Unlocked: %s" % achievement.title)
	achievement_unlocked.emit(achievement)

	# 应用奖励
	_apply_reward(achievement.reward)

	return true

## 应用奖励
func _apply_reward(reward: Dictionary) -> void:
	if reward.has("exp"):
		print("  Reward: %d EXP" % reward["exp"])
	if reward.has("gold"):
		print("  Reward: %d Gold" % reward["gold"])
	if reward.has("skill_points"):
		print("  Reward: %d Skill Points" % reward["skill_points"])

## 是否已解锁
func is_unlocked(achievement_id: String) -> bool:
	return unlocked_achievements.has(achievement_id)

## 获取进度
func get_progress(achievement_id: String) -> int:
	return progress.get(achievement_id, 0)

## 获取进度百分比
func get_progress_percentage(achievement_id: String) -> float:
	if not achievement_database:
		return 0.0

	var achievement = achievement_database.get_achievement_by_id(achievement_id)
	if not achievement:
		return 0.0

	if is_unlocked(achievement_id):
		return 100.0

	var current = get_progress(achievement_id)
	return (float(current) / float(achievement.requirement)) * 100.0

## 增加进度
func increment_progress(achievement_id: String, amount: int) -> void:
	if is_unlocked(achievement_id):
		return

	if not progress.has(achievement_id):
		progress[achievement_id] = 0

	progress[achievement_id] += amount
	check_achievement(achievement_id)

## 获取所有已解锁成就
func get_unlocked_achievements() -> Array:
	var result = []
	for achievement_id in unlocked_achievements.keys():
		if achievement_database:
			var achievement = achievement_database.get_achievement_by_id(achievement_id)
			if achievement:
				result.append(achievement)
	return result

## 获取完成百分比
func get_completion_percentage() -> float:
	if not achievement_database:
		return 0.0

	var total = achievement_database.get_achievement_count()
	if total == 0:
		return 0.0

	var unlocked = unlocked_achievements.size()
	return (float(unlocked) / float(total)) * 100.0

## 获取已解锁数量
func get_unlocked_count() -> int:
	return unlocked_achievements.size()

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked_achievements.duplicate(),
		"progress": progress.duplicate()
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked"):
		unlocked_achievements = data["unlocked"]
	if data.has("progress"):
		progress = data["progress"]

	print("[AchievementSystem] Loaded: %d unlocked, %d in progress" % [
		unlocked_achievements.size(),
		progress.size()
	])
