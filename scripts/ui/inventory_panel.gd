extends Panel
class_name InventoryPanel
## 背包 UI 面板

const InventoryItemClass = preload("res://scripts/inventory/inventory_item.gd")

signal slot_clicked(slot_index: int)
signal item_used(slot_index: int)

# UI 节点
@onready var grid_container: GridContainer = $VBox/ScrollContainer/GridContainer
@onready var sort_button: Button = $VBox/TopBar/SortButton
@onready var close_button: Button = $VBox/TopBar/CloseButton
@onready var usage_label: Label = $VBox/TopBar/UsageLabel
@onready var item_info_panel: Panel = $ItemInfoPanel

# GameManager 引用
var game_manager = null

# 状态
var selected_slot_index: int = -1
var slot_buttons: Array[Button] = []

func _ready() -> void:
	# 连接按钮信号
	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	# 等待游戏管理器
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_initialize()
		else:
			game_manager.game_initialized.connect(_initialize)
		_initialize()
	else:
		game_manager.game_initialized.connect(_initialize)

func _initialize() -> void:
	# 连接背包信号
	game_manager.inventory_system.inventory_changed.connect(_on_inventory_changed)
	game_manager.inventory_system.slot_changed.connect(_on_slot_changed)

	# 创建背包槽位
	_create_inventory_slots()

	# 初始刷新
	refresh()

## 创建背包槽位
func _create_inventory_slots() -> void:
	if not grid_container:
		return

	# 清空现有槽位
	for child in grid_container.get_children():
		child.queue_free()
	slot_buttons.clear()

	# 设置网格
	grid_container.columns = 8  # 8列

	# 创建 48 个槽位
	for i in range(game_manager.inventory_system.INVENTORY_SIZE):
		var slot_button = _create_slot_button(i)
		grid_container.add_child(slot_button)
		slot_buttons.append(slot_button)

## 创建单个槽位按钮
func _create_slot_button(slot_index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.toggle_mode = false

	# 添加图标容器
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)

	# 物品名称
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# 数量标签
	var quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.add_theme_font_size_override("font_size", 12)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(quantity_label)

	# 连接信号
	button.pressed.connect(_on_slot_button_pressed.bind(slot_index))

	return button

## 刷新背包显示
func refresh() -> void:
	if not game_manager or not game_manager.is_initialized:
		return

	# 更新每个槽位
	for i in range(slot_buttons.size()):
		_update_slot_display(i)

	# 更新使用率
	_update_usage_label()

## 更新单个槽位显示
func _update_slot_display(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slot_buttons.size():
		return

	var button = slot_buttons[slot_index]
	var slot = game_manager.inventory_system.get_slot(slot_index)

	if slot and slot.item:
		# 有物品
		var name_label = button.get_node_or_null("VBoxContainer/NameLabel")
		var quantity_label = button.get_node_or_null("VBoxContainer/QuantityLabel")

		if name_label:
			name_label.text = slot.item.item_name
		if quantity_label:
			quantity_label.text = "x%d" % slot.quantity

		# 根据稀有度设置颜色
		var rarity_color = _get_rarity_color(slot.item.rarity)
		button.modulate = rarity_color

		button.disabled = false
	else:
		# 空槽位
		var name_label = button.get_node_or_null("VBoxContainer/NameLabel")
		var quantity_label = button.get_node_or_null("VBoxContainer/QuantityLabel")

		if name_label:
			name_label.text = ""
		if quantity_label:
			quantity_label.text = ""

		button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		button.disabled = true

## 获取稀有度颜色
func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0:  # COMMON
			return Color.WHITE
		1:  # UNCOMMON
			return Color(0.3, 1.0, 0.3)  # 绿色
		2:  # RARE
			return Color(0.3, 0.5, 1.0)  # 蓝色
		3:  # EPIC
			return Color(0.8, 0.3, 1.0)  # 紫色
		4:  # LEGENDARY
			return Color(1.0, 0.6, 0.0)  # 橙色
		_:
			return Color.WHITE

## 更新使用率标签
func _update_usage_label() -> void:
	if usage_label:
		var usage = game_manager.inventory_system.get_usage_percentage()
		var used = game_manager.inventory_system.get_used_slots()
		var total = game_manager.inventory_system.INVENTORY_SIZE
		usage_label.text = "背包: %d/%d (%.0f%%)" % [used, total, usage]

## 槽位被点击
func _on_slot_button_pressed(slot_index: int) -> void:
	selected_slot_index = slot_index

	var slot = game_manager.inventory_system.get_slot(slot_index)
	if not slot or not slot.item:
		return

	# 显示物品信息
	_show_item_info(slot.item, slot.quantity)

	# 发射信号
	slot_clicked.emit(slot_index)

## 显示物品信息
func _show_item_info(item, quantity: int) -> void:
	if not item_info_panel:
		return

	# TODO: 实现详细的物品信息显示
	print("[InventoryPanel] Item: %s x%d" % [item.item_name, quantity])

	# 简单显示
	item_info_panel.visible = true

	# 创建信息标签
	for child in item_info_panel.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	item_info_panel.add_child(vbox)

	var name_label = Label.new()
	name_label.text = item.item_name
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	var quantity_label = Label.new()
	quantity_label.text = "数量: %d" % quantity
	vbox.add_child(quantity_label)

	# 如果是消耗品，添加使用按钮
	if item.item_type == InventoryItemClass.ItemType.CONSUMABLE:
		var use_button = Button.new()
		use_button.text = "使用"
		use_button.pressed.connect(_on_use_item_pressed)
		vbox.add_child(use_button)

## 使用物品
func _on_use_item_pressed() -> void:
	if selected_slot_index < 0:
		return

	var slot = game_manager.inventory_system.get_slot(selected_slot_index)
	if not slot or not slot.item:
		return

	# TODO: 实现物品使用效果
	print("[InventoryPanel] Use item: %s" % slot.item.item_name)

	# 移除一个物品
	game_manager.inventory_system.remove_item(slot.item.item_id, 1)

	# 发射信号
	item_used.emit(selected_slot_index)

	# 隐藏信息面板
	if item_info_panel:
		item_info_panel.visible = false

## 排序按钮点击
func _on_sort_button_pressed() -> void:
	# 创建排序选项菜单
	var popup = PopupMenu.new()
	popup.add_item("按稀有度排序", 0)
	popup.add_item("按类型排序", 1)
	popup.add_item("按名称排序", 2)
	popup.add_item("按数量排序", 3)

	popup.id_pressed.connect(_on_sort_option_selected)

	add_child(popup)
	popup.popup_centered()

## 排序选项被选择
func _on_sort_option_selected(id: int) -> void:
	match id:
		0:
			game_manager.inventory_system.sort_by("rarity")
		1:
			game_manager.inventory_system.sort_by("type")
		2:
			game_manager.inventory_system.sort_by("name")
		3:
			game_manager.inventory_system.sort_by("quantity")

## 关闭按钮点击
func _on_close_button_pressed() -> void:
	visible = false

## 信号处理
func _on_inventory_changed() -> void:
	refresh()

func _on_slot_changed(slot_index: int) -> void:
	_update_slot_display(slot_index)
	_update_usage_label()

## 处理输入
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC 关闭
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
