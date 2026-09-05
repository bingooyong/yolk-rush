extends Node
class_name SkillDatabase
## 技能数据库 - 加载和管理所有技能数据

# 预加载脚本
const SkillScript = preload("res://scripts/skill/skill.gd")

signal database_loaded(skill_count: int)

var skills: Dictionary = {}  # {skill_id: Skill}
var skills_by_type: Dictionary = {}  # {SkillType: Array}

func _ready() -> void:
	_initialize_type_arrays()

func _initialize_type_arrays() -> void:
	skills_by_type[0] = []  # ACTIVE
	skills_by_type[1] = []  # PASSIVE
	skills_by_type[2] = []  # TOGGLE

## 从JSON文件加载技能数据
func load_from_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("[SkillDatabase] File not found: %s" % path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SkillDatabase] Failed to open file: %s" % path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[SkillDatabase] JSON parse error: %s" % json.get_error_message())
		return false

	var data = json.get_data()
	if not data is Dictionary:
		push_error("[SkillDatabase] Invalid JSON structure")
		return false

	if not data.has("skills"):
		push_error("[SkillDatabase] No 'skills' array in JSON")
		return false

	# 清空现有数据
	skills.clear()
	_initialize_type_arrays()

	# 加载技能
	var skill_array = data.skills
	for skill_data in skill_array:
		var skill = SkillScript.from_dict(skill_data)
		skills[skill.skill_id] = skill
		skills_by_type[skill.type].append(skill)

	print("[SkillDatabase] Loaded %d skills" % skills.size())
	database_loaded.emit(skills.size())
	return true

## 获取指定ID的技能
func get_skill(skill_id: String):
	if skills.has(skill_id):
		return skills[skill_id]
	push_warning("[SkillDatabase] Skill not found: %s" % skill_id)
	return null

## 获取所有技能
func get_all_skills() -> Array:
	var result: Array = []
	for skill in skills.values():
		result.append(skill)
	return result

## 获取指定类型的所有技能
func get_skills_by_type(type: int) -> Array:
	if skills_by_type.has(type):
		return skills_by_type[type]
	return []

## 检查技能是否存在
func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)

## 获取技能数量
func get_skill_count() -> int:
	return skills.size()

## 搜索技能（按名称）
func search_skills(query: String) -> Array:
	var result: Array = []
	var lower_query = query.to_lower()

	for skill in skills.values():
		if skill.skill_name.to_lower().contains(lower_query):
			result.append(skill)

	return result

## 获取技能列表信息（用于调试）
func get_skill_list_info() -> String:
	var info = "=== Skill Database ===\n"
	info += "Total skills: %d\n\n" % skills.size()

	for type in skills_by_type.keys():
		var type_name = ""
		match type:
			SkillScript.SkillType.ACTIVE:
				type_name = "Active"
			SkillScript.SkillType.PASSIVE:
				type_name = "Passive"
			SkillScript.SkillType.TOGGLE:
				type_name = "Toggle"

		var type_skills = skills_by_type[type]
		info += "%s Skills (%d):\n" % [type_name, type_skills.size()]

		for skill in type_skills:
			info += "  - %s (%s) - CD: %.1fs\n" % [skill.skill_name, skill.skill_id, skill.cooldown]

	return info
