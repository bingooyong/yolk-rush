extends SceneTree
## 关卡1 功能测试
## 验证敌人生成、道具拾取、战斗系统和关卡流程

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Level 01 - Grassland Playtest")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: 敌人实体创建
	print("\n[Test 1] Basic Enemy Creation")
	if await test_enemy_creation(root):
		tests_passed += 1
		print("  ✓ Enemy creation test passed")
	else:
		tests_failed += 1
		print("  ✗ Enemy creation test failed")

	# Test 2: 障碍物创建
	print("\n[Test 2] Obstacle Creation")
	if await test_obstacle_creation(root):
		tests_passed += 1
		print("  ✓ Obstacle test passed")
	else:
		tests_failed += 1
		print("  ✗ Obstacle test failed")

	# Test 3: 道具创建
	print("\n[Test 3] Item Creation")
	if await test_item_creation(root):
		tests_passed += 1
		print("  ✓ Item test passed")
	else:
		tests_failed += 1
		print("  ✗ Item test failed")

	# Test 4: 战斗系统
	print("\n[Test 4] Combat System")
	if await test_combat_system(root):
		tests_passed += 1
		print("  ✓ Combat system test passed")
	else:
		tests_failed += 1
		print("  ✗ Combat system test failed")

	# Test 5: 场景预加载
	print("\n[Test 5] Scene Preloading")
	if await test_scene_preloading(root):
		tests_passed += 1
		print("  ✓ Scene preloading test passed")
	else:
		tests_failed += 1
		print("  ✗ Scene preloading test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Level 01 is ready.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_enemy_creation(root: Node) -> bool:
	# 加载敌人脚本
	var enemy_script = load("res://scripts/entities/basic_enemy.gd")
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_script)
	enemy.name = "TestEnemy"
	root.add_child(enemy)

	await process_frame

	assert(enemy != null, "Enemy should be created")
	print("  - Enemy created")

	# 检查属性
	assert(enemy.get("max_hp") != null, "Enemy should have max_hp")
	assert(enemy.get("damage") != null, "Enemy should have damage")
	print("  - Enemy has required attributes")

	# 检查方法
	assert(enemy.has_method("take_damage"), "Enemy should have take_damage method")
	assert(enemy.has_method("set_level"), "Enemy should have set_level method")
	print("  - Enemy has required methods")

	# 测试受伤
	var initial_hp = enemy.get("current_hp")
	enemy.take_damage(10)
	await process_frame
	assert(enemy.get("current_hp") == initial_hp - 10, "Enemy HP should decrease")
	print("  - Enemy damage system works")

	enemy.queue_free()
	return true

func test_obstacle_creation(root: Node) -> bool:
	# 先加载基类
	var obstacle_base_script = load("res://scripts/objects/obstacle_base.gd")
	assert(obstacle_base_script != null, "ObstacleBase should load")

	# 加载障碍物脚本
	var obstacle_script = load("res://scripts/objects/spike_obstacle.gd")
	var obstacle = Area3D.new()
	obstacle.set_script(obstacle_script)
	obstacle.name = "TestObstacle"
	root.add_child(obstacle)

	await process_frame

	assert(obstacle != null, "Obstacle should be created")
	print("  - Obstacle created")

	# 检查属性
	assert(obstacle.get("damage") != null, "Obstacle should have damage")
	assert(obstacle.get("obstacle_type") != null, "Obstacle should have type")
	print("  - Obstacle has required attributes")

	obstacle.queue_free()
	return true

func test_item_creation(root: Node) -> bool:
	# 先加载基类
	var item_base_script = load("res://scripts/objects/item_base.gd")
	assert(item_base_script != null, "ItemBase should load")

	# 测试金币
	var coin_script = load("res://scripts/objects/coin_item.gd")
	var coin = Area3D.new()
	coin.set_script(coin_script)
	coin.name = "TestCoin"
	root.add_child(coin)

	await process_frame

	assert(coin != null, "Coin should be created")
	assert(coin.get("item_type") == "coin", "Coin type should be correct")
	print("  - Coin created")

	coin.queue_free()

	# 测试药水
	var potion_script = load("res://scripts/objects/health_potion.gd")
	var potion = Area3D.new()
	potion.set_script(potion_script)
	potion.name = "TestPotion"
	root.add_child(potion)

	await process_frame

	assert(potion != null, "Potion should be created")
	assert(potion.get("item_type") == "health_potion", "Potion type should be correct")
	print("  - Health potion created")

	potion.queue_free()
	return true

func test_combat_system(root: Node) -> bool:
	# 加载战斗系统
	var combat_system = load("res://scripts/systems/combat_system.gd")

	assert(combat_system != null, "Combat system should load")
	print("  - Combat system loaded")

	# 测试伤害计算
	var damage = combat_system.calculate_damage(50)
	assert(damage == 50, "Damage calculation should work")
	print("  - Damage calculation: %d" % damage)

	# 创建测试实体
	var enemy_script = load("res://scripts/entities/basic_enemy.gd")
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_script)
	enemy.name = "CombatTestEnemy"
	root.add_child(enemy)

	await process_frame

	# 测试应用伤害
	var initial_hp = enemy.get("current_hp")
	var success = combat_system.apply_damage(enemy, 20)
	await process_frame

	assert(success, "Damage should be applied successfully")
	assert(enemy.get("current_hp") == initial_hp - 20, "Enemy HP should decrease correctly")
	print("  - Damage application works: %d -> %d" % [initial_hp, enemy.get("current_hp")])

	enemy.queue_free()
	return true

func test_scene_preloading(root: Node) -> bool:
	# 先加载基类
	var item_base_script = load("res://scripts/objects/item_base.gd")
	var obstacle_base_script = load("res://scripts/objects/obstacle_base.gd")

	# 测试场景文件是否存在
	var enemy_scene = load("res://scenes/entities/basic_enemy.tscn")
	assert(enemy_scene != null, "Enemy scene should load")
	print("  - Enemy scene loaded")

	var spike_scene = load("res://scenes/objects/spike_obstacle.tscn")
	assert(spike_scene != null, "Spike scene should load")
	print("  - Spike obstacle scene loaded")

	var coin_scene = load("res://scenes/objects/coin_item.tscn")
	assert(coin_scene != null, "Coin scene should load")
	print("  - Coin scene loaded")

	var potion_scene = load("res://scenes/objects/health_potion.tscn")
	assert(potion_scene != null, "Potion scene should load")
	print("  - Potion scene loaded")

	# 测试实例化
	var enemy_instance = enemy_scene.instantiate()
	assert(enemy_instance != null, "Enemy should instantiate")
	print("  - Enemy instantiated successfully")
	enemy_instance.queue_free()

	return true
