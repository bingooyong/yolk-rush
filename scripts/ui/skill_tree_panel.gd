extends Panel
class_name SkillTreePanel
## 技能树面板 UI

const SkillNodeClass = preload("res://scripts/skill_tree/skill_node.gd")

# UI 节点
@onready var tree_tabs: TabContainer = $VBox/TreeTabs
@onready var skill_points_label: Label = $VBox/TopBar/SkillPointsLabel
@onready var reset_button: Button = $VBox/TopBar/ResetButton
@onready var close_button: Button = $VBox/TopBar/CloseButton
@onready var skill_info_panel: Panel = $SkillInfoPanel

# GameManager 引用
var game_manager = null

# 技能树容器
var tree_containers: Dictionary = {}
var skill_buttons: Dictionary = {}

# 选中的技能
var selected_skill_id: String = ""

func _ready() -> void:
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_initialize()
		else:
			game_manager.game_initialized.connect(_initialize)

func _initialize() -> void:
	# 连接技能树信号
	game_manager.skill_tree_system.skill_unlocked.connect(_on_skill_unlocked)
	game_manager.skill_tree_system.skill_upgraded.connect(_on_skill_upgraded)
	game_manager.skill_tree_system.skill_points_changed.connect(_on_skill_points_changed)
	game_manager.skill_tree_system.skills_reset.connect(_on_skills_reset)

	# 创建技能树标签页
	_create_skill_trees()

	# 初始刷新
	refresh()

## 创建技能树标签页
func _create_skill_trees() -> void:
	if not tree_tabs:
		return

	# 清空现有标签
	for child in tree_tabs.get_children():
		child.queue_free()
	tree_containers.clear()
	skill_buttons.clear()

	# 获取所有技能树
	var trees = ["combat", "survival", "crafting"]
	var tree_names = {
		"combat": "战斗",
		"survival": "生存",
		"crafting": "工艺"
	}

	for tree_id in trees:
		var tab = ScrollContainer.new()
		tab.name = tree_names[tree_id]

		var container = Control.new()
		container.custom_minimum_size = Vector2(800, 600)
		tab.add_child(container)

		tree_tabs.add_child(tab)
		tree_containers[tree_id] = container

		# 创建技能节点
		_create_skill_nodes(tree_id, container)

## 创建技能节点
func _create_skill_nodes(tree_id: String, container: Control) -> void:
	# 获取技能树的所有技能
	var skills = game_manager.skill_tree_system.get_tree_skills(tree_id)

	# 简单布局：每行 4 个技能
	var x = 50
	var y = 50
	var spacing_x = 150
	var spacing_y = 120
	var per_row = 4

	var index = 0
	for skill_id in skills:
		var skill = game_manager.skill_tree_system.get_skill_node(skill_id)
		if not skill:
			continue

		# 计算位置
		var col = index % per_row
		var row = index / per_row
		var pos = Vector2(x + col * spacing_x, y + row * spacing_y)

		# 创建技能按钮
		var button = _create_skill_button(skill_id, skill)
		button.position = pos
		container.add_child(button)

		skill_buttons[skill_id] = button

		index += 1

## 创建技能按钮
func _create_skill_button(skill_id: String, skill) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 100)
	button.name = skill_id

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)

	# 技能名称
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = skill.skill_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# 技能等级
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(level_label)

	# 连接信号
	button.pressed.connect(_on_skill_button_pressed.bind(skill_id))

	return button

## 刷新显示
func refresh() -> void:
	if not game_manager or not game_manager.is_initialized:
		return

	# 更新技能点显示
	_update_skill_points()

	# 更新所有技能按钮
	for skill_id in skill_buttons.keys():
		_update_skill_button(skill_id)

## 更新技能点显示
func _update_skill_points() -> void:
	if skill_points_label:
		var points = game_manager.skill_tree_system.available_skill_points
		skill_points_label.text = "可用技能点: %d" % points

## 更新技能按钮
func _update_skill_button(skill_id: String) -> void:
	if not skill_buttons.has(skill_id):
		return

	var button = skill_buttons[skill_id]
	var level = game_manager.skill_tree_system.get_skill_level(skill_id)
	var skill = game_manager.skill_tree_system.get_skill_node(skill_id)

	if not skill:
		return

	var level_label = button.get_node_or_null("VBoxContainer/LevelLabel")
	if level_label:
		if level > 0:
			level_label.text = "等级 %d/%d" % [level, skill.max_level]
		else:
			level_label.text = "未解锁"

	# 设置按钮状态
	if level == 0:
		# 未解锁
		button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		button.disabled = not game_manager.skill_tree_system.can_unlock_skill(skill_id)
	elif level < skill.max_level:
		# 已解锁但未满级
		button.modulate = Color(0.3, 1.0, 0.3, 1.0)
		button.disabled = not game_manager.skill_tree_system.can_upgrade_skill(skill_id)
	else:
		# 满级
		button.modulate = Color(1.0, 0.8, 0.0, 1.0)
		button.disabled = true

## 技能按钮被点击
func _on_skill_button_pressed(skill_id: String) -> void:
	selected_skill_id = skill_id

	var skill = game_manager.skill_tree_system.get_skill_node(skill_id)
	if not skill:
		return

	# 显示技能信息
	_show_skill_info(skill_id, skill)

## 显示技能信息
func _show_skill_info(skill_id: String, skill) -> void:
	if not skill_info_panel:
		return

	# 清空现有内容
	for child in skill_info_panel.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	skill_info_panel.add_child(vbox)

	# 技能名称
	var name_label = Label.new()
	name_label.text = skill.skill_name
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# 技能描述
	var desc_label = Label.new()
	desc_label.text = skill.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# 当前等级
	var level = game_manager.skill_tree_system.get_skill_level(skill_id)
	var level_label = Label.new()
	level_label.text = "当前等级: %d/%d" % [level, skill.max_level]
	vbox.add_child(level_label)

	# 等级需求
	var req_label = Label.new()
	req_label.text = "需求等级: %d" % skill.level_requirement
	vbox.add_child(req_label)

	# 技能点消耗
	var cost_label = Label.new()
	cost_label.text = "技能点消耗: %d" % skill.skill_point_cost
	vbox.add_child(cost_label)

	# 前置技能
	if skill.prerequisites.size() > 0:
		var prereq_label = Label.new()
		prereq_label.text = "前置技能: " + ", ".join(skill.prerequisites)
		vbox.add_child(prereq_label)

	# 当前效果
	if level > 0:
		var effects = skill.get_effects_at_level(level)
		var effects_label = Label.new()
		effects_label.text = "当前效果:"
		vbox.add_child(effects_label)

		for effect_name in effects.keys():
			var effect_value_label = Label.new()
			effect_value_label.text = "  %s: %.1f" % [effect_name, effects[effect_name]]
			vbox.add_child(effect_value_label)

	# 添加操作按钮
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)

	if level == 0 and game_manager.skill_tree_system.can_unlock_skill(skill_id):
		# 解锁按钮
		var unlock_button = Button.new()
		unlock_button.text = "解锁"
		unlock_button.pressed.connect(_on_unlock_skill_pressed.bind(skill_id))
		button_container.add_child(unlock_button)
	elif level > 0 and level < skill.max_level and game_manager.skill_tree_system.can_upgrade_skill(skill_id):
		# 升级按钮
		var upgrade_button = Button.new()
		upgrade_button.text = "升级"
		upgrade_button.pressed.connect(_on_upgrade_skill_pressed.bind(skill_id))
		button_container.add_child(upgrade_button)

	# 关闭按钮
	var close_info_button = Button.new()
	close_info_button.text = "关闭"
	close_info_button.pressed.connect(_on_close_skill_info_pressed)
	button_container.add_child(close_info_button)

	skill_info_panel.visible = true

## 解锁技能
func _on_unlock_skill_pressed(skill_id: String) -> void:
	if game_manager.skill_tree_system.unlock_skill(skill_id):
		print("[SkillTreePanel] Unlocked skill: %s" % skill_id)
		_update_skill_button(skill_id)
		# 重新显示信息（更新按钮状态）
		var skill = game_manager.skill_tree_system.get_skill_node(skill_id)
		if skill:
			_show_skill_info(skill_id, skill)

## 升级技能
func _on_upgrade_skill_pressed(skill_id: String) -> void:
	if game_manager.skill_tree_system.upgrade_skill(skill_id):
		print("[SkillTreePanel] Upgraded skill: %s" % skill_id)
		_update_skill_button(skill_id)
		# 重新显示信息
		var skill = game_manager.skill_tree_system.get_skill_node(skill_id)
		if skill:
			_show_skill_info(skill_id, skill)

## 关闭技能信息
func _on_close_skill_info_pressed() -> void:
	if skill_info_panel:
		skill_info_panel.visible = false

## 重置按钮
func _on_reset_button_pressed() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要重置所有技能吗？\n这将返还所有技能点。"
	dialog.ok_button_text = "重置"
	dialog.cancel_button_text = "取消"

	dialog.confirmed.connect(func():
		var refunded = game_manager.skill_tree_system.reset_skills()
		print("[SkillTreePanel] Reset skills, refunded %d points" % refunded)
		refresh()
	)

	add_child(dialog)
	dialog.popup_centered()

## 关闭按钮
func _on_close_button_pressed() -> void:
	visible = false

## 信号处理
func _on_skill_unlocked(skill_id: String) -> void:
	_update_skill_button(skill_id)

func _on_skill_upgraded(skill_id: String, new_level: int) -> void:
	_update_skill_button(skill_id)

func _on_skill_points_changed(current_points: int) -> void:
	_update_skill_points()
	# 更新所有按钮（可用性可能改变）
	refresh()

func _on_skills_reset() -> void:
	refresh()

## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if skill_info_panel and skill_info_panel.visible:
			_on_close_skill_info_pressed()
		else:
			_on_close_button_pressed()
		get_viewport().set_input_as_handled()
