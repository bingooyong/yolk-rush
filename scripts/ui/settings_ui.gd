extends Control
class_name SettingsUI
## 设置界面
## 提供音效、画质、控制等设置选项

## 信号
signal settings_changed(settings: Dictionary)
signal ui_closed()

## 节点引用
var tab_container: TabContainer
var apply_button: Button
var cancel_button: Button
var reset_button: Button

## 音频设置节点
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var sfx_volume_slider: HSlider
var audio_enable_checkbox: CheckBox

## 画质设置节点
var quality_preset_option: OptionButton
var vsync_checkbox: CheckBox
var fps_limit_option: OptionButton
var particle_quality_option: OptionButton

## 控制设置节点
var sensitivity_slider: HSlider
var invert_y_checkbox: CheckBox
var vibration_checkbox: CheckBox

## 游戏设置节点
var language_option: OptionButton
var show_fps_checkbox: CheckBox
var tutorial_enable_checkbox: CheckBox

## 当前设置
var current_settings: Dictionary = {}

## 默认设置
const DEFAULT_SETTINGS = {
	# 音频
	"master_volume": 80.0,
	"music_volume": 70.0,
	"sfx_volume": 80.0,
	"audio_enabled": true,

	# 画质
	"quality_preset": 1,  # 0=低, 1=中, 2=高
	"vsync_enabled": true,
	"fps_limit": 60,  # 30, 60, 120, 无限制
	"particle_quality": 1,  # 0=低, 1=中, 2=高

	# 控制
	"camera_sensitivity": 50.0,
	"invert_y_axis": false,
	"vibration_enabled": true,

	# 游戏
	"language": "zh_CN",
	"show_fps": false,
	"tutorial_enabled": true
}

func _ready() -> void:
	# 创建基础UI结构
	_create_base_ui()

	# 加载当前设置
	_load_settings()

	# 创建UI
	_create_ui()

	# 连接信号
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)

	# 应用当前设置到UI
	_apply_settings_to_ui()

## 创建基础UI结构
func _create_base_ui() -> void:
	# 创建主面板
	var panel = Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(800, 600)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400
	panel.offset_top = -300
	panel.offset_right = 400
	panel.offset_bottom = 300
	add_child(panel)

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# TabContainer
	tab_container = TabContainer.new()
	tab_container.name = "TabContainer"
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_container)

	# 底部按钮栏
	var bottom_bar = HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 20)
	vbox.add_child(bottom_bar)

	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "重置"
	bottom_bar.add_child(reset_button)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "取消"
	bottom_bar.add_child(cancel_button)

	apply_button = Button.new()
	apply_button.name = "ApplyButton"
	apply_button.text = "应用"
	bottom_bar.add_child(apply_button)

## 创建UI
func _create_ui() -> void:
	if not tab_container:
		return

	# 清空现有标签
	for child in tab_container.get_children():
		child.queue_free()

	# 创建音频标签页
	_create_audio_tab()

	# 创建画质标签页
	_create_graphics_tab()

	# 创建控制标签页
	_create_controls_tab()

	# 创建游戏标签页
	_create_game_tab()

## 创建音频标签页
func _create_audio_tab() -> void:
	var tab = ScrollContainer.new()
	tab.name = "音频"
	tab_container.add_child(tab)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	tab.add_child(vbox)

	# 音频开关
	audio_enable_checkbox = _create_checkbox("启用音频", vbox)

	# 主音量
	_create_volume_slider("主音量", "master_volume_slider", vbox)
	if vbox.has_node("MasterVolumeSliderContainer/Slider"):
		master_volume_slider = vbox.get_node("MasterVolumeSliderContainer/Slider")

	# 音乐音量
	_create_volume_slider("音乐音量", "music_volume_slider", vbox)
	if vbox.has_node("MusicVolumeSliderContainer/Slider"):
		music_volume_slider = vbox.get_node("MusicVolumeSliderContainer/Slider")

	# 音效音量
	_create_volume_slider("音效音量", "sfx_volume_slider", vbox)
	if vbox.has_node("SfxVolumeSliderContainer/Slider"):
		sfx_volume_slider = vbox.get_node("SfxVolumeSliderContainer/Slider")

## 创建画质标签页
func _create_graphics_tab() -> void:
	var tab = ScrollContainer.new()
	tab.name = "画质"
	tab_container.add_child(tab)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	tab.add_child(vbox)

	# 画质预设
	quality_preset_option = _create_option("画质预设", ["低", "中", "高"], vbox)

	# 垂直同步
	vsync_checkbox = _create_checkbox("垂直同步", vbox)

	# 帧率限制
	fps_limit_option = _create_option("帧率限制", ["30 FPS", "60 FPS", "120 FPS", "无限制"], vbox)

	# 粒子质量
	particle_quality_option = _create_option("粒子质量", ["低", "中", "高"], vbox)

## 创建控制标签页
func _create_controls_tab() -> void:
	var tab = ScrollContainer.new()
	tab.name = "控制"
	tab_container.add_child(tab)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	tab.add_child(vbox)

	# 镜头灵敏度
	_create_slider("镜头灵敏度", "sensitivity_slider", 0, 100, vbox)
	if vbox.has_node("SensitivitySliderContainer/Slider"):
		sensitivity_slider = vbox.get_node("SensitivitySliderContainer/Slider")

	# 反转Y轴
	invert_y_checkbox = _create_checkbox("反转Y轴", vbox)

	# 振动反馈
	vibration_checkbox = _create_checkbox("振动反馈", vbox)

## 创建游戏标签页
func _create_game_tab() -> void:
	var tab = ScrollContainer.new()
	tab.name = "游戏"
	tab_container.add_child(tab)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	tab.add_child(vbox)

	# 语言
	language_option = _create_option("语言", ["简体中文", "English", "日本語"], vbox)

	# 显示FPS
	show_fps_checkbox = _create_checkbox("显示FPS", vbox)

	# 启用教学
	tutorial_enable_checkbox = _create_checkbox("启用新手教学", vbox)

## 辅助函数：创建滑块
func _create_volume_slider(label_text: String, slider_name: String, parent: VBoxContainer) -> void:
	var container = VBoxContainer.new()
	container.name = slider_name.capitalize().replace(" ", "") + "Container"
	parent.add_child(container)

	var label = Label.new()
	label.text = label_text
	container.add_child(label)

	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)

	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size.x = 50
	hbox.add_child(value_label)

	slider.value_changed.connect(func(value): value_label.text = "%d%%" % value)

func _create_slider(label_text: String, slider_name: String, min_val: float, max_val: float, parent: VBoxContainer) -> void:
	_create_volume_slider(label_text, slider_name, parent)

## 辅助函数：创建复选框
func _create_checkbox(label_text: String, parent: VBoxContainer) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.text = label_text
	parent.add_child(checkbox)
	return checkbox

## 辅助函数：创建下拉框
func _create_option(label_text: String, options: Array, parent: VBoxContainer) -> OptionButton:
	var container = VBoxContainer.new()
	parent.add_child(container)

	var label = Label.new()
	label.text = label_text
	container.add_child(label)

	var option_button = OptionButton.new()
	for option in options:
		option_button.add_item(option)
	container.add_child(option_button)

	return option_button

## 加载设置
func _load_settings() -> void:
	# 从SettingsManager加载
	var settings_manager = _find_settings_manager()
	if settings_manager and settings_manager.has_method("get_all_settings"):
		current_settings = settings_manager.get_all_settings()
	else:
		# 使用默认设置
		current_settings = DEFAULT_SETTINGS.duplicate()

## 应用设置到UI
func _apply_settings_to_ui() -> void:
	if not is_node_ready():
		return

	# 音频
	if audio_enable_checkbox:
		audio_enable_checkbox.button_pressed = current_settings.get("audio_enabled", true)
	if master_volume_slider:
		master_volume_slider.value = current_settings.get("master_volume", 80.0)
	if music_volume_slider:
		music_volume_slider.value = current_settings.get("music_volume", 70.0)
	if sfx_volume_slider:
		sfx_volume_slider.value = current_settings.get("sfx_volume", 80.0)

	# 画质
	if quality_preset_option:
		quality_preset_option.selected = current_settings.get("quality_preset", 1)
	if vsync_checkbox:
		vsync_checkbox.button_pressed = current_settings.get("vsync_enabled", true)
	if fps_limit_option:
		var fps = current_settings.get("fps_limit", 60)
		fps_limit_option.selected = _fps_to_index(fps)
	if particle_quality_option:
		particle_quality_option.selected = current_settings.get("particle_quality", 1)

	# 控制
	if sensitivity_slider:
		sensitivity_slider.value = current_settings.get("camera_sensitivity", 50.0)
	if invert_y_checkbox:
		invert_y_checkbox.button_pressed = current_settings.get("invert_y_axis", false)
	if vibration_checkbox:
		vibration_checkbox.button_pressed = current_settings.get("vibration_enabled", true)

	# 游戏
	if language_option:
		language_option.selected = _language_to_index(current_settings.get("language", "zh_CN"))
	if show_fps_checkbox:
		show_fps_checkbox.button_pressed = current_settings.get("show_fps", false)
	if tutorial_enable_checkbox:
		tutorial_enable_checkbox.button_pressed = current_settings.get("tutorial_enabled", true)

## 从UI收集设置
func _collect_settings_from_ui() -> Dictionary:
	var settings = {}

	# 音频
	if audio_enable_checkbox:
		settings["audio_enabled"] = audio_enable_checkbox.button_pressed
	if master_volume_slider:
		settings["master_volume"] = master_volume_slider.value
	if music_volume_slider:
		settings["music_volume"] = music_volume_slider.value
	if sfx_volume_slider:
		settings["sfx_volume"] = sfx_volume_slider.value

	# 画质
	if quality_preset_option:
		settings["quality_preset"] = quality_preset_option.selected
	if vsync_checkbox:
		settings["vsync_enabled"] = vsync_checkbox.button_pressed
	if fps_limit_option:
		settings["fps_limit"] = _index_to_fps(fps_limit_option.selected)
	if particle_quality_option:
		settings["particle_quality"] = particle_quality_option.selected

	# 控制
	if sensitivity_slider:
		settings["camera_sensitivity"] = sensitivity_slider.value
	if invert_y_checkbox:
		settings["invert_y_axis"] = invert_y_checkbox.button_pressed
	if vibration_checkbox:
		settings["vibration_enabled"] = vibration_checkbox.button_pressed

	# 游戏
	if language_option:
		settings["language"] = _index_to_language(language_option.selected)
	if show_fps_checkbox:
		settings["show_fps"] = show_fps_checkbox.button_pressed
	if tutorial_enable_checkbox:
		settings["tutorial_enabled"] = tutorial_enable_checkbox.button_pressed

	return settings

## 应用按钮
func _on_apply_pressed() -> void:
	# 收集设置
	var new_settings = _collect_settings_from_ui()

	# 保存设置
	var settings_manager = _find_settings_manager()
	if settings_manager and settings_manager.has_method("apply_settings"):
		settings_manager.apply_settings(new_settings)

	current_settings = new_settings
	settings_changed.emit(new_settings)

	# 关闭界面
	_on_close()

## 取消按钮
func _on_cancel_pressed() -> void:
	# 恢复原设置到UI
	_apply_settings_to_ui()
	_on_close()

## 重置按钮
func _on_reset_pressed() -> void:
	current_settings = DEFAULT_SETTINGS.duplicate()
	_apply_settings_to_ui()

## 关闭界面
func _on_close() -> void:
	ui_closed.emit()
	hide()

## 辅助函数
func _fps_to_index(fps: int) -> int:
	match fps:
		30: return 0
		60: return 1
		120: return 2
		_: return 3

func _index_to_fps(index: int) -> int:
	match index:
		0: return 30
		1: return 60
		2: return 120
		_: return 0  # 无限制

func _language_to_index(lang: String) -> int:
	match lang:
		"zh_CN": return 0
		"en_US": return 1
		"ja_JP": return 2
		_: return 0

func _index_to_language(index: int) -> String:
	match index:
		0: return "zh_CN"
		1: return "en_US"
		2: return "ja_JP"
		_: return "zh_CN"

## 查找设置管理器
func _find_settings_manager() -> Node:
	if has_node("/root/SettingsManager"):
		return get_node("/root/SettingsManager")

	var tree = get_tree()
	if tree and tree.root:
		return tree.root.find_child("SettingsManager", true, false)

	return null

## 显示UI
func show_ui() -> void:
	show()
	_apply_settings_to_ui()
