extends RefCounted
class_name StatusEffectInstance
## 状态效果实例 - 应用到实体上的状态效果

signal stack_changed(new_stacks: int)
signal expired()
signal tick_applied(value: float, tick_type: String)

var effect_data  # StatusEffect的实例
var caster: Node = null
var target: Node = null

var remaining_time: float = 0.0
var stacks: int = 1
var tick_timer: float = 0.0

# 已应用的属性修改（用于移除时恢复）
var applied_modifiers: Array = []

func _init(data = null, _caster: Node = null, _target: Node = null) -> void:
	effect_data = data
	caster = _caster
	target = _target

	if effect_data:
		remaining_time = effect_data.duration
		tick_timer = effect_data.tick_interval

## 更新状态效果（每帧调用）
func update(delta: float) -> bool:
	if effect_data == null:
		return true  # 无效数据，应该移除

	# 永久效果不过期
	if effect_data.duration <= 0:
		_update_tick(delta)
		return false

	# 更新剩余时间
	remaining_time -= delta

	# 更新DOT/HOT
	_update_tick(delta)

	# 检查是否到期
	if remaining_time <= 0:
		expired.emit()
		return true  # 应该移除

	return false  # 继续保持

## 更新DOT/HOT计时
func _update_tick(delta: float) -> void:
	if not effect_data.has_tick_effect():
		return

	tick_timer -= delta

	if tick_timer <= 0:
		apply_tick_effect()
		tick_timer = effect_data.tick_interval

## 应用DOT/HOT效果
func apply_tick_effect() -> void:
	if not effect_data.has_tick_effect():
		return

	if target == null or not is_instance_valid(target):
		return

	var tick_type = effect_data.tick_effect.get("type", "")
	var base_value = effect_data.tick_effect.get("base_value", 0.0)

	# 堆叠层数影响效果值
	var total_value = base_value * stacks

	match tick_type:
		"damage":
			if target.has_method("take_damage"):
				target.take_damage(total_value)
			tick_applied.emit(total_value, "damage")

		"heal":
			if target.has_method("heal"):
				target.heal(total_value)
			elif target.has_method("add_health"):
				target.add_health(total_value)
			tick_applied.emit(total_value, "heal")

## 刷新持续时间
func refresh() -> void:
	if effect_data and effect_data.can_refresh:
		remaining_time = effect_data.duration
		tick_timer = effect_data.tick_interval

## 增加层数
func add_stack() -> void:
	if effect_data == null:
		return

	if stacks < effect_data.max_stacks:
		stacks += 1
		stack_changed.emit(stacks)

## 获取进度（0.0 - 1.0）
func get_progress() -> float:
	if effect_data == null or effect_data.duration <= 0:
		return 1.0
	return remaining_time / effect_data.duration

## 获取显示文本
func get_display_text() -> String:
	if effect_data == null:
		return ""

	var text = effect_data.name

	# 显示层数
	if stacks > 1:
		text += " x%d" % stacks

	return text

## 获取剩余时间文本
func get_time_text() -> String:
	if effect_data == null or effect_data.duration <= 0:
		return "∞"

	if remaining_time >= 60:
		return "%dm" % int(remaining_time / 60)
	else:
		return "%ds" % int(remaining_time)

## 是否是Buff
func is_buff() -> bool:
	if effect_data == null:
		return false
	return effect_data.effect_type == 0  # StatusEffect.EffectType.BUFF

## 是否是Debuff
func is_debuff() -> bool:
	if effect_data == null:
		return false
	return effect_data.effect_type == 1  # StatusEffect.EffectType.DEBUFF

## 获取效果ID
func get_effect_id() -> String:
	if effect_data == null:
		return ""
	return effect_data.effect_id

## 获取效果名称
func get_effect_name() -> String:
	if effect_data == null:
		return ""
	return effect_data.name
