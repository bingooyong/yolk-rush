extends SceneTree
## Phase 19 完整游戏循环测试

const GameStateManagerScript = preload("res://scripts/core/game_state_manager.gd")
const LevelFlowControllerScript = preload("res://scripts/core/level_flow_controller.gd")
const GameConfigScript = preload("res://scripts/core/game_config.gd")
const PerformanceMonitorScript = preload("res://scripts/core/performance_monitor.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 19 - Complete Game Loop Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: GameStateManager 初始化
	print("\n[Test 1] GameStateManager Initialization")
	if await test_game_state_manager(root):
		tests_passed += 1
		print("  ✓ GameStateManager test passed")
	else:
		tests_failed += 1
		print("  ✗ GameStateManager test failed")

	# Test 2: GameConfig 系统
	print("\n[Test 2] GameConfig System")
	if await test_game_config(root):
		tests_passed += 1
		print("  ✓ GameConfig test passed")
	else:
		tests_failed += 1
		print("  ✗ GameConfig test failed")

	# Test 3: LevelFlowController
	print("\n[Test 3] LevelFlowController")
	if await test_level_flow_controller(root):
		tests_passed += 1
		print("  ✓ LevelFlowController test passed")
	else:
		tests_failed += 1
		print("  ✗ LevelFlowController test failed")

	# Test 4: 状态转换流程
	print("\n[Test 4] State Transitions")
	if await test_state_transitions(root):
		tests_passed += 1
		print("  ✓ State transitions test passed")
	else:
		tests_failed += 1
		print("  ✗ State transitions test failed")

	# Test 5: 关卡目标系统
	print("\n[Test 5] Level Objectives")
	if await test_level_objectives(root):
		tests_passed += 1
		print("  ✓ Level objectives test passed")
	else:
		tests_failed += 1
		print("  ✗ Level objectives test failed")

	# Test 6: 奖励计算
	print("\n[Test 6] Reward Calculation")
	if await test_reward_calculation(root):
		tests_passed += 1
		print("  ✓ Reward calculation test passed")
	else:
		tests_failed += 1
		print("  ✗ Reward calculation test failed")

	# Test 7: PerformanceMonitor
	print("\n[Test 7] Performance Monitor")
	if await test_performance_monitor(root):
		tests_passed += 1
		print("  ✓ Performance monitor test passed")
	else:
		tests_failed += 1
		print("  ✗ Performance monitor test failed")

	# Test 8: 完整游戏流程
	print("\n[Test 8] Complete Game Flow")
	if await test_complete_flow(root):
		tests_passed += 1
		print("  ✓ Complete game flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Complete game flow test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 19 Complete Game Loop is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_game_state_manager(root: Node) -> bool:
	var manager = GameStateManagerScript.new()
	manager.name = "GameStateManager"
	root.add_child(manager)

	# 等待 _ready 完成和状态转换
	await process_frame
	await process_frame

	# 测试初始化
	assert(manager != null, "GameStateManager should be created")
	print("  - GameStateManager created")

	# 测试初始状态（_ready 后应该是 MAIN_MENU）
	assert(manager.current_state == manager.GameState.MAIN_MENU, "Should start in MAIN_MENU")
	print("  - Initial state: MAIN_MENU")

	# 测试统计初始化
	assert(manager.session_stats.has("levels_completed"), "Should have session stats")
	assert(manager.level_stats.has("start_time"), "Should have level stats")
	print("  - Stats initialized")

	return true

func test_game_config(root: Node) -> bool:
	var config = GameConfigScript.new()
	config.name = "GameConfig"
	root.add_child(config)

	await process_frame

	# 测试关卡配置加载
	var level_count = config.get_level_count()
	assert(level_count == 3, "Should have 3 levels")
	print("  - Loaded %d levels" % level_count)

	# 测试关卡数据
	var level0 = config.get_level_config(0)
	assert(level0.has("name"), "Level should have name")
	assert(level0.has("objectives"), "Level should have objectives")
	print("  - Level 0: %s" % level0.name)

	# 测试难度系统
	config.set_difficulty("hard")
	var difficulty = config.get_difficulty_config()
	assert(difficulty.has("enemy_health_multiplier"), "Should have difficulty config")
	print("  - Difficulty set to: hard")

	# 测试数值获取
	var player_health = config.get_stat("player", "base_health")
	assert(player_health > 0, "Should get player health")
	print("  - Player base health: %.1f" % player_health)

	config.queue_free()
	return true

func test_level_flow_controller(root: Node) -> bool:
	var controller = LevelFlowControllerScript.new()
	controller.name = "LevelFlowController"
	root.add_child(controller)

	await process_frame

	# 创建测试配置
	var test_config = {
		"name": "Test Level",
		"objectives": [
			{
				"id": "test_obj",
				"type": "collect",
				"description": "Collect 5 items",
				"target": 5,
				"optional": false
			}
		]
	}

	# 测试初始化
	controller.initialize_level(test_config)
	await controller.level_ready

	assert(controller.is_ready, "Controller should be ready")
	print("  - Level initialized")

	# 测试目标加载
	var objectives = controller.get_objectives()
	assert(objectives.size() == 1, "Should have 1 objective")
	print("  - Objectives loaded: %d" % objectives.size())

	controller.queue_free()
	return true

func test_state_transitions(root: Node) -> bool:
	var manager = root.get_node("GameStateManager")

	# 测试状态转换
	manager.change_state(manager.GameState.LEVEL_SELECT)
	assert(manager.current_state == manager.GameState.LEVEL_SELECT, "Should transition to LEVEL_SELECT")
	print("  - Transitioned to LEVEL_SELECT")

	manager.change_state(manager.GameState.LOADING)
	assert(manager.current_state == manager.GameState.LOADING, "Should transition to LOADING")
	print("  - Transitioned to LOADING")

	manager.change_state(manager.GameState.PLAYING)
	assert(manager.current_state == manager.GameState.PLAYING, "Should transition to PLAYING")
	assert(manager.is_playing(), "Should be playing")
	print("  - Transitioned to PLAYING")

	# 测试暂停
	manager.pause_game()
	assert(manager.current_state == manager.GameState.PAUSED, "Should be paused")
	assert(manager.is_paused(), "Should report paused")
	print("  - Game paused")

	# 测试恢复
	manager.resume_game()
	assert(manager.current_state == manager.GameState.PLAYING, "Should resume to PLAYING")
	print("  - Game resumed")

	return true

func test_level_objectives(root: Node) -> bool:
	var controller = LevelFlowControllerScript.new()
	root.add_child(controller)

	await process_frame

	var test_config = {
		"name": "Objective Test",
		"objectives": [
			{
				"id": "collect_coins",
				"type": "collect",
				"description": "Collect coins",
				"target": 10,
				"optional": false
			},
			{
				"id": "defeat_enemies",
				"type": "defeat",
				"description": "Defeat enemies",
				"target": 5,
				"optional": true
			}
		]
	}

	controller.initialize_level(test_config)
	await controller.level_ready

	# 测试进度更新
	controller.update_objective("collect_coins", 5)
	var progress = controller.get_objective_progress("collect_coins")
	assert(progress == 0.5, "Progress should be 50%")
	print("  - Objective progress: %.0f%%" % (progress * 100))

	# 测试目标完成
	controller.update_objective("collect_coins", 5)
	var objectives = controller.get_objectives()
	assert(objectives[0].completed, "Objective should be completed")
	print("  - Objective completed")

	# 测试剩余目标
	var remaining = controller.get_remaining_objectives_count()
	assert(remaining == 0, "No required objectives remaining")
	print("  - Remaining objectives: %d" % remaining)

	controller.queue_free()
	return true

func test_reward_calculation(root: Node) -> bool:
	var config = GameConfigScript.new()
	root.add_child(config)

	await process_frame

	# 测试奖励计算
	var stats = {
		"play_time": 45.0,
		"damage_taken": 0.0,
		"enemies_defeated": 5,
		"items_collected": 8
	}

	var reward = config.calculate_level_reward(0, stats)
	assert(reward.has("total_score"), "Should have total score")
	assert(reward.has("breakdown"), "Should have breakdown")
	print("  - Total score: %d" % reward.total_score)

	# 验证奖励组成
	var breakdown = reward.breakdown
	assert(breakdown.has("completion"), "Should have completion bonus")
	assert(breakdown.has("speed_bonus"), "Should have speed bonus")
	assert(breakdown.has("no_damage"), "Should have no damage bonus")
	print("  - Bonus breakdown: %d components" % breakdown.size())

	config.queue_free()
	return true

func test_performance_monitor(root: Node) -> bool:
	var monitor = PerformanceMonitorScript.new()
	monitor.name = "PerformanceMonitor"
	root.add_child(monitor)

	await process_frame

	# 测试初始化
	assert(monitor != null, "Monitor should be created")
	print("  - Performance monitor created")

	# 测试统计获取
	var stats = monitor.get_stats()
	assert(stats.has("fps"), "Should have FPS stat")
	assert(stats.has("memory_used"), "Should have memory stat")
	print("  - Stats available: %d metrics" % stats.size())

	# 测试性能等级
	var level = monitor.get_performance_level()
	assert(level != "", "Should have performance level")
	print("  - Performance level: %s" % level)

	# 测试报告生成
	var report = monitor.generate_report()
	assert(report.length() > 0, "Should generate report")
	print("  - Performance report generated")

	monitor.queue_free()
	return true

func test_complete_flow(root: Node) -> bool:
	var manager = root.get_node("GameStateManager")
	var config = GameConfigScript.new()
	var controller = LevelFlowControllerScript.new()

	root.add_child(config)
	root.add_child(controller)

	await process_frame

	# 1. 开始关卡
	print("  - Starting level 0...")
	manager.current_level_id = 0
	manager.change_state(manager.GameState.LOADING)
	await create_timer(0.1).timeout

	# 2. 进入游戏
	manager.change_state(manager.GameState.PLAYING)
	assert(manager.is_playing(), "Should be in playing state")
	print("  - Entered playing state")

	# 3. 初始化关卡流程
	var level_config = config.get_level_config(0)
	controller.initialize_level(level_config)
	await controller.level_ready
	print("  - Level flow initialized")

	# 4. 模拟游戏进行
	manager.record_enemy_defeated()
	manager.record_item_collected()
	print("  - Recorded game events")

	# 5. 完成目标
	for obj in controller.get_objectives():
		controller.update_objective(obj.id, obj.target)
	print("  - Completed all objectives")

	# 6. 等待胜利状态
	await create_timer(0.1).timeout

	# 7. 验证统计
	var level_stats = manager.get_level_stats()
	assert(level_stats.enemies_defeated >= 1, "Should have defeated enemies")
	assert(level_stats.items_collected >= 1, "Should have collected items")
	print("  - Stats verified")

	# 8. 计算奖励
	var reward = config.calculate_level_reward(0, level_stats)
	assert(reward.total_score > 0, "Should have reward score")
	print("  - Reward calculated: %d" % reward.total_score)

	config.queue_free()
	controller.queue_free()

	return true
