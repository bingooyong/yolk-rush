extends GutTest
## 快捷栏系统测试

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")

var quick_bar: QuickBarSystem
var inventory: InventorySystem
var consumable: InventoryItem

func before_each():
	quick_bar = QuickBarSystem.new()
	quick_bar._initialize_quick_bar()

	inventory = InventorySystem.new()
	inventory._initialize_slots()

	quick_bar.set_inventory(inventory)

	consumable = InventoryItem.new()
	consumable.id = "health_potion"
	consumable.item_name = "生命药水"
	consumable.item_type = InventoryItem.ItemType.CONSUMABLE
	consumable.max_stack_size = 20

func after_each():
	quick_bar = null
	inventory = null
	consumable = null

## 测试初始化
func test_initialization():
	assert_not_null(quick_bar, "QuickBar should be created")
	assert_eq(quick_bar.quick_bar_slots.size(), 8, "Should have 8 slots")

	for i in range(8):
		assert_eq(quick_bar.get_bound_inventory_slot(i), -1, "All slots should be unbound")

## 测试绑定槽位
func test_bind_slot():
	inventory.add_item(consumable, 5)

	var success = quick_bar.bind_slot(0, 0)

	assert_true(success, "Bind should succeed")
	assert_eq(quick_bar.get_bound_inventory_slot(0), 0, "Should be bound to inventory slot 0")

## 测试绑定无效快捷栏槽位
func test_bind_invalid_quick_bar_slot():
	var success = quick_bar.bind_slot(10, 0)

	assert_false(success, "Should fail for invalid quick bar slot")

## 测试绑定无效背包槽位
func test_bind_invalid_inventory_slot():
	var success = quick_bar.bind_slot(0, 100)

	assert_false(success, "Should fail for invalid inventory slot")

## 测试解绑槽位
func test_unbind_slot():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)

	var success = quick_bar.unbind_slot(0)

	assert_true(success, "Unbind should succeed")
	assert_eq(quick_bar.get_bound_inventory_slot(0), -1, "Should be unbound")

## 测试获取快捷栏堆叠
func test_get_quick_bar_stack():
	inventory.add_item(consumable, 10)
	quick_bar.bind_slot(0, 0)

	var stack = quick_bar.get_quick_bar_stack(0)

	assert_not_null(stack, "Stack should be returned")
	assert_eq(stack.quantity, 10, "Should have 10 items")
	assert_eq(stack.item.id, "health_potion", "Item should match")

## 测试空快捷栏槽位
func test_empty_quick_bar_slot():
	assert_true(quick_bar.is_quick_bar_slot_empty(0), "Unbound slot should be empty")

	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)

	assert_false(quick_bar.is_quick_bar_slot_empty(0), "Bound slot with items should not be empty")

## 测试使用快捷栏物品
func test_use_quick_bar_item():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)

	var success = quick_bar.use_quick_bar_item(0)

	assert_true(success, "Use should succeed")
	assert_eq(inventory.get_item_count("health_potion"), 4, "Should have 4 left")

## 测试使用空槽位
func test_use_empty_slot():
	var success = quick_bar.use_quick_bar_item(0)

	assert_false(success, "Should fail on empty slot")

## 测试使用非消耗品
func test_use_non_consumable():
	var equipment = InventoryItem.new()
	equipment.id = "sword"
	equipment.item_name = "剑"
	equipment.item_type = InventoryItem.ItemType.EQUIPMENT
	equipment.max_stack_size = 1

	inventory.add_item(equipment, 1)
	quick_bar.bind_slot(0, 0)

	var success = quick_bar.use_quick_bar_item(0)

	assert_false(success, "Should fail for non-consumable")

## 测试交换快捷栏槽位
func test_swap_quick_bar_slots():
	inventory.add_item(consumable, 5)

	var potion2 = consumable.duplicate_item()
	potion2.id = "mana_potion"
	inventory.add_item(potion2, 3)

	quick_bar.bind_slot(0, 0)
	quick_bar.bind_slot(1, 1)

	var success = quick_bar.swap_quick_bar_slots(0, 1)

	assert_true(success, "Swap should succeed")
	assert_eq(quick_bar.get_bound_inventory_slot(0), 1, "Slot 0 should point to inv 1")
	assert_eq(quick_bar.get_bound_inventory_slot(1), 0, "Slot 1 should point to inv 0")

## 测试自动绑定物品
func test_auto_bind_item():
	inventory.add_item(consumable, 5)

	var slot_index = quick_bar.auto_bind_item(0)

	assert_eq(slot_index, 0, "Should bind to first empty slot")
	assert_eq(quick_bar.get_bound_inventory_slot(0), 0, "Should be bound")

## 测试自动绑定已满
func test_auto_bind_when_full():
	inventory.add_item(consumable, 5)

	# 填满快捷栏
	for i in range(8):
		quick_bar.bind_slot(i, 0)

	var slot_index = quick_bar.auto_bind_item(0)

	assert_eq(slot_index, -1, "Should return -1 when full")

## 测试清空快捷栏
func test_clear_all():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)
	quick_bar.bind_slot(1, 0)

	quick_bar.clear_all()

	for i in range(8):
		assert_eq(quick_bar.get_bound_inventory_slot(i), -1, "All slots should be unbound")

## 测试清理无效绑定
func test_cleanup_invalid_bindings():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)
	quick_bar.bind_slot(1, 1)  # 绑定到空槽位

	quick_bar.cleanup_invalid_bindings()

	assert_eq(quick_bar.get_bound_inventory_slot(0), 0, "Valid binding should remain")
	assert_eq(quick_bar.get_bound_inventory_slot(1), -1, "Invalid binding should be cleared")

## 测试获取所有绑定
func test_get_all_bindings():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)
	quick_bar.bind_slot(2, 1)

	var bindings = quick_bar.get_all_bindings()

	assert_not_null(bindings, "Bindings should be returned")
	assert_eq(bindings.size(), 8, "Should have 8 entries")
	assert_eq(bindings[0], 0, "Slot 0 should be bound to inv 0")
	assert_eq(bindings[2], 1, "Slot 2 should be bound to inv 1")
	assert_eq(bindings[3], -1, "Slot 3 should be unbound")

## 测试存档数据
func test_save_data():
	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)
	quick_bar.bind_slot(3, 2)

	var save_data = quick_bar.get_save_data()

	assert_not_null(save_data, "Save data should be created")
	assert_true(save_data.has("bindings"), "Should have bindings")
	assert_eq(save_data["bindings"][0], 0, "Should save slot 0 binding")
	assert_eq(save_data["bindings"][3], 2, "Should save slot 3 binding")

## 测试加载存档
func test_load_save_data():
	var save_data = {
		"bindings": [0, -1, 1, -1, -1, -1, -1, 2]
	}

	quick_bar.load_save_data(save_data)

	assert_eq(quick_bar.get_bound_inventory_slot(0), 0, "Slot 0 should be loaded")
	assert_eq(quick_bar.get_bound_inventory_slot(1), -1, "Slot 1 should be unbound")
	assert_eq(quick_bar.get_bound_inventory_slot(2), 1, "Slot 2 should be loaded")
	assert_eq(quick_bar.get_bound_inventory_slot(7), 2, "Slot 7 should be loaded")

## 测试使用物品后清理绑定
func test_use_item_until_empty():
	inventory.add_item(consumable, 1)
	quick_bar.bind_slot(0, 0)

	quick_bar.use_quick_bar_item(0)

	# 物品用完后，绑定应该仍然存在但指向空槽位
	assert_eq(quick_bar.get_bound_inventory_slot(0), 0, "Binding should still exist")
	assert_true(quick_bar.is_quick_bar_slot_empty(0), "But slot should be empty")

	# 清理无效绑定
	quick_bar.cleanup_invalid_bindings()
	assert_eq(quick_bar.get_bound_inventory_slot(0), -1, "Binding should be cleaned up")

## 测试信号发射
func test_signals():
	watch_signals(quick_bar)

	inventory.add_item(consumable, 5)
	quick_bar.bind_slot(0, 0)

	assert_signal_emitted(quick_bar, "quick_bar_changed", "Should emit quick_bar_changed on bind")

	quick_bar.use_quick_bar_item(0)

	assert_signal_emitted(quick_bar, "item_used", "Should emit item_used on use")
	assert_signal_emit_count(quick_bar, "quick_bar_changed", 2, "Should emit changed again after use")
