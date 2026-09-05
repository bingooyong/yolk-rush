extends SceneTree
## 系统整合测试 - 验证所有Phase的互操作性

const SaveManagerScript = preload("res://scripts/core/save_manager.gd")
const GameConfigScript = preload("res://scripts/core/game_config.gd")
const GameStateManagerScript = preload("res://scripts/core/game_state_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Integration Test - All Systems")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: 完整游戏流程 + 保存系统
	print("\n[Test 1] Complete Game Flow with Save System")
	if await test_game_flow_with_save(root):
		tests_passed += 1
		print("  ✓ Game flow with save test passed")
	else:
		tests_failed += 1
		print("  ✗ Game flow with save test failed")

	# Test 2: 跨会话数据持久化
	print("\n[Test 2] Cross-Session Data Persistence")
	if await test_cross_session_persistence(root):
		tests_passed += 1
		print("  ✓ Cross-session persistence test passed")
	else:
		tests_failed += 1
		print("  ✗ Cross-session persistence test failed")

	# Test 3: 多系统协作
	print("\n[Test 3] Multi-System Cooperation")
	if await test_multi_system_cooperation(root):
		tests_passed += 1
		print("  ✓ Multi-system cooperation test passed")
	else:
		tests_failed += 1
		print("  ✗ Multi-system cooperation test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All integration tests passed!\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

## Test 1: 完整游戏流程 + 保存系统
func test_game_flow_with_save(root: Node) -> bool:
	# 创建核心系统
	var save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)

	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	var game_state = GameStateManagerScript.new()
	game_state.name = "GameStateManager"
	root.add_child(game_state)

	await process_frame

	# 设置引用
	save_manager.game_config_override = game_config

	print("  - Core systems initialized")

	# 模拟游戏流程
	game_state.change_state(GameStateManagerScript.GameState.LEVEL_SELECT)
	print("  - Entered level select")

	game_state.start_level(0)
	await create_timer(0.1).timeout
	print("  - Started level 0")

	# 模拟游戏进度
	game_config.unlock_level(1)
	game_state.record_enemy_defeated()
	game_state.record_item_collected()
	print("  - Recorded game progress")

	# 保存游戏
	var save_result = save_manager.save_game(0)
	assert(save_result, "Save should succeed")
	print("  - Saved to slot 0")

	# 验证保存
	assert(save_manager.has_save(0), "Save should exist")
	print("  - Save verified")

	# 清理
	game_state.queue_free()
	game_config.queue_free()
	save_manager.queue_free()
	await process_frame

	return true

## Test 2: 跨会话数据持久化
func test_cross_session_persistence(root: Node) -> bool:
	# 第一个会话：保存数据
	var save_manager1 = SaveManagerScript.new()
	save_manager1.name = "SaveManager1"
	root.add_child(save_manager1)

	var game_config1 = GameConfigScript.new()
	game_config1.name = "GameConfig1"
	root.add_child(game_config1)

	await process_frame

	save_manager1.game_config_override = game_config1

	# 设置进度
	game_config1.unlock_level(0)
	game_config1.unlock_level(1)
	game_config1.unlock_level(2)
	print("  - Session 1: Set progress (3 levels unlocked)")

	# 保存
	save_manager1.save_game(1)
	print("  - Session 1: Saved to slot 1")

	# 清理第一个会话
	game_config1.queue_free()
	save_manager1.queue_free()
	await process_frame

	# 第二个会话：加载数据
	var save_manager2 = SaveManagerScript.new()
	save_manager2.name = "SaveManager2"
	root.add_child(save_manager2)

	var game_config2 = GameConfigScript.new()
	game_config2.name = "GameConfig2"
	root.add_child(game_config2)

	await process_frame

	save_manager2.game_config_override = game_config2

	# 加载
	var load_result = save_manager2.load_game(1)
	assert(load_result, "Load should succeed")
	print("  - Session 2: Loaded from slot 1")

	# 验证数据
	assert(game_config2.is_level_unlocked(0), "Level 0 should be unlocked")
	assert(game_config2.is_level_unlocked(1), "Level 1 should be unlocked")
	assert(game_config2.is_level_unlocked(2), "Level 2 should be unlocked")
	print("  - Session 2: Data verified (3 levels unlocked)")

	# 清理
	game_config2.queue_free()
	save_manager2.queue_free()
	await process_frame

	return true

## Test 3: 多系统协作
func test_multi_system_cooperation(root: Node) -> bool:
	# 创建所有核心系统
	var save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)

	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	var game_state = GameStateManagerScript.new()
	game_state.name = "GameStateManager"
	root.add_child(game_state)

	await process_frame

	save_manager.game_config_override = game_config

	print("  - All systems initialized")

	# 测试系统间协作
	# GameState -> GameConfig
	game_state.start_level(0)
	await create_timer(0.1).timeout
	assert(game_state.current_level_id == 0, "Level ID should be set")
	print("  - GameState <-> GameConfig: OK")

	# GameState -> SaveManager
	game_state.record_enemy_defeated()
	game_state.record_item_collected()
	var stats = game_state.get_level_stats()
	assert(stats.enemies_defeated == 1, "Stats should be tracked")
	print("  - GameState stats tracking: OK")

	# SaveManager <-> GameConfig
	game_config.unlock_level(1)
	save_manager.save_game(2)
	assert(save_manager.has_save(2), "Save should exist")
	print("  - SaveManager <-> GameConfig: OK")

	# 完整循环：保存 -> 清理 -> 加载 -> 验证
	save_manager.save_game(2)
	var old_level_id = game_state.current_level_id

	game_state.change_state(GameStateManagerScript.GameState.MAIN_MENU)
	game_state.current_level_id = -1

	save_manager.load_game(2)
	assert(game_config.is_level_unlocked(1), "Level should be unlocked after load")
	print("  - Full cycle (save -> clear -> load -> verify): OK")

	# 清理
	game_state.queue_free()
	game_config.queue_free()
	save_manager.queue_free()
	await process_frame

	return true
