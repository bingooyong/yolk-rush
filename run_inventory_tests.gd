extends SceneTree
## 库存系统测试运行器

func _init() -> void:
	print("=== Inventory System Test Suite ===")
	print("Running manual test verification...\n")
	
	var test_results := {
		"passed": 0,
		"failed": 0,
		"total": 0
	}
	
	# 测试 ItemStack
	_test_item_stack(test_results)
	
	# 测试 InventorySystem
	_test_inventory_system(test_results)
	
	# 测试 QuickBarSystem
	_test_quick_bar_system(test_results)
	
	# 测试 ItemDatabase
	_test_item_database(test_results)
	
	# 测试集成
	_test_integration(test_results)
	
	print("\n=== Test Summary ===")
	print("Total: %d" % test_results["total"])
	print("Passed: %d" % test_results["passed"])
	print("Failed: %d" % test_results["failed"])
	
	if test_results["failed"] == 0:
		print("\n✓ All tests passed!")
		quit(0)
	else:
		print("\n✗ Some tests failed!")
		quit(1)

func _test_item_stack(results: Dictionary) -> void:
	print("--- Testing ItemStack ---")
	
	var item = InventoryItem.new()
	item.id = "test_item"
	item.item_name = "Test Item"
	item.max_stack_size = 50
	
	var stack = ItemStack.new(item, 10)
	
	_assert("ItemStack initial quantity", stack.quantity == 10, results)
	_assert("ItemStack is not empty", not stack.is_empty(), results)
	_assert("ItemStack can add 20", stack.can_add(20), results)
	
	var overflow = stack.add(30)
	_assert("ItemStack add returns 0 overflow", overflow == 0, results)
	_assert("ItemStack quantity after add", stack.quantity == 40, results)
	
	var removed = stack.remove(15)
	_assert("ItemStack remove 15", removed == 15, results)
	_assert("ItemStack quantity after remove", stack.quantity == 25, results)
	
	var split = stack.split(10)
	_assert("ItemStack split not empty", not split.is_empty(), results)
	_assert("ItemStack split quantity", split.quantity == 10, results)
	_assert("ItemStack quantity after split", stack.quantity == 15, results)
	
	print()

func _test_inventory_system(results: Dictionary) -> void:
	print("--- Testing InventorySystem ---")
	
	var inventory = InventorySystem.new()
	inventory._initialize_slots()
	
	_assert("Inventory initial slots", inventory.get_empty_slot_count() == 48, results)
	_assert("Inventory not full", not inventory.is_full(), results)
	
	var item = InventoryItem.new()
	item.id = "test_consumable"
	item.item_name = "Test Consumable"
	item.item_type = InventoryItem.ItemType.CONSUMABLE
	item.max_stack_size = 99
	
	var added = inventory.add_item(item, 50)
	_assert("Inventory add item", added, results)
	_assert("Inventory item count", inventory.get_item_count(item.id) == 50, results)
	_assert("Inventory empty slots", inventory.get_empty_slot_count() == 47, results)
	
	var removed = inventory.remove_item(item.id, 20)
	_assert("Inventory remove 20", removed == 20, results)
	_assert("Inventory remaining", inventory.get_item_count(item.id) == 30, results)
	
	var slot = inventory.find_empty_slot()
	_assert("Inventory find empty slot", slot == 1, results)
	
	inventory.clear_all()
	_assert("Inventory cleared", inventory.get_empty_slot_count() == 48, results)
	
	inventory.free()
	print()

func _test_quick_bar_system(results: Dictionary) -> void:
	print("--- Testing QuickBarSystem ---")
	
	var inventory = InventorySystem.new()
	inventory._initialize_slots()
	
	var quick_bar = QuickBarSystem.new()
	quick_bar._initialize_quick_bar()
	quick_bar.set_inventory(inventory)
	
	_assert("QuickBar 8 slots", quick_bar.QUICK_BAR_SLOTS == 8, results)
	
	var item = InventoryItem.new()
	item.id = "test_potion"
	item.item_name = "Test Potion"
	item.item_type = InventoryItem.ItemType.CONSUMABLE
	item.max_stack_size = 99
	
	inventory.add_item(item, 10)
	
	var bound = quick_bar.bind_slot(0, 0)
	_assert("QuickBar bind slot", bound, results)
	_assert("QuickBar bound to 0", quick_bar.get_bound_inventory_slot(0) == 0, results)
	
	var stack = quick_bar.get_quick_bar_stack(0)
	_assert("QuickBar stack not empty", not stack.is_empty(), results)
	_assert("QuickBar stack quantity", stack.quantity == 10, results)
	
	var used = quick_bar.use_quick_bar_item(0)
	_assert("QuickBar use item", used, results)
	_assert("QuickBar item count after use", inventory.get_item_count(item.id) == 9, results)
	
	var auto_slot = quick_bar.auto_bind_item(0)
	_assert("QuickBar auto bind", auto_slot == 1, results)
	
	quick_bar.free()
	inventory.free()
	print()

func _test_item_database(results: Dictionary) -> void:
	print("--- Testing ItemDatabase ---")
	
	var database = ItemDatabase.new()
	var loaded = database.load_database()
	
	_assert("Database loaded", loaded, results)
	_assert("Database has items", database.get_item_count() > 0, results)
	
	var potion = database.get_item_by_id("health_potion_minor")
	_assert("Database get potion", potion != null, results)
	
	if potion:
		_assert("Potion ID correct", potion.id == "health_potion_minor", results)
		_assert("Potion name correct", potion.item_name == "小型生命药水", results)
		_assert("Potion is consumable", potion.item_type == InventoryItem.ItemType.CONSUMABLE, results)
	
	var consumables = database.get_items_by_type(InventoryItem.ItemType.CONSUMABLE)
	_assert("Database has consumables", consumables.size() > 0, results)
	
	var common_items = database.get_items_by_rarity(InventoryItem.Rarity.COMMON)
	_assert("Database has common items", common_items.size() > 0, results)
	
	var random_item = database.get_random_item()
	_assert("Database random item", random_item != null, results)
	
	database.free()
	print()

func _test_integration(results: Dictionary) -> void:
	print("--- Testing Integration ---")
	
	var database = ItemDatabase.new()
	database.load_database()
	
	var inventory = InventorySystem.new()
	inventory._initialize_slots()
	inventory.set_database(database)
	
	var quick_bar = QuickBarSystem.new()
	quick_bar._initialize_quick_bar()
	quick_bar.set_inventory(inventory)
	
	# 完整工作流测试
	var health = database.get_item_by_id("health_potion_minor")
	var mana = database.get_item_by_id("mana_potion_minor")
	
	_assert("Integration: health potion exists", health != null, results)
	_assert("Integration: mana potion exists", mana != null, results)
	
	if health and mana:
		inventory.add_item(health, 20)
		inventory.add_item(mana, 15)
		
		_assert("Integration: health count", inventory.get_item_count(health.id) == 20, results)
		_assert("Integration: mana count", inventory.get_item_count(mana.id) == 15, results)
		
		quick_bar.bind_slot(0, 0)
		quick_bar.bind_slot(1, 1)
		
		quick_bar.use_quick_bar_item(0)
		_assert("Integration: after use health", inventory.get_item_count(health.id) == 19, results)
		
		# 存档和加载
		var inv_save = inventory.get_save_data()
		var qb_save = quick_bar.get_save_data()
		
		_assert("Integration: save data has slots", inv_save.has("slots"), results)
		_assert("Integration: save data has bindings", qb_save.has("bindings"), results)
		
		inventory.clear_all()
		quick_bar.clear_all()
		
		inventory.load_save_data(inv_save)
		quick_bar.load_save_data(qb_save)
		
		_assert("Integration: restore health count", inventory.get_item_count(health.id) == 19, results)
		_assert("Integration: restore binding", quick_bar.get_bound_inventory_slot(0) == 0, results)
	
	quick_bar.free()
	inventory.free()
	database.free()
	print()

func _assert(test_name: String, condition: bool, results: Dictionary) -> void:
	results["total"] += 1
	
	if condition:
		results["passed"] += 1
		print("  ✓ %s" % test_name)
	else:
		results["failed"] += 1
		print("  ✗ %s" % test_name)
