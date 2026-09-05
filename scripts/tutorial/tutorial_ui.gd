extends Control
class_name TutorialUI
## 教学UI
## 显示教学提示和进度

## UI组件
@onready var message_panel: Panel = null
@onready var message_label: Label = null
@onready var progress_bar: ProgressBar = null
@onready var skip_button: Button = null

## 动画
var tween: Tween = null

## 消息队列
var message_queue: Array[String] = []
var is_showing_message: bool = false

func _ready() -> void:
	print("[TutorialUI] Initializing...")

	_setup_ui()

	# 初始隐藏
	hide_tutorial_ui()

	print("[TutorialUI] Initialized")

## 设置UI组件
func _setup_ui() -> void:
	# 创建主容器
	var container = VBoxContainer.new()
	container.name = "TutorialContainer"
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	add_child(container)

	# 顶部进度区域
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_top", 20)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	container.add_child(top_margin)

	var top_hbox = HBoxContainer.new()
	top_margin.add_child(top_hbox)

	# 进度条
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(300, 30)
	progress_bar.show_percentage = true
	top_hbox.add_child(progress_bar)

	top_hbox.add_child(Control.new())  # 弹簧

	# 跳过按钮
	skip_button = Button.new()
	skip_button.text = "跳过教学"
	skip_button.custom_minimum_size = Vector2(120, 40)
	skip_button.pressed.connect(_on_skip_pressed)
	top_hbox.add_child(skip_button)

	# 中间弹簧
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(spacer)

	# 底部消息区域
	var bottom_margin = MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_bottom", 100)
	bottom_margin.add_theme_constant_override("margin_left", 50)
	bottom_margin.add_theme_constant_override("margin_right", 50)
	container.add_child(bottom_margin)

	var center_container = CenterContainer.new()
	bottom_margin.add_child(center_container)

	# 消息面板
	message_panel = Panel.new()
	message_panel.custom_minimum_size = Vector2(600, 100)
	center_container.add_child(message_panel)

	var panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_top", 15)
	panel_margin.add_theme_constant_override("margin_bottom", 15)
	panel_margin.add_theme_constant_override("margin_left", 20)
	panel_margin.add_theme_constant_override("margin_right", 20)
	message_panel.add_child(panel_margin)

	# 消息文本
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 24)
	panel_margin.add_child(message_label)

	# 初始隐藏消息面板
	message_panel.modulate = Color(1, 1, 1, 0)

## 显示教学消息
func show_tutorial_message(message: String, duration: float = 3.0) -> void:
	if is_showing_message:
		# 如果正在显示消息，加入队列
		message_queue.append(message)
		return

	is_showing_message = true

	# 设置消息文本
	message_label.text = message

	# 淡入动画
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 淡入
	tween.tween_property(message_panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# 等待
	if duration > 0:
		tween.tween_interval(duration)

		# 淡出
		tween.tween_property(message_panel, "modulate", Color(1, 1, 1, 0), 0.3)

		# 完成回调
		tween.finished.connect(_on_message_finished)

## 消息显示完成
func _on_message_finished() -> void:
	is_showing_message = false

	# 检查队列中是否有待显示的消息
	if message_queue.size() > 0:
		var next_message = message_queue.pop_front()
		show_tutorial_message(next_message)

## 更新进度
func update_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress

## 隐藏教学UI
func hide_tutorial_ui() -> void:
	visible = false

## 显示教学UI
func show_tutorial_ui() -> void:
	visible = true

## 跳过按钮点击
func _on_skip_pressed() -> void:
	# 确认对话框
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "确定要跳过教学吗？"
	confirm_dialog.ok_button_text = "跳过"
	confirm_dialog.cancel_button_text = "继续教学"

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_on_skip_confirmed)
	confirm_dialog.popup_centered()

## 确认跳过
func _on_skip_confirmed() -> void:
	# 通知教学控制器
	var tutorial_controller = get_tree().root.find_child("TutorialController", true, false)
	if tutorial_controller and tutorial_controller.has_method("skip_tutorial"):
		tutorial_controller.skip_tutorial()

	hide_tutorial_ui()

## 设置样式主题
func _apply_theme() -> void:
	if not message_panel:
		return

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.6, 1.0, 1.0)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10

	message_panel.add_theme_stylebox_override("panel", panel_style)

	# 文本颜色
	if message_label:
		message_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
