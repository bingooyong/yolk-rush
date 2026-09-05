extends Control
class_name MainMenu
## 主菜单 - 游戏启动界面（视觉升级版）

signal start_game_pressed()
signal continue_game_pressed()
signal settings_pressed()
signal quit_pressed()

@onready var title_label: Label
@onready var subtitle_label: Label
@onready var start_button: Button
@onready var continue_button: Button
@onready var settings_button: Button
@onready var quit_button: Button
@onready var version_label: Label
@onready var background_panel: Panel

const VERSION = "Alpha 0.1.0"

# 设计系统颜色
const COLOR_PRIMARY = Color("#3B6DFF")      # 主色调
const COLOR_ACCENT = Color("#38BDF8")       # 强调色
const COLOR_SUCCESS = Color("#6EE7B7")      # 成功色
const COLOR_WARNING = Color("#E9A568")      # 警告色
const COLOR_DANGER = Color("#EF4444")       # 错误色
const COLOR_BG_DARK_1 = Color("#05070C")    # 背景最深
const COLOR_BG_DARK_2 = Color("#0A0D12")
const COLOR_BG_DARK_3 = Color("#0F131C")
const COLOR_BG_DARK_4 = Color("#161D2B")
const COLOR_TEXT_PRIMARY = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#E5E7EB")
const COLOR_TEXT_TERTIARY = Color("#9CA3AF")

func _ready() -> void:
	_setup_background()
	_setup_ui()
	_connect_signals()
	_play_entrance_animation()
	print("[MainMenu] Initialized (Visual Upgrade)")

## 设置背景
func _setup_background() -> void:
	# 渐变背景
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_panel)
	move_child(background_panel, 0)  # 移到最底层

	# 创建渐变背景样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG_DARK_1

	# 渐变效果（从深蓝到深紫）
	bg_style.draw_center = true

	# 添加微妙的渐变
	var gradient = Gradient.new()
	gradient.add_point(0.0, COLOR_BG_DARK_1)
	gradient.add_point(0.5, Color("#0A0D1A"))
	gradient.add_point(1.0, Color("#0F1020"))

	background_panel.add_theme_stylebox_override("panel", bg_style)

## 设置UI
func _setup_ui() -> void:
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(-250, -300)
	main_container.custom_minimum_size = Vector2(500, 600)
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)

	# Logo区域
	_create_logo_section(main_container)

	# 间隔
	_add_spacer(main_container, 48)

	# 按钮区域
	_create_button_section(main_container)

	# 弹性间隔（推到底部）
	var flex_spacer = Control.new()
	flex_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(flex_spacer)

	# 版本号
	_create_version_label(main_container)

## 创建Logo区域
func _create_logo_section(parent: Control) -> void:
	var logo_container = VBoxContainer.new()
	logo_container.add_theme_constant_override("separation", 12)
	parent.add_child(logo_container)

	# 游戏标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "YOLK RUSH"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)

	# 标题颜色 - 渐变效果（通过阴影模拟）
	title_label.add_theme_color_override("font_color", COLOR_WARNING)
	title_label.add_theme_color_override("font_outline_color", Color("#8B5A2B"))
	title_label.add_theme_constant_override("outline_size", 6)

	# 添加阴影效果
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)

	logo_container.add_child(title_label)

	# 副标题
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.text = "疯狂的蛋黄冒险"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	subtitle_label.modulate.a = 0.8
	logo_container.add_child(subtitle_label)

## 创建按钮区域
func _create_button_section(parent: Control) -> void:
	var button_container = VBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.add_theme_constant_override("separation", 12)
	parent.add_child(button_container)

	# 开始游戏按钮（主要按钮）
	start_button = _create_styled_button(
		"开始游戏",
		COLOR_SUCCESS,
		Vector2(400, 60),
		28
	)
	start_button.name = "StartButton"
	button_container.add_child(start_button)

	# 继续游戏按钮（次要按钮）
	continue_button = _create_styled_button(
		"继续游戏",
		COLOR_PRIMARY,
		Vector2(400, 56),
		24
	)
	continue_button.name = "ContinueButton"
	button_container.add_child(continue_button)

	# 设置按钮
	settings_button = _create_styled_button(
		"设置",
		COLOR_BG_DARK_4,
		Vector2(400, 56),
		24
	)
	settings_button.name = "SettingsButton"
	button_container.add_child(settings_button)

	# 退出按钮
	quit_button = _create_styled_button(
		"退出游戏",
		COLOR_BG_DARK_3,
		Vector2(400, 56),
		24
	)
	quit_button.name = "QuitButton"
	button_container.add_child(quit_button)

## 创建样式化按钮
func _create_styled_button(
	text: String,
	base_color: Color,
	min_size: Vector2,
	font_size: int
) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size

	# 正常状态
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.content_margin_left = 24
	normal_style.content_margin_right = 24
	normal_style.content_margin_top = 16
	normal_style.content_margin_bottom = 16

	# 边框
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = base_color.lightened(0.3)

	# 阴影
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 2)

	button.add_theme_stylebox_override("normal", normal_style)

	# 悬停状态
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = base_color.lightened(0.15)
	hover_style.border_color = base_color.lightened(0.4)
	hover_style.shadow_size = 6
	hover_style.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("hover", hover_style)

	# 按下状态
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.15)
	pressed_style.border_color = base_color
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)
	pressed_style.content_margin_top = 18
	pressed_style.content_margin_bottom = 14
	button.add_theme_stylebox_override("pressed", pressed_style)

	# 禁用状态
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = COLOR_BG_DARK_3
	disabled_style.border_color = COLOR_BG_DARK_4
	button.add_theme_stylebox_override("disabled", disabled_style)

	# 字体
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_SECONDARY)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_TERTIARY)

	return button

## 创建版本号标签
func _create_version_label(parent: Control) -> void:
	version_label = Label.new()
	version_label.name = "VersionLabel"
	version_label.text = "Version %s" % VERSION
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", COLOR_TEXT_TERTIARY)
	version_label.modulate.a = 0.6
	parent.add_child(version_label)

## 添加间隔
func _add_spacer(parent: Control, height: float) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)

## 连接信号
func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 音效反馈
	start_button.mouse_entered.connect(_on_button_hover)
	continue_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_hover")

func _on_start_pressed() -> void:
	print("[MainMenu] Start game pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_confirm")
	_play_exit_animation()
	await get_tree().create_timer(0.3).timeout
	start_game_pressed.emit()

func _on_continue_pressed() -> void:
	print("[MainMenu] Continue game pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_click")
	continue_game_pressed.emit()

func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_click")
	settings_pressed.emit()

func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_cancel")
	quit_pressed.emit()

## 入场动画
func _play_entrance_animation() -> void:
	# 初始状态
	title_label.modulate.a = 0.0
	title_label.position.y = -50
	subtitle_label.modulate.a = 0.0

	for button in [start_button, continue_button, settings_button, quit_button]:
		button.modulate.a = 0.0
		button.position.x = -30

	version_label.modulate.a = 0.0

	# 动画序列
	var tween = create_tween()
	tween.set_parallel(false)

	# 标题淡入+下落
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(title_label, "position:y", 0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 副标题淡入
	tween.tween_property(subtitle_label, "modulate:a", 0.8, 0.3)

	# 按钮依次淡入+滑入
	tween.tween_interval(0.2)
	for button in [start_button, continue_button, settings_button, quit_button]:
		tween.tween_property(button, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(button, "position:x", 0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.1)

	# 版本号淡入
	tween.tween_property(version_label, "modulate:a", 0.6, 0.3)

## 退出动画
func _play_exit_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# 所有元素淡出
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

	# 标题向上飞出
	tween.tween_property(title_label, "position:y", -100, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

## 显示菜单（带淡入动画）
func show_menu() -> void:
	visible = true
	modulate.a = 0.0
	_play_entrance_animation()

## 隐藏菜单（带淡出动画）
func hide_menu() -> void:
	_play_exit_animation()
	await get_tree().create_timer(0.3).timeout
	visible = false

## 更新继续按钮状态（根据是否有存档）
func update_continue_button(has_save: bool) -> void:
	if continue_button:
		continue_button.disabled = not has_save
		continue_button.modulate.a = 1.0 if has_save else 0.5
