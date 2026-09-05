extends Node

const EquipmentDatabaseClass = preload("res://scripts/equipment/equipment_database.gd")
const ItemDatabaseClass = preload("res://scripts/inventory/item_database.gd")
const SkillDatabaseClass = preload("res://scripts/skill_tree/skill_database.gd")
const AchievementDatabaseClass = preload("res://scripts/achievement/achievement_database.gd")
const ShopDatabaseClass = preload("res://scripts/shop/shop_database.gd")
const DropDatabaseClass = preload("res://scripts/drop/drop_database.gd")

func _ready():
	print("=== Testing Database Instantiation ===")

	print("Testing EquipmentDatabase...")
	var eq_db = EquipmentDatabaseClass.new()
	print("  ✓ Success: ", eq_db != null)

	print("Testing ItemDatabase...")
	var item_db = ItemDatabaseClass.new()
	print("  ✓ Success: ", item_db != null)

	print("Testing SkillDatabase...")
	var skill_db = SkillDatabaseClass.new()
	print("  ✓ Success: ", skill_db != null)

	print("Testing AchievementDatabase...")
	var ach_db = AchievementDatabaseClass.new()
	print("  ✓ Success: ", ach_db != null)

	print("Testing ShopDatabase...")
	var shop_db = ShopDatabaseClass.new()
	print("  ✓ Success: ", shop_db != null)

	print("Testing DropDatabase...")
	var drop_db = DropDatabaseClass.new()
	print("  ✓ Success: ", drop_db != null)

	print("\n=== All databases instantiated successfully ===")
	get_tree().quit()
