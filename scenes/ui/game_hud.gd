extends CanvasLayer
class_name GameHUD
## 游戏内 HUD - 玩家状态、技能栏、小地图等

signal skill_activated(slot: int)
signal item_used(slot: int)
signal pause_requested()

# UI 组件引用
var player_status: Control
var skill_bar: Control
var minimap: Control
var objective_panel: Control

# 玩家数据
var player_health: float = 100.0
var player_max_health: float = 100.0
var player_energy: float = 100.0
var player_max_energy: float = 100.0
var player_level: int = 1
var player_exp: float = 0.0
var player_exp_to_next: float = 100.0

# 技能数据
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var skill_slots: int = 4

func _ready() -> void:
	_setup_ui()
	_connect_input()
	print("[GameHUD] Initialized")

func _setup_ui() -> void:
	# 主容器
	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)

	# 玩家状态区（左上角）
	player_status = _create_player_status()
	main_container.add_child(player_status)

	# 技能栏（底部居中）
	skill_bar = _create_skill_bar()
	main_container.add_child(skill_bar)

	# 小地图（右上角）
	minimap = _create_minimap()
	main_container.add_child(minimap)

	# 目标面板（右侧）
	objective_panel = _create_objective_panel()
	main_container.add_child(objective_panel)

func _create_player_status() -> Control:
	var container = Control.new()
	container.name = "PlayerStatus"
	container.position = Vector2(20, 20)
	container.custom_minimum_size = Vector2(300, 120)

	# 背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bg)

	# 内容容器
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 100)
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	# 等级显示
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Level 1"
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(level_label)

	# 生命值条
	var health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 2)
	vbox.add_child(health_container)

	var health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: 100 / 100"
	health_label.add_theme_font_size_override("font_size", 14)
	health_container.add_child(health_label)

	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(260, 20)
	health_bar.value = 100
	health_bar.show_percentage = false
	_style_progress_bar(health_bar, Color(0.8, 0.2, 0.2))
	health_container.add_child(health_bar)

	# 能量值条
	var energy_container = VBoxContainer.new()
	energy_container.add_theme_constant_override("separation", 2)
	vbox.add_child(energy_container)

	var energy_label = Label.new()
	energy_label.name = "EnergyLabel"
	energy_label.text = "Energy: 100 / 100"
	energy_label.add_theme_font_size_override("font_size", 14)
	energy_container.add_child(energy_label)

	var energy_bar = ProgressBar.new()
	energy_bar.name = "EnergyBar"
	energy_bar.custom_minimum_size = Vector2(260, 20)
	energy_bar.value = 100
	energy_bar.show_percentage = false
	_style_progress_bar(energy_bar, Color(0.2, 0.6, 0.9))
	energy_container.add_child(energy_bar)

	# 经验值条
	var exp_bar = ProgressBar.new()
	exp_bar.name = "ExpBar"
	exp_bar.custom_minimum_size = Vector2(260, 8)
	exp_bar.value = 0
	exp_bar.show_percentage = false
	_style_progress_bar(exp_bar, Color(0.3, 0.8, 0.3))
	vbox.add_child(exp_bar)

	return container

func _create_skill_bar() -> Control:
	var container = Control.new()
	container.name = "SkillBar"
	container.anchor_left = 0.5
	container.anchor_top = 1.0
	container.anchor_right = 0.5
	container.anchor_bottom = 1.0
	container.offset_left = -200
	container.offset_right = 200
	container.offset_top = -100
	container.offset_bottom = -20
	container.custom_minimum_size = Vector2(400, 80)

	# 背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bg)

	# 技能槽容器
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(10, 10)
	hbox.size = Vector2(380, 60)
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)

	# 创建技能槽
	for i in skill_slots:
		var skill_slot = _create_skill_slot(i)
		hbox.add_child(skill_slot)

	return container

func _create_skill_slot(slot_index: int) -> Control:
	var slot = Control.new()
	slot.name = "SkillSlot%d" % slot_index
	slot.custom_minimum_size = Vector2(60, 60)

	# 背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.4)
	bg.add_theme_stylebox_override("panel", bg_style)
	slot.add_child(bg)

	# 快捷键提示
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = str(slot_index + 1)
	key_label.position = Vector2(5, 5)
	key_label.add_theme_font_size_override("font_size", 12)
	key_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	slot.add_child(key_label)

	# 冷却遮罩
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0, 0, 0, 0.6)
	cooldown_overlay.anchor_right = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.visible = false
	slot.add_child(cooldown_overlay)

	# 冷却文字
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.anchor_left = 0.5
	cooldown_label.anchor_top = 0.5
	cooldown_label.anchor_right = 0.5
	cooldown_label.anchor_bottom = 0.5
	cooldown_label.offset_left = -15
	cooldown_label.offset_top = -10
	cooldown_label.offset_right = 15
	cooldown_label.offset_bottom = 10
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 18)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	cooldown_label.visible = false
	slot.add_child(cooldown_label)

	return slot

func _create_minimap() -> Control:
	var container = Control.new()
	container.name = "Minimap"
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.position = Vector2(-220, 20)
	container.custom_minimum_size = Vector2(200, 200)

	# 背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "地图"
	title.position = Vector2(10, 5)
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)

	# 地图内容区
	var map_area = ColorRect.new()
	map_area.name = "MapArea"
	map_area.color = Color(0.15, 0.15, 0.15)
	map_area.position = Vector2(10, 30)
	map_area.size = Vector2(180, 160)
	container.add_child(map_area)

	# 玩家标记（中心）
	var player_marker = ColorRect.new()
	player_marker.name = "PlayerMarker"
	player_marker.color = Color(0.2, 0.8, 0.3)
	player_marker.position = Vector2(85, 75)
	player_marker.size = Vector2(10, 10)
	map_area.add_child(player_marker)

	return container

func _create_objective_panel() -> Control:
	var container = Control.new()
	container.name = "ObjectivePanel"
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.position = Vector2(-220, 240)
	container.custom_minimum_size = Vector2(200, 150)

	# 背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "任务目标"
	title.position = Vector2(10, 5)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	container.add_child(title)

	# 目标列表
	var objective_list = VBoxContainer.new()
	objective_list.name = "ObjectiveList"
	objective_list.position = Vector2(10, 30)
	objective_list.size = Vector2(180, 110)
	objective_list.add_theme_constant_override("separation", 5)
	container.add_child(objective_list)

	# 默认目标
	var obj1 = Label.new()
	obj1.text = "□ 探索地图"
	obj1.add_theme_font_size_override("font_size", 12)
	objective_list.add_child(obj1)

	var obj2 = Label.new()
	obj2.text = "□ 击败敌人 (0/10)"
	obj2.add_theme_font_size_override("font_size", 12)
	objective_list.add_child(obj2)

	return container

func _style_progress_bar(bar: ProgressBar, color: Color) -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

func _connect_input() -> void:
	# 技能快捷键 1-4
	for i in skill_slots:
		pass  # 在 _input 中处理

func _input(event: InputEvent) -> void:
	# ESC 暂停
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()

	# 技能快捷键
	for i in skill_slots:
		var action_name = "skill_%d" % (i + 1)
		if event.is_action_pressed(action_name):
			_activate_skill(i)
			get_viewport().set_input_as_handled()

func _activate_skill(slot: int) -> void:
	if skill_cooldowns[slot] > 0:
		print("[GameHUD] Skill %d on cooldown: %.1fs" % [slot, skill_cooldowns[slot]])
		return

	print("[GameHUD] Activated skill slot: %d" % slot)
	skill_activated.emit(slot)

## 更新玩家生命值
func update_player_health(current: float, maximum: float) -> void:
	player_health = current
	player_max_health = maximum

	var health_bar = player_status.find_child("HealthBar", true, false)
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

	var health_label = player_status.find_child("HealthLabel", true, false)
	if health_label:
		health_label.text = "HP: %d / %d" % [int(current), int(maximum)]

## 更新玩家能量
func update_player_energy(current: float, maximum: float) -> void:
	player_energy = current
	player_max_energy = maximum

	var energy_bar = player_status.find_child("EnergyBar", true, false)
	if energy_bar:
		energy_bar.max_value = maximum
		energy_bar.value = current

	var energy_label = player_status.find_child("EnergyLabel", true, false)
	if energy_label:
		energy_label.text = "Energy: %d / %d" % [int(current), int(maximum)]

## 更新玩家等级和经验
func update_player_level(level: int, exp: float, exp_to_next: float) -> void:
	player_level = level
	player_exp = exp
	player_exp_to_next = exp_to_next

	var level_label = player_status.find_child("LevelLabel", true, false)
	if level_label:
		level_label.text = "Level %d" % level

	var exp_bar = player_status.find_child("ExpBar", true, false)
	if exp_bar:
		exp_bar.max_value = exp_to_next
		exp_bar.value = exp

## 设置技能冷却
func set_skill_cooldown(slot: int, cooldown: float) -> void:
	if slot < 0 or slot >= skill_slots:
		return

	skill_cooldowns[slot] = cooldown

	var skill_slot = skill_bar.find_child("SkillSlot%d" % slot, true, false)
	if skill_slot:
		var overlay = skill_slot.find_child("CooldownOverlay", true, false)
		var label = skill_slot.find_child("CooldownLabel", true, false)

		if cooldown > 0:
			overlay.visible = true
			label.visible = true
			label.text = "%.1f" % cooldown
		else:
			overlay.visible = false
			label.visible = false

func _process(delta: float) -> void:
	# 更新技能冷却
	for i in skill_slots:
		if skill_cooldowns[i] > 0:
			skill_cooldowns[i] -= delta
			if skill_cooldowns[i] < 0:
				skill_cooldowns[i] = 0

			set_skill_cooldown(i, skill_cooldowns[i])

## 添加目标
func add_objective(text: String) -> void:
	var objective_list = objective_panel.find_child("ObjectiveList", true, false)
	if objective_list:
		var obj_label = Label.new()
		obj_label.text = "□ " + text
		obj_label.add_theme_font_size_override("font_size", 12)
		objective_list.add_child(obj_label)

## 完成目标
func complete_objective(index: int) -> void:
	var objective_list = objective_panel.find_child("ObjectiveList", true, false)
	if objective_list and index < objective_list.get_child_count():
		var obj_label = objective_list.get_child(index) as Label
		if obj_label:
			obj_label.text = obj_label.text.replace("□", "☑")
			obj_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))

## 显示 HUD
func show_hud() -> void:
	visible = true

## 隐藏 HUD
func hide_hud() -> void:
	visible = false
