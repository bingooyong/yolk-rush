extends SceneTree
## 性能和平衡系统测试

const BalanceManagerScript = preload("res://scripts/core/balance_manager.gd")
const PerformanceMonitorScript = preload("res://scripts/core/performance_monitor.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Performance & Balance Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: BalanceManager 加载
	print("\n[Test 1] BalanceManager Loading")
	if await test_balance_manager_loading(root):
		tests_passed += 1
		print("  ✓ BalanceManager loading test passed")
	else:
		tests_failed += 1
		print("  ✗ BalanceManager loading test failed")

	# Test 2: 难度修正
	print("\n[Test 2] Difficulty Modifiers")
	if await test_difficulty_modifiers(root):
		tests_passed += 1
		print("  ✓ Difficulty modifiers test passed")
	else:
		tests_failed += 1
		print("  ✗ Difficulty modifiers test failed")

	# Test 3: 关卡配置
	print("\n[Test 3] Level Configuration")
	if await test_level_configuration(root):
		tests_passed += 1
		print("  ✓ Level configuration test passed")
	else:
		tests_failed += 1
		print("  ✗ Level configuration test failed")

	# Test 4: 奖励计算
	print("\n[Test 4] Reward Calculation")
	if await test_reward_calculation(root):
		tests_passed += 1
		print("  ✓ Reward calculation test passed")
	else:
		tests_failed += 1
		print("  ✗ Reward calculation test failed")

	# Test 5: 性能监控
	print("\n[Test 5] Performance Monitoring")
	if await test_performance_monitoring(root):
		tests_passed += 1
		print("  ✓ Performance monitoring test passed")
	else:
		tests_failed += 1
		print("  ✗ Performance monitoring test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed!\n")
	else:
		print("\n✗ Some tests failed.\n")

	await create_timer(0.5).timeout

func test_balance_manager_loading(root: Node) -> bool:
	var balance_manager = BalanceManagerScript.new()
	balance_manager.name = "BalanceManager"
	root.add_child(balance_manager)

	await process_frame

	# 测试配置加载
	assert(balance_manager.balance_config.size() > 0, "Balance config should be loaded")
	print("  - Balance config loaded: %d sections" % balance_manager.balance_config.size())

	# 测试各个部分
	assert(balance_manager.balance_config.has("player"), "Should have player config")
	assert(balance_manager.balance_config.has("levels"), "Should have levels config")
	assert(balance_manager.balance_config.has("enemies"), "Should have enemies config")
	assert(balance_manager.balance_config.has("items"), "Should have items config")
	print("  - All config sections present")

	return true

func test_difficulty_modifiers(root: Node) -> bool:
	var balance_manager = root.get_node("BalanceManager")

	# 测试默认难度
	assert(balance_manager.current_difficulty == "normal", "Default should be normal")
	print("  - Default difficulty: normal")

	# 测试简单难度
	balance_manager.set_difficulty("easy")
	var easy_mod = balance_manager.get_difficulty_modifiers()
	assert(easy_mod.player_health_multiplier == 1.5, "Easy should boost player health")
	print("  - Easy mode: player health x1.5")

	# 测试困难难度
	balance_manager.set_difficulty("hard")
	var hard_mod = balance_manager.get_difficulty_modifiers()
	assert(hard_mod.enemy_health_multiplier == 1.3, "Hard should boost enemy health")
	print("  - Hard mode: enemy health x1.3")

	# 恢复默认
	balance_manager.set_difficulty("normal")

	return true

func test_level_configuration(root: Node) -> bool:
	var balance_manager = root.get_node("BalanceManager")

	# 测试教学关卡
	var tutorial_config = balance_manager.get_level_config(0)
	assert(tutorial_config.has("difficulty"), "Level should have difficulty")
	assert(tutorial_config.difficulty == 0.3, "Tutorial should be easy")
	print("  - Tutorial level: difficulty 0.3")

	# 测试竞速关卡
	var race_config = balance_manager.get_level_config(1)
	assert(race_config.difficulty == 0.6, "Race should be medium")
	print("  - Race level: difficulty 0.6")

	# 测试Boss关卡
	var boss_config = balance_manager.get_level_config(2)
	assert(boss_config.difficulty == 1.0, "Boss should be hard")
	assert(boss_config.has("boss"), "Boss level should have boss config")
	print("  - Boss level: difficulty 1.0, boss health %d" % boss_config.boss.health)

	return true

func test_reward_calculation(root: Node) -> bool:
	var balance_manager = root.get_node("BalanceManager")

	# 测试完美通关
	var perfect_stats = {
		"play_time": 60.0,
		"damage_taken": 0,
		"items_collected": 10,
		"enemies_defeated": 5
	}

	var perfect_reward = balance_manager.calculate_level_reward(0, perfect_stats)
	assert(perfect_reward.has("total_score"), "Should calculate total score")
	assert(perfect_reward.stars == 3, "Perfect run should get 3 stars")
	assert(perfect_reward.no_damage_bonus > 0, "Should have no damage bonus")
	print("  - Perfect run: %d points, %d stars" % [perfect_reward.total_score, perfect_reward.stars])

	# 测试普通通关
	var normal_stats = {
		"play_time": 200.0,
		"damage_taken": 50,
		"items_collected": 3,
		"enemies_defeated": 3
	}

	var normal_reward = balance_manager.calculate_level_reward(0, normal_stats)
	assert(normal_reward.stars < 3, "Normal run should get fewer stars")
	assert(normal_reward.no_damage_bonus == 0, "Damaged run should not get bonus")
	print("  - Normal run: %d points, %d stars" % [normal_reward.total_score, normal_reward.stars])

	return true

func test_performance_monitoring(root: Node) -> bool:
	var perf_monitor = PerformanceMonitorScript.new()
	perf_monitor.name = "PerformanceMonitor"
	root.add_child(perf_monitor)

	await process_frame

	# 测试统计获取
	var stats = perf_monitor.get_stats()
	assert(stats.has("fps"), "Should track FPS")
	assert(stats.has("memory_used"), "Should track memory")
	print("  - Performance stats: FPS %.1f, Memory %.1f MB" % [stats.fps, stats.memory_used])

	# 测试性能等级
	var performance_level = perf_monitor.get_performance_level()
	assert(performance_level in ["优秀", "良好", "一般", "较差"], "Should have valid performance level")
	print("  - Performance level: %s" % performance_level)

	# 清理
	perf_monitor.queue_free()
	await process_frame

	return true
