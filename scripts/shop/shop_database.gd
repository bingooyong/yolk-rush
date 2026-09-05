extends Node
class_name ShopDatabase
## 商店数据库

const ShopItemClass = preload("res://scripts/shop/shop_item.gd")

signal database_loaded()

var shop_items = {}  # item_id -> ShopItem
var items_by_category = {}  # category -> Array

func _ready() -> void:
	load_database()

## 加载数据库
func load_database() -> bool:
	var file_path = "res://data/shop/shop_items.json"

	if not FileAccess.file_exists(file_path):
		push_error("[ShopDatabase] File not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ShopDatabase] Failed to open file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[ShopDatabase] Parse error: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	if not data.has("items"):
		push_error("[ShopDatabase] No 'items' array")
		return false

	_parse_items(data["items"])

	print("[ShopDatabase] Loaded %d shop items" % shop_items.size())
	database_loaded.emit()

	return true

## 解析商品数据
func _parse_items(data: Array) -> void:
	shop_items.clear()
	items_by_category.clear()

	for item_data in data:
		if not item_data is Dictionary:
			continue

		var shop_item = ShopItemClass.from_json(item_data)
		if shop_item:
			shop_items[shop_item.item_id] = shop_item

			var category = shop_item.category
			if not items_by_category.has(category):
				items_by_category[category] = []
			items_by_category[category].append(shop_item)

## 获取商品
func get_shop_item(item_id: String):
	if shop_items.has(item_id):
		return shop_items[item_id]
	push_warning("[ShopDatabase] Item not found: %s" % item_id)
	return null

## 按类别获取商品
func get_items_by_category(category: String) -> Array:
	if items_by_category.has(category):
		return items_by_category[category].duplicate()
	return []

## 获取所有商品
func get_all_shop_items() -> Array:
	var result = []
	for item in shop_items.values():
		result.append(item)
	return result

## 获取所有类别
func get_all_categories() -> Array:
	var categories = []
	for category in items_by_category.keys():
		categories.append(category)
	return categories

## 商品是否存在
func has_item(item_id: String) -> bool:
	return shop_items.has(item_id)

## 获取商品数量
func get_item_count() -> int:
	return shop_items.size()
