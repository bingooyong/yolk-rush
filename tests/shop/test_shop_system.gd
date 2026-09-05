extends Node
## 商店系统集成测试

var shop_system
var shop_database

func _ready():
	print("\n=== 商店系统集成测试 ===\n")

	setup_systems()
	test_basic_shop_operations()
	test_purchase_restrictions()
	test_stock_management()
	test_category_filtering()
	test_save_load()

	print("\n=== 所有测试完成 ===\n")
	get_tree().quit()

func setup_systems():
	print(">>> 初始化系统")

	shop_database = ShopDatabase.new()
	add_child(shop_database)
	shop_database.load_database()

	shop_system = ShopSystem.new()
	add_child(shop_system)
	shop_system.set_database(shop_database)
	shop_system.set_player_gold(10000)
	shop_system.set_player_level(1)

	print("✓ 系统初始化完成\n")

func test_basic_shop_operations():
	print(">>> 测试基本商店操作")

	# 购买物品
	var can_buy = shop_system.can_buy("health_potion_small", 5)
	assert_true(can_buy, "应该能购买生命药水")

	var initial_gold = shop_system.get_player_gold()
	var success = shop_system.buy_item("health_potion_small", 5)
	assert_true(success, "购买应该成功")

	var new_gold = shop_system.get_player_gold()
	assert_true(new_gold < initial_gold, "金币应该减少")

	# 出售物品
	var before_sell = shop_system.get_player_gold()
	shop_system.sell_item("iron_ore", 10)
	var after_sell = shop_system.get_player_gold()
	assert_true(after_sell > before_sell, "出售后金币应该增加")

	print("✓ 基本商店操作测试通过\n")

func test_purchase_restrictions():
	print(">>> 测试购买限制")

	# 金币不足
	shop_system.set_player_gold(10)
	var can_buy_expensive = shop_system.can_buy("iron_sword", 1)
	assert_false(can_buy_expensive, "金币不足应该无法购买")

	# 等级不足
	shop_system.set_player_gold(10000)
	shop_system.set_player_level(1)
	var can_buy_high_level = shop_system.can_buy("steel_sword", 1)
	assert_false(can_buy_high_level, "等级不足应该无法购买")

	# 满足条件后可购买
	shop_system.set_player_level(10)
	var can_buy_now = shop_system.can_buy("steel_sword", 1)
	assert_true(can_buy_now, "满足条件后应该能购买")

	print("✓ 购买限制测试通过\n")

func test_stock_management():
	print(">>> 测试库存管理")

	shop_system.refresh_shop()
	shop_system.set_player_gold(100000)
	shop_system.set_player_level(50)

	# 购买限量商品
	var initial_stock = shop_system.get_remaining_stock("iron_sword")
	assert_true(initial_stock == 5, "初始库存应该是5")

	shop_system.buy_item("iron_sword", 3)
	var after_purchase = shop_system.get_remaining_stock("iron_sword")
	assert_true(after_purchase == 2, "购买后库存应该是2")

	# 尝试购买超过库存
	var can_buy_too_much = shop_system.can_buy("iron_sword", 5)
	assert_false(can_buy_too_much, "库存不足应该无法购买")

	# 刷新商店
	shop_system.refresh_shop()
	var after_refresh = shop_system.get_remaining_stock("iron_sword")
	assert_true(after_refresh == 5, "刷新后库存应该恢复")

	print("✓ 库存管理测试通过\n")

func test_category_filtering():
	print(">>> 测试类别过滤")

	shop_system.set_player_level(50)

	var consumables = shop_system.get_available_items("consumable")
	assert_true(consumables.size() > 0, "应该有消耗品")

	var weapons = shop_system.get_available_items("weapon")
	assert_true(weapons.size() > 0, "应该有武器")

	var all_items = shop_system.get_available_items("")
	assert_true(all_items.size() > consumables.size(), "全部商品应该更多")

	print("✓ 类别过滤测试通过\n")

func test_save_load():
	print(">>> 测试存档系统")

	shop_system.refresh_shop()
	shop_system.set_player_gold(5000)
	shop_system.buy_item("iron_sword", 2)

	var save_data = shop_system.get_save_data()
	assert_true(save_data.has("player_gold"), "存档应该包含金币")
	assert_true(save_data.has("purchased_counts"), "存档应该包含购买记录")

	var original_gold = shop_system.get_player_gold()
	var original_stock = shop_system.get_remaining_stock("iron_sword")

	# 模拟重置
	shop_system.set_player_gold(0)
	shop_system.refresh_shop()

	# 加载存档
	shop_system.load_save_data(save_data)

	var loaded_gold = shop_system.get_player_gold()
	assert_true(loaded_gold == original_gold, "加载后金币应该一致")

	print("✓ 存档系统测试通过\n")

func assert_true(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		get_tree().quit(1)

func assert_false(condition: bool, message: String):
	if condition:
		push_error("❌ 断言失败: " + message)
		get_tree().quit(1)
