extends Control
class_name PauseMenu
## 暂停菜单 - 游戏中按 ESC 显示（视觉升级版）

signal resume_pressed()
signal restart_pressed()
signal settings_pressed()
signal main_menu_pressed()

@onready var resume_button: Button
@onready var restart_button: Button
@onready var settings_button: Button
@onready var main_menu_button: Button
@onready var overlay: ColorRect
@onready var stats_container: VBoxContainer

# 设计系统颜色
const COLOR_PRIMARY = Color("#3B6DFF")
const COLOR_SUCCESS = Color("#6EE7B7")
const COLOR_WARNING = Color("#E9A568")
const COLOR_DANGER = Color("#EF4444")
const COLOR_BG_DARK = Color("#0A0D12")
const COLOR_BG_PANEL = Color("#1E2636")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#9CA3AF")

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	hide_menu()
	print("[PauseMenu] Initialized (Visual Upgrade)")

func _setup_ui() -> void:
	# 半透明遮罩（模拟背景模糊）
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# 主面板
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.position = Vector2(-300, -250)
	main_panel.custom_minimum_size = Vector2(600, 500)
	add_child(main_panel)

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_PANEL
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.3)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	main_panel.add_theme_stylebox_override("panel", panel_style)

	# 内容容器
	var content = VBoxContainer.new()
	content.position = Vector2(32, 32)
	content.custom_minimum_size = Vector2(536, 436)
	content.add_theme_constant_override("separation", 20)
	main_panel.add_child(content)

	# 标题
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "游戏暂停"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 3)
	content.add_child(title_label)

	# 统计区域
	_create_stats_section(content)

	# 间隔
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	content.add_child(spacer)

	# 按钮区域
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 12)
	content.add_child(button_container)

	# 继续游戏按钮
	resume_button = _create_styled_button("继续游戏", COLOR_SUCCESS, Vector2(500, 56))
	resume_button.name = "ResumeButton"
	button_container.add_child(resume_button)

	# 重新开始按钮
	restart_button = _create_styled_button("重新开始", COLOR_WARNING, Vector2(500, 52))
	restart_button.name = "RestartButton"
	button_container.add_child(restart_button)

	# 设置按钮
	settings_button = _create_styled_button("设置", COLOR_PRIMARY, Vector2(500, 52))
	settings_button.name = "SettingsButton"
	button_container.add_child(settings_button)

	# 返回主菜单按钮
	main_menu_button = _create_styled_button("返回主菜单", COLOR_DANGER, Vector2(500, 52))
	main_menu_button.name = "MainMenuButton"
	button_container.add_child(main_menu_button)

## 创建统计区域
func _create_stats_section(parent: Control) -> void:
	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(536, 100)
	parent.add_child(stats_panel)

	# 统计面板样式
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = COLOR_BG_DARK
	stats_style.corner_radius_top_left = 12
	stats_style.corner_radius_top_right = 12
	stats_style.corner_radius_bottom_left = 12
	stats_style.corner_radius_bottom_right = 12
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.position = Vector2(20, 16)
	stats_container.custom_minimum_size = Vector2(496, 68)
	stats_container.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_container)

	# 默认统计
	_add_stat_row("游戏时间", "--:--")
	_add_stat_row("击败敌人", "0")
	_add_stat_row("收集道具", "0")

## 添加统计行
func _add_stat_row(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	# 标签
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# 数值
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", COLOR_TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	stats_container.add_child(row)

## 创建样式化按钮
func _create_styled_button(text: String, color: Color, min_size: Vector2) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size

	# 正常状态
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 14
	normal_style.content_margin_bottom = 14
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = color.lightened(0.3)
	normal_style.shadow_color = Color(0, 0, 0, 0.4)
	normal_style.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal_style)

	# 悬停状态
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	hover_style.shadow_size = 6
	button.add_theme_stylebox_override("hover", hover_style)

	# 按下状态
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	pressed_style.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed_style)

	# 字体
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", COLOR_TEXT)

	return button

func _connect_signals() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# 音效反馈
	resume_button.mouse_entered.connect(_on_button_hover)
	restart_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	main_menu_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_hover")

func _on_resume_pressed() -> void:
	print("[PauseMenu] Resume pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_confirm")
	hide_menu()
	resume_pressed.emit()

func _on_restart_pressed() -> void:
	print("[PauseMenu] Restart pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_click")
	restart_pressed.emit()

func _on_settings_pressed() -> void:
	print("[PauseMenu] Settings pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_click")
	settings_pressed.emit()

func _on_main_menu_pressed() -> void:
	print("[PauseMenu] Main menu pressed")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_cancel")
	main_menu_pressed.emit()

## 更新统计显示
func update_stats(stats: Dictionary) -> void:
	if not stats_container:
		return

	# 清空现有统计
	for child in stats_container.get_children():
		child.queue_free()

	# 游戏时间
	var play_time = stats.get("play_time", 0.0)
	_add_stat_row("⏱ 游戏时间", _format_time(play_time))

	# 击败敌人
	var enemies = stats.get("enemies_defeated", 0)
	_add_stat_row("⚔ 击败敌人", "%d" % enemies)

	# 收集道具
	var items = stats.get("items_collected", 0)
	_add_stat_row("💎 收集道具", "%d" % items)

## 格式化时间
func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

## 显示暂停菜单
func show_menu() -> void:
	visible = true
	get_tree().paused = true

	# 淡入动画
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# 播放音效
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_hover")

## 隐藏暂停菜单
func hide_menu() -> void:
	# 淡出动画
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

	visible = false
	get_tree().paused = false

## 切换显示状态
func toggle_menu() -> void:
	if visible:
		hide_menu()
	else:
		show_menu()

