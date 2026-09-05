extends ProgressBar
class_name AnimatedHealthBar
## 动画生命值条组件
## 提供平滑的数值变化动画和低血量警告效果

## 动画配置
@export var smooth_duration: float = 0.3
@export var low_health_threshold: float = 0.3  # 低于30%触发警告
@export var flash_duration: float = 0.5

## 颜色配置
@export var normal_color: Color = Color(0.2, 0.8, 0.2)  # 绿色
@export var warning_color: Color = Color(1.0, 0.7, 0.0)  # 橙色
@export var danger_color: Color = Color(0.9, 0.2, 0.2)  # 红色

## 内部状态
var target_value: float = 100.0
var current_display_value: float = 100.0
var tween: Tween = null
var is_flashing: bool = false

## 样式
var fill_style: StyleBoxFlat = null

func _ready() -> void:
	# 初始化样式
	_setup_styles()

	# 初始化数值
	max_value = 100.0
	value = 100.0
	current_display_value = 100.0
	target_value = 100.0

func _setup_styles() -> void:
	# 创建填充样式
	fill_style = StyleBoxFlat.new()
	fill_style.bg_color = normal_color
	fill_style.corner_radius_top_left = 999
	fill_style.corner_radius_top_right = 999
	fill_style.corner_radius_bottom_left = 999
	fill_style.corner_radius_bottom_right = 999

	add_theme_stylebox_override("fill", fill_style)

	# 创建背景样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 999
	bg_style.corner_radius_top_right = 999
	bg_style.corner_radius_bottom_left = 999
	bg_style.corner_radius_bottom_right = 999

	add_theme_stylebox_override("background", bg_style)

## 设置生命值（带动画）
func set_health(new_value: float, animate: bool = true) -> void:
	target_value = clamp(new_value, 0.0, max_value)

	if not animate:
		value = target_value
		current_display_value = target_value
		_update_color()
		return

	# 停止当前动画
	if tween and tween.is_running():
		tween.kill()

	# 创建平滑动画
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "value", target_value, smooth_duration)
	tween.finished.connect(_on_tween_finished)

	# 更新颜色
	_update_color()

	# 检查是否需要闪烁警告
	var health_percent = target_value / max_value
	if health_percent <= low_health_threshold and not is_flashing:
		_start_flash_warning()

## 更新颜色
func _update_color() -> void:
	if not fill_style:
		return

	var health_percent = target_value / max_value

	var new_color: Color
	if health_percent > 0.5:
		# 健康：绿色
		new_color = normal_color
	elif health_percent > low_health_threshold:
		# 警告：橙色
		new_color = warning_color
	else:
		# 危险：红色
		new_color = danger_color

	# 平滑过渡颜色
	var color_tween = create_tween()
	color_tween.tween_property(fill_style, "bg_color", new_color, 0.2)

## 开始闪烁警告
func _start_flash_warning() -> void:
	if is_flashing:
		return

	is_flashing = true
	_flash_loop()

## 闪烁循环
func _flash_loop() -> void:
	if not is_flashing:
		return

	var health_percent = target_value / max_value
	if health_percent > low_health_threshold:
		is_flashing = false
		return

	# 闪烁动画
	var flash_tween = create_tween()
	flash_tween.set_ease(Tween.EASE_IN_OUT)
	flash_tween.set_trans(Tween.TRANS_SINE)

	# 变亮
	flash_tween.tween_property(fill_style, "bg_color:a", 1.0, flash_duration * 0.5)
	# 变暗
	flash_tween.tween_property(fill_style, "bg_color:a", 0.6, flash_duration * 0.5)

	flash_tween.finished.connect(_flash_loop)

## 停止闪烁
func stop_flash() -> void:
	is_flashing = false
	if fill_style:
		fill_style.bg_color.a = 1.0

## 动画完成回调
func _on_tween_finished() -> void:
	current_display_value = target_value

## 获取当前生命值百分比
func get_health_percent() -> float:
	return value / max_value

## 是否处于危险状态
func is_in_danger() -> bool:
	return get_health_percent() <= low_health_threshold
