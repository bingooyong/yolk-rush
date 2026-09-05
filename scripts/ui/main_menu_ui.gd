extends Control
class_name MainMenuUI
## 主菜单界面

signal start_game_pressed()
signal level_select_pressed()
signal settings_pressed()
signal quit_pressed()

## 节点引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var button_container: VBoxContainer = $VBoxContainer/ButtonContainer
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var level_select_button: Button = $VBoxContainer/ButtonContainer/LevelSelectButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var background_particles: CPUParticles2D = $BackgroundParticles

func _ready() -> void:
	print("[MainMenuUI] Initializing...")

	# 如果节点不存在，创建它们
	if not has_node("VBoxContainer"):
		_create_ui()

	# 连接信号
	_connect_signals()

	# 启动背景粒子
	if background_particles:
		background_particles.emitting = true

	print("[MainMenuUI] Initialized")

## 创建UI（如果节点不存在）
func _create_ui() -> void:
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "VBoxContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_container)

	# 标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "YOLK RUSH"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 标题样式
	var title_font = SystemFont.new()
	title_font.font_names = ["Arial", "Helvetica"]
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))

	main_container.add_child(title_label)

	# 添加间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 50)
	main_container.add_child(spacer1)

	# 按钮容器
	button_container = VBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_child(button_container)

	# 开始游戏按钮
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(300, 60)
	_style_button(start_button, true)
	button_container.add_child(start_button)

	# 按钮间距
	_add_button_spacer(button_container)

	# 关卡选择按钮
	level_select_button = Button.new()
	level_select_button.name = "LevelSelectButton"
	level_select_button.text = "关卡选择"
	level_select_button.custom_minimum_size = Vector2(300, 60)
	_style_button(level_select_button, false)
	button_container.add_child(level_select_button)

	_add_button_spacer(button_container)

	# 设置按钮
	settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(300, 60)
	_style_button(settings_button, false)
	button_container.add_child(settings_button)

	_add_button_spacer(button_container)

	# 退出按钮
	quit_button = Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "退出"
	quit_button.custom_minimum_size = Vector2(300, 60)
	_style_button(quit_button, false)
	button_container.add_child(quit_button)

	# 背景粒子
	background_particles = CPUParticles2D.new()
	background_particles.name = "BackgroundParticles"
	background_particles.position = Vector2(640, 360)
	background_particles.amount = 50
	background_particles.lifetime = 3.0
	background_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	background_particles.emission_sphere_radius = 400
	background_particles.direction = Vector2(0, 1)
	background_particles.spread = 45
	background_particles.gravity = Vector2(0, 50)
	background_particles.initial_velocity_min = 50
	background_particles.initial_velocity_max = 100
	background_particles.scale_amount_min = 0.5
	background_particles.scale_amount_max = 1.5
	background_particles.color = Color(1, 0.9, 0.3, 0.6)
	add_child(background_particles)
	move_child(background_particles, 0)  # 移到最底层

## 添加按钮间距
func _add_button_spacer(container: VBoxContainer) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	container.add_child(spacer)

## 设置按钮样式
func _style_button(button: Button, is_primary: bool) -> void:
	# 字体大小
	button.add_theme_font_size_override("font_size", 28)

	# 颜色
	if is_primary:
		button.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		button.add_theme_color_override("font_hover_color", Color(0.2, 0.2, 0.2))
	else:
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1))

## 连接信号
func _connect_signals() -> void:
	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

	if level_select_button and not level_select_button.pressed.is_connected(_on_level_select_pressed):
		level_select_button.pressed.connect(_on_level_select_pressed)

	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)

	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

## 按钮回调
func _on_start_pressed() -> void:
	print("[MainMenuUI] Start game pressed")
	start_game_pressed.emit()

func _on_level_select_pressed() -> void:
	print("[MainMenuUI] Level select pressed")
	level_select_pressed.emit()

func _on_settings_pressed() -> void:
	print("[MainMenuUI] Settings pressed")
	settings_pressed.emit()

func _on_quit_pressed() -> void:
	print("[MainMenuUI] Quit pressed")
	quit_pressed.emit()

## 显示/隐藏
func show_menu() -> void:
	visible = true
	if background_particles:
		background_particles.emitting = true

func hide_menu() -> void:
	visible = false
	if background_particles:
		background_particles.emitting = false
