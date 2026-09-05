extends GutTest
## 库存系统测试

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")

var inventory: InventorySystem
var test_item: InventoryItem
var stackable_item: InventoryItem

func before_each():
	inventory = InventorySystem.new()
	inventory._initialize_slots()

	test_item = InventoryItem.new()
	test_item.id = "test_item"
	test_item.item_name = "测试物品"
	test_item.max_stack_size = 1

	stackable_item = InventoryItem.new()
	stackable_item.id = "stackable"
	stackable_item.item_name = "可堆叠物品"
	stackable_item.max_stack_size = 20

func after_each():
	inventory = null
	test_item = null
	stackable_item = null

## 测试初始化
func test_initialization():
	assert_not_null(inventory, "Inventory should be created")
	assert_eq(inventory.slots.size(), 48, "Should have 48 slots")
	assert_eq(inventory.get_empty_slot_count(), 48, "All slots should be empty")

## 测试添加单个物品
func test_add_single_item():
	var success = inventory.add_item(test_item, 1)

	assert_true(success, "Should add item successfully")
	assert_eq(inventory.get_item_count(test_item.id), 1, "Should have 1 item")
	assert_eq(inventory.get_empty_slot_count(), 47, "Should have 47 empty slots")

## 测试添加可堆叠物品
func test_add_stackable_items():
	var success = inventory.add_item(stackable_item, 15)

	assert_true(success, "Should add items successfully")
	assert_eq(inventory.get_item_count(stackable_item.id), 15, "Should have 15 items")

## 测试堆叠合并
func test_stack_merging():
	inventory.add_item(stackable_item, 10)
	inventory.add_item(stackable_item, 5)

	assert_eq(inventory.get_item_count(stackable_item.id), 15, "Should have 15 total")
	# 应该只占用一个槽位
	assert_eq(inventory.get_empty_slot_count(), 47, "Should use only one slot")

## 测试堆叠溢出到新槽位
func test_stack_overflow():
	inventory.add_item(stackable_item, 25)

	assert_eq(inventory.get_item_count(stackable_item.id), 25, "Should have 25 items")
	# 应该占用两个槽位 (20 + 5)
	assert_eq(inventory.get_empty_slot_count(), 46, "Should use two slots")

## 测试背包已满
func test_inventory_full():
	# 填满背包
	for i in range(48):
		inventory.add_item(test_item.duplicate_item(), 1)

	assert_true(inventory.is_full(), "Inventory should be full")
	assert_eq(inventory.get_empty_slot_count(), 0, "Should have no empty slots")

	# 尝试添加更多物品
	var success = inventory.add_item(test_item.duplicate_item(), 1)
	assert_false(success, "Should fail to add when full")

## 测试移除物品
func test_remove_item():
	inventory.add_item(stackable_item, 10)

	var removed = inventory.remove_item(stackable_item.id, 5)

	assert_eq(removed, 5, "Should remove 5 items")
	assert_eq(inventory.get_item_count(stackable_item.id), 5, "Should have 5 remaining")

## 测试移除所有物品
func test_remove_all_items():
	inventory.add_item(stackable_item, 10)

	var removed = inventory.remove_item(stackable_item.id, 10)

	assert_eq(removed, 10, "Should remove all 10")
	assert_eq(inventory.get_item_count(stackable_item.id), 0, "Should have none left")
	assert_true(inventory.is_slot_empty(0), "Slot should be empty")

## 测试从槽位移除
func test_remove_from_slot():
	inventory.add_item(stackable_item, 10)

	var removed = inventory.remove_from_slot(0, 3)

	assert_eq(removed, 3, "Should remove 3")
	assert_eq(inventory.get_slot(0).quantity, 7, "Should have 7 left")

## 测试查找空槽位
func test_find_empty_slot():
	var slot = inventory.find_empty_slot()
	assert_eq(slot, 0, "First empty should be 0")

	inventory.add_item(test_item, 1)
	slot = inventory.find_empty_slot()
	assert_eq(slot, 1, "Next empty should be 1")

## 测试交换槽位
func test_swap_slots():
	var item_a = test_item.duplicate_item()
	item_a.id = "item_a"
	var item_b = test_item.duplicate_item()
	item_b.id = "item_b"

	inventory.add_item(item_a, 1)
	inventory.add_item(item_b, 1)

	var success = inventory.swap_slots(0, 1)

	assert_true(success, "Swap should succeed")
	assert_eq(inventory.get_slot(0).item.id, "item_b", "Slot 0 should have item_b")
	assert_eq(inventory.get_slot(1).item.id, "item_a", "Slot 1 should have item_a")

## 测试合并槽位
func test_merge_slots():
	inventory.add_item(stackable_item, 10)
	inventory.add_item(stackable_item, 5)

	# 手动将它们放入不同槽位
	var stack_b = inventory.slots[0].split(5)
	inventory.slots[1] = stack_b

	var success = inventory.merge_slots(0, 1)

	assert_true(success, "Merge should succeed")
	assert_eq(inventory.get_slot(0).quantity, 10, "Slot 0 should have 10")
	assert_true(inventory.is_slot_empty(1), "Slot 1 should be empty")

## 测试分割槽位
func test_split_slot():
	inventory.add_item(stackable_item, 10)

	var success = inventory.split_slot(0, 3, 1)

	assert_true(success, "Split should succeed")
	assert_eq(inventory.get_slot(0).quantity, 7, "Original should have 7")
	assert_eq(inventory.get_slot(1).quantity, 3, "Split should have 3")

## 测试分割到非空槽位失败
func test_split_to_non_empty_fails():
	inventory.add_item(stackable_item, 10)
	inventory.add_item(test_item, 1)

	var success = inventory.split_slot(0, 3, 1)

	assert_false(success, "Split to non-empty should fail")

## 测试按稀有度排序
func test_sort_by_rarity():
	var common = test_item.duplicate_item()
	common.id = "common"
	common.rarity = InventoryItem.Rarity.COMMON

	var rare = test_item.duplicate_item()
	rare.id = "rare"
	rare.rarity = InventoryItem.Rarity.RARE

	var epic = test_item.duplicate_item()
	epic.id = "epic"
	epic.rarity = InventoryItem.Rarity.EPIC

	inventory.add_item(common, 1)
	inventory.add_item(rare, 1)
	inventory.add_item(epic, 1)

	inventory.sort_by("rarity")

	# Epic 应该在前 (最高稀有度)
	assert_eq(inventory.get_slot(0).item.id, "epic", "Epic should be first")
	assert_eq(inventory.get_slot(1).item.id, "rare", "Rare should be second")
	assert_eq(inventory.get_slot(2).item.id, "common", "Common should be third")

## 测试按类型排序
func test_sort_by_type():
	var consumable = test_item.duplicate_item()
	consumable.id = "consumable"
	consumable.item_type = InventoryItem.ItemType.CONSUMABLE

	var material = test_item.duplicate_item()
	material.id = "material"
	material.item_type = InventoryItem.ItemType.MATERIAL

	var equipment = test_item.duplicate_item()
	equipment.id = "equipment"
	equipment.item_type = InventoryItem.ItemType.EQUIPMENT

	inventory.add_item(material, 1)
	inventory.add_item(consumable, 1)
	inventory.add_item(equipment, 1)

	inventory.sort_by("type")

	# Equipment (0) < Consumable (1) < Material (2)
	assert_eq(inventory.get_slot(0).item.item_type, InventoryItem.ItemType.EQUIPMENT)
	assert_eq(inventory.get_slot(1).item.item_type, InventoryItem.ItemType.CONSUMABLE)
	assert_eq(inventory.get_slot(2).item.item_type, InventoryItem.ItemType.MATERIAL)

## 测试按名称排序
func test_sort_by_name():
	var item_c = test_item.duplicate_item()
	item_c.id = "c"
	item_c.item_name = "C物品"

	var item_a = test_item.duplicate_item()
	item_a.id = "a"
	item_a.item_name = "A物品"

	var item_b = test_item.duplicate_item()
	item_b.id = "b"
	item_b.item_name = "B物品"

	inventory.add_item(item_c, 1)
	inventory.add_item(item_a, 1)
	inventory.add_item(item_b, 1)

	inventory.sort_by("name")

	assert_eq(inventory.get_slot(0).item.item_name, "A物品")
	assert_eq(inventory.get_slot(1).item.item_name, "B物品")
	assert_eq(inventory.get_slot(2).item.item_name, "C物品")

## 测试按数量排序
func test_sort_by_quantity():
	inventory.add_item(stackable_item.duplicate_item(), 5)
	inventory.add_item(stackable_item.duplicate_item(), 15)
	inventory.add_item(stackable_item.duplicate_item(), 10)

	inventory.sort_by("quantity")

	# 数量从大到小
	assert_eq(inventory.get_slot(0).quantity, 15)
	assert_eq(inventory.get_slot(1).quantity, 10)
	assert_eq(inventory.get_slot(2).quantity, 5)

## 测试清空背包
func test_clear_all():
	inventory.add_item(test_item, 1)
	inventory.add_item(stackable_item, 10)

	inventory.clear_all()

	assert_eq(inventory.get_empty_slot_count(), 48, "All slots should be empty")
	assert_eq(inventory.get_item_count(test_item.id), 0, "Should have no items")

## 测试按类型过滤
func test_get_items_by_type():
	var consumable = test_item.duplicate_item()
	consumable.item_type = InventoryItem.ItemType.CONSUMABLE

	var material = test_item.duplicate_item()
	material.item_type = InventoryItem.ItemType.MATERIAL

	inventory.add_item(consumable, 1)
	inventory.add_item(material, 1)
	inventory.add_item(consumable.duplicate_item(), 1)

	var consumables = inventory.get_items_by_type(InventoryItem.ItemType.CONSUMABLE)

	assert_eq(consumables.size(), 2, "Should have 2 consumables")

## 测试背包使用率
func test_usage_percentage():
	assert_almost_eq(inventory.get_usage_percentage(), 0.0, 0.01, "Empty should be 0%")

	inventory.add_item(test_item, 1)
	var usage = inventory.get_usage_percentage()
	assert_almost_eq(usage, 2.08, 0.01, "1/48 should be ~2.08%")

	# 填满一半
	for i in range(23):
		inventory.add_item(test_item.duplicate_item(), 1)

	usage = inventory.get_usage_percentage()
	assert_almost_eq(usage, 50.0, 0.1, "24/48 should be 50%")

## 测试存档和加载
func test_save_and_load():
	inventory.add_item(test_item, 1)
	inventory.add_item(stackable_item, 10)

	var save_data = inventory.get_save_data()

	assert_not_null(save_data, "Save data should be created")
	assert_true(save_data.has("slots"), "Should have slots data")

	var new_inventory = InventorySystem.new()
	new_inventory._initialize_slots()

	var mock_db = MockItemDatabase.new()
	new_inventory.set_database(mock_db)
	new_inventory.load_save_data(save_data)

	# 验证加载后的数据（注意：由于没有真实数据库，物品ID可能不匹配）
	assert_eq(new_inventory.get_empty_slot_count(), 46, "Should have same empty slot count")

## Mock 物品数据库
class MockItemDatabase:
	func get_item_by_id(item_id: String):
		var mock_item = InventoryItem.new()
		mock_item.id = item_id
		mock_item.item_name = "Mock " + item_id
		mock_item.max_stack_size = 20
		return mock_item
