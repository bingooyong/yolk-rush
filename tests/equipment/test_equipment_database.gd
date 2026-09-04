extends GutTest
## EquipmentDatabase 单元测试

var database: Node

func before_each():
	database = Node.new()
	database.set_script(load("res://scripts/equipment/equipment_database.gd"))
	add_child_autofree(database)
	database._ready()

func after_each():
	database = null

## 测试数据库加载
func test_database_loading():
	assert_gt(database.get_total_count(), 0, "Database should load items")
	assert_true(database.equipment_by_id.size() > 0, "Should have items indexed by ID")

## 测试根据 ID 获取装备
func test_get_equipment_by_id():
	var sword := database.get_equipment_by_id("sword_iron")

	assert_not_null(sword, "Should find sword_iron")
	assert_eq(sword.item_name, "铁剑", "Name should match")
	assert_eq(sword.equipment_type, EquipmentItem.EquipmentType.MAIN_HAND, "Type should be MAIN_HAND")

## 测试获取不存在的装备
func test_get_nonexistent_equipment():
	var item := database.get_equipment_by_id("nonexistent_item")

	assert_null(item, "Should return null for nonexistent item")

## 测试获取所有武器
func test_get_all_weapons():
	var weapons := database.get_all_weapons()

	assert_gt(weapons.size(), 0, "Should have weapons")
	for weapon in weapons:
		assert_true(weapon is EquipmentItem, "Should be EquipmentItem")

## 测试获取所有护甲
func test_get_all_armors():
	var armors := database.get_all_armors()

	assert_gt(armors.size(), 0, "Should have armors")

## 测试获取所有饰品
func test_get_all_accessories():
	var accessories := database.get_all_accessories()

	assert_gt(accessories.size(), 0, "Should have accessories")

## 测试根据类型获取装备
func test_get_equipment_by_type():
	var helmets := database.get_equipment_by_type(EquipmentItem.EquipmentType.HELMET)

	assert_gt(helmets.size(), 0, "Should have helmets")
	for helmet in helmets:
		assert_eq(helmet.equipment_type, EquipmentItem.EquipmentType.HELMET, "All should be helmets")

## 测试根据稀有度获取装备
func test_get_equipment_by_rarity():
	var legendary := database.get_equipment_by_rarity(EquipmentItem.Rarity.LEGENDARY)

	assert_gt(legendary.size(), 0, "Should have legendary items")
	for item in legendary:
		assert_eq(item.rarity, EquipmentItem.Rarity.LEGENDARY, "All should be legendary")

## 测试根据等级范围获取装备
func test_get_equipment_by_level_range():
	var low_level := database.get_equipment_by_level_range(1, 5)

	assert_gt(low_level.size(), 0, "Should have low level items")
	for item in low_level:
		assert_gte(item.level_requirement, 1, "Level should be >= 1")
		assert_lte(item.level_requirement, 5, "Level should be <= 5")

## 测试随机获取装备
func test_get_random_equipment():
	var random_item := database.get_random_equipment(1, 10)

	assert_not_null(random_item, "Should return a random item")
	assert_gte(random_item.level_requirement, 1, "Level should be >= 1")
	assert_lte(random_item.level_requirement, 10, "Level should be <= 10")

## 测试随机装备稀有度权重
func test_random_equipment_with_weights():
	# 100% 传说概率
	var weights := {
		EquipmentItem.Rarity.LEGENDARY: 100.0,
		EquipmentItem.Rarity.COMMON: 0.0
	}

	var legendary := database.get_random_equipment(1, 50, weights)

	# 注意：如果范围内没有传说装备，可能返回 null
	if legendary:
		assert_eq(legendary.rarity, EquipmentItem.Rarity.LEGENDARY, "Should be legendary")

## 测试装备复制独立性
func test_equipment_duplication():
	var sword1 := database.get_equipment_by_id("sword_iron")
	var sword2 := database.get_equipment_by_id("sword_iron")

	assert_not_null(sword1, "First sword should exist")
	assert_not_null(sword2, "Second sword should exist")
	assert_ne(sword1, sword2, "Should be different instances")

## 测试获取统计信息
func test_get_statistics():
	var stats := database.get_statistics()

	assert_true(stats.has("total"), "Should have total count")
	assert_true(stats.has("weapons"), "Should have weapon count")
	assert_true(stats.has("armors"), "Should have armor count")
	assert_true(stats.has("accessories"), "Should have accessory count")
	assert_true(stats.has("by_rarity"), "Should have rarity breakdown")

	assert_gt(stats["total"], 0, "Total should be > 0")
	assert_eq(
		stats["total"],
		stats["weapons"] + stats["armors"] + stats["accessories"],
		"Total should equal sum of categories"
	)

## 测试稀有度统计
func test_rarity_statistics():
	var stats := database.get_statistics()
	var by_rarity = stats["by_rarity"]

	var total_by_rarity := (
		by_rarity["common"] +
		by_rarity["uncommon"] +
		by_rarity["rare"] +
		by_rarity["epic"] +
		by_rarity["legendary"]
	)

	assert_eq(total_by_rarity, stats["total"], "Rarity counts should sum to total")

## 测试数据库完整性
func test_database_integrity():
	# 检查所有装备都有必需字段
	for item_id in database.equipment_by_id.keys():
		var item: EquipmentItem = database.equipment_by_id[item_id]

		assert_false(item.id.is_empty(), "Item should have ID: %s" % item_id)
		assert_false(item.item_name.is_empty(), "Item should have name: %s" % item_id)
		assert_gte(item.level_requirement, 1, "Level requirement should be >= 1: %s" % item_id)
		assert_true(item.stats is Dictionary, "Stats should be a dictionary: %s" % item_id)

## 测试特定装备属性
func test_specific_equipment_stats():
	# 测试铁剑
	var iron_sword := database.get_equipment_by_id("sword_iron")
	assert_not_null(iron_sword, "Iron sword should exist")
	assert_eq(iron_sword.stats.get("physical_damage", 0), 10, "Iron sword damage should be 10")

	# 测试传说圣剑
	var legend_sword := database.get_equipment_by_id("sword_legend")
	if legend_sword:
		assert_eq(legend_sword.rarity, EquipmentItem.Rarity.LEGENDARY, "Should be legendary")
		assert_gte(legend_sword.stats.get("physical_damage", 0), 100, "Should have high damage")

## 测试装备等级递增
func test_equipment_level_progression():
	# 获取所有主手武器并按等级排序
	var weapons := database.get_equipment_by_type(EquipmentItem.EquipmentType.MAIN_HAND)

	if weapons.size() >= 2:
		weapons.sort_custom(func(a, b): return a.level_requirement < b.level_requirement)

		# 检查等级递增时属性也应该增加
		for i in range(weapons.size() - 1):
			var current_dmg = weapons[i].stats.get("physical_damage", 0)
			var next_dmg = weapons[i + 1].stats.get("physical_damage", 0)

			if weapons[i].level_requirement < weapons[i + 1].level_requirement:
				assert_lte(current_dmg, next_dmg, "Higher level weapons should have more damage")
