extends GutTest
## 库存物品测试

var item: InventoryItem

func before_each():
	item = InventoryItem.new()

func after_each():
	item = null

## 测试物品初始化
func test_item_initialization():
	assert_not_null(item, "Item should be created")
	assert_eq(item.id, "", "Default id should be empty")
	assert_eq(item.item_name, "", "Default name should be empty")
	assert_eq(item.max_stack_size, 99, "Default stack size should be 99")

## 测试物品可堆叠性
func test_item_stackable():
	item.max_stack_size = 1
	assert_false(item.is_stackable(), "Item with stack size 1 should not be stackable")

	item.max_stack_size = 20
	assert_true(item.is_stackable(), "Item with stack size > 1 should be stackable")

## 测试稀有度颜色
func test_rarity_colors():
	item.rarity = InventoryItem.Rarity.COMMON
	assert_eq(item.get_rarity_color(), Color.WHITE, "Common should be white")

	item.rarity = InventoryItem.Rarity.LEGENDARY
	var legendary_color = item.get_rarity_color()
	assert_gt(legendary_color.r, 0.9, "Legendary should be orangish")

## 测试稀有度文本
func test_rarity_text():
	item.rarity = InventoryItem.Rarity.COMMON
	assert_eq(item.get_rarity_text(), "普通", "Common text should be correct")

	item.rarity = InventoryItem.Rarity.EPIC
	assert_eq(item.get_rarity_text(), "史诗", "Epic text should be correct")

	item.rarity = InventoryItem.Rarity.LEGENDARY
	assert_eq(item.get_rarity_text(), "传说", "Legendary text should be correct")

## 测试类型文本
func test_type_text():
	item.item_type = InventoryItem.ItemType.CONSUMABLE
	assert_eq(item.get_type_text(), "消耗品", "Consumable text should be correct")

	item.item_type = InventoryItem.ItemType.MATERIAL
	assert_eq(item.get_type_text(), "材料", "Material text should be correct")

	item.item_type = InventoryItem.ItemType.QUEST
	assert_eq(item.get_type_text(), "任务物品", "Quest text should be correct")

## 测试 Tooltip 文本生成
func test_tooltip_generation():
	item.item_name = "测试物品"
	item.item_type = InventoryItem.ItemType.CONSUMABLE
	item.rarity = InventoryItem.Rarity.RARE
	item.description = "这是一个测试物品"
	item.sell_price = 100

	var tooltip = item.get_tooltip_text()
	assert_string_contains(tooltip, "测试物品", "Tooltip should contain item name")
	assert_string_contains(tooltip, "消耗品", "Tooltip should contain type")
	assert_string_contains(tooltip, "稀有", "Tooltip should contain rarity")
	assert_string_contains(tooltip, "这是一个测试物品", "Tooltip should contain description")
	assert_string_contains(tooltip, "100", "Tooltip should contain price")

## 测试物品复制
func test_item_duplication():
	item.id = "test_item"
	item.item_name = "原始物品"
	item.item_type = InventoryItem.ItemType.MATERIAL
	item.rarity = InventoryItem.Rarity.UNCOMMON
	item.max_stack_size = 50
	item.sell_price = 25

	var copy = item.duplicate_item()

	assert_not_null(copy, "Copy should be created")
	assert_eq(copy.id, item.id, "ID should match")
	assert_eq(copy.item_name, item.item_name, "Name should match")
	assert_eq(copy.item_type, item.item_type, "Type should match")
	assert_eq(copy.rarity, item.rarity, "Rarity should match")
	assert_eq(copy.max_stack_size, item.max_stack_size, "Stack size should match")
	assert_eq(copy.sell_price, item.sell_price, "Sell price should match")

## 测试存档数据
func test_save_data():
	item.id = "save_test"

	var save_data = item.to_save_data()

	assert_not_null(save_data, "Save data should be created")
	assert_true(save_data is Dictionary, "Save data should be a dictionary")
	assert_eq(save_data.get("id"), "save_test", "Save data should contain id")
