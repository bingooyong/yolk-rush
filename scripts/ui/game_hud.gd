extends CanvasLayer
class_name GameHUD
## 游戏战斗 HUD - 视觉升级版
## 提供清晰的战斗信息显示

@onready var health_bar: ProgressBar
@onready var energy_bar: ProgressBar
@onready var shield_bar: ProgressBar
@onready var health_text: Label
@onready var energy_text: Label
@onready var health_icon: Label
@onready var energy_icon: Label

@onready var skill_q: Control
@onready var skill_e: Control
@onready var skill_r: Control
@onready var skill_f: Control

@onready var combo_label: Label
@onready var combo_timer: Timer

@onready var objective_list: VBoxContainer

var current_combo := 0

# 设计系统颜色
const COLOR_HEALTH = Color("#EF4444")        # 生命值红色
const COLOR_HEALTH_LOW = Color("#7F1D1D")    # 低血量深红
const COLOR_ENERGY = Color("#3B82F6")        # 能量蓝色
const COLOR_SHIELD = Color("#A78BFA")        # 护盾紫色
const COLOR_BG_DARK = Color("#1E2636")       # 深色背景
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#9CA3AF")

func _ready() -> void:
	_setup_hud_ui()
	if combo_timer:
		combo_timer.timeout.connect(_on_combo_timeout)
	print("[GameHUD] Initialized (Visual Upgrade)")

## 程序化创建HUD界面
func _setup_hud_ui() -> void:
	# 左上角 - 生命值和能量条
	_create_health_energy_panel()

	# 右下角 - 技能图标
	_create_skill_panel()

	# 中上 - 连击显示
	_create_combo_display()

	# 右上 - 目标列表
	_create_objective_panel()

## 创建生命值和能量面板
func _create_health_energy_panel() -> void:
	var panel = Panel.new()
	panel.name = "HealthEnergyPanel"
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(300, 100)
	add_child(panel)

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_DARK
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.2)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(12, 12)
	vbox.custom_minimum_size = Vector2(276, 76)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 生命值行
	var health_row = HBoxContainer.new()
	health_row.add_theme_constant_override("separation", 8)
	vbox.add_child(health_row)

	# 生命图标
	health_icon = Label.new()
	health_icon.text = "♥"
	health_icon.add_theme_font_size_override("font_size", 24)
	health_icon.add_theme_color_override("font_color", COLOR_HEALTH)
	health_row.add_child(health_icon)

	# 生命值条容器
	var health_container = VBoxContainer.new()
	health_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_container.add_theme_constant_override("separation", 2)
	health_row.add_child(health_container)

	# 生命值文本
	health_text = Label.new()
	health_text.text = "100 / 100"
	health_text.add_theme_font_size_override("font_size", 14)
	health_text.add_theme_color_override("font_color", COLOR_TEXT)
	health_container.add_child(health_text)

	# 生命值条
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(220, 16)
	health_bar.show_percentage = false
	_style_progress_bar(health_bar, COLOR_HEALTH, COLOR_HEALTH_LOW)
	health_container.add_child(health_bar)

	# 能量值行
	var energy_row = HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 8)
	vbox.add_child(energy_row)

	# 能量图标
	energy_icon = Label.new()
	energy_icon.text = "⚡"
	energy_icon.add_theme_font_size_override("font_size", 24)
	energy_icon.add_theme_color_override("font_color", COLOR_ENERGY)
	energy_row.add_child(energy_icon)

	# 能量值容器
	var energy_container = VBoxContainer.new()
	energy_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_container.add_theme_constant_override("separation", 2)
	energy_row.add_child(energy_container)

	# 能量值文本
	energy_text = Label.new()
	energy_text.text = "100 / 100"
	energy_text.add_theme_font_size_override("font_size", 14)
	energy_text.add_theme_color_override("font_color", COLOR_TEXT)
	energy_container.add_child(energy_text)

	# 能量值条
	energy_bar = ProgressBar.new()
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.value = 100
	energy_bar.custom_minimum_size = Vector2(220, 16)
	energy_bar.show_percentage = false
	_style_progress_bar(energy_bar, COLOR_ENERGY, Color("#1E3A8A"))
	energy_container.add_child(energy_bar)

## 样式化进度条
func _style_progress_bar(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	# 背景样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	# 填充样式
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

## 创建技能面板
func _create_skill_panel() -> void:
	var panel = Panel.new()
	panel.name = "SkillPanel"
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -280
	panel.offset_top = -96
	panel.offset_right = -16
	panel.offset_bottom = -16
	add_child(panel)

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_DARK
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.2)
	panel.add_theme_stylebox_override("panel", panel_style)

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(12, 12)
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	# 创建4个技能图标
	skill_q = _create_skill_icon("Q", Color("#3B82F6"))
	skill_e = _create_skill_icon("E", Color("#8B5CF6"))
	skill_r = _create_skill_icon("R", Color("#EF4444"))
	skill_f = _create_skill_icon("F", Color("#10B981"))

	hbox.add_child(skill_q)
	hbox.add_child(skill_e)
	hbox.add_child(skill_r)
	hbox.add_child(skill_f)

## 创建单个技能图标
func _create_skill_icon(key: String, color: Color) -> Control:
	var container = Control.new()
	container.name = "Skill" + key
	container.custom_minimum_size = Vector2(56, 56)

	# 背景
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = color.darkened(0.6)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = color
	bg.add_theme_stylebox_override("panel", bg_style)

	# 按键文本
	var label = Label.new()
	label.text = key
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	container.add_child(label)

	return container

## 创建连击显示
func _create_combo_display() -> void:
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = "x0 COMBO!"
	combo_label.visible = false
	combo_label.anchor_left = 0.5
	combo_label.anchor_right = 0.5
	combo_label.offset_left = -100
	combo_label.offset_right = 100
	combo_label.offset_top = 100
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 48)
	combo_label.add_theme_color_override("font_color", Color.WHITE)
	combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	combo_label.add_theme_constant_override("outline_size", 4)
	add_child(combo_label)

	combo_timer = Timer.new()
	combo_timer.name = "ComboTimer"
	combo_timer.one_shot = true
	add_child(combo_timer)

## 创建目标面板
func _create_objective_panel() -> void:
	var panel = Panel.new()
	panel.name = "ObjectivePanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -280
	panel.offset_top = 16
	panel.offset_right = -16
	panel.custom_minimum_size = Vector2(264, 100)
	add_child(panel)

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_DARK
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.2)
	panel.add_theme_stylebox_override("panel", panel_style)

	# 标题
	var title = Label.new()
	title.text = "目标"
	title.position = Vector2(12, 8)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(title)

	# 目标列表
	objective_list = VBoxContainer.new()
	objective_list.name = "ObjectiveList"
	objective_list.position = Vector2(12, 36)
	objective_list.custom_minimum_size = Vector2(240, 56)
	objective_list.add_theme_constant_override("separation", 4)
	panel.add_child(objective_list)

## 更新生命值显示
func update_health(current: float, max_value: float, shield: float = 0.0, max_shield: float = 0.0) -> void:
	if health_bar:
		health_bar.max_value = max_value

		# 平滑过渡
		var tween := create_tween()
		tween.tween_property(health_bar, "value", current, 0.2)

		# 低血量警告效果
		if current / max_value < 0.3:
			_flash_health_warning()

	if health_text:
		health_text.text = "%d / %d" % [int(current), int(max_value)]

	# 护盾显示（暂时未实现，预留接口）
	if shield > 0 and shield_bar:
		shield_bar.max_value = max_shield
		shield_bar.value = shield
		shield_bar.visible = true
	elif shield_bar:
		shield_bar.visible = false

## 更新能量显示
func update_energy(current: float, max_value: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_value

		var tween := create_tween()
		tween.tween_property(energy_bar, "value", current, 0.15)

	if energy_text:
		energy_text.text = "%d / %d" % [int(current), int(max_value)]

## 低血量警告闪烁
func _flash_health_warning() -> void:
	if not health_icon:
		return

	var tween := create_tween()
	tween.tween_property(health_icon, "modulate:a", 0.3, 0.3)
	tween.tween_property(health_icon, "modulate:a", 1.0, 0.3)

## 更新技能冷却
func update_skill_cooldown(skill_key: String, remaining: float, total: float) -> void:
	var skill_ui: Control = null
	match skill_key:
		"Q": skill_ui = skill_q
		"E": skill_ui = skill_e
		"R": skill_ui = skill_r
		"F": skill_ui = skill_f

	if not skill_ui:
		return

	# 冷却遮罩
	var cooldown_overlay := skill_ui.get_node_or_null("CooldownOverlay") as ColorRect
	if not cooldown_overlay:
		cooldown_overlay = ColorRect.new()
		cooldown_overlay.name = "CooldownOverlay"
		cooldown_overlay.color = Color(0, 0, 0, 0.7)
		cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_ui.add_child(cooldown_overlay)
		cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	if remaining > 0:
		var progress := 1.0 - (remaining / total)
		cooldown_overlay.visible = true
		# 从下往上收缩
		cooldown_overlay.anchor_top = progress
	else:
		cooldown_overlay.visible = false
		# 技能就绪时播放闪烁效果
		_skill_ready_flash(skill_ui)

## 技能就绪闪烁
func _skill_ready_flash(skill_ui: Control) -> void:
	var tween := create_tween()
	tween.tween_property(skill_ui, "modulate:a", 1.5, 0.2)
	tween.tween_property(skill_ui, "modulate:a", 1.0, 0.2)

## 添加目标到列表
func add_objective(id: String, description: String, current: int = 0, target: int = 0) -> void:
	if not objective_list:
		return

	var objective_item = HBoxContainer.new()
	objective_item.name = "Objective_" + id
	objective_item.add_theme_constant_override("separation", 8)

	# 复选框/进度
	var checkbox = Label.new()
	checkbox.text = "□"
	checkbox.add_theme_font_size_override("font_size", 16)
	checkbox.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	objective_item.add_child(checkbox)

	# 描述
	var desc_label = Label.new()
	desc_label.text = description
	if target > 0:
		desc_label.text += " (%d/%d)" % [current, target]
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_item.add_child(desc_label)

	objective_list.add_child(objective_item)

## 更新目标进度
func update_objective(id: String, current: int, target: int, completed: bool = false) -> void:
	if not objective_list:
		return

	var objective_item = objective_list.get_node_or_null("Objective_" + id)
	if not objective_item:
		return

	var checkbox = objective_item.get_child(0) as Label
	var desc_label = objective_item.get_child(1) as Label

	if completed:
		checkbox.text = "✓"
		checkbox.add_theme_color_override("font_color", Color("#10B981"))
		desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)

		# 完成动画
		var tween := create_tween()
		tween.tween_property(objective_item, "modulate", Color(0.5, 1.0, 0.5), 0.3)
		tween.tween_property(objective_item, "modulate", Color.WHITE, 0.3)
	else:
		# 更新进度文本
		var base_text = desc_label.text.split("(")[0].strip_edges()
		desc_label.text = base_text + " (%d/%d)" % [current, target]

## 移除目标
func remove_objective(id: String) -> void:
	if not objective_list:
		return

	var objective_item = objective_list.get_node_or_null("Objective_" + id)
	if objective_item:
		objective_item.queue_free()

## 增加连击数
func add_combo() -> void:
	current_combo += 1
	combo_label.text = "x%d COMBO!" % current_combo
	combo_label.visible = true

	# 重置计时器
	combo_timer.start(2.0)

	# 动画效果
	var tween := create_tween()
	tween.set_parallel(true)
	combo_label.scale = Vector2.ONE * 1.5
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

	# 颜色变化
	if current_combo >= 10:
		combo_label.add_theme_color_override("font_color", Color.GOLD)
	elif current_combo >= 5:
		combo_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		combo_label.add_theme_color_override("font_color", Color.WHITE)

## 重置连击
func reset_combo() -> void:
	current_combo = 0
	combo_label.visible = false

func _on_combo_timeout() -> void:
	reset_combo()

## 显示伤害飘字
func show_damage_number(amount: float, position: Vector2, is_crit: bool = false) -> void:
	var damage_label := Label.new()
	damage_label.text = "-%d" % int(amount)
	damage_label.add_theme_font_size_override("font_size", 24 if not is_crit else 36)

	if is_crit:
		damage_label.text = "CRIT! " + damage_label.text
		damage_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		damage_label.add_theme_color_override("font_color", Color.RED)

	# 添加描边
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.add_theme_constant_override("outline_size", 2)

	add_child(damage_label)
	damage_label.global_position = position

	# 飘字动画
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "global_position:y", position.y - 50, 0.8)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	await tween.finished
	damage_label.queue_free()

## 显示治疗飘字
func show_heal_number(amount: float, position: Vector2) -> void:
	var heal_label := Label.new()
	heal_label.text = "+%d" % int(amount)
	heal_label.add_theme_font_size_override("font_size", 24)
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.add_theme_color_override("font_outline_color", Color.BLACK)
	heal_label.add_theme_constant_override("outline_size", 2)

	add_child(heal_label)
	heal_label.global_position = position

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_label, "global_position:y", position.y - 50, 0.8)
	tween.tween_property(heal_label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	await tween.finished
	heal_label.queue_free()

