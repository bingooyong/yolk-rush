extends Node
class_name StatusEffectDatabase
## 状态效果数据库 - 管理所有状态效果定义

const StatusEffectClass = preload("res://scripts/status/status_effect.gd")

var effects: Dictionary = {}  # effect_id -> StatusEffect

func _ready() -> void:
	_load_effects()
	print("[StatusEffectDatabase] Loaded %d status effects" % effects.size())

## 从JSON加载状态效果
func _load_effects() -> void:
	var file_path = "res://data/status_effects.json"

	if not FileAccess.file_exists(file_path):
		push_warning("[StatusEffectDatabase] File not found: %s" % file_path)
		_create_default_effects()
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[StatusEffectDatabase] Failed to open: %s" % file_path)
		_create_default_effects()
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("[StatusEffectDatabase] JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		_create_default_effects()
		return

	var data = json.get_data()

	if not data is Dictionary or not data.has("status_effects"):
		push_error("[StatusEffectDatabase] Invalid JSON structure")
		_create_default_effects()
		return

	var effects_data = data["status_effects"]
	for effect_data in effects_data:
		var effect = StatusEffectClass.from_dict(effect_data)
		effects[effect.effect_id] = effect
		print("[StatusEffectDatabase] Loaded: %s" % effect.effect_id)

## 创建默认效果（如果JSON不存在）
func _create_default_effects() -> void:
	print("[StatusEffectDatabase] Creating default effects...")

	# 中毒
	var poison = StatusEffectClass.new()
	poison.effect_id = "poison"
	poison.name = "中毒"
	poison.description = "持续受到毒素伤害"
	poison.effect_type = StatusEffectClass.EffectType.DEBUFF
	poison.duration = 5.0
	poison.tick_interval = 1.0
	poison.tick_effect = {"type": "damage", "base_value": 5.0}
	poison.max_stacks = 5
	poison.stack_behavior = StatusEffectClass.StackBehavior.ADD_STACK
	poison.dispellable = true
	effects["poison"] = poison

	# 眩晕
	var stun = StatusEffectClass.new()
	stun.effect_id = "stun"
	stun.name = "眩晕"
	stun.description = "无法移动或攻击"
	stun.effect_type = StatusEffectClass.EffectType.DEBUFF
	stun.duration = 2.0
	stun.max_stacks = 1
	stun.stack_behavior = StatusEffectClass.StackBehavior.REFRESH_TIME
	stun.dispellable = true
	effects["stun"] = stun

	# 速度提升
	var speed_boost = StatusEffectClass.new()
	speed_boost.effect_id = "speed_boost"
	speed_boost.name = "加速"
	speed_boost.description = "移动速度大幅提升"
	speed_boost.effect_type = StatusEffectClass.EffectType.BUFF
	speed_boost.duration = 10.0
	speed_boost.max_stacks = 1
	speed_boost.stack_behavior = StatusEffectClass.StackBehavior.REFRESH_TIME
	speed_boost.stat_modifiers = [
		{"stat": "speed", "modifier_type": "multiply", "value": 1.5}
	]
	speed_boost.dispellable = true
	effects["speed_boost"] = speed_boost

	# 力量提升
	var strength_boost = StatusEffectClass.new()
	strength_boost.effect_id = "strength_boost"
	strength_boost.name = "力量增强"
	strength_boost.description = "攻击力提升"
	strength_boost.effect_type = StatusEffectClass.EffectType.BUFF
	strength_boost.duration = 15.0
	strength_boost.max_stacks = 3
	strength_boost.stack_behavior = StatusEffectClass.StackBehavior.ADD_STACK
	strength_boost.stat_modifiers = [
		{"stat": "attack", "modifier_type": "add", "value": 10.0}
	]
	strength_boost.dispellable = true
	effects["strength_boost"] = strength_boost

	# 持续治疗
	var regeneration = StatusEffectClass.new()
	regeneration.effect_id = "regeneration"
	regeneration.name = "生命恢复"
	regeneration.description = "持续恢复生命值"
	regeneration.effect_type = StatusEffectClass.EffectType.BUFF
	regeneration.duration = 10.0
	regeneration.tick_interval = 1.0
	regeneration.tick_effect = {"type": "heal", "base_value": 3.0}
	regeneration.max_stacks = 3
	regeneration.stack_behavior = StatusEffectClass.StackBehavior.ADD_STACK
	regeneration.dispellable = true
	effects["regeneration"] = regeneration

	# 燃烧
	var burn = StatusEffectClass.new()
	burn.effect_id = "burn"
	burn.name = "燃烧"
	burn.description = "被火焰灼烧，持续受到伤害"
	burn.effect_type = StatusEffectClass.EffectType.DEBUFF
	burn.duration = 6.0
	burn.tick_interval = 1.0
	burn.tick_effect = {"type": "damage", "base_value": 8.0}
	burn.max_stacks = 3
	burn.stack_behavior = StatusEffectClass.StackBehavior.ADD_STACK
	burn.dispellable = true
	effects["burn"] = burn

	# 减速
	var slow = StatusEffectClass.new()
	slow.effect_id = "slow"
	slow.name = "减速"
	slow.description = "移动速度降低"
	slow.effect_type = StatusEffectClass.EffectType.DEBUFF
	slow.duration = 5.0
	slow.max_stacks = 1
	slow.stack_behavior = StatusEffectClass.StackBehavior.REFRESH_TIME
	slow.stat_modifiers = [
		{"stat": "speed", "modifier_type": "multiply", "value": 0.5}
	]
	slow.dispellable = true
	effects["slow"] = slow

	print("[StatusEffectDatabase] Created %d default effects" % effects.size())

## 获取状态效果
func get_effect(effect_id: String):
	if effects.has(effect_id):
		return effects[effect_id]

	push_warning("[StatusEffectDatabase] Effect not found: %s" % effect_id)
	return null

## 获取所有效果ID
func get_all_effect_ids() -> Array:
	return effects.keys()

## 按类型获取效果
func get_effects_by_type(effect_type: int) -> Array:
	var result = []
	for effect in effects.values():
		if effect.effect_type == effect_type:
			result.append(effect)
	return result

## 重新加载
func reload() -> void:
	effects.clear()
	_load_effects()
