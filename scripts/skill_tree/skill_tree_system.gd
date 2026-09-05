extends Node
class_name SkillTreeSystem
## 技能树系统 - 管理技能解锁、升级和效果

signal skill_unlocked(skill_id)
signal skill_upgraded(skill_id, new_level)
signal skill_points_changed(current_points)
signal skills_reset()

var unlocked_skills= {}  # skill_id -> level
var available_skill_points = 0
var skill_database = null
var player_level = 1

func _ready() -> void:
	print("[SkillTreeSystem] Initialized")

## 设置技能数据库
func set_database(db) -> void:
	skill_database = db
	print("[SkillTreeSystem] Database set")

## 设置玩家等级
func set_player_level(level: int) -> void:
	player_level = level

## 添加技能点
func add_skill_points(amount: int) -> void:
	available_skill_points += amount
	skill_points_changed.emit(available_skill_points)
	print("[SkillTreeSystem] Added %d skill points, total: %d" % [amount, available_skill_points])

## 获取技能等级
func get_skill_level(skill_id: String) -> int:
	return unlocked_skills.get(skill_id, 0)

## 是否已解锁技能
func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id) and unlocked_skills[skill_id] > 0

## 检查是否可以解锁技能
func can_unlock_skill(skill_id: String) -> bool:
	if not skill_database:
		return false

	var skill = skill_database.get_skill_by_id(skill_id)
	if not skill:
		return false

	# 已经解锁
	if is_skill_unlocked(skill_id):
		return false

	# 等级不足
	if player_level < skill.required_level:
		return false

	# 技能点不足
	if available_skill_points < skill.required_skill_points:
		return false

	# 检查前置技能
	for prereq_id in skill.prerequisites:
		if not is_skill_unlocked(prereq_id):
			return false

	return true

## 解锁技能
func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false

	var skill = skill_database.get_skill_by_id(skill_id)
	if not skill:
		return false

	unlocked_skills[skill_id] = 1
	available_skill_points -= skill.required_skill_points

	print("[SkillTreeSystem] Unlocked skill: %s" % skill.skill_name)
	skill_unlocked.emit(skill_id)
	skill_points_changed.emit(available_skill_points)

	return true

## 检查是否可以升级技能
func can_upgrade_skill(skill_id: String) -> bool:
	if not skill_database:
		return false

	var skill = skill_database.get_skill_by_id(skill_id)
	if not skill:
		return false

	# 未解锁
	if not is_skill_unlocked(skill_id):
		return false

	var current_level = get_skill_level(skill_id)

	# 已满级
	if current_level >= skill.max_level:
		return false

	# 技能点不足
	if available_skill_points < skill.required_skill_points:
		return false

	return true

## 升级技能
func upgrade_skill(skill_id: String) -> bool:
	if not can_upgrade_skill(skill_id):
		return false

	var skill = skill_database.get_skill_by_id(skill_id)
	if not skill:
		return false

	unlocked_skills[skill_id] += 1
	available_skill_points -= skill.required_skill_points

	var new_level = unlocked_skills[skill_id]
	print("[SkillTreeSystem] Upgraded %s to level %d" % [skill.skill_name, new_level])
	skill_upgraded.emit(skill_id, new_level)
	skill_points_changed.emit(available_skill_points)

	return true

## 获取所有技能加成
func get_total_skill_bonuses() -> Dictionary:
	var totals = {}

	for skill_id in unlocked_skills.keys():
		var level = unlocked_skills[skill_id]
		var skill = skill_database.get_skill_by_id(skill_id)

		if not skill:
			continue

		var effects = skill.get_all_effects_at_level(level)
		for effect_name in effects.keys():
			var value = effects[effect_name]
			if totals.has(effect_name):
				totals[effect_name] += value
			else:
				totals[effect_name] = value

	return totals

## 获取指定树的技能加成
func get_tree_bonuses(tree_name: String) -> Dictionary:
	var totals = {}

	for skill_id in unlocked_skills.keys():
		var level = unlocked_skills[skill_id]
		var skill = skill_database.get_skill_by_id(skill_id)

		if not skill or skill.tree_name != tree_name:
			continue

		var effects = skill.get_all_effects_at_level(level)
		for effect_name in effects.keys():
			var value = effects[effect_name]
			if totals.has(effect_name):
				totals[effect_name] += value
			else:
				totals[effect_name] = value

	return totals

## 获取已解锁技能数量
func get_unlocked_skill_count() -> int:
	return unlocked_skills.size()

## 获取指定树的已解锁技能数量
func get_tree_unlocked_count(tree_name: String) -> int:
	var count = 0
	for skill_id in unlocked_skills.keys():
		var skill = skill_database.get_skill_by_id(skill_id)
		if skill and skill.tree_name == tree_name:
			count += 1
	return count

## 获取已投入的技能点数
func get_spent_skill_points() -> int:
	var total = 0
	for skill_id in unlocked_skills.keys():
		var level = unlocked_skills[skill_id]
		var skill = skill_database.get_skill_by_id(skill_id)
		if skill:
			total += skill.required_skill_points * level
	return total

## 重置技能树
func reset_skills() -> int:
	var refunded_points = get_spent_skill_points()

	unlocked_skills.clear()
	available_skill_points += refunded_points

	print("[SkillTreeSystem] Reset all skills, refunded %d points" % refunded_points)
	skills_reset.emit()
	skill_points_changed.emit(available_skill_points)

	return refunded_points

## 重置指定树的技能
func reset_tree(tree_name: String) -> int:
	var refunded_points = 0
	var skills_to_remove = []

	for skill_id in unlocked_skills.keys():
		var skill = skill_database.get_skill_by_id(skill_id)
		if skill and skill.tree_name == tree_name:
			var level = unlocked_skills[skill_id]
			refunded_points += skill.required_skill_points * level
			skills_to_remove.append(skill_id)

	for skill_id in skills_to_remove:
		unlocked_skills.erase(skill_id)

	available_skill_points += refunded_points

	print("[SkillTreeSystem] Reset %s tree, refunded %d points" % [tree_name, refunded_points])
	skills_reset.emit()
	skill_points_changed.emit(available_skill_points)

	return refunded_points

## 获取所有已解锁技能
func get_all_unlocked_skills() -> Dictionary:
	return unlocked_skills.duplicate()

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"unlocked_skills": unlocked_skills.duplicate(),
		"available_skill_points": available_skill_points,
		"player_level": player_level
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	if not data.has("unlocked_skills"):
		push_warning("[SkillTreeSystem] No unlocked_skills data in save")
		return

	unlocked_skills = data.get("unlocked_skills", {})
	available_skill_points = data.get("available_skill_points", 0)
	player_level = data.get("player_level", 1)

	print("[SkillTreeSystem] Loaded save data: %d skills, %d points" % [unlocked_skills.size(), available_skill_points])
	skill_points_changed.emit(available_skill_points)

## 调试：打印技能树
func _debug_print_skills() -> void:
	print("[SkillTreeSystem] === Unlocked Skills ===")
	print("  Available Points: %d" % available_skill_points)
	print("  Spent Points: %d" % get_spent_skill_points())

	for skill_id in unlocked_skills.keys():
		var level = unlocked_skills[skill_id]
		var skill = skill_database.get_skill_by_id(skill_id)
		if skill:
			print("  %s (Level %d/%d)" % [skill.skill_name, level, skill.max_level])

	print("  Total Bonuses:")
	var bonuses = get_total_skill_bonuses()
	for effect_name in bonuses.keys():
		print("    %s: +%s" % [effect_name, bonuses[effect_name]])
