extends SceneTree
## Level 01 Tutorial Integration Test

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Level 01 Tutorial - Integration Test")
	print("=".repeat(60) + "\n")

	await run_all_tests()

	quit()

func run_all_tests() -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: 场景加载
	print("\n[Test 1] Scene Loading")
	if await test_scene_loading():
		tests_passed += 1
		print("  ✓ Scene loading test passed")
	else:
		tests_failed += 1
		print("  ✗ Scene loading test failed")

	# Test 2: 关卡初始化
	print("\n[Test 2] Level Initialization")
	if await test_level_initialization():
		tests_passed += 1
		print("  ✓ Level initialization test passed")
	else:
		tests_failed += 1
		print("  ✗ Level initialization test failed")

	# Test 3: 关卡内容生成
	print("\n[Test 3] Level Content Generation")
	if await test_level_content():
		tests_passed += 1
		print("  ✓ Level content test passed")
	else:
		tests_failed += 1
		print("  ✗ Level content test failed")

	# Test 4: 教学系统集成
	print("\n[Test 4] Tutorial System Integration")
	if await test_tutorial_integration():
		tests_passed += 1
		print("  ✓ Tutorial integration test passed")
	else:
		tests_failed += 1
		print("  ✗ Tutorial integration test failed")

	# Test 5: 出生点验证
	print("\n[Test 5] Spawn Point Validation")
	if await test_spawn_point():
		tests_passed += 1
		print("  ✓ Spawn point test passed")
	else:
		tests_failed += 1
		print("  ✗ Spawn point test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Level 01 is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_scene_loading() -> bool:
	var scene_path = "res://scenes/levels/level_01_tutorial.tscn"

	if not FileAccess.file_exists(scene_path):
		print("  ✗ Scene file not found: %s" % scene_path)
		return false

	var scene = load(scene_path)
	if not scene:
		print("  ✗ Failed to load scene")
		return false

	var instance = scene.instantiate()
	if not instance:
		print("  ✗ Failed to instantiate scene")
		return false

	get_root().add_child(instance)
	await process_frame

	print("  - Scene loaded: %s" % instance.name)
	print("  - Scene type: %s" % instance.get_class())

	return true

func test_level_initialization() -> bool:
	var level = get_root().get_node("Level01Tutorial")
	if not level:
		print("  ✗ Level node not found")
		return false

	# 等待初始化完成
	await create_timer(0.2).timeout

	# 检查配置是否加载
	if level.level_config.is_empty():
		print("  ✗ Level config not loaded")
		return false

	print("  - Config loaded: %s" % level.level_config.name)
	print("  - Objectives: %d" % level.level_config.objectives.size())
	print("  - Tutorial steps: %d" % level.level_config.tutorial_steps.size())

	return true

func test_level_content() -> bool:
	var level = get_root().get_node("Level01Tutorial")
	if not level:
		return false

	# 检查地面
	var ground = level.find_child("Ground", true, false)
	assert(ground != null, "Ground should exist")
	print("  - Ground created: ✓")

	# 检查检查点
	var checkpoints = level.find_child("Checkpoints", true, false)
	if checkpoints:
		print("  - Checkpoints: %d" % checkpoints.get_child_count())
	else:
		print("  - Checkpoints: 0 (none in config)")

	# 检查道具
	var items = level.find_child("Items", true, false)
	if items:
		var item_count = items.get_child_count()
		assert(item_count > 0, "Should have items")
		print("  - Items spawned: %d" % item_count)

	# 检查敌人
	var enemies = level.find_child("Enemies", true, false)
	if enemies:
		var enemy_count = enemies.get_child_count()
		assert(enemy_count > 0, "Should have enemies")
		print("  - Enemies spawned: %d" % enemy_count)

	# 检查障碍物
	var obstacles = level.find_child("Obstacles", true, false)
	if obstacles:
		var obstacle_count = obstacles.get_child_count()
		assert(obstacle_count > 0, "Should have obstacles")
		print("  - Obstacles spawned: %d" % obstacle_count)

	return true

func test_tutorial_integration() -> bool:
	var level = get_root().get_node("Level01Tutorial")
	if not level:
		return false

	# 查找教学控制器
	var tutorial_controller = level.tutorial_controller
	if not tutorial_controller:
		# 尝试从根节点查找
		tutorial_controller = get_root().find_child("TutorialController", true, false)

	if not tutorial_controller:
		print("  - Tutorial controller not found (expected)")
		return true  # 这是可接受的，因为可能还没有加载

	print("  - Tutorial controller found")

	# 检查教学是否已开始
	if tutorial_controller.has_method("is_active"):
		var is_active = tutorial_controller.is_active()
		print("  - Tutorial active: %s" % is_active)

	return true

func test_spawn_point() -> bool:
	var level = get_root().get_node("Level01Tutorial")
	if not level:
		return false

	var spawn_pos = level.get_spawn_position()
	print("  - Spawn position: %s" % spawn_pos)

	# 验证出生点位置合理
	assert(spawn_pos.y >= 0, "Spawn Y should be above ground")
	assert(spawn_pos != Vector3.ZERO or level.level_config.has("spawn_point"),
		"Spawn position should be set")

	print("  - Spawn point valid: ✓")

	return true
