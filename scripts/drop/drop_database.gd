extends Node
class_name DropDatabase
## 掉落数据库

const LootTableClass = preload("res://scripts/drop/loot_table.gd")

signal database_loaded()

var loot_tables = {}  # table_id -> LootTable
var item_rarities = {}  # item_id -> rarity

func _ready() -> void:
	load_database()

## 加载数据库
func load_database() -> bool:
	var file_path = "res://data/drop/loot_tables.json"

	if not FileAccess.file_exists(file_path):
		push_error("[DropDatabase] File not found: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[DropDatabase] Failed to open file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[DropDatabase] Parse error: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	if data.has("loot_tables"):
		_parse_loot_tables(data["loot_tables"])

	if data.has("item_rarities"):
		item_rarities = data["item_rarities"]

	print("[DropDatabase] Loaded %d loot tables" % loot_tables.size())
	database_loaded.emit()

	return true

## 解析掉落表
func _parse_loot_tables(data: Array) -> void:
	loot_tables.clear()

	for table_data in data:
		if not table_data is Dictionary:
			continue

		var table = LootTableClass.from_json(table_data)
		if table:
			loot_tables[table.table_id] = table

## 获取掉落表
func get_loot_table(table_id: String):
	if loot_tables.has(table_id):
		return loot_tables[table_id]
	push_warning("[DropDatabase] Loot table not found: %s" % table_id)
	return null

## 获取所有掉落表
func get_all_loot_tables() -> Array:
	var result = []
	for table in loot_tables.values():
		result.append(table)
	return result

## 掉落表是否存在
func has_loot_table(table_id: String) -> bool:
	return loot_tables.has(table_id)

## 按稀有度获取物品
func get_items_by_rarity(rarity: String) -> Array:
	var items = []
	for item_id in item_rarities.keys():
		if item_rarities[item_id] == rarity:
			items.append(item_id)
	return items

## 获取物品稀有度
func get_item_rarity(item_id: String) -> String:
	return item_rarities.get(item_id, "common")
