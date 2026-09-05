extends Node
class_name SkillDatabase
## 技能数据库 - 加载和管理所有技能数据

const SkillNodeClass = preload("res://scripts/skill_tree/skill_node.gd")

signal database_loaded()

var skills= {}  # id -> SkillNode
var skills_by_tree= {}  # tree_name -> Array[SkillNode]
var trees= {}  # tree_name -> {name, description}

func _ready() -> void:
	load_database()

## 加载技能数据库
func load_database() -> bool:
	var file_path = "res://data/skill_tree/skill_database.json"

	if not FileAccess.file_exists(file_path):
		push_error("[SkillDatabase] Database file not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[SkillDatabase] Failed to open database file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[SkillDatabase] Failed to parse JSON: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	if not data.has("trees"):
		push_error("[SkillDatabase] No 'trees' in database")
		return false

	_parse_trees(data["trees"])

	print("[SkillDatabase] Loaded %d skills across %d trees" % [skills.size(), trees.size()])
	database_loaded.emit()

	return true

## 解析技能树数据
func _parse_trees(trees_data: Dictionary) -> void:
	skills.clear()
	skills_by_tree.clear()
	trees.clear()

	for tree_name in trees_data.keys():
		var tree_data = trees_data[tree_name]

		# 存储树信息
		trees[tree_name] = {
			"name": tree_data.get("name", tree_name),
			"description": tree_data.get("description", "")
		}

		# 解析技能
		var tree_skills = []
		var skills_data = tree_data.get("skills", [])

		for skill_data in skills_data:
			if not skill_data is Dictionary:
				continue

			var skill = SkillNodeClass.from_json(skill_data, tree_name)
			if skill:
				skills[skill.id] = skill
				tree_skills.append(skill)

		skills_by_tree[tree_name] = tree_skills

## 通过 ID 获取技能
func get_skill_by_id(skill_id: String):
	if skills.has(skill_id):
		return skills[skill_id]

	push_warning("[SkillDatabase] Skill not found: %s" % skill_id)
	return null

## 获取所有技能 ID
func get_all_skill_ids() -> Array:
	var ids = []
	for id in skills.keys():
		ids.append(id)
	return ids

## 获取所有技能
func get_all_skills() -> Array:
	var result = []
	for skill in skills.values():
		result.append(skill)
	return result

## 按树获取技能
func get_skills_by_tree(tree_name: String) -> Array:
	if skills_by_tree.has(tree_name):
		return skills_by_tree[tree_name].duplicate()
	return []

## 获取所有树名称
func get_all_tree_names() -> Array:
	var names = []
	for name in trees.keys():
		names.append(name)
	return names

## 获取树信息
func get_tree_info(tree_name: String) -> Dictionary:
	if trees.has(tree_name):
		return trees[tree_name].duplicate()
	return {}

## 技能是否存在
func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)

## 获取技能数量
func get_skill_count() -> int:
	return skills.size()

## 获取指定树的技能数量
func get_tree_skill_count(tree_name: String) -> int:
	if skills_by_tree.has(tree_name):
		return skills_by_tree[tree_name].size()
	return 0

## 获取技能的前置技能
func get_prerequisites(skill_id: String) -> Array:
	var skill = get_skill_by_id(skill_id)
	if not skill:
		return []

	var prereqs = []
	for prereq_id in skill.prerequisites:
		var prereq_skill = get_skill_by_id(prereq_id)
		if prereq_skill:
			prereqs.append(prereq_skill)

	return prereqs

## 获取依赖指定技能的技能列表
func get_dependents(skill_id: String) -> Array:
	var dependents = []

	for other_skill in skills.values():
		if skill_id in other_skill.prerequisites:
			dependents.append(other_skill)

	return dependents

## 获取技能链（从根到指定技能的路径）
func get_skill_chain(skill_id: String) -> Array:
	var chain = []
	var visited = {}

	_build_chain_recursive(skill_id, chain, visited)

	chain.reverse()
	return chain

func _build_chain_recursive(skill_id: String, chain: Array, visited: Dictionary) -> void:
	if visited.has(skill_id):
		return

	visited[skill_id] = true
	chain.append(skill_id)

	var skill = get_skill_by_id(skill_id)
	if not skill:
		return

	for prereq_id in skill.prerequisites:
		_build_chain_recursive(prereq_id, chain, visited)

## 验证技能树完整性
func validate_tree() -> Dictionary:
	var errors = []
	var warnings = []

	# 检查前置技能是否存在
	for skill in skills.values():
		for prereq_id in skill.prerequisites:
			if not has_skill(prereq_id):
				errors.append("Skill '%s' has invalid prerequisite: '%s'" % [skill.id, prereq_id])

	# 检查循环依赖
	for skill_id in skills.keys():
		if _has_circular_dependency(skill_id):
			errors.append("Circular dependency detected for skill: '%s'" % skill_id)

	# 检查孤立技能（除了根技能）
	for skill in skills.values():
		if skill.prerequisites.is_empty():
			continue  # 根技能

		var has_path_to_root = false
		for root_skill in skills.values():
			if root_skill.prerequisites.is_empty():
				var chain = get_skill_chain(skill.id)
				if root_skill.id in chain:
					has_path_to_root = true
					break

		if not has_path_to_root:
			warnings.append("Skill '%s' may be unreachable" % skill.id)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings
	}

## 检查循环依赖
func _has_circular_dependency(skill_id: String, visited: Array = []) -> bool:
	if skill_id in visited:
		return true

	visited.append(skill_id)

	var skill = get_skill_by_id(skill_id)
	if not skill:
		return false

	for prereq_id in skill.prerequisites:
		if _has_circular_dependency(prereq_id, visited.duplicate()):
			return true

	return false

## 调试：打印数据库统计
func _debug_print_stats() -> void:
	print("[SkillDatabase] === Database Statistics ===")
	print("  Total skills: %d" % skills.size())
	print("  Total trees: %d" % trees.size())

	for tree_name in trees.keys():
		var tree_info = trees[tree_name]
		var count = get_tree_skill_count(tree_name)
		print("  Tree '%s' (%s): %d skills" % [tree_name, tree_info["name"], count])

	var validation = validate_tree()
	if validation["valid"]:
		print("  ✓ Tree structure is valid")
	else:
		print("  ✗ Tree has errors:")
		for error in validation["errors"]:
			print("    - %s" % error)

	if not validation["warnings"].is_empty():
		print("  Warnings:")
		for warning in validation["warnings"]:
			print("    - %s" % warning)
