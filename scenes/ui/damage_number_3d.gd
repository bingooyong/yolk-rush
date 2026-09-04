extends Node3D
## DamageNumber3D - 3D 伤害飘字
## Phase 6: 视觉反馈系统

@onready var label: Label3D = $Label3D
@onready var lifetime_timer: Timer = $LifetimeTimer

var move_speed: float = 2.0
var fade_speed: float = 1.0

func _ready() -> void:
	# 随机横向偏移
	var random_offset := Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	global_position += random_offset

	# 启动上升 + 淡出动画
	_start_animation()

	# 生命周期结束后删除
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

func set_damage(amount: float, is_critical: bool = false) -> void:
	var damage_text := "%d" % int(amount)

	if is_critical:
		label.text = "CRIT! %s" % damage_text
		label.modulate = Color(1.0, 0.3, 0.3)  # 红色暴击
		label.font_size = 64
		label.outline_size = 12
	else:
		label.text = damage_text
		label.modulate = Color(1.0, 0.9, 0.5)  # 黄色普通伤害
		label.font_size = 48
		label.outline_size = 8

func set_text(custom_text: String) -> void:
	label.text = custom_text
	label.modulate = Color(1.0, 1.0, 1.0)
	label.font_size = 56
	label.outline_size = 10

func _start_animation() -> void:
	# 上升动画
	var tween := create_tween()
	tween.set_parallel(true)

	# 向上移动
	tween.tween_property(self, "global_position:y", global_position.y + 2.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 淡出
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)

	# 放大后缩小
	tween.tween_property(label, "outline_modulate:a", 0.0, 1.0).set_delay(0.5)

func _on_lifetime_timeout() -> void:
	queue_free()
