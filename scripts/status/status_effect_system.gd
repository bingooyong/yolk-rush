extends Node
class_name StatusEffectSystem
## 状态效果系统 - 管理实体上的所有状态效果

# 预加载StatusEffect脚本
const StatusEffectScript = preload("res://scripts/status/status_effect.gd")

signal effect_applied(effect)
signal effect_removed(effect)
signal effect_stack_changed(effect, stacks: int)

## 当前活跃的效果
var active_effects: Array = []  # Array[StatusEffect]

## 效果分组（按类别）
var effects_by_category: Dictionary = {}

## 父实体引用
var entity: Node = null

func _ready() -> void:
	entity = get_parent()
	print("[StatusEffectSystem] Initialized for: %s" % (entity.name if entity else "Unknown"))

func _process(delta: float) -> void:
	_update_effects(delta)

## 更新所有效果
func _update_effects(delta: float) -> void:
	var expired_effects: Array = []

	for effect in active_effects:
		if not effect.update(delta):
			expired_effects.append(effect)

	# 移除过期效果
	for effect in expired_effects:
		remove_effect(effect)

## 添加效果
func add_effect(effect: StatusEffect, caster: Node = null) -> bool:
	if not effect:
		return false

	# 检查是否已存在同类效果
	var existing = find_effect_by_id(effect.effect_id)

	if existing:
		return _handle_existing_effect(existing, effect)
	else:
		return _add_new_effect(effect, caster)

## 处理已存在的效果（堆叠逻辑）
func _handle_existing_effect(existing: StatusEffect, new_effect) -> bool:
	match new_effect.stack_mode:
		"replace":
			# 替换模式：移除旧的，添加新的
			remove_effect(existing)
			return _add_new_effect(new_effect, new_effect.caster)

		"add":
			# 叠加模式：增加层数
			if existing.add_stack(1):
				effect_stack_changed.emit(existing, existing.current_stacks)
				return true
			return false

		"extend":
			# 延长模式：延长持续时间
			existing.extend_duration(new_effect.duration)
			return true

		"refresh":
			# 刷新模式：重置持续时间
			existing.refresh_duration()
			return true

	return false

## 添加新效果
func _add_new_effect(effect: StatusEffect, caster: Node) -> bool:
	# 应用效果
	effect.apply(entity, caster)

	# 添加到活跃列表
	active_effects.append(effect)

	# 按类别分组
	var category = effect.effect_category
	if not effects_by_category.has(category):
		effects_by_category[category] = []
	effects_by_category[category].append(effect)

	# 触发信号
	effect_applied.emit(effect)

	print("[StatusEffectSystem] Applied: %s to %s" % [effect.effect_name, entity.name])
	return true

## 移除效果
func remove_effect(effect) -> bool:
	if effect not in active_effects:
		return false

	# 从列表移除
	active_effects.erase(effect)

	# 从分类移除
	var category = effect.effect_category
	if effects_by_category.has(category):
		effects_by_category[category].erase(effect)

	# 调用移除回调
	effect.remove()

	# 触发信号
	effect_removed.emit(effect)

	print("[StatusEffectSystem] Removed: %s from %s" % [effect.effect_name, entity.name])
	return true

## 按ID移除效果
func remove_effect_by_id(effect_id: String) -> bool:
	var effect = find_effect_by_id(effect_id)
	if effect:
		return remove_effect(effect)
	return false

## 清除所有效果
func clear_all_effects() -> void:
	var effects_copy = active_effects.duplicate()
	for effect in effects_copy:
		remove_effect(effect)

## 清除指定类型的效果
func clear_effects_by_type(effect_type: int) -> void:
	var effects_to_remove: Array = []

	for effect in active_effects:
		if effect.effect_type == effect_type:
			effects_to_remove.append(effect)

	for effect in effects_to_remove:
		remove_effect(effect)

## 清除指定类别的效果
func clear_effects_by_category(category: int) -> void:
	if not effects_by_category.has(category):
		return

	var effects_copy = effects_by_category[category].duplicate()
	for effect in effects_copy:
		remove_effect(effect)

## 查找效果
func find_effect_by_id(effect_id: String) :
	for effect in active_effects:
		if effect.effect_id == effect_id:
			return effect
	return null

## 检查是否有指定效果
func has_effect(effect_id: String) -> bool:
	return find_effect_by_id(effect_id) != null

## 检查是否有指定类型的效果
func has_effect_type(effect_type: int) -> bool:
	for effect in active_effects:
		if effect.effect_type == effect_type:
			return true
	return false

## 检查是否有指定类别的效果
func has_effect_category(category: int) -> bool:
	return effects_by_category.has(category) and not effects_by_category[category].is_empty()

## 获取所有效果
func get_all_effects() -> Array:
	return active_effects.duplicate()

## 获取指定类型的效果
func get_effects_by_type(effect_type: int) -> Array:
	var result: Array = []
	for effect in active_effects:
		if effect.effect_type == effect_type:
			result.append(effect)
	return result

## 获取指定类别的效果
func get_effects_by_category(category: int) -> Array:
	if effects_by_category.has(category):
		return effects_by_category[category].duplicate()
	return []

## 获取所有 Buff
func get_all_buffs() -> Array:
	return get_effects_by_type(StatusEffectScript.EffectType.BUFF)

## 获取所有 Debuff
func get_all_debuffs() -> Array:
	return get_effects_by_type(StatusEffectScript.EffectType.DEBUFF)

## 获取所有控制效果
func get_all_controls() -> Array:
	return get_effects_by_type(StatusEffectScript.EffectType.CONTROL)

## 检查是否被眩晕
func is_stunned() -> bool:
	return has_effect_category(StatusEffectScript.EffectCategory.STUN)

## 检查是否被沉默
func is_silenced() -> bool:
	return has_effect_category(StatusEffectScript.EffectCategory.SILENCE)

## 检查是否被定身
func is_rooted() -> bool:
	return has_effect_category(StatusEffectScript.EffectCategory.ROOT)

## 检查是否被减速
func is_slowed() -> bool:
	return has_effect_category(StatusEffectScript.EffectCategory.SLOW)

## 获取属性修改器总和
func get_stat_modifier(stat_name: String) -> float:
	var total_modifier: float = 0.0

	for effect in active_effects:
		if effect.effect_category == StatusEffectScript.EffectCategory.STAT_MODIFIER:
			# 检查效果是否修改指定属性
			if effect.effect_id.contains(stat_name.to_lower()):
				total_modifier += effect.get_total_value()

	return total_modifier

## 获取移动速度修改器
func get_movement_speed_modifier() -> float:
	var multiplier: float = 1.0

	for effect in active_effects:
		if effect.effect_category == StatusEffectScript.EffectCategory.MOVEMENT_MODIFIER:
			multiplier *= (1.0 + effect.get_total_value())

	# 减速效果
	if is_slowed():
		var slow_effects = get_effects_by_category(StatusEffectScript.EffectCategory.SLOW)
		for effect in slow_effects:
			multiplier *= (1.0 + effect.get_total_value())  # 负值会减速

	return multiplier

## 获取效果总数
func get_effect_count() -> int:
	return active_effects.size()

## 获取 Buff 数量
func get_buff_count() -> int:
	return get_all_buffs().size()

## 获取 Debuff 数量
func get_debuff_count() -> int:
	return get_all_debuffs().size()

## 快速创建常见效果的便捷方法

## 创建中毒效果
static func create_poison(damage_per_tick: float, duration: float, caster: Node = null):
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "poison",
		"name": "Poison",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.DAMAGE_OVER_TIME,
		"duration": duration,
		"value": damage_per_tick,
		"tick_interval": 1.0,
		"color": "#22aa22"
	})
	effect.caster = caster
	return effect

## 创建燃烧效果
static func create_burn(damage_per_tick: float, duration: float, caster: Node = null):
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "burn",
		"name": "Burn",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.DAMAGE_OVER_TIME,
		"duration": duration,
		"value": damage_per_tick,
		"tick_interval": 0.5,
		"color": "#ff4400"
	})
	effect.caster = caster
	return effect

## 创建生命恢复效果
static func create_regeneration(heal_per_tick: float, duration: float, caster: Node = null) :
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "regeneration",
		"name": "Regeneration",
		"type": StatusEffectScript.EffectType.BUFF,
		"category": StatusEffectScript.EffectCategory.HEAL_OVER_TIME,
		"duration": duration,
		"value": heal_per_tick,
		"tick_interval": 1.0,
		"color": "#00ff00"
	})
	effect.caster = caster
	return effect

## 创建减速效果
static func create_slow(slow_percentage: float, duration: float, caster: Node = null) :
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "slow",
		"name": "Slow",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.SLOW,
		"duration": duration,
		"value": -slow_percentage,  # 负值表示减速
		"color": "#4488ff"
	})
	effect.caster = caster
	return effect

## 创建眩晕效果
static func create_stun(duration: float, caster: Node = null) :
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "stun",
		"name": "Stun",
		"type": StatusEffectScript.EffectType.CONTROL,
		"category": StatusEffectScript.EffectCategory.STUN,
		"duration": duration,
		"color": "#ffff00"
	})
	effect.caster = caster
	return effect

## 创建攻击力提升效果
static func create_attack_boost(boost_percentage: float, duration: float, caster: Node = null) :
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new({
		"id": "attack_boost",
		"name": "Attack Boost",
		"type": StatusEffectScript.EffectType.BUFF,
		"category": StatusEffectScript.EffectCategory.STAT_MODIFIER,
		"duration": duration,
		"value": boost_percentage,
		"color": "#ff0000"
	})
	effect.caster = caster
	return effect
