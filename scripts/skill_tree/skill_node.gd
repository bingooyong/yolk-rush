extends Resource
## 技能节点 - 技能树中的单个技能

@export var id= ""
@export var skill_name= ""
@export var description= ""
@export var icon_path= ""
@export var max_level = 5

@export var required_level = 1
@export var required_skill_points = 1
@export var prerequisites= []  # Array[String] - skill IDs

@export var effects= {}  # effect_name -> value_per_level
@export var tree_name= ""
@export var tree_position= Vector2.ZERO

## 获取等级效果
func get_effect_at_level(effect_name: String, level: int):
	if not effects.has(effect_name):
		return 0

	var base_value = effects[effect_name]
	return base_value * level

## 获取所有效果（指定等级）
func get_all_effects_at_level(level: int) -> Dictionary:
	var result = {}
	for effect_name in effects.keys():
		result[effect_name] = get_effect_at_level(effect_name, level)
	return result

## 获取描述文本（包含等级信息）
func get_description_with_level(level: int) -> String:
	var text = description + "\n\n"

	if level > 0:
		text += "[当前等级 %d]\n" % level
		var current_effects = get_all_effects_at_level(level)
		for effect_name in current_effects.keys():
			text += "  • %s: +%s\n" % [_format_effect_name(effect_name), _format_value(current_effects[effect_name])]

	if level < max_level:
		text += "\n[下一级效果]\n"
		var next_level = level + 1
		var next_effects = get_all_effects_at_level(next_level)
		for effect_name in next_effects.keys():
			text += "  • %s: +%s\n" % [_format_effect_name(effect_name), _format_value(next_effects[effect_name])]

	return text

## 格式化效果名称
func _format_effect_name(effect_name: String) -> String:
	match effect_name:
		"physical_damage_bonus": return "物理伤害"
		"skill_damage_bonus": return "技能伤害"
		"crit_chance": return "暴击率"
		"crit_damage": return "暴击伤害"
		"attack_speed": return "攻击速度"
		"armor_bonus": return "护甲"
		"max_health": return "最大生命"
		"block_chance": return "格挡率"
		"health_regen": return "生命恢复"
		"max_mana": return "最大法力"
		"spell_penetration": return "法术穿透"
		"mana_regen": return "法力恢复"
		"elemental_damage": return "元素伤害"
		_: return effect_name

## 格式化数值
func _format_value(value) -> String:
	if value is int:
		return str(value)
	elif value is float:
		if abs(value) < 1.0:
			return "%.1f%%" % (value * 100)
		else:
			return "%.1f" % value
	else:
		return str(value)

## 从JSON数据创建
static func from_json(data: Dictionary, tree: String):
	var SkillNodeClass = load("res://scripts/skill_tree/skill_node.gd")
	var node = SkillNodeClass.new()

	node.id = data.get("id", "")
	node.skill_name = data.get("skill_name", "")
	node.description = data.get("description", "")
	node.icon_path = data.get("icon_path", "")
	node.max_level = data.get("max_level", 5)

	node.required_level = data.get("required_level", 1)
	node.required_skill_points = data.get("required_skill_points", 1)
	node.prerequisites = data.get("prerequisites", [])

	node.effects = data.get("effects", {})
	node.tree_name = tree

	var pos_data = data.get("tree_position", {"x": 0, "y": 0})
	node.tree_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

	return node

## 复制技能节点
func duplicate_skill():
	var SkillNodeClass = load("res://scripts/skill_tree/skill_node.gd")
	var copy = SkillNodeClass.new()
	copy.id = id
	copy.skill_name = skill_name
	copy.description = description
	copy.icon_path = icon_path
	copy.max_level = max_level
	copy.required_level = required_level
	copy.required_skill_points = required_skill_points
	copy.prerequisites = prerequisites.duplicate()
	copy.effects = effects.duplicate()
	copy.tree_name = tree_name
	copy.tree_position = tree_position
	return copy
