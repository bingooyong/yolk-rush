extends Control
class_name SaveLoadUI
## 保存/加载UI
## 提供存档管理界面

## 信号
signal save_selected(slot_id: int)
signal load_selected(slot_id: int)
signal delete_requested(slot_id: int)
signal back_pressed()

## UI模式
enum UIMode {
	SAVE,    ## 保存模式
	LOAD     ## 加载模式
}

## 当前模式
var current_mode: UIMode = UIMode.LOAD

## SaveManager引用
var save_manager: Node = null

## UI组件
var title_label: Label = null
var slots_container: VBoxContainer = null
var back_button: Button = null
var slot_buttons: Array[Button] = []

## 存档槽数据
var slots_data: Array[Dictionary] = []

func _ready() -> void:
	# 查找SaveManager
	save_manager = _find_save_manager()

	if not save_manager:
		push_warning("[SaveLoadUI] SaveManager not found")

	# 创建UI
	_create_ui()

	# 刷新存档列表
	refresh_slots()

## 查找SaveManager
func _find_save_manager() -> Node:
	if has_node("/root/SaveManager"):
		return get_node("/root/SaveManager")

	var tree = get_tree()
	if tree and tree.root:
		return tree.root.find_child("SaveManager", true, false)

	return null

## 创建UI
func _create_ui() -> void:
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)

	# 标题
	title_label = Label.new()
	title_label.text = "加载游戏"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	main_container.add_child(title_label)

	# 存档槽容器
	slots_container = VBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 10)
	main_container.add_child(slots_container)

	# 返回按钮
	back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.pressed.connect(_on_back_pressed)
	main_container.add_child(back_button)

## 设置UI模式
func set_mode(mode: UIMode) -> void:
	current_mode = mode

	match mode:
		UIMode.SAVE:
			title_label.text = "保存游戏"
		UIMode.LOAD:
			title_label.text = "加载游戏"

	refresh_slots()

## 刷新存档槽
func refresh_slots() -> void:
	if not save_manager:
		return

	# 清空现有按钮
	for button in slot_buttons:
		button.queue_free()
	slot_buttons.clear()

	# 获取存档信息
	slots_data = save_manager.get_all_saves_info()

	# 创建存档槽按钮
	for i in range(slots_data.size()):
		var slot_data = slots_data[i]
		var slot_button = _create_slot_button(slot_data)
		slots_container.add_child(slot_button)
		slot_buttons.append(slot_button)

## 创建存档槽按钮
func _create_slot_button(slot_data: Dictionary) -> Button:
	var slot_id = slot_data.get("slot_id", 0)
	var exists = slot_data.get("exists", false)
	var metadata = slot_data.get("metadata", {})

	var button = Button.new()
	button.custom_minimum_size = Vector2(600, 100)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# 构建按钮文本
	var button_text = "存档槽 %d\n" % (slot_id + 1)

	if exists:
		# 显示存档信息
		var timestamp = metadata.get("timestamp", 0)
		var play_time = metadata.get("play_time", 0.0)
		var level_progress = metadata.get("level_progress", "0/0")

		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		var time_str = "%04d-%02d-%02d %02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]

		var play_time_str = _format_time(play_time)

		button_text += "时间: %s\n" % time_str
		button_text += "游戏时长: %s\n" % play_time_str
		button_text += "关卡进度: %s" % level_progress
	else:
		button_text += "空存档"

	button.text = button_text

	# 连接信号
	button.pressed.connect(_on_slot_pressed.bind(slot_id))

	# 添加右键菜单（删除选项）
	if exists:
		button.mouse_filter = Control.MOUSE_FILTER_PASS

	return button

## 格式化时间
func _format_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60

	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%02d:%02d" % [minutes, secs]

## 存档槽被点击
func _on_slot_pressed(slot_id: int) -> void:
	var slot_data = slots_data[slot_id]
	var exists = slot_data.get("exists", false)

	match current_mode:
		UIMode.SAVE:
			# 保存模式：总是可以保存
			if exists:
				# 确认覆盖
				_show_overwrite_confirmation(slot_id)
			else:
				# 直接保存
				save_selected.emit(slot_id)

		UIMode.LOAD:
			# 加载模式：只能加载存在的存档
			if exists:
				load_selected.emit(slot_id)
			else:
				print("[SaveLoadUI] Cannot load empty slot")

## 显示覆盖确认对话框
func _show_overwrite_confirmation(slot_id: int) -> void:
	# 简化版：直接触发保存
	# TODO: 添加确认对话框
	save_selected.emit(slot_id)

## 返回按钮被点击
func _on_back_pressed() -> void:
	back_pressed.emit()

## 显示菜单
func show_menu() -> void:
	visible = true
	refresh_slots()

## 隐藏菜单
func hide_menu() -> void:
	visible = false
