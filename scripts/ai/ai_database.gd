extends Node
class_name AIDatabase
## AI数据库 - 加载和管理AI预设配置

## AI预设数据
var ai_presets: Dictionary = {}

## 行为修饰符
var behavior_modifiers: Dictionary = {}

## 数据文件路径
const AI_PRESETS_PATH = "res://data/ai/ai_presets.json"

func _ready() -> void:
	load_database()

## 加载数据库
func load_database() -> bool:
	if not FileAccess.file_exists(AI_PRESETS_PATH):
		push_warning("[AIDatabase] AI预设文件不存在: %s" % AI_PRESETS_PATH)
		return false

	var file = FileAccess.open(AI_PRESETS_PATH, FileAccess.READ)
	if not file:
		push_error("[AIDatabase] 无法打开AI预设文件")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[AIDatabase] JSON解析错误: %s" % json.get_error_message())
		return false

	var data = json.data

	# 加载AI预设
	if data.has("ai_presets"):
		ai_presets = data["ai_presets"]
		print("[AIDatabase] Loaded %d AI presets" % ai_presets.size())

	# 加载行为修饰符
	if data.has("behavior_modifiers"):
		behavior_modifiers = data["behavior_modifiers"]
		print("[AIDatabase] Loaded %d behavior modifiers" % behavior_modifiers.size())

	return true

## 获取AI预设
func get_preset(preset_id: String) -> Dictionary:
	if ai_presets.has(preset_id):
		return ai_presets[preset_id].duplicate()

	push_warning("[AIDatabase] AI预设不存在: %s" % preset_id)
	return {}

## 获取行为修饰符
func get_modifier(modifier_id: String) -> Dictionary:
	if behavior_modifiers.has(modifier_id):
		return behavior_modifiers[modifier_id].duplicate()

	push_warning("[AIDatabase] 行为修饰符不存在: %s" % modifier_id)
	return {}

## 应用预设到AI
func apply_preset_to_ai(ai: Node, preset_id: String, modifiers: Array = []) -> bool:
	var preset = get_preset(preset_id)
	if preset.is_empty():
		return false

	# 应用基础预设
	_apply_preset_values(ai, preset)

	# 应用修饰符
	for modifier_id in modifiers:
		var modifier = get_modifier(modifier_id)
		if not modifier.is_empty():
			_apply_modifier_values(ai, modifier)

	return true

## 应用预设值
func _apply_preset_values(ai: Node, preset: Dictionary) -> void:
	# 战斗参数
	if preset.has("attack_range"):
		ai.attack_range = preset["attack_range"]
	if preset.has("attack_cooldown"):
		ai.attack_cooldown = preset["attack_cooldown"]
	if preset.has("move_speed"):
		ai.move_speed = preset["move_speed"]
	if preset.has("chase_distance"):
		ai.chase_distance = preset["chase_distance"]
	if preset.has("skill_usage_chance"):
		ai.skill_usage_chance = preset["skill_usage_chance"]
	if preset.has("flee_health_threshold"):
		ai.flee_health_threshold = preset["flee_health_threshold"]

	# 感知参数
	if ai.perception:
		if preset.has("sight_range"):
			ai.perception.sight_range = preset["sight_range"]
		if preset.has("sight_angle"):
			ai.perception.sight_angle = preset["sight_angle"]
		if preset.has("hearing_range"):
			ai.perception.hearing_range = preset["hearing_range"]

## 应用修饰符值
func _apply_modifier_values(ai: Node, modifier: Dictionary) -> void:
	if modifier.has("flee_health_threshold_modifier"):
		ai.flee_health_threshold = clampf(
			ai.flee_health_threshold + modifier["flee_health_threshold_modifier"],
			0.0, 1.0
		)

	if modifier.has("move_speed_modifier"):
		ai.move_speed *= modifier["move_speed_modifier"]

	if modifier.has("attack_cooldown_modifier"):
		ai.attack_cooldown *= modifier["attack_cooldown_modifier"]

	if modifier.has("skill_usage_chance_modifier"):
		ai.skill_usage_chance = clampf(
			ai.skill_usage_chance + modifier["skill_usage_chance_modifier"],
			0.0, 1.0
		)

	# 感知修饰符
	if ai.perception:
		if modifier.has("sight_range_modifier"):
			ai.perception.sight_range *= modifier["sight_range_modifier"]

## 获取所有预设ID
func get_all_preset_ids() -> Array:
	return ai_presets.keys()

## 获取所有修饰符ID
func get_all_modifier_ids() -> Array:
	return behavior_modifiers.keys()

## 创建配置好的AI实例
static func create_ai_with_preset(preset_id: String, modifiers: Array = []) -> Node:
	var CombatAIScript = load("res://scripts/ai/combat_ai.gd")
	if not CombatAIScript:
		push_error("[AIDatabase] 无法加载CombatAI脚本")
		return null

	var ai = CombatAIScript.new()

	# 需要数据库实例来应用预设
	# 这通常在GameManager中完成
	# 这里只是创建AI实例

	return ai
