extends Node
## 状态效果数据库 - 加载和管理状态效果模板

# 预加载状态效果脚本
const StatusEffectScript = preload("res://scripts/status/status_effect.gd")

## 效果模板库
var effect_templates: Dictionary = {}

## 效果数据文件路径
const EFFECT_DATA_PATH = "res://data/status_effects/common_effects.json"

func _ready() -> void:
	load_effect_templates()
	print("[StatusEffectDatabase] Loaded %d effect templates" % effect_templates.size())

## 加载效果模板
func load_effect_templates() -> void:
	var file = FileAccess.open(EFFECT_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("[StatusEffectDatabase] Failed to open: %s" % EFFECT_DATA_PATH)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("[StatusEffectDatabase] Failed to parse JSON: %s" % EFFECT_DATA_PATH)
		return

	var data = json.get_data()
	if not data.has("effects"):
		push_error("[StatusEffectDatabase] No 'effects' array in data")
		return

	# 加载所有效果模板
	for effect_data in data["effects"]:
		var effect_id = effect_data.get("id", "")
		if effect_id.is_empty():
			continue

		effect_templates[effect_id] = effect_data

## 创建效果实例
func create_effect(effect_id: String, caster: Node = null) -> StatusEffectScript:
	if not effect_templates.has(effect_id):
		push_warning("[StatusEffectDatabase] Unknown effect: %s" % effect_id)
		return null

	var template = effect_templates[effect_id]
	var effect = StatusEffectScript.new(template)
	effect.caster = caster

	return effect

## 创建自定义效果（基于模板但修改参数）
func create_custom_effect(effect_id: String, overrides: Dictionary, caster: Node = null) -> StatusEffectScript:
	if not effect_templates.has(effect_id):
		push_warning("[StatusEffectDatabase] Unknown effect: %s" % effect_id)
		return null

	var template = effect_templates[effect_id].duplicate(true)

	# 应用覆盖参数
	for key in overrides:
		template[key] = overrides[key]

	var effect = StatusEffectScript.new(template)
	effect.caster = caster

	return effect

## 检查效果是否存在
func has_effect(effect_id: String) -> bool:
	return effect_templates.has(effect_id)

## 获取效果模板数据
func get_effect_template(effect_id: String) -> Dictionary:
	if effect_templates.has(effect_id):
		return effect_templates[effect_id].duplicate(true)
	return {}

## 获取所有效果ID
func get_all_effect_ids() -> Array:
	return effect_templates.keys()

## 按类型获取效果ID
func get_effects_by_type(effect_type: int) -> Array:
	var result: Array = []
	for effect_id in effect_templates:
		var template = effect_templates[effect_id]
		if template.get("type", -1) == effect_type:
			result.append(effect_id)
	return result

## 按类别获取效果ID
func get_effects_by_category(category: int) -> Array:
	var result: Array = []
	for effect_id in effect_templates:
		var template = effect_templates[effect_id]
		if template.get("category", -1) == category:
			result.append(effect_id)
	return result

## 便捷方法 - 创建常见效果

func create_poison(duration: float = 5.0, damage_per_tick: float = 5.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("poison", {
		"duration": duration,
		"value": damage_per_tick
	}, caster)

func create_burn(duration: float = 4.0, damage_per_tick: float = 8.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("burn", {
		"duration": duration,
		"value": damage_per_tick
	}, caster)

func create_bleed(duration: float = 6.0, damage_per_tick: float = 3.0, stacks: int = 1, caster: Node = null) -> StatusEffectScript:
	var effect = create_custom_effect("bleed", {
		"duration": duration,
		"value": damage_per_tick
	}, caster)
	if effect:
		effect.current_stacks = stacks
	return effect

func create_regeneration(duration: float = 10.0, heal_per_tick: float = 5.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("regeneration", {
		"duration": duration,
		"value": heal_per_tick
	}, caster)

func create_attack_boost(duration: float = 10.0, boost_percentage: float = 0.5, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("attack_boost", {
		"duration": duration,
		"value": boost_percentage
	}, caster)

func create_defense_boost(duration: float = 10.0, boost_percentage: float = 0.3, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("defense_boost", {
		"duration": duration,
		"value": boost_percentage
	}, caster)

func create_speed_boost(duration: float = 8.0, boost_percentage: float = 0.5, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("speed_boost", {
		"duration": duration,
		"value": boost_percentage
	}, caster)

func create_slow(duration: float = 4.0, slow_percentage: float = 0.5, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("slow", {
		"duration": duration,
		"value": -slow_percentage
	}, caster)

func create_stun(duration: float = 2.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("stun", {
		"duration": duration
	}, caster)

func create_silence(duration: float = 3.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("silence", {
		"duration": duration
	}, caster)

func create_root(duration: float = 3.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("root", {
		"duration": duration
	}, caster)

func create_weakness(duration: float = 6.0, reduction_percentage: float = 0.3, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("weakness", {
		"duration": duration,
		"value": -reduction_percentage
	}, caster)

func create_fury(duration: float = 12.0, attack_boost: float = 1.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("fury", {
		"duration": duration,
		"value": attack_boost
	}, caster)

func create_shield(duration: float = 8.0, shield_amount: float = 50.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("shield", {
		"duration": duration,
		"value": shield_amount
	}, caster)

func create_invulnerable(duration: float = 3.0, caster: Node = null) -> StatusEffectScript:
	return create_custom_effect("invulnerable", {
		"duration": duration
	}, caster)
