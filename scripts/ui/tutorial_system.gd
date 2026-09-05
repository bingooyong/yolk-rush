extends Control
class_name TutorialSystem
## 教学引导系统
## 为新玩家提供分步教学

## 信号
signal tutorial_started()
signal tutorial_step_completed(step_id: String)
signal tutorial_completed()
signal tutorial_skipped()

## 教学步骤定义
const TUTORIAL_STEPS = [
	{
		"id": "welcome",
		"title": "欢迎来到 Yolk Rush！",
		"description": "让我们开始一段刺激的冒险吧！",
		"icon": "🎮",
		"position": "center",
		"highlight": null,
		"actions": ["continue"]
	},
	{
		"id": "movement",
		"title": "移动控制",
		"description": "使用方向键或WASD移动角色\n空格键跳跃",
		"icon": "🏃",
		"position": "bottom",
		"highlight": "player",
		"actions": ["move", "jump"]
	},
	{
		"id": "combat",
		"title": "战斗系统",
		"description": "靠近敌人自动攻击\n按Q使用技能",
		"icon": "⚔️",
		"position": "top_right",
		"highlight": "enemy",
		"actions": ["attack", "skill"]
	},
	{
		"id": "items",
		"title": "道具拾取",
		"description": "收集金币和道具\n它们会帮助你变得更强！",
		"icon": "💰",
		"position": "top_left",
		"highlight": "item",
		"actions": ["collect"]
	},
	{
		"id": "obstacles",
		"title": "小心障碍",
		"description": "避开红色障碍物\n它们会造成伤害！",
		"icon": "⚠️",
		"position": "center",
		"highlight": "obstacle",
		"actions": ["avoid"]
	},
	{
		"id": "objective",
		"title": "关卡目标",
		"description": "完成所有目标即可通关\n查看右上角的任务列表",
		"icon": "🎯",
		"position": "top_right",
		"highlight": "objective_ui",
		"actions": ["continue"]
	},
	{
		"id": "complete",
		"title": "教学完成！",
		"description": "你已经掌握了基础操作\n现在去征服所有关卡吧！",
		"icon": "🎉",
		"position": "center",
		"highlight": null,
		"actions": ["finish"]
	}
]

## 当前步骤索引
var current_step_index: int = -1

## 是否正在教学
var is_active: bool = false

## 是否已完成教学
var tutorial_completed_flag: bool = false

## UI节点
var tutorial_panel: Panel
var step_icon: Label
var step_title: Label
var step_description: Label
var continue_button: Button
var skip_button: Button
var highlight_rect: ColorRect

## 配置
@export var auto_start_for_new_players: bool = true
@export var can_skip: bool = true

func _ready() -> void:
	# 创建UI
	_create_ui()

	# 检查是否需要自动开始
	if auto_start_for_new_players:
		_check_auto_start()

## 创建UI
func _create_ui() -> void:
	# 半透明背景
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.visible = false
	add_child(overlay)

	# 高亮矩形
	highlight_rect = ColorRect.new()
	highlight_rect.name = "Highlight"
	highlight_rect.color = Color(1, 1, 0, 0.3)
	highlight_rect.visible = false
	highlight_rect.z_index = 10
	add_child(highlight_rect)

	# 教学面板
	tutorial_panel = Panel.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.custom_minimum_size = Vector2(400, 250)
	tutorial_panel.visible = false
	tutorial_panel.z_index = 11
	add_child(tutorial_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	tutorial_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# 图标
	step_icon = Label.new()
	step_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_icon.add_theme_font_size_override("font_size", 48)
	vbox.add_child(step_icon)

	# 标题
	step_title = Label.new()
	step_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(step_title)

	# 描述
	step_description = Label.new()
	step_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_description.custom_minimum_size.y = 80
	vbox.add_child(step_description)

	# 按钮区域
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(button_hbox)

	# 跳过按钮
	skip_button = Button.new()
	skip_button.text = "跳过教学"
	skip_button.pressed.connect(_on_skip_pressed)
	button_hbox.add_child(skip_button)

	# 继续按钮
	continue_button = Button.new()
	continue_button.text = "继续"
	continue_button.pressed.connect(_on_continue_pressed)
	button_hbox.add_child(continue_button)

## 检查自动开始
func _check_auto_start() -> void:
	# 从保存数据检查是否完成过教学
	var save_manager = _find_save_manager()
	if save_manager and save_manager.has_method("get_tutorial_completed"):
		tutorial_completed_flag = save_manager.get_tutorial_completed()

	# 如果没完成过，自动开始
	if not tutorial_completed_flag:
		await get_tree().create_timer(1.0).timeout
		start_tutorial()

## 开始教学
func start_tutorial() -> void:
	if is_active:
		return

	is_active = true
	current_step_index = -1

	# 显示UI
	get_node("Overlay").visible = true
	tutorial_panel.visible = true

	# 暂停游戏
	get_tree().paused = true

	tutorial_started.emit()

	# 显示第一步
	_next_step()

## 下一步
func _next_step() -> void:
	current_step_index += 1

	if current_step_index >= TUTORIAL_STEPS.size():
		_finish_tutorial()
		return

	var step = TUTORIAL_STEPS[current_step_index]
	_show_step(step)

## 显示步骤
func _show_step(step: Dictionary) -> void:
	# 更新UI
	step_icon.text = step.get("icon", "")
	step_title.text = step.get("title", "")
	step_description.text = step.get("description", "")

	# 定位面板
	var position_type = step.get("position", "center")
	_position_panel(position_type)

	# 高亮目标
	var highlight_target = step.get("highlight", null)
	if highlight_target:
		_highlight_target(highlight_target)
	else:
		highlight_rect.visible = false

	# 更新按钮
	var actions = step.get("actions", [])
	if "finish" in actions:
		continue_button.text = "完成"
	else:
		continue_button.text = "继续"

	skip_button.visible = can_skip and current_step_index > 0

## 定位面板
func _position_panel(position_type: String) -> void:
	var viewport_size = get_viewport_rect().size
	var panel_size = tutorial_panel.custom_minimum_size

	match position_type:
		"center":
			tutorial_panel.position = (viewport_size - panel_size) / 2
		"top":
			tutorial_panel.position = Vector2(
				(viewport_size.x - panel_size.x) / 2,
				50
			)
		"bottom":
			tutorial_panel.position = Vector2(
				(viewport_size.x - panel_size.x) / 2,
				viewport_size.y - panel_size.y - 50
			)
		"top_left":
			tutorial_panel.position = Vector2(50, 50)
		"top_right":
			tutorial_panel.position = Vector2(
				viewport_size.x - panel_size.x - 50,
				50
			)

## 高亮目标
func _highlight_target(target: String) -> void:
	# 这里需要根据实际游戏对象来定位
	# 暂时使用占位逻辑
	highlight_rect.visible = true
	highlight_rect.size = Vector2(100, 100)
	highlight_rect.position = Vector2(200, 200)

## 继续按钮
func _on_continue_pressed() -> void:
	var step = TUTORIAL_STEPS[current_step_index]
	tutorial_step_completed.emit(step.get("id", ""))

	_next_step()

## 跳过按钮
func _on_skip_pressed() -> void:
	_skip_tutorial()

## 跳过教学
func _skip_tutorial() -> void:
	tutorial_skipped.emit()
	_end_tutorial()

## 完成教学
func _finish_tutorial() -> void:
	tutorial_completed_flag = true

	# 保存完成状态
	var save_manager = _find_save_manager()
	if save_manager and save_manager.has_method("set_tutorial_completed"):
		save_manager.set_tutorial_completed(true)

	tutorial_completed.emit()
	_end_tutorial()

## 结束教学
func _end_tutorial() -> void:
	is_active = false

	# 隐藏UI
	get_node("Overlay").visible = false
	tutorial_panel.visible = false
	highlight_rect.visible = false

	# 恢复游戏
	get_tree().paused = false

## 查找保存管理器
func _find_save_manager() -> Node:
	if has_node("/root/SaveManager"):
		return get_node("/root/SaveManager")

	var tree = get_tree()
	if tree and tree.root:
		return tree.root.find_child("SaveManager", true, false)

	return null

## 是否已完成教学
func is_tutorial_completed() -> bool:
	return tutorial_completed_flag

## 重置教学（用于测试）
func reset_tutorial() -> void:
	tutorial_completed_flag = false
	current_step_index = -1
	is_active = false
