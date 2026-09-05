extends RefCounted
class_name StatusEffect
## 状态效果基类 - Buff/Debuff 数据和逻辑

enum EffectType {
	BUFF,           # 增益
	DEBUFF,         # 减益
	CONTROL         # 控制效果
}

enum EffectCategory {
	DAMAGE_OVER_TIME,      # 持续伤害 (DOT)
	HEAL_OVER_TIME,        # 持续治疗 (HOT)
	STAT_MODIFIER,         # 属性修改
	MOVEMENT_MODIFIER,     # 移动修改
	STUN,                  # 眩晕
	SILENCE,               # 沉默
	ROOT,                  # 定身
	SLOW,                  # 减速
	CUSTOM                 # 自定义
}

## 效果数据
var effect_id: String = ""
var effect_name: String = ""
var effect_type: EffectType = EffectType.BUFF
var effect_category: EffectCategory = EffectCategory.STAT_MODIFIER

## 持续时间
var duration: float = 5.0           # 总持续时间（秒）
var remaining_time: float = 5.0     # 剩余时间
var is_permanent: bool = false      # 是否永久

## 堆叠
var max_stacks: int = 1             # 最大堆叠层数
var current_stacks: int = 1         # 当前层数
var stack_mode: String = "replace"  # replace/add/extend/refresh

## 效果数值
var value: float = 0.0              # 基础数值
var value_per_stack: float = 0.0    # 每层额外数值
var tick_interval: float = 1.0      # DOT/HOT 触发间隔
var tick_timer: float = 0.0         # 当前计时器

## 目标和施法者
var target: Node = null
var caster: Node = null

## 视觉效果
var icon_path: String = ""
var particle_effect: String = ""
var color: Color = Color.WHITE

## 回调（可选）
var on_applied: Callable
var on_removed: Callable
var on_tick: Callable
var on_stack_changed: Callable

func _init(data: Dictionary = {}) -> void:
	_load_from_dict(data)

## 从字典加载数据
func _load_from_dict(data: Dictionary) -> void:
	if data.has("id"):
		effect_id = data["id"]
	if data.has("name"):
		effect_name = data["name"]
	if data.has("type"):
		effect_type = data["type"]
	if data.has("category"):
		effect_category = data["category"]
	if data.has("duration"):
		duration = data["duration"]
		remaining_time = duration
	if data.has("is_permanent"):
		is_permanent = data["is_permanent"]
	if data.has("max_stacks"):
		max_stacks = data["max_stacks"]
	if data.has("stack_mode"):
		stack_mode = data["stack_mode"]
	if data.has("value"):
		value = data["value"]
	if data.has("value_per_stack"):
		value_per_stack = data["value_per_stack"]
	if data.has("tick_interval"):
		tick_interval = data["tick_interval"]
	if data.has("icon"):
		icon_path = data["icon"]
	if data.has("particle_effect"):
		particle_effect = data["particle_effect"]
	if data.has("color"):
		var c = data["color"]
		if c is Color:
			color = c
		elif c is String:
			color = Color(c)

## 更新效果（每帧调用）
func update(delta: float) -> bool:
	if is_permanent:
		return true

	remaining_time -= delta

	# 处理 DOT/HOT
	if effect_category in [EffectCategory.DAMAGE_OVER_TIME, EffectCategory.HEAL_OVER_TIME]:
		tick_timer += delta
		if tick_timer >= tick_interval:
			tick_timer = 0.0
			_do_tick()

	# 效果到期
	if remaining_time <= 0:
		return false

	return true

## 执行周期性效果
func _do_tick() -> void:
	if not is_instance_valid(target):
		return

	var total_value = get_total_value()

	match effect_category:
		EffectCategory.DAMAGE_OVER_TIME:
			if target.has_method("take_damage"):
				target.take_damage(total_value)

		EffectCategory.HEAL_OVER_TIME:
			if target.has_method("heal"):
				target.heal(total_value)
			elif target.has_method("add_health"):
				target.add_health(total_value)

	if on_tick.is_valid():
		on_tick.call(self, target, total_value)

## 获取总数值（考虑堆叠）
func get_total_value() -> float:
	return value + (value_per_stack * max(0, current_stacks - 1))

## 添加堆叠
func add_stack(amount: int = 1) -> bool:
	if current_stacks >= max_stacks:
		return false

	current_stacks = mini(current_stacks + amount, max_stacks)

	if on_stack_changed.is_valid():
		on_stack_changed.call(self, current_stacks)

	return true

## 刷新持续时间
func refresh_duration() -> void:
	remaining_time = duration

## 延长持续时间
func extend_duration(extra_time: float) -> void:
	remaining_time += extra_time

## 应用效果（首次应用时调用）
func apply(target_node: Node, caster_node: Node = null) -> void:
	target = target_node
	caster = caster_node

	if on_applied.is_valid():
		on_applied.call(self, target)

## 移除效果
func remove() -> void:
	if on_removed.is_valid():
		on_removed.call(self, target)

## 是否是同类效果
func is_same_effect(other: StatusEffect) -> bool:
	return effect_id == other.effect_id

## 获取剩余时间百分比
func get_remaining_percentage() -> float:
	if is_permanent:
		return 1.0
	return remaining_time / duration if duration > 0 else 0.0

## 转为字典（用于保存/网络传输）
func to_dict() -> Dictionary:
	return {
		"id": effect_id,
		"name": effect_name,
		"type": effect_type,
		"category": effect_category,
		"duration": duration,
		"remaining_time": remaining_time,
		"is_permanent": is_permanent,
		"current_stacks": current_stacks,
		"max_stacks": max_stacks,
		"value": value,
		"icon": icon_path
	}

## 复制效果
func duplicate_effect() -> StatusEffect:
	# 获取当前脚本并创建新实例
	var StatusEffectScript = get_script()
	var new_effect = StatusEffectScript.new(to_dict())
	new_effect.on_applied = on_applied
	new_effect.on_removed = on_removed
	new_effect.on_tick = on_tick
	new_effect.on_stack_changed = on_stack_changed
	return new_effect
