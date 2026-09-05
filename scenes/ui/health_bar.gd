extends Control
class_name HealthBar
## 生命值条组件 - 平滑动画显示

@export var bar_color_high: Color = Color(0.2, 0.8, 0.3)  # 高血量绿色
@export var bar_color_mid: Color = Color(0.9, 0.7, 0.2)   # 中血量黄色
@export var bar_color_low: Color = Color(0.9, 0.2, 0.2)   # 低血量红色
@export var bar_height: float = 20.0
@export var show_text: bool = true
@export var animate_duration: float = 0.3

var current_health: float = 100.0
var max_health: float = 100.0
var target_health: float = 100.0

var background_panel: Panel
var health_fill: ColorRect
var damage_fill: ColorRect  # 延迟显示的伤害部分
var health_label: Label

var tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(200, bar_height)
	_setup_ui()

func _setup_ui() -> void:
	# 背景
	background_panel = Panel.new()
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	add_child(background_panel)

	# 创建自定义样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	background_panel.add_theme_stylebox_override("panel", bg_style)

	# 伤害延迟显示层（红色淡出）
	damage_fill = ColorRect.new()
	damage_fill.color = Color(0.8, 0.3, 0.3, 0.6)
	damage_fill.anchor_top = 0.0
	damage_fill.anchor_bottom = 1.0
	damage_fill.offset_left = 2
	damage_fill.offset_top = 2
	damage_fill.offset_bottom = -2
	background_panel.add_child(damage_fill)

	# 生命值填充
	health_fill = ColorRect.new()
	health_fill.color = bar_color_high
	health_fill.anchor_top = 0.0
	health_fill.anchor_bottom = 1.0
	health_fill.offset_left = 2
	health_fill.offset_top = 2
	health_fill.offset_bottom = -2
	background_panel.add_child(health_fill)

	# 文字显示
	if show_text:
		health_label = Label.new()
		health_label.anchor_left = 0.0
		health_label.anchor_right = 1.0
		health_label.anchor_top = 0.0
		health_label.anchor_bottom = 1.0
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		health_label.add_theme_font_size_override("font_size", 12)
		health_label.add_theme_color_override("font_color", Color.WHITE)
		health_label.add_theme_color_override("font_outline_color", Color.BLACK)
		health_label.add_theme_constant_override("outline_size", 1)
		background_panel.add_child(health_label)

	_update_display()

func set_health(current: float, maximum: float) -> void:
	var old_health = current_health

	max_health = maximum
	target_health = clampf(current, 0.0, max_health)

	# 如果是受伤，先更新伤害层
	if target_health < current_health:
		_animate_damage(current_health, target_health)
	else:
		# 治疗直接更新
		current_health = target_health
		_animate_health()

func _animate_health() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 动画更新当前值
	tween.tween_property(self, "current_health", target_health, animate_duration)
	tween.tween_callback(_update_display).set_delay(0.0)

	# 每帧更新显示
	tween.tween_method(_update_display_tick, 0.0, 1.0, animate_duration)

func _update_display_tick(_progress: float) -> void:
	_update_display()

func _animate_damage(from: float, to: float) -> void:
	# 立即更新主血条
	current_health = to
	_update_health_bar()

	# 延迟更新伤害层（制造延迟效果）
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# 伤害层延迟0.2秒后淡出到新位置
	await get_tree().create_timer(0.2).timeout

	var damage_tween = create_tween()
	damage_tween.set_parallel(true)
	damage_tween.set_ease(Tween.EASE_OUT)
	damage_tween.set_trans(Tween.TRANS_QUAD)

	# 缩小伤害层宽度
	var target_width = (to / max_health) * (size.x - 4)
	damage_tween.tween_property(damage_fill, "size:x", target_width, 0.3)
	damage_tween.tween_property(damage_fill, "modulate:a", 0.3, 0.3)

func _update_display() -> void:
	_update_health_bar()
	_update_color()
	_update_text()

func _update_health_bar() -> void:
	var health_percent = current_health / max_health if max_health > 0 else 0.0
	var bar_width = (size.x - 4) * health_percent
	health_fill.size.x = bar_width

func _update_color() -> void:
	var health_percent = current_health / max_health if max_health > 0 else 0.0

	if health_percent > 0.5:
		# 高血量 -> 中血量插值
		var t = (health_percent - 0.5) * 2.0
		health_fill.color = bar_color_mid.lerp(bar_color_high, t)
	else:
		# 低血量 -> 中血量插值
		var t = health_percent * 2.0
		health_fill.color = bar_color_low.lerp(bar_color_mid, t)

func _update_text() -> void:
	if health_label:
		health_label.text = "%d / %d" % [int(current_health), int(max_health)]

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0 else 0.0

## 设置为百分比模式（不显示具体数值）
func set_percentage_mode(enabled: bool) -> void:
	show_text = enabled
	if health_label:
		health_label.visible = enabled
		if enabled:
			_update_text()
