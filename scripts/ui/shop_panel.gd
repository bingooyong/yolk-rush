extends Panel
class_name ShopPanel
## 商店面板 UI

# UI 节点
@onready var shop_tabs: TabContainer = $VBox/ShopTabs
@onready var gold_label: Label = $VBox/TopBar/GoldLabel
@onready var close_button: Button = $VBox/TopBar/CloseButton

# GameManager 引用
var game_manager = null

# 商店容器
var shop_containers: Dictionary = {}
var current_shop_id: String = ""

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
	# 连接商店系统信号
	game_manager.shop_system.gold_changed.connect(_on_gold_changed)
	game_manager.shop_system.item_purchased.connect(_on_item_purchased)
	game_manager.shop_system.item_sold.connect(_on_item_sold)

	# 创建商店标签页
	_create_shop_tabs()

	# 初始刷新
	refresh()

## 创建商店标签页
func _create_shop_tabs() -> void:
	if not shop_tabs:
		return

	# 清空现有标签
	for child in shop_tabs.get_children():
		child.queue_free()
	shop_containers.clear()

	# 获取所有商店
	var shops = game_manager.shop_system.get_all_shops()

	for shop in shops:
		var tab = ScrollContainer.new()
		tab.name = shop.shop_name

		var container = VBoxContainer.new()
		tab.add_child(container)

		shop_tabs.add_child(tab)
		shop_containers[shop.shop_id] = container

## 刷新显示
func refresh() -> void:
	if not game_manager or not game_manager.is_initialized:
		return

	# 更新金币显示
	_update_gold_display()

	# 刷新所有商店
	for shop_id in shop_containers.keys():
		_refresh_shop(shop_id)

## 更新金币显示
func _update_gold_display() -> void:
	if gold_label:
		var gold = game_manager.shop_system.get_player_gold()
		gold_label.text = "金币: %d" % gold

## 刷新单个商店
func _refresh_shop(shop_id: String) -> void:
	if not shop_containers.has(shop_id):
		return

	var container = shop_containers[shop_id]

	# 清空现有内容
	for child in container.get_children():
		child.queue_free()

	# 获取商店信息
	var shop = game_manager.shop_system.get_shop(shop_id)
	if not shop:
		return

	# 商店描述
	var desc_label = Label.new()
	desc_label.text = shop.shop_description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)

	# 添加分隔线
	var separator = HSeparator.new()
	container.add_child(separator)

	# 获取可购买的物品
	var items = game_manager.shop_system.get_available_items(shop_id)

	if items.size() == 0:
		var no_items_label = Label.new()
		no_items_label.text = "暂无可购买的物品"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(no_items_label)
		return

	# 创建物品列表
	for item_entry in items:
		var item_panel = _create_shop_item(shop_id, item_entry)
		container.add_child(item_panel)

## 创建商店物品面板
func _create_shop_item(shop_id: String, item_entry: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 图标占位
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.color = Color(0.3, 0.3, 0.5)
	hbox.add_child(icon)

	# 信息区域
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# 物品名称
	var item_id = item_entry.get("item_id", "")
	var item = game_manager.item_database.get_item_by_id(item_id)

	var name_label = Label.new()
	if item:
		name_label.text = item.item_name
	else:
		name_label.text = item_id
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# 物品描述
	if item:
		var desc_label = Label.new()
		desc_label.text = item.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		vbox.add_child(desc_label)

	# 价格和购买按钮区域
	var button_hbox = HBoxContainer.new()
	hbox.add_child(button_hbox)

	# 价格标签
	var price = item_entry.get("price", 0)
	var price_label = Label.new()
	price_label.text = "%d 金币" % price
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	button_hbox.add_child(price_label)

	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(80, 40)

	# 检查是否能购买
	var can_buy = game_manager.shop_system.can_buy(shop_id, item_id, 1)
	buy_button.disabled = not can_buy

	if not can_buy:
		buy_button.tooltip_text = "金币不足或等级不够"

	buy_button.pressed.connect(_on_buy_button_pressed.bind(shop_id, item_id, price))
	button_hbox.add_child(buy_button)

	return panel

## 购买按钮点击
func _on_buy_button_pressed(shop_id: String, item_id: String, price: int) -> void:
	if game_manager.shop_system.buy_item(shop_id, item_id, 1):
		print("[ShopPanel] Purchased: %s for %d gold" % [item_id, price])
		# 刷新商店显示
		_refresh_shop(shop_id)
		_update_gold_display()
	else:
		print("[ShopPanel] Purchase failed: %s" % item_id)

## 关闭按钮
func _on_close_button_pressed() -> void:
	visible = false

## 信号处理
func _on_gold_changed(current_gold: int) -> void:
	_update_gold_display()
	# 刷新所有商店（按钮可用性可能改变）
	refresh()

func _on_item_purchased(shop_id: String, item_id: String, quantity: int, total_cost: int) -> void:
	print("[ShopPanel] Item purchased: %s x%d for %d gold" % [item_id, quantity, total_cost])

func _on_item_sold(item_id: String, quantity: int, total_value: int) -> void:
	print("[ShopPanel] Item sold: %s x%d for %d gold" % [item_id, quantity, total_value])

## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
