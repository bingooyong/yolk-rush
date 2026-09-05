extends Node
class_name ItemDatabase
## 物品数据库 - 加载和管理所有物品数据

const InventoryItemClass = preload("res://scripts/inventory/inventory_item.gd")

signal database_loaded()

var items: Dictionary = {}  # id 
var items_by_type: Dictionary = {}  # ItemType 
var items_by_rarity: Dictionary = {}  # Rarity 

func _ready() -> void:
	load_database()

## 加载物品数据库
func load_database() -> bool:
	var file_path = "res://data/inventory/item_database.json"

	if not FileAccess.file_exists(file_path):
		push_error("[ItemDatabase] Database file not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ItemDatabase] Failed to open database file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[ItemDatabase] Failed to parse JSON: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	if not data.has("items"):
		push_error("[ItemDatabase] No 'items' array in database")
		return false

	_parse_items(data["items"])

	print("[ItemDatabase] Loaded %d items" % items.size())
	database_loaded.emit()

	return true

## 解析物品数据
func _parse_items(items_data: Array) -> void:
	items.clear()
	items_by_type.clear()
	items_by_rarity.clear()

	for item_data in items_data:
		if not item_data is Dictionary:
			continue

		var item = _create_item_from_data(item_data)
		if item:
			items[item.id] = item

			# 按类型分类
			if not items_by_type.has(item.item_type):
				items_by_type[item.item_type] = []
			items_by_type[item.item_type].append(item)

			# 按稀有度分类
			if not items_by_rarity.has(item.rarity):
				items_by_rarity[item.rarity] = []
			items_by_rarity[item.rarity].append(item)

## 从数据创建物品
func _create_item_from_data(data: Dictionary) :
	var item = InventoryItemClass.new()

	item.id = data.get("id", "")
	item.item_name = data.get("item_name", "")
	item.max_stack_size = data.get("max_stack_size", 1)
	item.icon_path = data.get("icon_path", "")
	item.description = data.get("description", "")
	item.sell_price = data.get("sell_price", 0)
	item.buy_price = data.get("buy_price", 0)

	# 解析枚举类型
	var type_str: String = data.get("item_type", "MATERIAL")
	item.item_type = _parse_item_type(type_str)

	var rarity_str: String = data.get("rarity", "COMMON")
	item.rarity = _parse_rarity(rarity_str)

	return item

## 解析物品类型字符串
func _parse_item_type(type_str: String):
	match type_str:
		"EQUIPMENT": return InventoryItemClass.ItemType.EQUIPMENT
		"CONSUMABLE": return InventoryItemClass.ItemType.CONSUMABLE
		"MATERIAL": return InventoryItemClass.ItemType.MATERIAL
		"QUEST": return InventoryItemClass.ItemType.QUEST
		"CURRENCY": return InventoryItemClass.ItemType.CURRENCY
		_:
			push_warning("[ItemDatabase] Unknown item type: %s" % type_str)
			return InventoryItemClass.ItemType.MATERIAL

## 解析稀有度字符串
func _parse_rarity(rarity_str: String):
	match rarity_str:
		"COMMON": return InventoryItemClass.Rarity.COMMON
		"UNCOMMON": return InventoryItemClass.Rarity.UNCOMMON
		"RARE": return InventoryItemClass.Rarity.RARE
		"EPIC": return InventoryItemClass.Rarity.EPIC
		"LEGENDARY": return InventoryItemClass.Rarity.LEGENDARY
		_:
			push_warning("[ItemDatabase] Unknown rarity: %s" % rarity_str)
			return InventoryItemClass.Rarity.COMMON

## 通过 ID 获取物品
func get_item_by_id(item_id: String) :
	if items.has(item_id):
		return items[item_id].duplicate_item()

	push_warning("[ItemDatabase] Item not found: %s" % item_id)
	return null

## 获取所有物品 ID
func get_all_item_ids():
	var ids = []
	for id in items.keys():
		ids.append(id)
	return ids

## 获取所有物品
func get_all_items() :
	var result = []
	for item in items.values():
		result.append(item.duplicate_item())
	return result

## 按类型获取物品
func get_items_by_type(item_type) :
	var result = []

	if items_by_type.has(item_type):
		for item in items_by_type[item_type]:
			result.append(item.duplicate_item())

	return result

## 按稀有度获取物品
func get_items_by_rarity(rarity) :
	var result = []

	if items_by_rarity.has(rarity):
		for item in items_by_rarity[rarity]:
			result.append(item.duplicate_item())

	return result

## 获取随机物品
func get_random_item() :
	if items.is_empty():
		return null

	var ids = items.keys()
	var random_id: String = ids[randi() % ids.size()]
	return get_item_by_id(random_id)

## 获取随机物品（按类型）
func get_random_item_by_type(item_type) :
	if not items_by_type.has(item_type) or items_by_type[item_type].is_empty():
		return null

	var type_items: Array = items_by_type[item_type]
	var random_item = type_items[randi() % type_items.size()]
	return random_item.duplicate_item()

## 获取随机物品（按稀有度权重）
func get_random_item_by_rarity_weights(weights: Dictionary = {}) :
	# 默认权重：Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1%
	var default_weights = {
		InventoryItemClass.Rarity.COMMON: 50.0,
		InventoryItemClass.Rarity.UNCOMMON: 30.0,
		InventoryItemClass.Rarity.RARE: 15.0,
		InventoryItemClass.Rarity.EPIC: 4.0,
		InventoryItemClass.Rarity.LEGENDARY: 1.0
	}

	# 合并自定义权重
	for rarity in default_weights.keys():
		if weights.has(rarity):
			default_weights[rarity] = weights[rarity]

	# 计算总权重
	var total_weight = 0.0
	for weight in default_weights.values():
		total_weight += weight

	# 随机选择稀有度
	var roll = randf() * total_weight
	var accumulated = 0.0

	for rarity in default_weights.keys():
		accumulated += default_weights[rarity]
		if roll <= accumulated:
			return get_random_item_by_rarity(rarity)

	# 默认返回普通稀有度
	return get_random_item_by_rarity(InventoryItemClass.Rarity.COMMON)

## 获取随机物品（按稀有度）
func get_random_item_by_rarity(rarity) :
	if not items_by_rarity.has(rarity) or items_by_rarity[rarity].is_empty():
		return null

	var rarity_items: Array = items_by_rarity[rarity]
	var random_item = rarity_items[randi() % rarity_items.size()]
	return random_item.duplicate_item()

## 物品是否存在
func has_item(item_id: String) -> bool:
	return items.has(item_id)

## 获取物品数量
func get_item_count() -> int:
	return items.size()

## 获取类型物品数量
func get_type_count(item_type) -> int:
	if items_by_type.has(item_type):
		return items_by_type[item_type].size()
	return 0

## 获取稀有度物品数量
func get_rarity_count(rarity) -> int:
	if items_by_rarity.has(rarity):
		return items_by_rarity[rarity].size()
	return 0

## 调试：打印数据库统计
func _debug_print_stats() -> void:
	print("[ItemDatabase] === Database Statistics ===")
	print("  Total items: %d" % items.size())

	print("  By Type:")
	for type in InventoryItemClass.ItemType.values():
		var count = get_type_count(type)
		if count > 0:
			print("    %d: %d items" % [type, count])

	print("  By Rarity:")
	for rarity in InventoryItemClass.Rarity.values():
		var count = get_rarity_count(rarity)
		if count > 0:
			print("    %d: %d items" % [rarity, count])
