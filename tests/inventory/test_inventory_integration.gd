extends Node
## 库存系统集成测试场景

var inventory: InventorySystem
var quick_bar: QuickBarSystem
var item_database: ItemDatabase

func _ready():
	print("\n=== 开始库存系统集成测试 ===\n")

	# 初始化系统
	setup_systems()

	# 运行测试
	test_basic_inventory_operations()
	test_stacking_behavior()
	test_quick_bar_integration()
	test_item_usage()
	test_sorting_and_filtering()
	test_save_load_system()

	print("\n=== 所有测试完成 ===\n")
	get_tree().quit()

func setup_systems():
	print(">>> 初始化系统")

	item_database = ItemDatabase.new()
	add_child(item_database)
	item_database.load_database()

	inventory = InventorySystem.new()
	add_child(inventory)
	inventory.set_database(item_database)

	quick_bar = QuickBarSystem.new()
	add_child(quick_bar)
	quick_bar.set_inventory(inventory)

	print("✓ 系统初始化完成\n")

func test_basic_inventory_operations():
	print(">>> 测试基础库存操作")

	# 测试添加物品
	var health_potion = item_database.get_item_by_id("health_potion_small")
	check_assert(health_potion != null, "应该能获取生命药水")

	var success = inventory.add_item(health_potion, 10)
	check_assert(success, "应该能添加10个生命药水")
	check_assert(inventory.get_item_count("health_potion_small") == 10, "应该有10个生命药水")

	# 测试移除物品
	var removed = inventory.remove_item("health_potion_small", 5)
	check_assert(removed == 5, "应该移除5个")
	check_assert(inventory.get_item_count("health_potion_small") == 5, "应该剩余5个")

	print("✓ 基础库存操作测试通过\n")

func test_stacking_behavior():
	print(">>> 测试堆叠行为")

	# 清空库存
	inventory.clear_all()

	var iron_ore = item_database.get_item_by_id("iron_ore")

	# 添加超过最大堆叠的数量
	inventory.add_item(iron_ore, 150)

	var count = inventory.get_item_count("iron_ore")
	check_assert(count == 150, "应该有150个铁矿石")

	# 应该占用2个槽位 (99 + 51)
	var empty_slots = inventory.get_empty_slot_count()
	check_assert(empty_slots == 46, "应该占用2个槽位")

	print("✓ 堆叠行为测试通过\n")

func test_quick_bar_integration():
	print(">>> 测试快捷栏集成")

	# 获取库存中的物品槽位
	var potion_slot = -1
	for i in range(inventory.MAX_SLOTS):
		var stack = inventory.get_slot(i)
		if not stack.is_empty() and stack.item.id == "health_potion_small":
			potion_slot = i
			break

	check_assert(potion_slot != -1, "应该找到生命药水槽位")

	# 绑定到快捷栏
	var bind_success = quick_bar.bind_slot(0, potion_slot)
	check_assert(bind_success, "应该能绑定到快捷栏")

	var stack = quick_bar.get_quick_bar_stack(0)
	check_assert(not stack.is_empty(), "快捷栏应该有物品")
	check_assert(stack.item.id == "health_potion_small", "快捷栏应该是生命药水")

	print("✓ 快捷栏集成测试通过\n")

func test_item_usage():
	print(">>> 测试物品使用")

	var initial_count = inventory.get_item_count("health_potion_small")

	# 使用快捷栏物品
	var use_success = quick_bar.use_quick_bar_item(0)
	check_assert(use_success, "应该能使用快捷栏物品")

	var new_count = inventory.get_item_count("health_potion_small")
	check_assert(new_count == initial_count - 1, "物品数量应该减少1")

	print("✓ 物品使用测试通过\n")

func test_sorting_and_filtering():
	print(">>> 测试排序和过滤")

	# 添加不同稀有度的物品
	var silver = item_database.get_item_by_id("silver_ore")
	var gold = item_database.get_item_by_id("gold_ore")

	inventory.add_item(silver, 10)
	inventory.add_item(gold, 5)

	# 按稀有度排序
	inventory.sort_by("rarity")

	# 验证稀有物品在前
	var first_non_empty = -1
	for i in range(inventory.MAX_SLOTS):
		var stack = inventory.get_slot(i)
		if not stack.is_empty():
			first_non_empty = i
			break

	check_assert(first_non_empty != -1, "应该有非空槽位")

	# 按类型过滤
	var materials = inventory.get_items_by_type(InventoryItem.ItemType.MATERIAL)
	check_assert(materials.size() >= 3, "应该有至少3种材料")

	print("✓ 排序和过滤测试通过\n")

func test_save_load_system():
	print(">>> 测试存档系统")

	# 保存当前状态
	var inv_save = inventory.get_save_data()
	var qb_save = quick_bar.get_save_data()

	check_assert(inv_save != null, "应该能生成库存存档")
	check_assert(qb_save != null, "应该能生成快捷栏存档")

	var original_count = inventory.get_item_count("iron_ore")
	var original_bindings = quick_bar.get_all_bindings()

	# 清空并重新加载
	inventory.clear_all()
	quick_bar.clear_all()

	check_assert(inventory.get_empty_slot_count() == 48, "清空后应该全空")

	inventory.load_save_data(inv_save)
	quick_bar.load_save_data(qb_save)

	var loaded_count = inventory.get_item_count("iron_ore")
	var loaded_bindings = quick_bar.get_all_bindings()

	check_assert(loaded_count == original_count, "加载后物品数量应该一致")
	check_assert(loaded_bindings[0] == original_bindings[0], "加载后快捷栏绑定应该一致")

	print("✓ 存档系统测试通过\n")

func check_check_assert(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		get_tree().quit(1)
