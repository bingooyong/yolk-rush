extends Node
class_name AchievementDatabase
## 成就数据库

const AchievementClass = preload("res://scripts/achievement/achievement.gd")

signal database_loaded()

var achievements = {}  # id -> Achievement
var achievements_by_type = {}  # type_string -> Array

func _ready() -> void:
	load_database()

## 加载数据库
func load_database() -> bool:
	var file_path = "res://data/achievement/achievements.json"

	if not FileAccess.file_exists(file_path):
		push_error("[AchievementDatabase] File not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[AchievementDatabase] Failed to open file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[AchievementDatabase] Parse error: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	if not data.has("achievements"):
		push_error("[AchievementDatabase] No 'achievements' array")
		return false

	_parse_achievements(data["achievements"])

	print("[AchievementDatabase] Loaded %d achievements" % achievements.size())
	database_loaded.emit()

	return true

## 解析成就数据
func _parse_achievements(data: Array) -> void:
	achievements.clear()
	achievements_by_type.clear()

	for achievement_data in data:
		if not achievement_data is Dictionary:
			continue

		var achievement = AchievementClass.from_json(achievement_data)
		if achievement:
			achievements[achievement.id] = achievement

			var type_key = _type_to_string(achievement.achievement_type)
			if not achievements_by_type.has(type_key):
				achievements_by_type[type_key] = []
			achievements_by_type[type_key].append(achievement)

## 类型转字符串
func _type_to_string(type) -> String:
	match type:
		AchievementClass.AchievementType.KILL: return "KILL"
		AchievementClass.AchievementType.COLLECT: return "COLLECT"
		AchievementClass.AchievementType.LEVEL: return "LEVEL"
		AchievementClass.AchievementType.COMBAT: return "COMBAT"
		AchievementClass.AchievementType.EXPLORATION: return "EXPLORATION"
		AchievementClass.AchievementType.EQUIPMENT: return "EQUIPMENT"
		AchievementClass.AchievementType.SKILL: return "SKILL"
		_: return "KILL"

## 获取成就
func get_achievement_by_id(achievement_id: String):
	if achievements.has(achievement_id):
		return achievements[achievement_id]
	push_warning("[AchievementDatabase] Achievement not found: %s" % achievement_id)
	return null

## 按类型获取成就
func get_achievements_by_type(type_str: String) -> Array:
	if achievements_by_type.has(type_str):
		return achievements_by_type[type_str].duplicate()
	return []

## 获取所有成就
func get_all_achievements() -> Array:
	var result = []
	for achievement in achievements.values():
		result.append(achievement)
	return result

## 获取成就数量
func get_achievement_count() -> int:
	return achievements.size()

## 成就是否存在
func has_achievement(achievement_id: String) -> bool:
	return achievements.has(achievement_id)
