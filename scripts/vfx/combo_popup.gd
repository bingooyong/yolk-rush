extends Label3D
## Combo Popup: 连击数字弹出动画

@export var popup_duration: float = 1.0
@export var rise_height: float = 1.5

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	modulate = Color.TRANSPARENT
	outline_modulate = Color.BLACK
	outline_size = 4

func show_combo(combo_count: int) -> void:
	# 设置文本
	text = "x%d" % combo_count

	# 根据连击数设置颜色
	if combo_count >= 10:
		modulate = Color(1.0, 0.2, 1.0)  # 紫色（超高连击）
	elif combo_count >= 5:
		modulate = Color(1.0, 0.5, 0.0)  # 橙色（高连击）
	else:
		modulate = Color(1.0, 1.0, 0.2)  # 黄色（普通连击）

	# 根据连击数设置大小
	var base_size := 32
	var size_multiplier := 1.0 + (combo_count * 0.1)
	font_size = int(base_size * size_multiplier)

	# 弹出动画
	_play_popup_animation()

func _play_popup_animation() -> void:
	var start_pos := position
	var end_pos := start_pos + Vector3(0, rise_height, 0)

	var tween := create_tween()
	tween.set_parallel(true)

	# 向上移动
	tween.tween_property(self, "position", end_pos, popup_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 淡入淡出
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(popup_duration - 0.3)

	# 缩放效果
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.15).set_delay(0.15)

	# 完成后删除
	await tween.finished
	queue_free()
