extends GutTest
## 物品堆叠测试

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")

var stack
var item: InventoryItem

func before_each():
	item = InventoryItem.new()
	item.id = "test_item"
	item.item_name = "测试物品"
	item.max_stack_size = 10
	stack = ItemStackClass.new(item, 5)

func after_each():
	stack = null
	item = null

## 测试堆叠初始化
func test_stack_initialization():
	assert_not_null(stack, "Stack should be created")
	assert_eq(stack.quantity, 5, "Initial quantity should be 5")
	assert_eq(stack.item.id, "test_item", "Item should match")

## 测试空堆叠
func test_empty_stack():
	var empty_stack = ItemStackClass.new()
	assert_true(empty_stack.is_empty(), "Empty stack should be empty")

	var stack_with_item = ItemStackClass.new(item, 0)
	assert_true(stack_with_item.is_empty(), "Stack with 0 quantity should be empty")

## 测试添加物品
func test_add_items():
	var overflow = stack.add(3)
	assert_eq(stack.quantity, 8, "Quantity should be 8")
	assert_eq(overflow, 0, "Should have no overflow")

## 测试添加物品溢出
func test_add_items_overflow():
	var overflow = stack.add(8)
	assert_eq(stack.quantity, 10, "Quantity should be capped at max")
	assert_eq(overflow, 3, "Should have 3 overflow")

## 测试移除物品
func test_remove_items():
	var removed = stack.remove(3)
	assert_eq(stack.quantity, 2, "Quantity should be 2")
	assert_eq(removed, 3, "Should have removed 3")

## 测试移除物品超出数量
func test_remove_items_exceeds():
	var removed = stack.remove(10)
	assert_eq(removed, 5, "Should only remove available amount")
	assert_true(stack.is_empty(), "Stack should be empty after removing all")

## 测试堆叠已满
func test_stack_full():
	stack.quantity = 10
	assert_true(stack.is_full(), "Stack should be full")

	stack.quantity = 5
	assert_false(stack.is_full(), "Stack should not be full")

## 测试剩余空间
func test_free_space():
	assert_eq(stack.get_free_space(), 5, "Should have 5 free space")

	stack.quantity = 10
	assert_eq(stack.get_free_space(), 0, "Full stack should have 0 free space")

## 测试可以添加
func test_can_add():
	assert_true(stack.can_add(5), "Should be able to add 5")
	assert_false(stack.can_add(6), "Should not be able to add 6")

## 测试分割堆叠
func test_split_stack():
	var split = stack.split(3)

	assert_not_null(split, "Split stack should be created")
	assert_eq(stack.quantity, 2, "Original should have 2")
	assert_eq(split.quantity, 3, "Split should have 3")
	assert_eq(split.item.id, item.id, "Split item should match")

## 测试分割无效数量
func test_split_invalid():
	var split_zero = stack.split(0)
	assert_true(split_zero.is_empty(), "Split 0 should return empty")

	var split_all = stack.split(5)
	assert_true(split_all.is_empty(), "Split all should return empty")

	var split_exceed = stack.split(10)
	assert_true(split_exceed.is_empty(), "Split exceed should return empty")

## 测试合并堆叠
func test_merge_stacks():
	var stack_b = ItemStackClass.new(item, 3)

	var merged = ItemStackClass.merge(stack, stack_b)

	assert_true(merged, "Merge should succeed")
	assert_eq(stack.quantity, 8, "Stack A should have 8")
	assert_true(stack_b.is_empty(), "Stack B should be empty")

## 测试合并堆叠溢出
func test_merge_stacks_overflow():
	stack.quantity = 7
	var stack_b = ItemStackClass.new(item, 5)

	var merged = ItemStackClass.merge(stack, stack_b)

	assert_true(merged, "Merge should succeed")
	assert_eq(stack.quantity, 10, "Stack A should be full")
	assert_eq(stack_b.quantity, 2, "Stack B should have overflow")

## 测试合并不同物品
func test_merge_different_items():
	var other_item = InventoryItem.new()
	other_item.id = "other_item"
	other_item.max_stack_size = 10

	var stack_b = ItemStackClass.new(other_item, 3)

	var merged = ItemStackClass.merge(stack, stack_b)

	assert_false(merged, "Merge different items should fail")
	assert_eq(stack.quantity, 5, "Stack A should be unchanged")
	assert_eq(stack_b.quantity, 3, "Stack B should be unchanged")

## 测试复制堆叠
func test_duplicate_stack():
	var copy = stack.duplicate_stack()

	assert_not_null(copy, "Copy should be created")
	assert_eq(copy.quantity, stack.quantity, "Quantity should match")
	assert_eq(copy.item.id, stack.item.id, "Item should match")

## 测试显示文本
func test_display_text():
	var text = stack.get_display_text()
	assert_string_contains(text, "测试物品", "Should contain item name")
	assert_string_contains(text, "x5", "Should contain quantity")

	var single_stack = ItemStackClass.new(item, 1)
	var single_text = single_stack.get_display_text()
	assert_eq(single_text, "测试物品", "Single item should not show quantity")

## 测试存档数据
func test_save_data():
	var save_data = stack.to_save_data()

	assert_not_null(save_data, "Save data should be created")
	assert_eq(save_data.get("item_id"), "test_item", "Should save item id")
	assert_eq(save_data.get("quantity"), 5, "Should save quantity")

## 测试从存档加载
func test_load_from_save():
	var save_data = {
		"item_id": "test_item",
		"quantity": 7
	}

	var mock_db = MockItemDatabase.new()
	var loaded = ItemStackClass.from_save_data(save_data, mock_db)

	assert_not_null(loaded, "Loaded stack should be created")
	assert_eq(loaded.quantity, 7, "Quantity should match")
	assert_eq(loaded.item.id, "test_item", "Item id should match")

## Mock 物品数据库用于测试
class MockItemDatabase:
	func get_item_by_id(item_id: String):
		var mock_item = InventoryItem.new()
		mock_item.id = item_id
		mock_item.item_name = "Mock Item"
		mock_item.max_stack_size = 10
		return mock_item
