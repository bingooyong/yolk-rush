extends Control
class_name LevelSelectScreen
## 关卡选择界面

signal level_selected(level_id: String)
signal back_pressed()

## UI 组件
@onready var level_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/LevelGrid
@onready var level_info_panel: Panel = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel
@onready var level_name_label: Label = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/LevelName
@onready var level_desc_label: Label = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/Description
@onready var best_score_label: Label = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/BestScore
@onready var best_time_label: Label = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/BestTime
@onready var stars_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/Stars
@onready var play_button: Button = $Panel/MarginContainer/VBoxContainer/LevelInfoPanel/VBoxContainer/PlayButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/TopBar/BackButton

## 系统引用
var save_system: SaveSystem = null
var selected_level_id: String = ""

## 关卡定义
var available_levels: Array[Dictionary] = [
	{
		"id": "level_1",
		"name": "Tutorial",
		"description": "Learn the basics",
		"difficulty": 1,
		"target_score": 500,
		"time_limit": 60.0
	},
	{
		"id": "level_2",
		"name": "First Challenge",
		"description": "Put your skills to test",
		"difficulty": 2,
		"target_score": 1000,
		"time_limit": 90.0
	},
	{
		"id": "level_3",
		"name": "Speed Run",
		"description": "Fast paced obstacles",
		"difficulty": 3,
		"target_score": 1500,
		"time_limit": 120.0
	},
	{
		"id": "level_4",
		"name": "Power Up Paradise",
		"description": "Collect all power-ups",
		"difficulty": 2,
		"target_score": 2000,
		"time_limit": 150.0
	},
	{
		"id": "level_5",
		"name": "Final Test",
		"description": "Ultimate challenge",
		"difficulty": 4,
		"target_score": 3000,
		"time_limit": 180.0
	}
]

func _ready() -> void:
	# 获取存档系统
	save_system = _get_save_system()

	# 连接信号
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

	# 创建关卡按钮
	_create_level_buttons()

	# 默认选择第一关
	if available_levels.size() > 0:
		_select_level(available_levels[0].id)

## 获取存档系统
func _get_save_system() -> SaveSystem:
	# 从 GameFlowManager 获取
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager and flow_manager.save_system:
		return flow_manager.save_system

	# 创建临时的
	var temp_save = SaveSystem.new()
	add_child(temp_save)
	temp_save.load_game()
	return temp_save

## 创建关卡按钮
func _create_level_buttons() -> void:
	if not level_grid:
		return

	for level in available_levels:
		var button = _create_level_button(level)
		level_grid.add_child(button)

## 创建单个关卡按钮
func _create_level_button(level_data: Dictionary) -> Control:
	var button_container = VBoxContainer.new()
	button_container.custom_minimum_size = Vector2(150, 150)

	# 主按钮
	var button = Button.new()
	button.custom_minimum_size = Vector2(150, 100)
	button.text = level_data.name

	var level_id = level_data.id

	# 检查是否解锁
	var is_unlocked = save_system.is_level_unlocked(level_id)

	if not is_unlocked:
		button.disabled = true
		button.text += "\n🔒 Locked"
	else:
		# 显示星级
		var progress = save_system.get_level_progress(level_id)
		var stars = progress.best_stars

		if stars > 0:
			button.text += "\n" + "⭐".repeat(stars)

	button.pressed.connect(func(): _on_level_button_pressed(level_id))
	button_container.add_child(button)

	# 难度指示
	var difficulty_label = Label.new()
	difficulty_label.text = "Difficulty: " + "●".repeat(level_data.difficulty)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_container.add_child(difficulty_label)

	return button_container

## 选择关卡
func _select_level(level_id: String) -> void:
	selected_level_id = level_id

	# 查找关卡数据
	var level_data: Dictionary = {}
	for level in available_levels:
		if level.id == level_id:
			level_data = level
			break

	if level_data.is_empty():
		return

	# 更新信息面板
	_update_info_panel(level_data)

## 更新信息面板
func _update_info_panel(level_data: Dictionary) -> void:
	if not level_info_panel:
		return

	var level_id = level_data.id

	# 关卡名称
	if level_name_label:
		level_name_label.text = level_data.name

	# 描述
	if level_desc_label:
		level_desc_label.text = level_data.description
		level_desc_label.text += "\n\nTarget: %d points" % level_data.target_score
		if level_data.time_limit > 0:
			level_desc_label.text += "\nTime Limit: %d seconds" % level_data.time_limit

	# 获取进度
	var progress = save_system.get_level_progress(level_id)

	# 最佳成绩
	if best_score_label:
		if progress.best_score > 0:
			best_score_label.text = "Best Score: %d" % progress.best_score
		else:
			best_score_label.text = "Best Score: --"

	# 最佳时间
	if best_time_label:
		if progress.best_time > 0:
			best_time_label.text = "Best Time: %.1fs" % progress.best_time
		else:
			best_time_label.text = "Best Time: --"

	# 星级
	if stars_container:
		# 清空现有星星
		for child in stars_container.get_children():
			child.queue_free()

		# 显示3个星星位置
		for i in range(3):
			var star_label = Label.new()
			if i < progress.best_stars:
				star_label.text = "⭐"
			else:
				star_label.text = "☆"
			stars_container.add_child(star_label)

	# 播放按钮
	if play_button:
		var is_unlocked = save_system.is_level_unlocked(level_id)
		play_button.disabled = not is_unlocked

## === 信号回调 ===

func _on_level_button_pressed(level_id: String) -> void:
	_select_level(level_id)

func _on_play_pressed() -> void:
	if selected_level_id.is_empty():
		return

	level_selected.emit(selected_level_id)

	# 通知 GameFlowManager
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager:
		flow_manager.start_level(selected_level_id)

func _on_back_pressed() -> void:
	back_pressed.emit()

	# 返回主菜单
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager:
		flow_manager.return_to_main_menu()
