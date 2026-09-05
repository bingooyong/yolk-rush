extends Control
class_name LevelSelectMenu
## 关卡选择菜单
## 显示可用关卡，支持解锁状态显示

signal level_selected(level_id: int)
signal back_pressed()

## 关卡按钮容器
var level_buttons: Array[Button] = []

## 关卡数据
var level_data: Array[Dictionary] = []

## 当前选中的关卡
var selected_level: int = -1

func _ready() -> void:
	# 等待场景树就绪
	await get_tree().process_frame

	_create_ui()
	_load_level_data()
	_update_level_buttons()

	print("[LevelSelectMenu] Initialized with %d levels" % level_data.size())

## 创建UI
func _create_ui() -> void:
	# 设置为全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.02, 0.027, 0.047, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(-400, -300)
	main_container.custom_minimum_size = Vector2(800, 600)
	main_container.add_theme_constant_override("separation", 30)
	add_child(main_container)

	# 标题
	var title = Label.new()
	title.name = "Title"
	title.text = "选择关卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.22, 0.75, 0.97))
	main_container.add_child(title)

	# 关卡网格容器
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.custom_minimum_size = Vector2(800, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_container.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "LevelGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)

	# 底部按钮容器
	var bottom_container = HBoxContainer.new()
	bottom_container.name = "BottomContainer"
	bottom_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_container.add_theme_constant_override("separation", 20)
	main_container.add_child(bottom_container)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(150, 50)
	back_btn.pressed.connect(_on_back_pressed)
	bottom_container.add_child(back_btn)

	# 开始按钮
	var start_btn = Button.new()
	start_btn.name = "StartButton"
	start_btn.text = "开始游戏"
	start_btn.custom_minimum_size = Vector2(200, 50)
	start_btn.disabled = true
	start_btn.pressed.connect(_on_start_pressed)
	bottom_container.add_child(start_btn)

## 加载关卡数据
func _load_level_data() -> void:
	# 获取GameConfig
	var game_config = _find_game_config()

	if game_config:
		# 从GameConfig加载
		for i in range(game_config.total_levels):
			level_data.append({
				"id": i,
				"name": "关卡 %d" % (i + 1),
				"unlocked": game_config.is_level_unlocked(i),
				"completed": game_config.is_level_completed(i),
				"stars": game_config.get_level_stars(i)
			})
	else:
		# 默认3个关卡
		level_data = [
			{"id": 0, "name": "教学关卡", "unlocked": true, "completed": false, "stars": 0},
			{"id": 1, "name": "竞速关卡", "unlocked": false, "completed": false, "stars": 0},
			{"id": 2, "name": "Boss关卡", "unlocked": false, "completed": false, "stars": 0}
		]

## 查找GameConfig
func _find_game_config() -> Node:
	if has_node("/root/GameConfig"):
		return get_node("/root/GameConfig")
	return null

## 更新关卡按钮
func _update_level_buttons() -> void:
	var grid = get_node_or_null("MainContainer/ScrollContainer/LevelGrid")
	if not grid:
		return

	# 清空现有按钮
	for btn in level_buttons:
		btn.queue_free()
	level_buttons.clear()

	# 创建新按钮
	for level in level_data:
		var btn = _create_level_button(level)
		grid.add_child(btn)
		level_buttons.append(btn)

## 创建关卡按钮
func _create_level_button(level: Dictionary) -> Button:
	var btn = Button.new()
	btn.name = "LevelButton%d" % level.id
	btn.custom_minimum_size = Vector2(240, 180)

	# 设置文本
	var text = level.name + "\n"
	if level.completed:
		text += "已完成\n"
		text += "★".repeat(level.stars)
	elif level.unlocked:
		text += "未完成"
	else:
		text += "🔒 未解锁"

	btn.text = text

	# 设置状态
	btn.disabled = not level.unlocked

	# 设置颜色
	if level.completed:
		btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif level.unlocked:
		btn.add_theme_color_override("font_color", Color(0.22, 0.75, 0.97))
	else:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	# 连接信号
	btn.pressed.connect(_on_level_button_pressed.bind(level.id))

	return btn

## 关卡按钮点击
func _on_level_button_pressed(level_id: int) -> void:
	selected_level = level_id

	# 更新开始按钮状态
	var start_btn = get_node_or_null("MainContainer/BottomContainer/StartButton")
	if start_btn:
		start_btn.disabled = false
		start_btn.text = "开始 - %s" % level_data[level_id].name

	print("[LevelSelectMenu] Selected level: %d" % level_id)

## 开始按钮点击
func _on_start_pressed() -> void:
	if selected_level >= 0:
		print("[LevelSelectMenu] Starting level: %d" % selected_level)
		level_selected.emit(selected_level)
		hide_menu()

## 返回按钮点击
func _on_back_pressed() -> void:
	back_pressed.emit()
	hide_menu()

## 显示菜单
func show_menu() -> void:
	visible = true
	_load_level_data()
	_update_level_buttons()
	selected_level = -1

	var start_btn = get_node_or_null("MainContainer/BottomContainer/StartButton")
	if start_btn:
		start_btn.disabled = true
		start_btn.text = "开始游戏"

## 隐藏菜单
func hide_menu() -> void:
	visible = false

## 刷新关卡状态
func refresh() -> void:
	_load_level_data()
	_update_level_buttons()
