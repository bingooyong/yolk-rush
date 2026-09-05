extends SceneTree
## 独立测试运行器 - 不依赖 autoload

func _init():
	print("\n=== 库存系统集成测试 ===\n")

	# 直接实例化系统
	var item_database = load("res://scripts/inventory/item_database.gd").new()
	item_database.load_database()

	var inventory = load("res://scripts/inventory/inventory_system.gd").new()
	inventory._initialize_slots()
	inventory.set_database(item_database)

	var quick_bar = load("res://scripts/inventory/quick_bar_system.gd").new()
	quick_bar._initialize_quick_bar()
	quick_bar.set_inventory(inventory)

	print("✓ 系统初始化完成\n")

	# 测试 1: 基础操作
	print(">>> 测试基础库存操作")
	var health_potion = item_database.get_item_by_id("health_potion_small")
	if health_potion == null:
		print("❌ 无法获取生命药水")
		quit(1)
		return

	var success = inventory.add_item(health_potion, 10)
	if not success or inventory.get_item_count("health_potion_small") != 10:
		print("❌ 添加物品失败")
		quit(1)
		return

	var removed = inventory.remove_item("health_potion_small", 5)
	if removed != 5 or inventory.get_item_count("health_potion_small") != 5:
		print("❌ 移除物品失败")
		quit(1)
		return

	print("✓ 基础库存操作测试通过\n")

	# 测试 2: 堆叠行为
	print(">>> 测试堆叠行为")
	inventory.clear_all()

	var iron_ore = item_database.get_item_by_id("iron_ore")
	inventory.add_item(iron_ore, 150)

	if inventory.get_item_count("iron_ore") != 150:
		print("❌ 堆叠数量错误")
		quit(1)
		return

	if inventory.get_empty_slot_count() != 46:
		print("❌ 槽位占用错误，应该占用2个槽位")
		quit(1)
		return

	print("✓ 堆叠行为测试通过\n")

	# 测试 3: 快捷栏集成
	print(">>> 测试快捷栏集成")

	# 重新添加生命药水用于测试
	inventory.add_item(health_potion, 5)

	var potion_slot = -1
	for i in range(48):
		var stack = inventory.get_slot(i)
		if not stack.is_empty() and stack.item.id == "health_potion_small":
			potion_slot = i
			break

	if potion_slot == -1:
		print("❌ 找不到生命药水槽位")
		quit(1)
		return

	if not quick_bar.bind_slot(0, potion_slot):
		print("❌ 绑定快捷栏失败")
		quit(1)
		return

	var stack = quick_bar.get_quick_bar_stack(0)
	if stack.is_empty() or stack.item.id != "health_potion_small":
		print("❌ 快捷栏物品错误")
		quit(1)
		return

	print("✓ 快捷栏集成测试通过\n")

	# 测试 4: 物品使用
	print(">>> 测试物品使用")

	var initial_count = inventory.get_item_count("health_potion_small")
	if not quick_bar.use_quick_bar_item(0):
		print("❌ 使用物品失败")
		quit(1)
		return

	var new_count = inventory.get_item_count("health_potion_small")
	if new_count != initial_count - 1:
		print("❌ 使用后数量错误")
		quit(1)
		return

	print("✓ 物品使用测试通过\n")

	# 测试 5: 排序和过滤
	print(">>> 测试排序和过滤")

	var silver = item_database.get_item_by_id("silver_ore")
	var gold = item_database.get_item_by_id("gold_ore")

	inventory.add_item(silver, 10)
	inventory.add_item(gold, 5)

	inventory.sort_by("rarity")

	var InventoryItemClass = load("res://scripts/inventory/inventory_item.gd")
	var materials = inventory.get_items_by_type(InventoryItemClass.ItemType.MATERIAL)
	if materials.size() < 3:
		print("❌ 材料过滤错误")
		quit(1)
		return

	print("✓ 排序和过滤测试通过\n")

	# 测试 6: 存档系统
	print(">>> 测试存档系统")

	var inv_save = inventory.get_save_data()
	var qb_save = quick_bar.get_save_data()

	var original_count = inventory.get_item_count("iron_ore")
	var original_bindings = quick_bar.get_all_bindings()

	inventory.clear_all()
	quick_bar.clear_all()

	inventory.load_save_data(inv_save)
	quick_bar.load_save_data(qb_save)

	var loaded_count = inventory.get_item_count("iron_ore")
	var loaded_bindings = quick_bar.get_all_bindings()

	if loaded_count != original_count:
		print("❌ 加载后物品数量不一致")
		quit(1)
		return

	if loaded_bindings[0] != original_bindings[0]:
		print("❌ 加载后快捷栏绑定不一致")
		quit(1)
		return

	print("✓ 存档系统测试通过\n")

	print("\n=== 所有测试完成 ===")
	print("✓ 6/6 测试通过\n")

	quit(0)
