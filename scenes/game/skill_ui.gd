extends Control

## 技能 UI - 显示技能图标、冷却时间和快捷键

@onready var skill_container: HBoxContainer = $Panel/HBox

var player: CharacterBody3D
var skill_system: Node

func _ready() -> void:
	if not skill_container:
		_create_ui()

func _create_ui() -> void:
	# 创建面板
	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 1.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = -20
	add_child(panel)

	# 创建水平容器
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.anchor_left = 0.0
	hbox.anchor_top = 0.0
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	panel.add_child(hbox)

	skill_container = hbox

func set_player(p_player: CharacterBody3D) -> void:
	player = p_player

	# 等待技能系统初始化
	await get_tree().process_frame
	await get_tree().process_frame

	if player.has_node("SkillSystem"):
		skill_system = player.get_node("SkillSystem")
		_setup_skill_buttons()

func _setup_skill_buttons() -> void:
	# 清空现有按钮
	for child in skill_container.get_children():
		child.queue_free()

	# 创建 4 个技能按钮
	var keys := ["skill_1", "skill_2", "skill_3", "skill_ultimate"]
	var key_labels := ["Q", "E", "R", "F"]

	for i in keys.size():
		var skill_key := keys[i]
		var skill_data = skill_system.get_skill_by_key(skill_key)
		if not skill_data:
			continue

		var button := _create_skill_button(skill_data, key_labels[i])
		skill_container.add_child(button)

func _create_skill_button(skill_data, key_label: String) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(80, 80)

	# 技能图标背景
	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(60, 60)
	container.add_child(bg)

	# 技能名称
	var name_label := Label.new()
	name_label.text = skill_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	container.add_child(name_label)

	# 快捷键
	var key_label_node := Label.new()
	key_label_node.text = "[%s]" % key_label
	key_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label_node.add_theme_font_size_override("font_size", 10)
	container.add_child(key_label_node)

	# 冷却遮罩
	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0, 0, 0, 0.6)
	cooldown_overlay.anchor_right = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.visible = false
	bg.add_child(cooldown_overlay)

	# 冷却文字
	var cooldown_label := Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.anchor_left = 0.5
	cooldown_label.anchor_top = 0.5
	cooldown_label.anchor_right = 0.5
	cooldown_label.anchor_bottom = 0.5
	cooldown_label.offset_left = -20
	cooldown_label.offset_top = -10
	cooldown_label.offset_right = 20
	cooldown_label.offset_bottom = 10
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.visible = false
	bg.add_child(cooldown_label)

	return container

func _process(_delta: float) -> void:
	if not skill_system:
		return

	# 更新每个技能按钮的冷却状态
	var keys := ["skill_1", "skill_2", "skill_3", "skill_ultimate"]
	for i in keys.size():
		if i >= skill_container.get_child_count():
			break

		var button := skill_container.get_child(i)
		var bg := button.get_child(0) as Panel
		if not bg:
			continue

		var cooldown_remaining := skill_system.get_cooldown_remaining(keys[i])

		var overlay := bg.get_node_or_null("CooldownOverlay") as ColorRect
		var label := bg.get_node_or_null("CooldownLabel") as Label

		if overlay and label:
			if cooldown_remaining > 0.0:
				overlay.visible = true
				label.visible = true
				label.text = "%.1f" % cooldown_remaining
			else:
				overlay.visible = false
				label.visible = false
