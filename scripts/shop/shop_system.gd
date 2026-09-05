extends Node
class_name ShopSystem
## 商店系统

signal item_bought(item_id, quantity, total_cost)
signal item_sold(item_id, quantity, total_gain)
signal shop_refreshed()

var shop_database = null
var player_gold = 0
var player_level = 1
var purchased_counts = {}  # item_id -> count

func _ready() -> void:
	print("[ShopSystem] Initialized")

## 设置商店数据库
func set_database(db) -> void:
	shop_database = db
	print("[ShopSystem] Database set")

## 设置玩家金币
func set_player_gold(gold: int) -> void:
	player_gold = gold

## 设置玩家等级
func set_player_level(level: int) -> void:
	player_level = level

## 获取玩家金币
func get_player_gold() -> int:
	return player_gold

## 检查是否可以购买
func can_buy(item_id: String, quantity: int = 1) -> bool:
	if not shop_database:
		return false

	var shop_item = shop_database.get_shop_item(item_id)
	if not shop_item:
		return false

	# 检查等级
	if player_level < shop_item.required_level:
		return false

	# 检查库存
	if shop_item.stock != -1:
		var purchased = purchased_counts.get(item_id, 0)
		if purchased + quantity > shop_item.stock:
			return false

	# 检查金币
	var total_cost = shop_item.buy_price * quantity
	if player_gold < total_cost:
		return false

	return true

## 购买物品
func buy_item(item_id: String, quantity: int = 1) -> bool:
	if not can_buy(item_id, quantity):
		return false

	var shop_item = shop_database.get_shop_item(item_id)
	var total_cost = shop_item.buy_price * quantity

	player_gold -= total_cost

	if shop_item.stock != -1:
		if not purchased_counts.has(item_id):
			purchased_counts[item_id] = 0
		purchased_counts[item_id] += quantity

	print("[ShopSystem] Bought %d x %s for %d gold" % [quantity, item_id, total_cost])
	item_bought.emit(item_id, quantity, total_cost)

	return true

## 出售物品
func sell_item(item_id: String, quantity: int = 1) -> bool:
	if not shop_database:
		return false

	var shop_item = shop_database.get_shop_item(item_id)
	if not shop_item:
		return false

	var total_gain = shop_item.sell_price * quantity
	player_gold += total_gain

	print("[ShopSystem] Sold %d x %s for %d gold" % [quantity, item_id, total_gain])
	item_sold.emit(item_id, quantity, total_gain)

	return true

## 获取可购买物品列表（按类别）
func get_available_items(category: String = "") -> Array:
	if not shop_database:
		return []

	var items = []
	var all_items = shop_database.get_all_shop_items()

	for shop_item in all_items:
		# 等级过滤
		if player_level < shop_item.required_level:
			continue

		# 类别过滤
		if not category.is_empty() and shop_item.category != category:
			continue

		# 库存检查
		if shop_item.stock != -1:
			var purchased = purchased_counts.get(shop_item.item_id, 0)
			if purchased >= shop_item.stock:
				continue

		items.append(shop_item)

	return items

## 获取剩余库存
func get_remaining_stock(item_id: String) -> int:
	if not shop_database:
		return 0

	var shop_item = shop_database.get_shop_item(item_id)
	if not shop_item:
		return 0

	if shop_item.stock == -1:
		return -1  # 无限

	var purchased = purchased_counts.get(item_id, 0)
	return max(0, shop_item.stock - purchased)

## 刷新商店（重置库存）
func refresh_shop() -> void:
	purchased_counts.clear()
	print("[ShopSystem] Shop refreshed")
	shop_refreshed.emit()

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"player_gold": player_gold,
		"purchased_counts": purchased_counts.duplicate()
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	player_gold = data.get("player_gold", 0)
	purchased_counts = data.get("purchased_counts", {})
	print("[ShopSystem] Loaded save data: %d gold" % player_gold)
