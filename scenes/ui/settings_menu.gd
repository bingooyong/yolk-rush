extends Control
class_name SettingsMenu
## 设置菜单 - 音量、画质、控制设置

signal settings_changed(settings: Dictionary)
signal back_pressed()

# 设置数据
var current_settings: Dictionary = {
	"master_volume": 100,
	"music_volume": 80,
	"sfx_volume": 100,
	"graphics_quality": 1,  # 0=Low, 1=Medium, 2=High
	"vsync_enabled": true,
	"fullscreen": false
}

# UI 组件
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var quality_option: OptionButton
var vsync_check: CheckBox
var fullscreen_check: CheckBox
var back_button: Button
var apply_button: Button

const SETTINGS_FILE = "user://settings.json"

func _ready() -> void:
	_load_settings()
	_setup_ui()
	_connect_signals()
	_apply_current_settings()
	print("[SettingsMenu] Initialized")

func _setup_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# 主面板
	var panel = Panel.new()
	panel.name = "MainPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -250
	panel.offset_bottom = 250
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.4, 0.4, 0.4)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# 内容容器
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.position = Vector2(20, 20)
	main_vbox.size = Vector2(560, 460)
	main_vbox.add_theme_constant_override("separation", 15)
	panel.add_child(main_vbox)

	# 标题
	var title = Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	main_vbox.add_child(title)

	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var settings_vbox = VBoxContainer.new()
	settings_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(settings_vbox)

	# === 音频设置 ===
	var audio_section = _create_section_title("音频")
	settings_vbox.add_child(audio_section)

	# 主音量
	var master_container = _create_slider_setting("主音量", 0, 100, 1)
	master_slider = master_container.get_node("Slider")
	master_slider.value = current_settings.master_volume
	settings_vbox.add_child(master_container)

	# 音乐音量
	var music_container = _create_slider_setting("音乐音量", 0, 100, 1)
	music_slider = music_container.get_node("Slider")
	music_slider.value = current_settings.music_volume
	settings_vbox.add_child(music_container)

	# 音效音量
	var sfx_container = _create_slider_setting("音效音量", 0, 100, 1)
	sfx_slider = sfx_container.get_node("Slider")
	sfx_slider.value = current_settings.sfx_volume
	settings_vbox.add_child(sfx_container)

	# === 图形设置 ===
	var graphics_section = _create_section_title("图形")
	settings_vbox.add_child(graphics_section)

	# 画质
	var quality_container = _create_option_setting("画质", ["低", "中", "高"])
	quality_option = quality_container.get_node("Option")
	quality_option.selected = current_settings.graphics_quality
	settings_vbox.add_child(quality_container)

	# 垂直同步
	var vsync_container = _create_checkbox_setting("垂直同步 (VSync)")
	vsync_check = vsync_container.get_node("CheckBox")
	vsync_check.button_pressed = current_settings.vsync_enabled
	settings_vbox.add_child(vsync_container)

	# 全屏
	var fullscreen_container = _create_checkbox_setting("全屏")
	fullscreen_check = fullscreen_container.get_node("CheckBox")
	fullscreen_check.button_pressed = current_settings.fullscreen
	settings_vbox.add_child(fullscreen_container)

	# === 按钮区 ===
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(button_hbox)

	# 应用按钮
	apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.custom_minimum_size = Vector2(120, 40)
	_style_button(apply_button, Color(0.2, 0.8, 0.3))
	button_hbox.add_child(apply_button)

	# 返回按钮
	back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(120, 40)
	_style_button(back_button, Color(0.6, 0.6, 0.6))
	button_hbox.add_child(back_button)

func _create_section_title(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	return label

func _create_slider_setting(label_text: String, min_val: float, max_val: float, step: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.custom_minimum_size = Vector2(300, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(slider)

	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	container.add_child(value_label)

	slider.value_changed.connect(func(value):
		value_label.text = str(int(value))
	)
	value_label.text = str(int(slider.value))

	return container

func _create_option_setting(label_text: String, options: Array) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	var option = OptionButton.new()
	option.name = "Option"
	option.custom_minimum_size = Vector2(200, 0)
	for opt in options:
		option.add_item(opt)
	container.add_child(option)

	return container

func _create_checkbox_setting(label_text: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	var checkbox = CheckBox.new()
	checkbox.name = "CheckBox"
	container.add_child(checkbox)

	return container

func _style_button(button: Button, base_color: Color) -> void:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.content_margin_left = 15
	normal_style.content_margin_right = 15
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = base_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)

func _connect_signals() -> void:
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)

	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_apply_pressed() -> void:
	print("[SettingsMenu] Apply settings")
	_save_current_settings()
	_apply_current_settings()
	settings_changed.emit(current_settings)

func _on_back_pressed() -> void:
	print("[SettingsMenu] Back pressed")
	back_pressed.emit()

func _on_master_volume_changed(value: float) -> void:
	current_settings.master_volume = int(value)
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))

func _on_music_volume_changed(value: float) -> void:
	current_settings.music_volume = int(value)
	# TODO: 设置音乐总线音量

func _on_sfx_volume_changed(value: float) -> void:
	current_settings.sfx_volume = int(value)
	# TODO: 设置音效总线音量

func _save_current_settings() -> void:
	# 收集当前UI状态
	current_settings.master_volume = int(master_slider.value)
	current_settings.music_volume = int(music_slider.value)
	current_settings.sfx_volume = int(sfx_slider.value)
	current_settings.graphics_quality = quality_option.selected
	current_settings.vsync_enabled = vsync_check.button_pressed
	current_settings.fullscreen = fullscreen_check.button_pressed

	# 保存到文件
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_settings, "\t"))
		file.close()
		print("[SettingsMenu] Settings saved to: %s" % SETTINGS_FILE)
	else:
		push_error("[SettingsMenu] Failed to save settings")

func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()

			var json = JSON.new()
			var error = json.parse(json_string)

			if error == OK:
				var data = json.data
				if typeof(data) == TYPE_DICTIONARY:
					current_settings.merge(data, true)
					print("[SettingsMenu] Settings loaded from: %s" % SETTINGS_FILE)
			else:
				push_error("[SettingsMenu] Failed to parse settings JSON")
	else:
		print("[SettingsMenu] No settings file found, using defaults")

func _apply_current_settings() -> void:
	# 应用音频设置
	AudioServer.set_bus_volume_db(0, linear_to_db(current_settings.master_volume / 100.0))

	# 应用图形设置
	if current_settings.vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	if current_settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# 应用画质设置
	match current_settings.graphics_quality:
		0:  # Low
			_apply_low_graphics()
		1:  # Medium
			_apply_medium_graphics()
		2:  # High
			_apply_high_graphics()

	print("[SettingsMenu] Settings applied")

func _apply_low_graphics() -> void:
	# TODO: 设置低画质
	pass

func _apply_medium_graphics() -> void:
	# TODO: 设置中等画质
	pass

func _apply_high_graphics() -> void:
	# TODO: 设置高画质
	pass

## 显示设置菜单
func show_menu() -> void:
	visible = true

## 隐藏设置菜单
func hide_menu() -> void:
	visible = false
