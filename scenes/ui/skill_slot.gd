extends Control
class_name SkillSlot
## 技能槽位UI - 显示单个技能和冷却状态

signal slot_pressed(slot)

var skill_instance  # SkillInstance
var slot_index: int = 0

# UI组件
var background: Panel
var icon_texture: TextureRect
var cooldown_overlay: ColorRect
var cooldown_label: Label
var hotkey_label: Label
var border: Panel

# 状态
var is_enabled: bool = true
var is_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	_setup_ui()

func _setup_ui() -> void:
	# 背景
	background = Panel.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.4)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	background.add_theme_stylebox_override("panel", bg_style)

	# 技能图标
	icon_texture = TextureRect.new()
	icon_texture.anchor_left = 0.1
	icon_texture.anchor_right = 0.9
	icon_texture.anchor_top = 0.1
	icon_texture.anchor_bottom = 0.9
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.add_child(icon_texture)

	# 冷却遮罩
	cooldown_overlay = ColorRect.new()
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.anchor_right = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.visible = false
	background.add_child(cooldown_overlay)

	# 冷却文字
	cooldown_label = Label.new()
	cooldown_label.anchor_left = 0.0
	cooldown_label.anchor_right = 1.0
	cooldown_label.anchor_top = 0.0
	cooldown_label.anchor_bottom = 1.0
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 20)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cooldown_label.add_theme_constant_override("outline_size", 2)
	cooldown_label.visible = false
	background.add_child(cooldown_label)

	# 快捷键提示
	hotkey_label = Label.new()
	hotkey_label.anchor_left = 0.0
	hotkey_label.anchor_right = 1.0
	hotkey_label.anchor_top = 1.0
	hotkey_label.anchor_bottom = 1.0
	hotkey_label.offset_top = -20
	hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hotkey_label.add_theme_font_size_override("font_size", 12)
	hotkey_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hotkey_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hotkey_label.add_theme_constant_override("outline_size", 1)
	background.add_child(hotkey_label)

	# 边框高亮
	border = Panel.new()
	border.anchor_right = 1.0
	border.anchor_bottom = 1.0
	border.visible = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 3
	border_style.border_width_right = 3
	border_style.border_width_top = 3
	border_style.border_width_bottom = 3
	border_style.border_color = Color(1.0, 0.8, 0.2)
	border_style.corner_radius_top_left = 8
	border_style.corner_radius_top_right = 8
	border_style.corner_radius_bottom_left = 8
	border_style.corner_radius_bottom_right = 8
	border.add_theme_stylebox_override("panel", border_style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_enabled and skill_instance and skill_instance.is_ready():
				slot_pressed.emit(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			is_hovered = true
			border.visible = true
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
			border.visible = false

## 设置技能
func set_skill(p_skill_instance, p_slot_index: int) -> void:
	skill_instance = p_skill_instance
	slot_index = p_slot_index

	if skill_instance:
		# 设置快捷键显示
		hotkey_label.text = str(p_slot_index + 1)

		# TODO: 加载技能图标
		# if ResourceLoader.exists(skill_instance.skill.icon):
		#     icon_texture.texture = load(skill_instance.skill.icon)

		# 显示占位符
		icon_texture.modulate = Color(0.5, 0.5, 0.8)

func _process(_delta: float) -> void:
	if skill_instance:
		update_cooldown()

## 更新冷却显示
func update_cooldown() -> void:
	if not skill_instance:
		return

	if skill_instance.is_casting:
		# 显示施法时间
		cooldown_overlay.visible = true
		cooldown_label.visible = true
		cooldown_label.text = "%.1f" % skill_instance.cast_time_remaining
		cooldown_overlay.modulate = Color(0.5, 0.5, 1.0, 0.7)

	elif skill_instance.is_on_cooldown():
		# 显示冷却时间
		cooldown_overlay.visible = true
		cooldown_label.visible = true
		var remaining = skill_instance.get_cooldown_remaining()
		cooldown_label.text = "%.1f" % remaining

		# 冷却进度（从下到上减少）
		var progress = skill_instance.get_cooldown_progress()
		cooldown_overlay.anchor_top = progress
		cooldown_overlay.modulate = Color(0, 0, 0, 0.7)

	else:
		# 技能就绪
		cooldown_overlay.visible = false
		cooldown_label.visible = false

## 设置槽位启用状态
func set_slot_enabled(enabled: bool) -> void:
	is_enabled = enabled

	if enabled:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5)

## 获取技能提示信息
func get_skill_tooltip() -> String:
	if not skill_instance:
		return "空"

	var skill = skill_instance.skill
	var text = "[b]%s[/b]\n" % skill.skill_name
	text += "%s\n\n" % skill.description

	# 消耗
	if skill.cost.has("type") and skill.cost.has("value"):
		text += "[color=yellow]消耗:[/color] %s %.0f\n" % [skill.cost.type, skill.cost.value]

	# 冷却
	text += "[color=cyan]冷却:[/color] %.1fs\n" % skill.cooldown

	# 距离
	if skill.range_value > 0:
		text += "[color=green]距离:[/color] %.1fm\n" % skill.range_value

	# 快捷键
	text += "\n[color=gray]按 %d 使用[/color]" % (slot_index + 1)

	return text
