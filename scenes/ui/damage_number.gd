extends Node2D
class_name DamageNumber
## 伤害数字飘字特效

enum DamageType {
	NORMAL,      # 普通伤害
	CRITICAL,    # 暴击
	HEAL,        # 治疗
	MISS         # 未命中
}

@export var float_speed: float = 80.0
@export var float_duration: float = 1.5
@export var fade_start: float = 0.8  # 何时开始淡出（持续时间的百分比）

var damage_value: float = 0.0
var damage_type: DamageType = DamageType.NORMAL
var label: Label
var lifetime: float = 0.0

# 颜色配置
const COLOR_NORMAL = Color(1.0, 1.0, 1.0)      # 白色
const COLOR_CRITICAL = Color(1.0, 0.3, 0.1)    # 红橙色
const COLOR_HEAL = Color(0.3, 1.0, 0.4)        # 绿色
const COLOR_MISS = Color(0.6, 0.6, 0.6)        # 灰色

func _ready() -> void:
	_create_label()
	_setup_animation()

func setup(value: float, type: DamageType = DamageType.NORMAL) -> void:
	damage_value = value
	damage_type = type

	if label:
		_update_label()

func _create_label() -> void:
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 设置字体大小和样式
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	add_child(label)

func _update_label() -> void:
	match damage_type:
		DamageType.NORMAL:
			label.text = "-%d" % int(damage_value)
			label.add_theme_color_override("font_color", COLOR_NORMAL)
			label.add_theme_font_size_override("font_size", 24)

		DamageType.CRITICAL:
			label.text = "-%d!" % int(damage_value)
			label.add_theme_color_override("font_color", COLOR_CRITICAL)
			label.add_theme_font_size_override("font_size", 32)  # 暴击更大

		DamageType.HEAL:
			label.text = "+%d" % int(damage_value)
			label.add_theme_color_override("font_color", COLOR_HEAL)
			label.add_theme_font_size_override("font_size", 26)

		DamageType.MISS:
			label.text = "Miss"
			label.add_theme_color_override("font_color", COLOR_MISS)
			label.add_theme_font_size_override("font_size", 20)

func _setup_animation() -> void:
	# 创建浮动和淡出动画
	var tween = create_tween()
	tween.set_parallel(true)

	# 向上浮动
	tween.tween_property(self, "position:y", position.y - float_speed, float_duration)

	# 横向随机偏移
	var random_offset = randf_range(-30, 30)
	tween.tween_property(self, "position:x", position.x + random_offset, float_duration)

	# 缩放动画（出现时稍微放大）
	if damage_type == DamageType.CRITICAL:
		scale = Vector2(0.5, 0.5)
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.2)
	else:
		scale = Vector2(0.8, 0.8)
		tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

	# 淡出
	tween.tween_property(self, "modulate:a", 0.0, float_duration * (1.0 - fade_start)).set_delay(float_duration * fade_start)

	# 动画结束后销毁
	tween.finished.connect(queue_free)

func _process(delta: float) -> void:
	lifetime += delta

	# 安全检查：超时自动销毁
	if lifetime > float_duration + 0.5:
		queue_free()

## 静态工厂方法 - 快速创建伤害数字
static func create(value: float, type: DamageType, world_position: Vector2, parent: Node):
	var DamageNumberScript = load("res://scenes/ui/damage_number.gd")
	var damage_number = DamageNumberScript.new()
	damage_number.position = world_position
	parent.add_child(damage_number)
	damage_number.setup(value, type)
	return damage_number
