extends SceneTree
## 关卡流程集成测试
## 测试完整的关卡流程：开始 → 战斗 → 胜利

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Level Flow Integration Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: LevelFlowController 初始化
	print("\n[Test 1] LevelFlowController Initialization")
	if await test_flow_controller_init(root):
		tests_passed += 1
		print("  ✓ Flow controller test passed")
	else:
		tests_failed += 1
		print("  ✗ Flow controller test failed")

	# Test 2: 目标系统
	print("\n[Test 2] Objective System")
	if await test_objective_system(root):
		tests_passed += 1
		print("  ✓ Objective system test passed")
	else:
		tests_failed += 1
		print("  ✗ Objective system test failed")

	# Test 3: 敌人击败检测
	print("\n[Test 3] Enemy Defeat Detection")
	if await test_enemy_defeat_detection(root):
		tests_passed += 1
		print("  ✓ Enemy defeat detection test passed")
	else:
		tests_failed += 1
		print("  ✗ Enemy defeat detection test failed")

	# Test 4: 胜利条件
	print("\n[Test 4] Victory Condition")
	if await test_victory_condition(root):
		tests_passed += 1
		print("  ✓ Victory condition test passed")
	else:
		tests_failed += 1
		print("  ✗ Victory condition test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Level flow is working.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_flow_controller_init(root: Node) -> bool:
	# 加载 LevelFlowController
	var flow_script = load("res://scripts/core/level_flow_controller.gd")
	var flow = Node.new()
	flow.set_script(flow_script)
	flow.name = "TestFlowController"
	root.add_child(flow)

	await process_frame

	assert(flow != null, "Flow controller should be created")
	print("  - Flow controller created")

	# 初始化关卡
	var config = {
		"name": "Test Level",
		"objectives": [
			{
				"id": "test_obj",
				"type": "defeat_all",
				"description": "Test objective",
				"target": 5,
				"optional": false
			}
		]
	}

	await flow.initialize_level(config)
	await process_frame

	assert(flow.get("is_ready") == true, "Flow should be ready")
	print("  - Flow initialized")

	# 检查目标
	var objectives = flow.get_objectives()
	assert(objectives.size() == 1, "Should have 1 objective")
	print("  - Objectives loaded: %d" % objectives.size())

	flow.queue_free()
	return true

func test_objective_system(root: Node) -> bool:
	# 创建流程控制器
	var flow_script = load("res://scripts/core/level_flow_controller.gd")
	var flow = Node.new()
	flow.set_script(flow_script)
	flow.name = "TestFlow"
	root.add_child(flow)

	await process_frame

	# 初始化
	var config = {
		"name": "Objective Test",
		"objectives": [
			{
				"id": "defeat_enemies",
				"type": "defeat_all",
				"description": "Defeat 3 enemies",
				"target": 3,
				"optional": false
			}
		]
	}

	await flow.initialize_level(config)
	await process_frame

	# 测试进度更新
	var initial_progress = flow.get_objective_progress("defeat_enemies")
	assert(initial_progress == 0.0, "Initial progress should be 0")
	print("  - Initial progress: %.1f%%" % (initial_progress * 100))

	# 更新进度
	flow.update_objective("defeat_enemies", 1)
	var progress_1 = flow.get_objective_progress("defeat_enemies")
	assert(abs(progress_1 - 0.333) < 0.01, "Progress should be ~33%")
	print("  - Progress after 1 enemy: %.1f%%" % (progress_1 * 100))

	flow.update_objective("defeat_enemies", 1)
	var progress_2 = flow.get_objective_progress("defeat_enemies")
	assert(abs(progress_2 - 0.667) < 0.01, "Progress should be ~67%")
	print("  - Progress after 2 enemies: %.1f%%" % (progress_2 * 100))

	# 检查未完成
	assert(flow.are_required_objectives_completed() == false, "Should not be completed")
	print("  - Objectives not yet completed")

	flow.queue_free()
	return true

func test_enemy_defeat_detection(root: Node) -> bool:
	# 创建敌人
	var enemy_script = load("res://scripts/entities/basic_enemy.gd")
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_script)
	enemy.name = "TestEnemy"
	root.add_child(enemy)

	await process_frame

	# 使用数组来存储信号结果（避免闭包问题）
	var signal_data = [false, null]  # [received, enemy_ref]

	enemy.died.connect(func(e):
		signal_data[0] = true
		signal_data[1] = e
		print("  - Signal callback executed")
	)

	print("  - Signal connected, damaging enemy...")

	# 击败敌人
	var initial_hp = enemy.get("max_hp")
	enemy.take_damage(initial_hp)

	# 给信号传播时间
	await process_frame
	await process_frame

	assert(signal_data[0] == true, "Should receive died signal")
	print("  - Enemy died signal received")

	if signal_data[1]:
		assert(signal_data[1] == enemy, "Signal should pass enemy reference")
		print("  - Enemy reference passed correctly")

	return true

func test_victory_condition(root: Node) -> bool:
	# 创建流程控制器
	var flow_script = load("res://scripts/core/level_flow_controller.gd")
	var flow = Node.new()
	flow.set_script(flow_script)
	flow.name = "VictoryTestFlow"
	root.add_child(flow)

	await process_frame

	# 初始化
	var config = {
		"name": "Victory Test",
		"objectives": [
			{
				"id": "defeat_all",
				"type": "defeat_all",
				"description": "Defeat all enemies",
				"target": 2,
				"optional": false
			}
		]
	}

	# 使用数组存储信号结果
	var victory_data = [false]

	flow.all_objectives_completed.connect(func():
		victory_data[0] = true
		print("  - Victory signal callback executed")
	)

	await flow.initialize_level(config)
	await process_frame

	# 模拟击败敌人
	print("  - Defeating enemy 1/2...")
	flow.update_objective("defeat_all", 1)
	await process_frame
	await process_frame
	assert(victory_data[0] == false, "Should not trigger victory yet")
	print("  - Victory not triggered after 1/2 enemies")

	print("  - Defeating enemy 2/2...")
	flow.update_objective("defeat_all", 1)
	await process_frame
	await process_frame
	assert(victory_data[0] == true, "Should trigger victory")
	print("  - Victory triggered after 2/2 enemies")

	assert(flow.are_required_objectives_completed() == true, "All objectives completed")
	print("  - All objectives marked as completed")

	flow.queue_free()
	return true
