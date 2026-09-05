extends Node
class_name UITheme
## UI主题配置系统
## 统一管理游戏的UI视觉风格

## 颜色主题
class Colors:
	# 主色调 - 蛋黄黄/活力橙
	const PRIMARY = Color(1.0, 0.8, 0.0)  # 金黄色
	const PRIMARY_LIGHT = Color(1.0, 0.9, 0.4)  # 浅黄色
	const PRIMARY_DARK = Color(0.9, 0.6, 0.0)  # 深橙色

	# 辅助色
	const SECONDARY = Color(0.2, 0.7, 1.0)  # 天空蓝
	const ACCENT_GREEN = Color(0.3, 0.9, 0.3)  # 草绿色

	# 背景色
	const BACKGROUND_DARK = Color(0.1, 0.1, 0.15)  # 深灰
	const BACKGROUND_LIGHT = Color(0.95, 0.95, 0.9)  # 米白
	const PANEL_BG = Color(0.2, 0.2, 0.25, 0.9)  # 半透明面板

	# 状态色
	const SUCCESS = Color(0.2, 0.8, 0.2)  # 成功绿
	const WARNING = Color(1.0, 0.7, 0.0)  # 警告橙
	const DANGER = Color(0.9, 0.2, 0.2)  # 危险红
	const INFO = Color(0.3, 0.6, 1.0)  # 信息蓝

	# 文字色
	const TEXT_PRIMARY = Color(1.0, 1.0, 1.0)  # 主文字
	const TEXT_SECONDARY = Color(0.7, 0.7, 0.7)  # 次要文字
	const TEXT_DISABLED = Color(0.4, 0.4, 0.4)  # 禁用文字

	# UI元素
	const BUTTON_NORMAL = Color(0.3, 0.3, 0.4)
	const BUTTON_HOVER = Color(0.4, 0.4, 0.5)
	const BUTTON_PRESSED = Color(0.25, 0.25, 0.35)
	const BUTTON_DISABLED = Color(0.2, 0.2, 0.25)

## 尺寸配置
class Sizes:
	# 字体大小
	const FONT_TITLE = 48
	const FONT_SUBTITLE = 32
	const FONT_BODY = 24
	const FONT_SMALL = 18
	const FONT_TINY = 14

	# 按钮尺寸
	const BUTTON_HEIGHT = 60
	const BUTTON_WIDTH_NORMAL = 200
	const BUTTON_WIDTH_WIDE = 300

	# 圆角半径
	const RADIUS_SMALL = 8
	const RADIUS_MEDIUM = 12
	const RADIUS_LARGE = 16
	const RADIUS_ROUND = 999

	# 间距
	const SPACING_TINY = 4
	const SPACING_SMALL = 8
	const SPACING_MEDIUM = 16
	const SPACING_LARGE = 24
	const SPACING_XLARGE = 32

	# 触摸区域最小尺寸（iOS标准）
	const TOUCH_MIN_SIZE = 44

## 动画配置
class Animations:
	const DURATION_FAST = 0.15
	const DURATION_NORMAL = 0.3
	const DURATION_SLOW = 0.5

	const EASE_IN_OUT = Tween.TRANS_CUBIC
	const EASE_OUT = Tween.TRANS_QUAD
	const EASE_IN = Tween.TRANS_SINE

## 创建主题资源
static func create_theme() -> Theme:
	var theme = Theme.new()

	# 按钮样式
	_setup_button_style(theme)

	# 标签样式
	_setup_label_style(theme)

	# 面板样式
	_setup_panel_style(theme)

	# 进度条样式
	_setup_progress_bar_style(theme)

	return theme

## 设置按钮样式
static func _setup_button_style(theme: Theme) -> void:
	# Normal状态
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Colors.BUTTON_NORMAL
	style_normal.corner_radius_top_left = Sizes.RADIUS_MEDIUM
	style_normal.corner_radius_top_right = Sizes.RADIUS_MEDIUM
	style_normal.corner_radius_bottom_left = Sizes.RADIUS_MEDIUM
	style_normal.corner_radius_bottom_right = Sizes.RADIUS_MEDIUM
	style_normal.shadow_color = Color(0, 0, 0, 0.3)
	style_normal.shadow_size = 4
	theme.set_stylebox("normal", "Button", style_normal)

	# Hover状态
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Colors.BUTTON_HOVER
	style_hover.shadow_size = 6
	theme.set_stylebox("hover", "Button", style_hover)

	# Pressed状态
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Colors.BUTTON_PRESSED
	style_pressed.shadow_size = 2
	theme.set_stylebox("pressed", "Button", style_pressed)

	# Disabled状态
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Colors.BUTTON_DISABLED
	style_disabled.shadow_size = 0
	theme.set_stylebox("disabled", "Button", style_disabled)

	# 字体颜色
	theme.set_color("font_color", "Button", Colors.TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Colors.PRIMARY_LIGHT)
	theme.set_color("font_pressed_color", "Button", Colors.PRIMARY)
	theme.set_color("font_disabled_color", "Button", Colors.TEXT_DISABLED)

## 设置标签样式
static func _setup_label_style(theme: Theme) -> void:
	theme.set_color("font_color", "Label", Colors.TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))

## 设置面板样式
static func _setup_panel_style(theme: Theme) -> void:
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Colors.PANEL_BG
	style_panel.corner_radius_top_left = Sizes.RADIUS_LARGE
	style_panel.corner_radius_top_right = Sizes.RADIUS_LARGE
	style_panel.corner_radius_bottom_left = Sizes.RADIUS_LARGE
	style_panel.corner_radius_bottom_right = Sizes.RADIUS_LARGE
	style_panel.border_width_left = 2
	style_panel.border_width_top = 2
	style_panel.border_width_right = 2
	style_panel.border_width_bottom = 2
	style_panel.border_color = Colors.PRIMARY_DARK
	style_panel.shadow_color = Color(0, 0, 0, 0.5)
	style_panel.shadow_size = 8
	theme.set_stylebox("panel", "Panel", style_panel)

## 设置进度条样式
static func _setup_progress_bar_style(theme: Theme) -> void:
	# 背景
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = Sizes.RADIUS_ROUND
	style_bg.corner_radius_top_right = Sizes.RADIUS_ROUND
	style_bg.corner_radius_bottom_left = Sizes.RADIUS_ROUND
	style_bg.corner_radius_bottom_right = Sizes.RADIUS_ROUND
	theme.set_stylebox("background", "ProgressBar", style_bg)

	# 填充
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Colors.SUCCESS
	style_fill.corner_radius_top_left = Sizes.RADIUS_ROUND
	style_fill.corner_radius_top_right = Sizes.RADIUS_ROUND
	style_fill.corner_radius_bottom_left = Sizes.RADIUS_ROUND
	style_fill.corner_radius_bottom_right = Sizes.RADIUS_ROUND
	theme.set_stylebox("fill", "ProgressBar", style_fill)

## 创建渐变背景
static func create_gradient_background(from: Color, to: Color) -> ColorRect:
	var rect = ColorRect.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, from)
	gradient.add_point(1.0, to)

	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)

	rect.texture = gradient_texture
	return rect

## 创建按钮动画
static func animate_button_hover(button: Button, duration: float = Animations.DURATION_FAST) -> void:
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Animations.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), duration)

static func animate_button_normal(button: Button, duration: float = Animations.DURATION_FAST) -> void:
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Animations.EASE_IN)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), duration)

static func animate_button_press(button: Button, duration: float = Animations.DURATION_FAST) -> void:
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Animations.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), duration * 0.5)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), duration * 0.5)

## 应用模糊效果
static func apply_blur_effect(control: Control) -> void:
	# 创建半透明黑色遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 注: Godot 4.x的BackBufferCopy用于模糊效果
	# 这里简化为半透明遮罩

## 创建淡入动画
static func fade_in(control: Control, duration: float = Animations.DURATION_NORMAL) -> void:
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, duration)

## 创建淡出动画
static func fade_out(control: Control, duration: float = Animations.DURATION_NORMAL) -> void:
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(control, "modulate:a", 0.0, duration)

## 获取评分颜色
static func get_rank_color(rank: String) -> Color:
	match rank:
		"S": return Color(1.0, 0.843, 0.0)  # 金色
		"A": return Color(0.0, 0.8, 0.0)  # 绿色
		"B": return Color(0.0, 0.6, 1.0)  # 蓝色
		"C": return Color(1.0, 0.6, 0.0)  # 橙色
		"D": return Color(0.6, 0.6, 0.6)  # 灰色
		_: return Colors.TEXT_PRIMARY
