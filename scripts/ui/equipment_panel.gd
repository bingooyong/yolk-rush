extends Panel
class_name EquipmentPanel
## 装备面板 UI

const EquipmentItemClass = preload("res://scripts/equipment/equipment_item.gd")

# 装备槽位按钮
var slot_buttons: Dictionary = {}

# UI 节点
@onready var equipment_container: Control = $VBox/EquipmentContainer
@onready var stats_panel: Panel = $VBox/StatsPanel
@onready var stats_label: Label = $VBox/StatsPanel/StatsLabel
@onready var score_label: Label = $VBox/TopBar/ScoreLabel
@onready var close_button: Button = $VBox/TopBar/CloseButton

# GameManager 引用
var game_manager = null

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_initialize()
		else:
			game_manager.game_initialized.connect(_initialize)

func _initialize() -> void:
	# 连接装备系统信号
	game_manager.equipment_system.equipment_changed.connect(_on_equipment_changed)
	game_manager.equipment_system.stats_updated.connect(_on_stats_updated)

	# 创建装备槽位
	_create_equipment_slots()

	# 初始刷新
	refresh()

## 创建装备槽位
func _create_equipment_slots() -> void:
	if not equipment_container:
		return

	# 定义槽位布局
	var slot_positions = {
		"main_hand": Vector2(100, 200),
		"off_hand": Vector2(300, 200),
		"helmet": Vector2(200, 50),
		"chest": Vector2(200, 150),
		"gloves": Vector2(100, 150),
		"boots": Vector2(200, 250),
		"ring": Vector2(100, 300),
		"necklace": Vector2(200, 0),
	}

	for slot_name in slot_positions.keys():
		var button = _create_slot_button(slot_name)
		button.position = slot_positions[slot_name]
		equipment_container.add_child(button)
		slot_buttons[slot_name] = button

## 创建单个装备槽位按钮
func _create_slot_button(slot_name: String) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 80)
	button.name = slot_name

	# 添加标签
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)

	# 槽位名称
	var slot_label = Label.new()
	slot_label.name = "SlotLabel"
	slot_label.text = _get_slot_display_name(slot_name)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.add_theme_font_size_override("font_size", 10)
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(slot_label)

	# 装备名称
	var item_label = Label.new()
	item_label.name = "ItemLabel"
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.add_theme_font_size_override("font_size", 9)
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(item_label)

	# 连接信号
	button.pressed.connect(_on_slot_button_pressed.bind(slot_name))

	return button

## 获取槽位显示名称
func _get_slot_display_name(slot_name: String) -> String:
	match slot_name:
		"main_hand": return "主手"
		"off_hand": return "副手"
		"helmet": return "头盔"
		"chest": return "胸甲"
		"gloves": return "手套"
		"boots": return "靴子"
		"ring": return "戒指"
		"necklace": return "项链"
		_: return slot_name

## 刷新显示
func refresh() -> void:
	if not game_manager or not game_manager.is_initialized:
		return

	# 更新每个槽位
	for slot_name in slot_buttons.keys():
		_update_slot_display(slot_name)

	# 更新属性显示
	_update_stats_display()

	# 更新装备评分
	_update_score_display()

## 更新单个槽位显示
func _update_slot_display(slot_name: String) -> void:
	if not slot_buttons.has(slot_name):
		return

	var button = slot_buttons[slot_name]
	var item = game_manager.equipment_system.get_equipped_item(slot_name)

	var item_label = button.get_node_or_null("VBoxContainer/ItemLabel")
	if not item_label:
		return

	if item:
		# 有装备
		item_label.text = item.item_name

		# 根据稀有度设置颜色
		var rarity_color = _get_rarity_color(item.rarity)
		button.modulate = rarity_color
	else:
		# 空槽位
		item_label.text = "空"
		button.modulate = Color(0.6, 0.6, 0.6, 1.0)

## 获取稀有度颜色
func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color.WHITE
		1: return Color(0.3, 1.0, 0.3)
		2: return Color(0.3, 0.5, 1.0)
		3: return Color(0.8, 0.3, 1.0)
		4: return Color(1.0, 0.6, 0.0)
		_: return Color.WHITE

## 更新属性显示
func _update_stats_display() -> void:
	if not stats_label:
		return

	var stats = game_manager.equipment_system.get_total_stats()

	var text = "装备属性:\n"
	text += "物理伤害: +%.0f\n" % stats.physical_damage
	text += "魔法伤害: +%.0f\n" % stats.magical_damage
	text += "生命值: +%.0f\n" % stats.max_health
	text += "魔法值: +%.0f\n" % stats.max_mana
	text += "防御力: +%.0f\n" % stats.defense
	text += "魔法抗性: +%.0f\n" % stats.magic_resistance
	text += "攻击速度: +%.1f%%\n" % (stats.attack_speed * 100)
	text += "暴击率: +%.1f%%\n" % (stats.critical_chance * 100)
	text += "移动速度: +%.0f" % stats.movement_speed

	stats_label.text = text

## 更新装备评分
func _update_score_display() -> void:
	if score_label:
		var score = game_manager.equipment_system.get_equipment_score()
		score_label.text = "装备评分: %d" % score

## 槽位被点击
func _on_slot_button_pressed(slot_name: String) -> void:
	var item = game_manager.equipment_system.get_equipped_item(slot_name)

	if item:
		# 显示装备信息并询问是否卸下
		_show_unequip_dialog(slot_name, item)
	else:
		# 显示可装备的物品列表
		_show_equippable_items(slot_name)

## 显示卸下装备对话框
func _show_unequip_dialog(slot_name: String, item) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "卸下 %s？" % item.item_name
	dialog.ok_button_text = "卸下"

	dialog.confirmed.connect(func():
		game_manager.equipment_system.unequip_item(slot_name)
	)

	add_child(dialog)
	dialog.popup_centered()

## 显示可装备物品列表
func _show_equippable_items(slot_name: String) -> void:
	# TODO: 显示背包中可以装备到此槽位的物品
	print("[EquipmentPanel] Show equippable items for %s" % slot_name)

## 关闭按钮
func _on_close_button_pressed() -> void:
	visible = false

## 信号处理
func _on_equipment_changed(slot: String, item) -> void:
	_update_slot_display(slot)
	_update_stats_display()
	_update_score_display()

func _on_stats_updated(total_stats: Dictionary) -> void:
	_update_stats_display()

## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
