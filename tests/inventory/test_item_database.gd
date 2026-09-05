extends GutTest
## 物品数据库测试

var database: ItemDatabase

func before_all():
	database = ItemDatabase.new()
	database.load_database()

func after_all():
	database = null

## 测试数据库加载
func test_database_loaded():
	assert_not_null(database, "Database should be created")
	assert_gt(database.get_item_count(), 0, "Should have loaded items")
	assert_eq(database.get_item_count(), 17, "Should have 17 items")

## 测试通过 ID 获取物品
func test_get_item_by_id():
	var item = database.get_item_by_id("health_potion_small")

	assert_not_null(item, "Item should be found")
	assert_eq(item.id, "health_potion_small", "ID should match")
	assert_eq(item.item_name, "小型生命药水", "Name should match")
	assert_eq(item.item_type, InventoryItem.ItemType.CONSUMABLE, "Type should be consumable")
	assert_eq(item.rarity, InventoryItem.Rarity.COMMON, "Rarity should be common")

## 测试获取不存在的物品
func test_get_nonexistent_item():
	var item = database.get_item_by_id("nonexistent")

	assert_null(item, "Should return null for nonexistent item")

## 测试获取所有物品 ID
func test_get_all_item_ids():
	var ids = database.get_all_item_ids()

	assert_not_null(ids, "IDs should be returned")
	assert_eq(ids.size(), 17, "Should have 17 IDs")
	assert_true(ids.has("health_potion_small"), "Should contain health_potion_small")
	assert_true(ids.has("dragon_scale"), "Should contain dragon_scale")

## 测试获取所有物品
func test_get_all_items():
	var items = database.get_all_items()

	assert_not_null(items, "Items should be returned")
	assert_eq(items.size(), 17, "Should have 17 items")

## 测试按类型获取物品 - 消耗品
func test_get_consumables():
	var consumables = database.get_items_by_type(InventoryItem.ItemType.CONSUMABLE)

	assert_not_null(consumables, "Consumables should be returned")
	assert_eq(consumables.size(), 5, "Should have 5 consumables")

	for item in consumables:
		assert_eq(item.item_type, InventoryItem.ItemType.CONSUMABLE, "All should be consumables")

## 测试按类型获取物品 - 材料
func test_get_materials():
	var materials = database.get_items_by_type(InventoryItem.ItemType.MATERIAL)

	assert_not_null(materials, "Materials should be returned")
	assert_eq(materials.size(), 8, "Should have 8 materials")

## 测试按类型获取物品 - 任务物品
func test_get_quest_items():
	var quest_items = database.get_items_by_type(InventoryItem.ItemType.QUEST)

	assert_not_null(quest_items, "Quest items should be returned")
	assert_eq(quest_items.size(), 2, "Should have 2 quest items")

## 测试按类型获取物品 - 货币
func test_get_currency():
	var currency = database.get_items_by_type(InventoryItem.ItemType.CURRENCY)

	assert_not_null(currency, "Currency should be returned")
	assert_eq(currency.size(), 1, "Should have 1 currency")

## 测试按稀有度获取物品 - 普通
func test_get_common_items():
	var common = database.get_items_by_rarity(InventoryItem.Rarity.COMMON)

	assert_not_null(common, "Common items should be returned")
	assert_eq(common.size(), 8, "Should have 8 common items")

## 测试按稀有度获取物品 - 优秀
func test_get_uncommon_items():
	var uncommon = database.get_items_by_rarity(InventoryItem.Rarity.UNCOMMON)

	assert_not_null(uncommon, "Uncommon items should be returned")
	assert_eq(uncommon.size(), 4, "Should have 4 uncommon items")

## 测试按稀有度获取物品 - 稀有
func test_get_rare_items():
	var rare = database.get_items_by_rarity(InventoryItem.Rarity.RARE)

	assert_not_null(rare, "Rare items should be returned")
	assert_eq(rare.size(), 3, "Should have 3 rare items")

## 测试按稀有度获取物品 - 史诗
func test_get_epic_items():
	var epic = database.get_items_by_rarity(InventoryItem.Rarity.EPIC)

	assert_not_null(epic, "Epic items should be returned")
	assert_eq(epic.size(), 1, "Should have 1 epic item")

## 测试按稀有度获取物品 - 传说
func test_get_legendary_items():
	var legendary = database.get_items_by_rarity(InventoryItem.Rarity.LEGENDARY)

	assert_not_null(legendary, "Legendary items should be returned")
	assert_eq(legendary.size(), 1, "Should have 1 legendary item")

## 测试获取随机物品
func test_get_random_item():
	var item = database.get_random_item()

	assert_not_null(item, "Random item should be returned")
	assert_true(database.has_item(item.id), "Random item should exist in database")

## 测试获取随机消耗品
func test_get_random_consumable():
	var item = database.get_random_item_by_type(InventoryItem.ItemType.CONSUMABLE)

	assert_not_null(item, "Random consumable should be returned")
	assert_eq(item.item_type, InventoryItem.ItemType.CONSUMABLE, "Should be a consumable")

## 测试获取随机稀有物品
func test_get_random_rare_item():
	var item = database.get_random_item_by_rarity(InventoryItem.Rarity.RARE)

	assert_not_null(item, "Random rare item should be returned")
	assert_eq(item.rarity, InventoryItem.Rarity.RARE, "Should be rare")

## 测试加权随机物品
func test_get_weighted_random_item():
	# 运行多次确保权重系统工作
	var rarity_counts = {}
	for rarity in InventoryItem.Rarity.values():
		rarity_counts[rarity] = 0

	for i in range(100):
		var item = database.get_random_item_by_rarity_weights()
		if item:
			rarity_counts[item.rarity] += 1

	# 普通物品应该最多
	assert_gt(rarity_counts[InventoryItem.Rarity.COMMON], 30, "Common should be most frequent")
	# 传说物品应该最少
	assert_lt(rarity_counts[InventoryItem.Rarity.LEGENDARY], 10, "Legendary should be rare")

## 测试自定义权重
func test_weighted_random_with_custom_weights():
	var custom_weights = {
		InventoryItem.Rarity.LEGENDARY: 50.0,  # 提高传说概率
		InventoryItem.Rarity.COMMON: 10.0      # 降低普通概率
	}

	var legendary_count = 0

	for i in range(100):
		var item = database.get_random_item_by_rarity_weights(custom_weights)
		if item and item.rarity == InventoryItem.Rarity.LEGENDARY:
			legendary_count += 1

	# 使用自定义权重后，传说物品应该更常见
	assert_gt(legendary_count, 10, "Legendary should be more common with custom weights")

## 测试物品是否存在
func test_has_item():
	assert_true(database.has_item("health_potion_small"), "Should have health_potion_small")
	assert_true(database.has_item("dragon_scale"), "Should have dragon_scale")
	assert_false(database.has_item("nonexistent"), "Should not have nonexistent item")

## 测试物品计数
func test_item_counts():
	assert_eq(database.get_item_count(), 17, "Total should be 17")
	assert_eq(database.get_type_count(InventoryItem.ItemType.CONSUMABLE), 5, "5 consumables")
	assert_eq(database.get_type_count(InventoryItem.ItemType.MATERIAL), 8, "8 materials")
	assert_eq(database.get_type_count(InventoryItem.ItemType.QUEST), 2, "2 quest items")
	assert_eq(database.get_type_count(InventoryItem.ItemType.CURRENCY), 1, "1 currency")

## 测试物品复制独立性
func test_item_independence():
	var item1 = database.get_item_by_id("health_potion_small")
	var item2 = database.get_item_by_id("health_potion_small")

	assert_not_null(item1, "Item 1 should exist")
	assert_not_null(item2, "Item 2 should exist")

	# 修改一个不应影响另一个
	item1.item_name = "修改后的名称"

	assert_ne(item1.item_name, item2.item_name, "Items should be independent copies")
	assert_eq(item2.item_name, "小型生命药水", "Item 2 should keep original name")

## 测试物品数据完整性 - 小型生命药水
func test_health_potion_small_data():
	var item = database.get_item_by_id("health_potion_small")

	assert_eq(item.max_stack_size, 20, "Stack size should be 20")
	assert_eq(item.sell_price, 10, "Sell price should be 10")
	assert_eq(item.buy_price, 25, "Buy price should be 25")

## 测试物品数据完整性 - 龙鳞
func test_dragon_scale_data():
	var item = database.get_item_by_id("dragon_scale")

	assert_eq(item.item_type, InventoryItem.ItemType.MATERIAL, "Should be material")
	assert_eq(item.rarity, InventoryItem.Rarity.LEGENDARY, "Should be legendary")
	assert_eq(item.max_stack_size, 10, "Stack size should be 10")
	assert_eq(item.sell_price, 1000, "Sell price should be 1000")

## 测试物品数据完整性 - 金币
func test_gold_coin_data():
	var item = database.get_item_by_id("gold_coin")

	assert_eq(item.item_type, InventoryItem.ItemType.CURRENCY, "Should be currency")
	assert_eq(item.max_stack_size, 9999, "Stack size should be 9999")
