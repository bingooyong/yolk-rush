extends Control
class_name SaveSlotsUI
## 存档槽选择界面

signal slot_selected(slot_id: int, action: String)  # action: "save", "load", "delete"
signal back_pressed()

## 节点引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var slots_container: VBoxContainer = $VBoxContainer/ScrollContainer/SlotsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

## 模式
enum Mode {
	SAVE,    # 保存模式
	LOAD     # 加载模式
}

var current_mode: Mode = Mode.LOAD

## SaveManager引用
var save_manager: Node = null

## 存档槽按钮
var slot_buttons: Array[Panel] = []

func _ready() -> void:
	print("[SaveSlotsUI] Initializing...")

	# 查找SaveManager
	_find_save_manager()

	# 如果节点不存在，创建它们
	if not has_node("VBoxContainer"):
		_create_ui()

	# 连接信号
	_connect_signals()

	print("[SaveSlotsUI] Initialized")

## 查找SaveManager
func _find_save_manager() -> void:
	var root = get_tree().root
	if root:
		save_manager = root.find_child("SaveManager", true, false)

## 创建UI
func _create_ui() -> void:
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "VBoxContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 100
	main_container.offset_right = -100
	main_container.offset_top = 50
	main_container.offset_bottom = -50
	add_child(main_container)

	# 标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "选择存档"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	main_container.add_child(title_label)

	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	main_container.add_child(spacer1)

	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)

	# 存档槽容器
	slots_container = VBoxContainer.new()
	slots_container.name = "SlotsContainer"
	slots_container.add_theme_constant_override("separation", 20)
	scroll.add_child(slots_container)

	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	main_container.add_child(spacer2)

	# 返回按钮
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 24)
	main_container.add_child(back_button)

## 连接信号
func _connect_signals() -> void:
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

## 显示界面
func show_menu(mode: Mode = Mode.LOAD) -> void:
	current_mode = mode
	visible = true

	# 更新标题
	if title_label:
		match mode:
			Mode.SAVE:
				title_label.text = "保存游戏"
			Mode.LOAD:
				title_label.text = "加载游戏"

	# 刷新存档槽
	_refresh_slots()

## 隐藏界面
func hide_menu() -> void:
	visible = false

## 刷新存档槽
func _refresh_slots() -> void:
	# 清空现有槽位
	for button in slot_buttons:
		button.queue_free()
	slot_buttons.clear()

	if not save_manager:
		print("[SaveSlotsUI] SaveManager not found")
		return

	# 获取所有存档信息
	var saves_info = save_manager.get_all_saves_info()

	# 为每个槽位创建按钮
	for save_info in saves_info:
		var slot_panel = _create_slot_panel(save_info)
		slots_container.add_child(slot_panel)
		slot_buttons.append(slot_panel)

## 创建存档槽面板
func _create_slot_panel(save_info: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(800, 120)

	# 容器
	var hbox = HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 20
	hbox.offset_right = -20
	hbox.offset_top = 20
	hbox.offset_bottom = -20
	panel.add_child(hbox)

	var slot_id = save_info["slot_id"]
	var exists = save_info["exists"]
	var metadata = save_info.get("metadata", {})

	# 左侧：存档信息
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_container)

	# 存档槽标题
	var slot_label = Label.new()
	slot_label.text = "存档槽 %d" % (slot_id + 1)
	slot_label.add_theme_font_size_override("font_size", 28)
	slot_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	info_container.add_child(slot_label)

	if exists:
		# 存档时间
		var timestamp = metadata.get("timestamp", 0)
		var datetime = Time.get_datetime_dict_from_unix_time(int(timestamp))
		var time_label = Label.new()
		time_label.text = "保存时间: %04d-%02d-%02d %02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]
		time_label.add_theme_font_size_override("font_size", 16)
		info_container.add_child(time_label)

		# 游戏进度
		var progress_label = Label.new()
		progress_label.text = "进度: %s" % metadata.get("level_progress", "0/0")
		progress_label.add_theme_font_size_override("font_size", 16)
		info_container.add_child(progress_label)

		# 游戏时间
		var play_time = metadata.get("play_time", 0.0)
		var hours = int(play_time) / 3600
		var minutes = (int(play_time) % 3600) / 60
		var playtime_label = Label.new()
		playtime_label.text = "游戏时间: %dh %dm" % [hours, minutes]
		playtime_label.add_theme_font_size_override("font_size", 16)
		info_container.add_child(playtime_label)
	else:
		# 空槽
		var empty_label = Label.new()
		empty_label.text = "空存档"
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info_container.add_child(empty_label)

	# 右侧：操作按钮
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	hbox.add_child(button_container)

	match current_mode:
		Mode.SAVE:
			# 保存模式：显示保存按钮
			var save_button = Button.new()
			save_button.text = "保存" if exists else "新建"
			save_button.custom_minimum_size = Vector2(120, 40)
			button_container.add_child(save_button)
			save_button.pressed.connect(func(): _on_slot_action(slot_id, "save"))

			# 如果存档存在，显示删除按钮
			if exists:
				var delete_button = Button.new()
				delete_button.text = "删除"
				delete_button.custom_minimum_size = Vector2(120, 40)
				delete_button.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				button_container.add_child(delete_button)
				delete_button.pressed.connect(func(): _on_slot_action(slot_id, "delete"))

		Mode.LOAD:
			# 加载模式：只显示有存档的槽位的加载按钮
			if exists:
				var load_button = Button.new()
				load_button.text = "加载"
				load_button.custom_minimum_size = Vector2(120, 40)
				button_container.add_child(load_button)
				load_button.pressed.connect(func(): _on_slot_action(slot_id, "load"))

				var delete_button = Button.new()
				delete_button.text = "删除"
				delete_button.custom_minimum_size = Vector2(120, 40)
				delete_button.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				button_container.add_child(delete_button)
				delete_button.pressed.connect(func(): _on_slot_action(slot_id, "delete"))
			else:
				var disabled_label = Label.new()
				disabled_label.text = "无存档"
				disabled_label.add_theme_font_size_override("font_size", 16)
				disabled_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				button_container.add_child(disabled_label)

	return panel

## 存档槽操作
func _on_slot_action(slot_id: int, action: String) -> void:
	print("[SaveSlotsUI] Slot %d action: %s" % [slot_id, action])

	match action:
		"delete":
			# 删除需要确认
			_show_delete_confirmation(slot_id)
		_:
			slot_selected.emit(slot_id, action)

## 显示删除确认对话框
func _show_delete_confirmation(slot_id: int) -> void:
	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除存档槽 %d 吗？\n此操作无法撤销！" % (slot_id + 1)
	dialog.ok_button_text = "删除"
	dialog.cancel_button_text = "取消"

	add_child(dialog)

	# 连接确认信号
	dialog.confirmed.connect(func():
		slot_selected.emit(slot_id, "delete")
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()

## 返回按钮
func _on_back_pressed() -> void:
	print("[SaveSlotsUI] Back pressed")
	back_pressed.emit()
