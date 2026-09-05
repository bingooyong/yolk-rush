extends SceneTree
## Phase 21 成就系统测试

const AchievementManagerScript = preload("res://scripts/core/achievement_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 21 - Achievement System Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: AchievementManager 初始化
	print("\n[Test 1] AchievementManager Initialization")
	if await test_achievement_manager_init(root):
		tests_passed += 1
		print("  ✓ AchievementManager init test passed")
	else:
		tests_failed += 1
		print("  ✗ AchievementManager init test failed")

	# Test 2: 成就解锁
	print("\n[Test 2] Achievement Unlock")
	if await test_achievement_unlock(root):
		tests_passed += 1
		print("  ✓ Achievement unlock test passed")
	else:
		tests_failed += 1
		print("  ✗ Achievement unlock test failed")

	# Test 3: 统计追踪
	print("\n[Test 3] Statistics Tracking")
	if await test_statistics_tracking(root):
		tests_passed += 1
		print("  ✓ Statistics tracking test passed")
	else:
		tests_failed += 1
		print("  ✗ Statistics tracking test failed")

	# Test 4: 累积成就
	print("\n[Test 4] Cumulative Achievements")
	if await test_cumulative_achievements(root):
		tests_passed += 1
		print("  ✓ Cumulative achievements test passed")
	else:
		tests_failed += 1
		print("  ✗ Cumulative achievements test failed")

	# Test 5: 关卡完成记录
	print("\n[Test 5] Level Completion Recording")
	if await test_level_completion(root):
		tests_passed += 1
		print("  ✓ Level completion test passed")
	else:
		tests_failed += 1
		print("  ✗ Level completion test failed")

	# Test 6: 成就进度
	print("\n[Test 6] Achievement Progress")
	if await test_achievement_progress(root):
		tests_passed += 1
		print("  ✓ Achievement progress test passed")
	else:
		tests_failed += 1
		print("  ✗ Achievement progress test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 21 Achievement System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_achievement_manager_init(root: Node) -> bool:
	var achievement_manager = AchievementManagerScript.new()
	achievement_manager.name = "AchievementManager"
	root.add_child(achievement_manager)

	await process_frame

	# 测试初始化
	assert(achievement_manager != null, "AchievementManager should be created")
	print("  - AchievementManager created")

	# 测试成就加载
	assert(achievement_manager.achievements.size() > 0, "Achievements should be loaded")
	print("  - Achievements loaded: %d" % achievement_manager.achievements.size())

	# 测试统计初始化
	assert(achievement_manager.statistics.size() > 0, "Statistics should be initialized")
	print("  - Statistics initialized: %d fields" % achievement_manager.statistics.size())

	return true

func test_achievement_unlock(root: Node) -> bool:
	var achievement_manager = root.get_node("AchievementManager")

	# 直接解锁一个成就
	achievement_manager.unlock_achievement("first_steps")

	await process_frame

	# 验证解锁
	assert("first_steps" in achievement_manager.unlocked_achievements, "Achievement should be in unlocked list")
	print("  - Achievement 'first_steps' unlocked")
	print("  - Unlocked achievements: %d" % achievement_manager.unlocked_achievements.size())

	return true

func test_statistics_tracking(root: Node) -> bool:
	var achievement_manager = root.get_node("AchievementManager")

	# 测试统计更新
	achievement_manager.update_stat("total_coins_collected", 100, "add")
	assert(achievement_manager.statistics.total_coins_collected == 100, "Coins should be tracked")
	print("  - Coins collected: %d" % achievement_manager.statistics.total_coins_collected)

	achievement_manager.update_stat("total_coins_collected", 50, "add")
	assert(achievement_manager.statistics.total_coins_collected == 150, "Coins should accumulate")
	print("  - Coins after add: %d" % achievement_manager.statistics.total_coins_collected)

	# 测试敌人击败
	achievement_manager.record_enemy_defeated()
	assert(achievement_manager.statistics.total_enemies_defeated == 1, "Enemies should be tracked")
	print("  - Enemies defeated: %d" % achievement_manager.statistics.total_enemies_defeated)

	# 测试道具收集
	achievement_manager.record_item_collected()
	assert(achievement_manager.statistics.total_items_collected == 1, "Items should be tracked")
	print("  - Items collected: %d" % achievement_manager.statistics.total_items_collected)

	return true

func test_cumulative_achievements(root: Node) -> bool:
	var achievement_manager = root.get_node("AchievementManager")

	# 清空已解锁成就（测试用）
	achievement_manager.unlocked_achievements.clear()

	# 收集1000个金币
	achievement_manager.update_stat("total_coins_collected", 1000, "set")

	# 检查金币收藏家成就
	achievement_manager.check_achievement("coin_collector")
	assert("coin_collector" in achievement_manager.unlocked_achievements, "Coin collector achievement should be unlocked")
	print("  - Coin collector unlocked")

	# 击败100个敌人
	achievement_manager.update_stat("total_enemies_defeated", 100, "set")

	# 检查敌人终结者成就
	achievement_manager.check_achievement("enemy_slayer")
	assert("enemy_slayer" in achievement_manager.unlocked_achievements, "Enemy slayer achievement should be unlocked")
	print("  - Enemy slayer unlocked")

	return true

func test_level_completion(root: Node) -> bool:
	var achievement_manager = root.get_node("AchievementManager")

	# 清空统计
	achievement_manager.statistics.levels_completed = 0
	achievement_manager.statistics.perfect_clears = 0

	# 记录关卡完成（无伤）
	var stats = {
		"play_time": 60.0,
		"damage_taken": 0,
		"items_collected": 5,
		"enemies_defeated": 3,
		"stars": 3
	}

	achievement_manager.record_level_complete(0, stats)

	# 验证统计更新
	assert(achievement_manager.statistics.levels_completed == 1, "Level completion should be tracked")
	assert(achievement_manager.statistics.perfect_clears == 1, "Perfect clear should be tracked")
	assert(achievement_manager.statistics.three_star_clears == 1, "Three star clear should be tracked")
	print("  - Level completed: %d" % achievement_manager.statistics.levels_completed)
	print("  - Perfect clears: %d" % achievement_manager.statistics.perfect_clears)
	print("  - Three star clears: %d" % achievement_manager.statistics.three_star_clears)

	return true

func test_achievement_progress(root: Node) -> bool:
	var achievement_manager = root.get_node("AchievementManager")

	# 获取所有成就
	var all_achievements = achievement_manager.get_all_achievements()
	assert(all_achievements.size() > 0, "Should have achievements")
	print("  - Total achievements: %d" % all_achievements.size())

	# 获取已解锁成就
	var unlocked = achievement_manager.get_unlocked_achievements()
	print("  - Unlocked achievements: %d" % unlocked.size())

	# 获取完成百分比
	var completion = achievement_manager.get_completion_percentage()
	print("  - Completion percentage: %.1f%%" % completion)

	# 获取总点数
	var points = achievement_manager.get_total_points()
	print("  - Total points: %d" % points)

	assert(completion >= 0.0 and completion <= 100.0, "Completion should be valid percentage")
	assert(points >= 0, "Points should be non-negative")

	return true
