extends Resource
## 掉落表

var table_id = ""
var table_name = ""
var entries = []  # Array of LootEntry

## 从JSON创建
static func from_json(data: Dictionary):
	var LootTableClass = load("res://scripts/drop/loot_table.gd")
	var table = LootTableClass.new()
	table.table_id = data.get("id", "")
	table.table_name = data.get("name", "")

	var entries_data = data.get("entries", [])
	for entry_data in entries_data:
		var entry = LootEntry.from_json(entry_data)
		if entry:
			table.entries.append(entry)

	return table

## 掉落条目
class LootEntry:
	var item_id = ""
	var chance = 0.0  # 0.0 - 1.0
	var min_quantity = 1
	var max_quantity = 1

	static func from_json(data: Dictionary):
		var entry = LootEntry.new()
		entry.item_id = data.get("item_id", "")
		entry.chance = data.get("chance", 0.0)
		entry.min_quantity = data.get("min_quantity", 1)
		entry.max_quantity = data.get("max_quantity", 1)
		return entry
