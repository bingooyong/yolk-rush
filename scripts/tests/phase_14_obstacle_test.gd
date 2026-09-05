extends SceneTree
## Phase 14 障碍系统测试

# 预加载障碍类
const ObstacleManagerScript = preload("res://scripts/obstacles/obstacle_manager.gd")
const RotatingHammerScript = preload("res://scripts/obstacles/rotating_hammer.gd")
const MovingPlatformScript = preload("res://scripts/obstacles/moving_platform.gd")
const RollingLogScript = preload("res://scripts/obstacles/rolling_log.gd")
const BouncePadScript = preload("res://scripts/obstacles/bounce_pad.gd")
const FallingPlatformScript = preload("res://scripts/obstacles/falling_platform.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 14 - Obstacle System Test")
	print("=".repeat(60) + "\n")

	var root = Node3D.new()
	root.name = "TestRoot"
	get_tree().root.add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node3D) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: ObstacleManager
	print("\n[Test 1] ObstacleManager")
	if await test_obstacle_manager(root):
		tests_passed += 1
		print("  ✓ ObstacleManager test passed")
	else:
		tests_failed += 1
		print("  ✗ ObstacleManager test failed")

	# Test 2: RotatingHammer
	print("\n[Test 2] RotatingHammer")
	if await test_rotating_hammer(root):
		tests_passed += 1
		print("  ✓ RotatingHammer test passed")
	else:
		tests_failed += 1
		print("  ✗ RotatingHammer test failed")

	# Test 3: MovingPlatform
	print("\n[Test 3] MovingPlatform")
	if await test_moving_platform(root):
		tests_passed += 1
		print("  ✓ MovingPlatform test passed")
	else:
		tests_failed += 1
		print("  ✗ MovingPlatform test failed")

	# Test 4: RollingLog
	print("\n[Test 4] RollingLog")
	if await test_rolling_log(root):
		tests_passed += 1
		print("  ✓ RollingLog test passed")
	else:
		tests_failed += 1
		print("  ✗ RollingLog test failed")

	# Test 5: BouncePad
	print("\n[Test 5] BouncePad")
	if await test_bounce_pad(root):
		tests_passed += 1
		print("  ✓ BouncePad test passed")
	else:
		tests_failed += 1
		print("  ✗ BouncePad test failed")

	# Test 6: FallingPlatform
	print("\n[Test 6] FallingPlatform")
	if await test_falling_platform(root):
		tests_passed += 1
		print("  ✓ FallingPlatform test passed")
	else:
		tests_failed += 1
		print("  ✗ FallingPlatform test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 14 Obstacle System is working.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await get_tree().create_timer(0.5).timeout

func test_obstacle_manager(root: Node3D) -> bool:
	var manager = ObstacleManagerScript.new()
	root.add_child(manager)

	# 测试初始化
	assert(manager != null, "ObstacleManager should be created")
	print("  - ObstacleManager created")

	# 创建几个测试障碍
	var hammer = RotatingHammerScript.new()
	hammer.name = "TestHammer"
	root.add_child(hammer)

	var platform = MovingPlatformScript.new()
	platform.name = "TestPlatform"
	root.add_child(platform)

	await get_tree().process_frame

	# 测试注册
	manager.register_obstacle(hammer, "test_group")
	manager.register_obstacle(platform, "test_group")

	assert(manager.active_obstacles.size() == 2, "Should have 2 obstacles")
	print("  - Obstacle registration works")

	# 测试分组
	var group_obstacles = manager.get_obstacles_in_group("test_group")
	assert(group_obstacles.size() == 2, "Group should have 2 obstacles")
	print("  - Obstacle grouping works")

	# 测试激活/禁用
	manager.deactivate_group("test_group")
	assert(not hammer.is_active, "Hammer should be deactivated")
	assert(not platform.is_active, "Platform should be deactivated")
	print("  - Group deactivation works")

	manager.activate_group("test_group")
	assert(hammer.is_active, "Hammer should be activated")
	assert(platform.is_active, "Platform should be activated")
	print("  - Group activation works")

	# 测试统计
	var stats = manager.get_stats()
	assert(stats.total_obstacles == 2, "Should have 2 total obstacles")
	print("  - Statistics work")

	manager.queue_free()
	return true

func test_rotating_hammer(root: Node3D) -> bool:
	var hammer = RotatingHammerScript.new()
	hammer.name = "TestHammer"
	hammer.position = Vector3(5, 0, 0)
	root.add_child(hammer)

	await get_tree().process_frame

	# 测试初始化
	assert(hammer != null, "RotatingHammer should be created")
	assert(hammer.obstacle_name == "Rotating Hammer", "Name should be correct")
	print("  - RotatingHammer created")

	# 测试组件
	assert(hammer.rotation_pivot != null, "Should have rotation pivot")
	assert(hammer.hammer_arm != null, "Should have hammer arm")
	assert(hammer.hammer_head != null, "Should have hammer head")
	print("  - Visual components created")

	# 测试碰撞
	assert(hammer.collision_area != null, "Should have collision area")
	assert(hammer.collision_shape != null, "Should have collision shape")
	print("  - Collision setup complete")

	# 测试旋转
	var initial_rotation = hammer.rotation_pivot.rotation.y
	await get_tree().create_timer(0.5).timeout
	var after_rotation = hammer.rotation_pivot.rotation.y
	assert(initial_rotation != after_rotation, "Hammer should rotate")
	print("  - Rotation works")

	# 测试速度设置
	hammer.set_rotation_speed(120.0)
	assert(hammer.rotation_speed == 120.0, "Speed should be updated")
	print("  - Speed control works")

	hammer.queue_free()
	return true

func test_moving_platform(root: Node3D) -> bool:
	var platform = MovingPlatformScript.new()
	platform.name = "TestPlatform"
	platform.position = Vector3(10, 0, 0)
	platform.move_distance = 3.0
	platform.move_speed = 5.0
	root.add_child(platform)

	await get_tree().process_frame

	# 测试初始化
	assert(platform != null, "MovingPlatform should be created")
	print("  - MovingPlatform created")

	# 测试组件
	assert(platform.platform_mesh != null, "Should have platform mesh")
	assert(platform.platform_body != null, "Should have platform body")
	print("  - Platform components created")

	# 测试移动
	var start_pos = platform.global_position
	await get_tree().create_timer(1.0).timeout
	var moved_pos = platform.global_position
	var distance = start_pos.distance_to(moved_pos)
	assert(distance > 0, "Platform should move")
	print("  - Platform movement works (moved %.2f units)" % distance)

	# 测试设置
	platform.set_move_speed(10.0)
	assert(platform.move_speed == 10.0, "Speed should be updated")
	print("  - Speed control works")

	platform.queue_free()
	return true

func test_rolling_log(root: Node3D) -> bool:
	var log = RollingLogScript.new()
	log.name = "TestLog"
	log.position = Vector3(15, 0, 0)
	root.add_child(log)

	await get_tree().process_frame

	# 测试初始化
	assert(log != null, "RollingLog should be created")
	assert(log.roll_state == RollingLogScript.RollState.WAITING, "Should start in WAITING state")
	print("  - RollingLog created")

	# 测试组件
	assert(log.log_mesh != null, "Should have log mesh")
	print("  - Log mesh created")

	# 测试触发
	log.start_rolling()
	assert(log.roll_state == RollingLogScript.RollState.ROLLING, "Should be rolling")
	print("  - Trigger works")

	# 测试移动
	var start_pos = log.global_position
	await get_tree().create_timer(0.5).timeout
	var moved_pos = log.global_position
	assert(start_pos.distance_to(moved_pos) > 0, "Log should move")
	print("  - Rolling movement works")

	log.queue_free()
	return true

func test_bounce_pad(root: Node3D) -> bool:
	var pad = BouncePadScript.new()
	pad.name = "TestBouncePad"
	pad.position = Vector3(20, 0, 0)
	root.add_child(pad)

	await get_tree().process_frame

	# 测试初始化
	assert(pad != null, "BouncePad should be created")
	print("  - BouncePad created")

	# 测试组件
	assert(pad.pad_mesh != null, "Should have pad mesh")
	assert(pad.arrow_indicator != null, "Should have arrow indicator")
	print("  - BouncePad components created")

	# 测试弹跳力设置
	pad.set_bounce_force(20.0)
	assert(pad.bounce_force == 20.0, "Bounce force should be updated")
	print("  - Bounce force control works")

	# 测试方向设置
	pad.set_bounce_direction(Vector3(0, 1, 0.5))
	assert(pad.bounce_direction.length() > 0, "Bounce direction should be set")
	print("  - Bounce direction control works")

	# 测试冷却
	pad.is_on_cooldown = true
	pad.cooldown_timer = 0.3
	await get_tree().create_timer(0.5).timeout
	assert(not pad.is_on_cooldown, "Cooldown should expire")
	print("  - Cooldown system works")

	pad.queue_free()
	return true

func test_falling_platform(root: Node3D) -> bool:
	var platform = FallingPlatformScript.new()
	platform.name = "TestFallingPlatform"
	platform.position = Vector3(25, 5, 0)
	platform.fall_delay = 0.5
	root.add_child(platform)

	await get_tree().process_frame

	# 测试初始化
	assert(platform != null, "FallingPlatform should be created")
	assert(platform.platform_state == FallingPlatformScript.PlatformState.STABLE,
		"Should start in STABLE state")
	print("  - FallingPlatform created")

	# 测试组件
	assert(platform.platform_mesh != null, "Should have platform mesh")
	assert(platform.platform_body != null, "Should have platform body")
	print("  - Platform components created")

	# 测试触发
	var mock_player = CharacterBody3D.new()
	mock_player.add_to_group("player")
	root.add_child(mock_player)

	platform._on_body_entered(mock_player)
	assert(platform.platform_state == FallingPlatformScript.PlatformState.TRIGGERED,
		"Should be triggered")
	print("  - Trigger works")

	# 等待掉落
	await get_tree().create_timer(0.7).timeout
	assert(platform.platform_state == FallingPlatformScript.PlatformState.FALLING,
		"Should be falling")
	print("  - Falling works")

	mock_player.queue_free()
	platform.queue_free()
	return true
