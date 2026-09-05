extends RefCounted
class_name StatusEffect
## 状态效果数据类 - 定义Buff/Debuff

enum EffectType {
	BUFF,      # 增益
	DEBUFF     # 减益
}

enum StackBehavior {
	NONE,           # 不堆叠，新的覆盖旧的
	REFRESH_TIME,   # 刷新持续时间
	ADD_STACK,      # 增加层数
	REPLACE         # 替换旧的
}

## 基础属性
var effect_id: String = ""
var name: String = ""
var description: String = ""
var icon: String = "res://assets/icons/status_effects/default.png"

## 效果类型
var effect_type: EffectType = EffectType.BUFF

## 持续时间
var duration: float = 0.0  # 0 = 永久

## 堆叠规则
var max_stacks: int = 1
var stack_behavior: StackBehavior = StackBehavior.REFRESH_TIME
var can_refresh: bool = true

## DOT/HOT (Damage/Heal Over Time)
var tick_interval: float = 0.0  # 0 = 不触发
var tick_effect: Dictionary = {}  # {type: "damage"/"heal", base_value: float}

## 属性修改器
var stat_modifiers: Array = []  # [{stat: String, modifier_type: String, value: float}]

## 视觉效果
var particle_effect: String = ""
var animation: String = ""

## 是否可被驱散
var dispellable: bool = true

func _init() -> void:
	pass

## 从字典创建状态效果
static func from_dict(data: Dictionary):
	var StatusEffectScript = load("res://scripts/status/status_effect.gd")
	var effect = StatusEffectScript.new()

	effect.effect_id = data.get("effect_id", "")
	effect.name = data.get("name", "")
	effect.description = data.get("description", "")
	effect.icon = data.get("icon", "res://assets/icons/status_effects/default.png")

	# 效果类型
	var type_str = data.get("effect_type", "buff")
	effect.effect_type = EffectType.BUFF if type_str == "buff" else EffectType.DEBUFF

	# 持续时间
	effect.duration = float(data.get("duration", 0.0))

	# 堆叠规则
	effect.max_stacks = int(data.get("max_stacks", 1))
	effect.can_refresh = bool(data.get("can_refresh", true))

	var stack_str = data.get("stack_behavior", "refresh_time")
	match stack_str:
		"none":
			effect.stack_behavior = StackBehavior.NONE
		"refresh_time":
			effect.stack_behavior = StackBehavior.REFRESH_TIME
		"add_stack":
			effect.stack_behavior = StackBehavior.ADD_STACK
		"replace":
			effect.stack_behavior = StackBehavior.REPLACE

	# DOT/HOT
	effect.tick_interval = float(data.get("tick_interval", 0.0))
	effect.tick_effect = data.get("tick_effect", {})

	# 属性修改器
	effect.stat_modifiers = data.get("stat_modifiers", [])

	# 视觉效果
	effect.particle_effect = data.get("particle_effect", "")
	effect.animation = data.get("animation", "")

	# 驱散
	effect.dispellable = bool(data.get("dispellable", true))

	return effect

## 获取每层的效果值（用于堆叠计算）
func get_tick_value_per_stack() -> float:
	if tick_effect.is_empty():
		return 0.0
	return float(tick_effect.get("base_value", 0.0))

## 是否是DOT/HOT
func has_tick_effect() -> bool:
	return tick_interval > 0.0 and not tick_effect.is_empty()

## 是否修改属性
func has_stat_modifiers() -> bool:
	return not stat_modifiers.is_empty()

## 获取显示文本
func get_tooltip() -> String:
	var text = "[b]%s[/b]\n%s" % [name, description]

	if duration > 0:
		text += "\n持续时间: %.1f秒" % duration
	else:
		text += "\n持续时间: 永久"

	if max_stacks > 1:
		text += "\n最大层数: %d" % max_stacks

	if has_tick_effect():
		var tick_type = tick_effect.get("type", "")
		var tick_value = tick_effect.get("base_value", 0.0)
		if tick_type == "damage":
			text += "\n每%.1f秒造成%.0f伤害" % [tick_interval, tick_value]
		elif tick_type == "heal":
			text += "\n每%.1f秒恢复%.0f生命" % [tick_interval, tick_value]

	if has_stat_modifiers():
		text += "\n"
		for mod in stat_modifiers:
			var stat = mod.get("stat", "")
			var mod_type = mod.get("modifier_type", "")
			var value = mod.get("value", 0.0)

			if mod_type == "add":
				text += "\n%s +%.0f" % [stat, value]
			elif mod_type == "multiply":
				var percent = (value - 1.0) * 100.0
				if percent > 0:
					text += "\n%s +%.0f%%" % [stat, percent]
				else:
					text += "\n%s %.0f%%" % [stat, percent]

	return text
