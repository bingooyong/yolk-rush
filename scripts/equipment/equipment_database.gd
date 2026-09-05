extends Node
class_name EquipmentDatabase
## 装备数据库 - 加载和管理所有装备数据

const EquipmentItemClass = preload("res://scripts/equipment/equipment_item.gd")

var equipment_data: Dictionary = {
	"weapons": [],
	"armors": [],
	"accessories": []
}

var equipment_by_id: Dictionary = {}

func _ready() -> void:
	load_equipment_database()

## 加载装备数据库
func load_equipment_database() -> void:
	var db_path := "res://data/equipment/equipment_database.json"

	if not FileAccess.file_exists(db_path):
		push_error("[EquipmentDatabase] Database file not found: %s" % db_path)
		return

	var file := FileAccess.open(db_path, FileAccess.READ)
	if not file:
		push_error("[EquipmentDatabase] Failed to open database")
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)

	if parse_result != OK:
		push_error("[EquipmentDatabase] Failed to parse JSON: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data

	# 加载武器
	if data.has("weapons"):
		for weapon_data in data["weapons"]:
			var item = EquipmentItemClass.from_json(weapon_data)
			equipment_data["weapons"].append(item)
			equipment_by_id[item.id] = item

	# 加载护甲
	if data.has("armors"):
		for armor_data in data["armors"]:
			var item = EquipmentItemClass.from_json(armor_data)
			equipment_data["armors"].append(item)
			equipment_by_id[item.id] = item

	# 加载饰品
	if data.has("accessories"):
		for accessory_data in data["accessories"]:
			var item = EquipmentItemClass.from_json(accessory_data)
			equipment_data["accessories"].append(item)
			equipment_by_id[item.id] = item

	print("[EquipmentDatabase] Loaded %d equipment items" % equipment_by_id.size())

## 根据 ID 获取装备
func get_equipment_by_id(item_id: String) :
	if equipment_by_id.has(item_id):
		return equipment_by_id[item_id].duplicate_item()

	push_warning("[EquipmentDatabase] Equipment not found: %s" % item_id)
	return null

## 获取所有武器
func get_all_weapons() -> Array:
	return equipment_data["weapons"].duplicate()

## 获取所有护甲
func get_all_armors() -> Array:
	return equipment_data["armors"].duplicate()

## 获取所有饰品
func get_all_accessories() -> Array:
	return equipment_data["accessories"].duplicate()

## 根据类型获取装备
func get_equipment_by_type(equipment_type) -> Array:
	var result: Array = []

	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		if item.equipment_type == equipment_type:
			result.append(item.duplicate_item())

	return result

## 根据稀有度获取装备
func get_equipment_by_rarity(rarity) -> Array:
	var result: Array = []

	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		if item.rarity == rarity:
			result.append(item.duplicate_item())

	return result

## 根据等级要求获取装备
func get_equipment_by_level_range(min_level: int, max_level: int) -> Array:
	var result: Array = []

	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		if item.level_requirement >= min_level and item.level_requirement <= max_level:
			result.append(item.duplicate_item())

	return result

## 随机获取装备（用于掉落）
func get_random_equipment(min_level: int = 1, max_level: int = 50, rarity_weights: Dictionary = {}) :
	# 默认稀有度权重
	var default_weights := {
		EquipmentItemClass.Rarity.COMMON: 50.0,
		EquipmentItemClass.Rarity.UNCOMMON: 30.0,
		EquipmentItemClass.Rarity.RARE: 15.0,
		EquipmentItemClass.Rarity.EPIC: 4.0,
		EquipmentItemClass.Rarity.LEGENDARY: 1.0
	}

	var weights := rarity_weights if not rarity_weights.is_empty() else default_weights

	# 先确定稀有度
	var chosen_rarity := _weighted_random_rarity(weights)

	# 获取符合条件的装备
	var candidates: Array = []
	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		if item.rarity == chosen_rarity and item.level_requirement >= min_level and item.level_requirement <= max_level:
			candidates.append(item)

	if candidates.is_empty():
		push_warning("[EquipmentDatabase] No equipment found matching criteria")
		return null

	# 随机选择一个
	var random_item = candidates[randi() % candidates.size()]
	return random_item.duplicate_item()

## 加权随机选择稀有度
func _weighted_random_rarity(weights: Dictionary) -> int:
	var total_weight := 0.0
	for weight in weights.values():
		total_weight += weight

	var rand_value := randf() * total_weight
	var cumulative := 0.0

	for rarity in weights.keys():
		cumulative += weights[rarity]
		if rand_value <= cumulative:
			return rarity

	return EquipmentItemClass.Rarity.COMMON

## 获取装备总数
func get_total_count() -> int:
	return equipment_by_id.size()

## 获取统计信息
func get_statistics() -> Dictionary:
	var stats := {
		"total": equipment_by_id.size(),
		"weapons": equipment_data["weapons"].size(),
		"armors": equipment_data["armors"].size(),
		"accessories": equipment_data["accessories"].size(),
		"by_rarity": {
			"common": 0,
			"uncommon": 0,
			"rare": 0,
			"epic": 0,
			"legendary": 0
		}
	}

	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		match item.rarity:
			EquipmentItemClass.Rarity.COMMON: stats["by_rarity"]["common"] += 1
			EquipmentItemClass.Rarity.UNCOMMON: stats["by_rarity"]["uncommon"] += 1
			EquipmentItemClass.Rarity.RARE: stats["by_rarity"]["rare"] += 1
			EquipmentItemClass.Rarity.EPIC: stats["by_rarity"]["epic"] += 1
			EquipmentItemClass.Rarity.LEGENDARY: stats["by_rarity"]["legendary"] += 1

	return stats

## 调试：打印所有装备
func _debug_print_all_equipment() -> void:
	print("[EquipmentDatabase] === All Equipment ===")
	for item_id in equipment_by_id.keys():
		var item = equipment_by_id[item_id]
		print("  %s (%s) - %s | Level %d" % [
			item.item_name,
			item.id,
			item.get_rarity_text(),
			item.level_requirement
		])
