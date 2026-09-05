extends SceneTree
## Phase 22 Alpha原型集成测试
## 测试完整的游戏流程从启动到结算

const GameManagerScript = preload("res://scripts/core/game_manager.gd")
const GameStateManagerScript = preload("res://scripts/core/game_state_manager.gd")
const LevelFlowControllerScript = preload("res://scripts/core/level_flow_controller.gd")
const GameConfigScript = preload("res://scripts/core/game_config.gd")
const SaveManagerScript = preload("res://scripts/core/save_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 22 - Alpha Integration Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: 系统初始化
	print("\n[Test 1] System Initialization")
	if await test_system_initialization(root):
		tests_passed += 1
		print("  ✓ System initialization test passed")
	else:
		tests_failed += 1
		print("  ✗ System initialization test failed")

	# Test 2: 游戏启动流程
	print("\n[Test 2] Game Boot Flow")
	if await test_game_boot_flow(root):
		tests_passed += 1
		print("  ✓ Game boot flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Game boot flow test failed")

	# Test 3: 主菜单到游戏
	print("\n[Test 3] Main Menu to Game")
	if await test_menu_to_game(root):
		tests_passed += 1
		print("  ✓ Main menu to game test passed")
	else:
		tests_failed += 1
		print("  ✗ Main menu to game test failed")

	# Test 4: 关卡加载和初始化
	print("\n[Test 4] Level Loading")
	if await test_level_loading(root):
		tests_passed += 1
		print("  ✓ Level loading test passed")
	else:
		tests_failed += 1
		print("  ✗ Level loading test failed")

	# Test 5: 游戏流程完整性
	print("\n[Test 5] Complete Game Flow")
	if await test_complete_game_flow(root):
		tests_passed += 1
		print("  ✓ Complete game flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Complete game flow test failed")

	# Test 6: 保存和加载集成
	print("\n[Test 6] Save/Load Integration")
	if await test_save_load_integration(root):
		tests_passed += 1
		print("  ✓ Save/Load integration test passed")
	else:
		tests_failed += 1
		print("  ✗ Save/Load integration test failed")

	# Test 7: 暂停和恢复
	print("\n[Test 7] Pause and Resume")
	if await test_pause_resume(root):
		tests_passed += 1
		print("  ✓ Pause and resume test passed")
	else:
		tests_failed += 1
		print("  ✗ Pause and resume test failed")

	# Test 8: 游戏结算流程
	print("\n[Test 8] Game Over Flow")
	if await test_game_over_flow(root):
		tests_passed += 1
		print("  ✓ Game over flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Game over flow test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 22 Alpha Integration is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_system_initialization(root: Node) -> bool:
	# 创建所有核心系统
	var game_state_manager = GameStateManagerScript.new()
	game_state_manager.name = "GameStateManager"
	root.add_child(game_state_manager)

	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	var save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)

	await process_frame

	# 验证所有系统已初始化
	assert(game_state_manager != null, "GameStateManager should be initialized")
	assert(game_config != null, "GameConfig should be initialized")
	assert(save_manager != null, "SaveManager should be initialized")
	print("  - All core systems initialized")

	# 验证初始状态（GameStateManager在_ready后会自动转到MAIN_MENU）
	# 允许 BOOT 或 MAIN_MENU 状态
	var is_valid_state = game_state_manager.current_state == GameStateManagerScript.GameState.MAIN_MENU or \
						 game_state_manager.current_state == GameStateManagerScript.GameState.BOOT
	assert(is_valid_state, "Initial state should be BOOT or MAIN_MENU")
	print("  - Initial state: %s" % game_state_manager.get_current_state_string())

	return true

func test_game_boot_flow(root: Node) -> bool:
	var game_state_manager = root.get_node("GameStateManager")

	# 测试启动序列（允许BOOT或MAIN_MENU状态）
	var is_valid_state = game_state_manager.current_state == GameStateManagerScript.GameState.MAIN_MENU or \
						 game_state_manager.current_state == GameStateManagerScript.GameState.BOOT
	assert(is_valid_state, "Should be in BOOT or MAIN_MENU")
	print("  - Started in %s" % game_state_manager.get_current_state_string())

	# 验证游戏统计初始化
	var stats = game_state_manager.get_session_stats()
	assert(stats.has("levels_completed"), "Should have session stats")
	print("  - Session stats initialized")

	return true

func test_menu_to_game(root: Node) -> bool:
	var game_state_manager = root.get_node("GameStateManager")
	var game_config = root.get_node("GameConfig")

	# 模拟选择关卡
	game_config.unlock_level(0)
	print("  - Level 0 unlocked")

	# 开始关卡
	game_state_manager.start_level(0)
	print("  - Starting level 0...")

	await create_timer(0.6).timeout

	# 验证状态转换
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.PLAYING,
		"Should be in PLAYING state")
	print("  - Entered PLAYING state")

	# 验证当前关卡ID
	assert(game_state_manager.current_level_id == 0, "Current level should be 0")
	print("  - Current level ID: 0")

	return true

func test_level_loading(root: Node) -> bool:
	# 创建关卡流程控制器
	var level_controller = LevelFlowControllerScript.new()
	level_controller.name = "LevelFlowController"
	root.add_child(level_controller)

	await process_frame

	# 初始化测试关卡
	var level_config = {
		"name": "测试关卡",
		"objectives": [
			{
				"id": "collect_coins",
				"type": "collect",
				"description": "收集金币",
				"target": 5
			},
			{
				"id": "defeat_enemies",
				"type": "defeat",
				"description": "击败敌人",
				"target": 3
			}
		]
	}

	level_controller.initialize_level(level_config)
	await level_controller.level_ready

	# 验证关卡加载
	assert(level_controller.is_ready, "Level should be ready")
	assert(level_controller.objectives.size() == 2, "Should have 2 objectives")
	print("  - Level loaded with %d objectives" % level_controller.objectives.size())

	# 清理
	level_controller.queue_free()
	await process_frame

	return true

func test_complete_game_flow(root: Node) -> bool:
	var game_state_manager = root.get_node("GameStateManager")

	# 模拟完整游戏流程
	print("  - Simulating complete game flow...")

	# 1. 主菜单
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.PLAYING,
		"Currently in PLAYING")
	print("    1. Already in game (from previous test)")

	# 2. 记录游戏事件
	game_state_manager.record_enemy_defeated()
	game_state_manager.record_enemy_defeated()
	game_state_manager.record_item_collected()
	game_state_manager.record_item_collected()
	game_state_manager.record_item_collected()
	print("    2. Recorded game events")

	# 3. 完成关卡
	game_state_manager.level_victory()
	await process_frame
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.VICTORY,
		"Should be in VICTORY state")
	print("    3. Level completed - VICTORY state")

	# 4. 验证统计
	var stats = game_state_manager.get_session_stats()
	assert(stats.levels_completed == 1, "Should have 1 completed level")
	assert(stats.total_enemies_defeated == 2, "Should have 2 defeated enemies")
	assert(stats.total_items_collected == 3, "Should have 3 collected items")
	print("    4. Stats verified: %d levels, %d enemies, %d items" % [
		stats.levels_completed,
		stats.total_enemies_defeated,
		stats.total_items_collected
	])

	return true

func test_save_load_integration(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")
	var game_config = root.get_node("GameConfig")
	var game_state_manager = root.get_node("GameStateManager")

	# 设置SaveManager引用
	save_manager.game_config_override = game_config

	# 解锁更多关卡
	game_config.unlock_level(0)
	game_config.unlock_level(1)
	print("  - Unlocked 2 levels")

	# 保存游戏
	var save_result = save_manager.save_game(0)
	assert(save_result, "Save should succeed")
	print("  - Saved to slot 0")

	# 重置状态
	game_config.queue_free()
	await process_frame

	# 创建新的GameConfig
	game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)
	await process_frame

	# 更新引用
	save_manager.game_config_override = game_config

	# 加载游戏
	var load_result = save_manager.load_game(0)
	assert(load_result, "Load should succeed")
	print("  - Loaded from slot 0")

	# 验证数据恢复
	assert(game_config.is_level_unlocked(0), "Level 0 should be unlocked")
	assert(game_config.is_level_unlocked(1), "Level 1 should be unlocked")
	print("  - Progress restored: 2 levels unlocked")

	return true

func test_pause_resume(root: Node) -> bool:
	var game_state_manager = root.get_node("GameStateManager")

	# 回到游戏状态
	game_state_manager.change_state(GameStateManagerScript.GameState.PLAYING)
	await process_frame

	# 暂停游戏
	game_state_manager.pause_game()
	await process_frame
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.PAUSED,
		"Should be PAUSED")
	assert(root.get_tree().paused, "Game tree should be paused")
	print("  - Game paused successfully")

	# 恢复游戏
	game_state_manager.resume_game()
	await process_frame
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.PLAYING,
		"Should be PLAYING")
	assert(not root.get_tree().paused, "Game tree should not be paused")
	print("  - Game resumed successfully")

	return true

func test_game_over_flow(root: Node) -> bool:
	var game_state_manager = root.get_node("GameStateManager")

	# 测试失败流程
	game_state_manager.level_defeat()
	await process_frame
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.DEFEAT,
		"Should be in DEFEAT state")
	print("  - Level defeat handled")

	# 验证失败统计
	var stats = game_state_manager.get_session_stats()
	assert(stats.deaths == 1, "Should have 1 death")
	print("  - Death recorded in stats")

	# 测试重新开始
	game_state_manager.restart_level()
	await create_timer(0.6).timeout
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.PLAYING,
		"Should be back in PLAYING state")
	print("  - Level restarted successfully")

	# 测试返回主菜单
	game_state_manager.return_to_menu()
	await process_frame
	assert(game_state_manager.current_state == GameStateManagerScript.GameState.MAIN_MENU,
		"Should be back in MAIN_MENU")
	print("  - Returned to main menu")

	return true
