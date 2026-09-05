extends Resource
## 成就数据

enum AchievementType {
	KILL,
	COLLECT,
	LEVEL,
	COMBAT,
	EXPLORATION,
	EQUIPMENT,
	SKILL
}

@export var id = ""
@export var title = ""
@export var description = ""
@export var icon_path = ""
@export var achievement_type = AchievementType.KILL
@export var requirement = 1
@export var reward = {}
@export var hidden = false

## 从JSON创建
static func from_json(data: Dictionary):
	var AchievementClass = load("res://scripts/achievement/achievement.gd")
	var achievement = AchievementClass.new()
	achievement.id = data.get("id", "")
	achievement.title = data.get("title", "")
	achievement.description = data.get("description", "")
	achievement.icon_path = data.get("icon_path", "")
	achievement.requirement = data.get("requirement", 1)
	achievement.reward = data.get("reward", {})
	achievement.hidden = data.get("hidden", false)

	var type_str = data.get("type", "KILL")
	achievement.achievement_type = _parse_type(type_str)

	return achievement

static func _parse_type(type_str: String):
	match type_str:
		"KILL": return AchievementType.KILL
		"COLLECT": return AchievementType.COLLECT
		"LEVEL": return AchievementType.LEVEL
		"COMBAT": return AchievementType.COMBAT
		"EXPLORATION": return AchievementType.EXPLORATION
		"EQUIPMENT": return AchievementType.EQUIPMENT
		"SKILL": return AchievementType.SKILL
		_: return AchievementType.KILL
