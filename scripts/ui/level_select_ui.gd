extends Control
class_name LevelSelectUI
## 关卡选择界面

signal level_selected(level_id: int)
signal back_to_menu_pressed()

## 节点引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var level_grid: GridContainer = $VBoxContainer/ScrollContainer/LevelGrid
@onready var back_button: Button = $VBoxContainer/BackButton

## 游戏配置引用
var game_config: Node = null

## 关卡卡片数组
var level_cards: Array[Panel] = []

func _ready() -> void:
	print("[LevelSelectUI] Initializing...")

	# 查找游戏配置
	_find_game_config()

	# 如果节点不存在，创建它们
	if not has_node("VBoxContainer"):
		_create_ui()

	# 加载关卡卡片
	_load_level_cards()

	# 连接信号
	_connect_signals()

	print("[LevelSelectUI] Initialized")

## 查找游戏配置
func _find_game_config() -> void:
	var root = get_tree().root
	if root:
		game_config = root.find_child("GameConfig", true, false)

## 创建UI
func _create_ui() -> void:
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "VBoxContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 50
	main_container.offset_right = -50
	main_container.offset_top = 50
	main_container.offset_bottom = -50
	add_child(main_container)

	# 标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "选择关卡"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	main_container.add_child(title_label)

	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	main_container.add_child(spacer1)

	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)

	# 关卡网格
	level_grid = GridContainer.new()
	level_grid.name = "LevelGrid"
	level_grid.columns = 3
	level_grid.add_theme_constant_override("h_separation", 30)
	level_grid.add_theme_constant_override("v_separation", 30)
	scroll.add_child(level_grid)

	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	main_container.add_child(spacer2)

	# 返回按钮
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回主菜单"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 24)
	main_container.add_child(back_button)

## 加载关卡卡片
func _load_level_cards() -> void:
	if not game_config:
		print("[LevelSelectUI] GameConfig not found, cannot load levels")
		return

	# 清空现有卡片
	for card in level_cards:
		card.queue_free()
	level_cards.clear()

	# 获取关卡数量
	var level_count = game_config.get_level_count()

	# 为每个关卡创建卡片
	for i in range(level_count):
		var level_config = game_config.get_level_config(i)
		var card = _create_level_card(level_config)
		level_grid.add_child(card)
		level_cards.append(card)

	print("[LevelSelectUI] Loaded %d level cards" % level_count)

## 创建关卡卡片
func _create_level_card(config: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(300, 400)

	# 卡片容器
	var container = VBoxContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = 20
	container.offset_right = -20
	container.offset_top = 20
	container.offset_bottom = -20
	card.add_child(container)

	# 关卡缩略图（占位符）
	var thumbnail = ColorRect.new()
	thumbnail.custom_minimum_size = Vector2(260, 180)
	thumbnail.color = Color(0.2, 0.2, 0.3)
	container.add_child(thumbnail)

	# 缩略图上的关卡ID
	var id_label = Label.new()
	id_label.text = "关卡 %d" % config.id
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	id_label.add_theme_font_size_override("font_size", 32)
	id_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	id_label.anchor_right = 1.0
	id_label.anchor_bottom = 1.0
	thumbnail.add_child(id_label)

	# 间距
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	container.add_child(spacer)

	# 关卡名称
	var name_label = Label.new()
	name_label.text = config.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	container.add_child(name_label)

	# 关卡描述
	var desc_label = Label.new()
	desc_label.text = config.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(desc_label)

	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer2)

	# 统计信息
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 5)
	container.add_child(stats_container)

	# 最佳时间（占位符）
	var time_label = Label.new()
	time_label.text = "最佳时间: --:--"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(time_label)

	# 最高分数（占位符）
	var score_label = Label.new()
	score_label.text = "最高分数: ---"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(score_label)

	# 弹性间距
	var flex_spacer = Control.new()
	flex_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(flex_spacer)

	# 解锁状态和按钮
	var is_unlocked = game_config.is_level_unlocked(config.id)

	if is_unlocked:
		# 开始按钮
		var play_button = Button.new()
		play_button.text = "开始"
		play_button.custom_minimum_size = Vector2(0, 45)
		play_button.add_theme_font_size_override("font_size", 22)
		container.add_child(play_button)

		# 连接信号
		var level_id = config.id
		play_button.pressed.connect(func(): _on_level_card_pressed(level_id))
	else:
		# 锁定标签
		var locked_label = Label.new()
		locked_label.text = "🔒 未解锁"
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.add_theme_font_size_override("font_size", 20)
		locked_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(locked_label)

	return card

## 连接信号
func _connect_signals() -> void:
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

## 关卡卡片按下
func _on_level_card_pressed(level_id: int) -> void:
	print("[LevelSelectUI] Level %d selected" % level_id)
	level_selected.emit(level_id)

## 返回按钮
func _on_back_pressed() -> void:
	print("[LevelSelectUI] Back to menu pressed")
	back_to_menu_pressed.emit()

## 显示/隐藏
func show_menu() -> void:
	visible = true
	# 刷新关卡卡片（可能有新解锁）
	_load_level_cards()

func hide_menu() -> void:
	visible = false
