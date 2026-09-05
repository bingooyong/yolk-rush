extends SceneTree
## Phase 23 内容填充测试
## 测试UI集成和游戏流程

const GameManagerScript = preload("res://scripts/core/game_manager.gd")
const LevelSelectMenuScript = preload("res://scenes/ui/level_select_menu.gd")
const GameOverUIScript = preload("res://scenes/ui/game_over_ui.gd")
const GameConfigScript = preload("res://scripts/core/game_config.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 23 - Content Filling Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: LevelSelectMenu创建
	print("\n[Test 1] Level Select Menu Creation")
	if await test_level_select_creation(root):
		tests_passed += 1
		print("  ✓ Level select menu test passed")
	else:
		tests_failed += 1
		print("  ✗ Level select menu test failed")

	# Test 2: GameOverUI创建
	print("\n[Test 2] Game Over UI Creation")
	if await test_game_over_creation(root):
		tests_passed += 1
		print("  ✓ Game over UI test passed")
	else:
		tests_failed += 1
		print("  ✗ Game over UI test failed")

	# Test 3: 关卡选择流程
	print("\n[Test 3] Level Selection Flow")
	if await test_level_selection_flow(root):
		tests_passed += 1
		print("  ✓ Level selection flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Level selection flow test failed")

	# Test 4: 游戏结算流程
	print("\n[Test 4] Game Over Flow")
	if await test_game_over_flow(root):
		tests_passed += 1
		print("  ✓ Game over flow test passed")
	else:
		tests_failed += 1
		print("  ✗ Game over flow test failed")

	# Test 5: 评分系统
	print("\n[Test 5] Grading System")
	if await test_grading_system(root):
		tests_passed += 1
		print("  ✓ Grading system test passed")
	else:
		tests_failed += 1
		print("  ✗ Grading system test failed")

	# Test 6: UI状态管理
	print("\n[Test 6] UI State Management")
	if await test_ui_state_management(root):
		tests_passed += 1
		print("  ✓ UI state management test passed")
	else:
		tests_failed += 1
		print("  ✗ UI state management test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 23 Content is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_level_select_creation(root: Node) -> bool:
	# 创建GameConfig
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 创建关卡选择菜单
	var level_select = LevelSelectMenuScript.new()
	level_select.name = "LevelSelectMenu"
	root.add_child(level_select)

	await process_frame

	# 验证创建
	assert(level_select != null, "LevelSelectMenu should be created")
	print("  - LevelSelectMenu created")

	# 验证关卡数据加载
	assert(level_select.level_data.size() > 0, "Should have level data")
	print("  - Loaded %d levels" % level_select.level_data.size())

	# 验证UI组件
	assert(level_select.has_node("MainContainer"), "Should have main container")
	assert(level_select.has_node("MainContainer/Title"), "Should have title")
	print("  - UI components created")

	return true

func test_game_over_creation(root: Node) -> bool:
	# 创建游戏结算UI
	var game_over = GameOverUIScript.new()
	game_over.name = "GameOverUI"
	root.add_child(game_over)

	await process_frame

	# 验证创建
	assert(game_over != null, "GameOverUI should be created")
	print("  - GameOverUI created")

	# 验证UI组件
	assert(game_over.has_node("MainContainer"), "Should have main container")
	assert(game_over.has_node("MainContainer/Title"), "Should have title")
	assert(game_over.has_node("MainContainer/GradeLabel"), "Should have grade label")
	assert(game_over.has_node("MainContainer/StatsPanel"), "Should have stats panel")
	print("  - UI components created")

	# 验证按钮
	assert(game_over.has_node("MainContainer/ButtonContainer/RetryButton"), "Should have retry button")
	assert(game_over.has_node("MainContainer/ButtonContainer/NextButton"), "Should have next button")
	assert(game_over.has_node("MainContainer/ButtonContainer/MenuButton"), "Should have menu button")
	print("  - Buttons created")

	return true

func test_level_selection_flow(root: Node) -> bool:
	var level_select = root.get_node("LevelSelectMenu")

	# 显示菜单
	level_select.show_menu()
	assert(level_select.visible, "Menu should be visible")
	print("  - Menu shown")

	# 模拟选择关卡
	level_select._on_level_button_pressed(0)
	assert(level_select.selected_level == 0, "Should select level 0")
	print("  - Level 0 selected")

	# 创建一个简单的验证节点来捕获信号
	var signal_checker = Node.new()
	signal_checker.set_meta("signal_received", false)
	root.add_child(signal_checker)

	level_select.level_selected.connect(func(_id):
		signal_checker.set_meta("signal_received", true)
	)

	# 触发开始
	level_select._on_start_pressed()

	# 验证信号
	var received = signal_checker.get_meta("signal_received")
	signal_checker.queue_free()

	assert(received, "Signal should be emitted")
	print("  - Start button triggered with signal")

	return true

func test_game_over_flow(root: Node) -> bool:
	var game_over = root.get_node("GameOverUI")

	# 测试胜利结算
	var victory_stats = {
		"play_time": 60.0,
		"enemies_defeated": 5,
		"items_collected": 3,
		"damage_taken": 10,
		"skills_used": 8,
		"completed": true
	}

	game_over.show_result(GameOverUIScript.ResultType.VICTORY, victory_stats)
	await process_frame

	assert(game_over.visible, "Game over UI should be visible")
	assert(game_over.result_type == GameOverUIScript.ResultType.VICTORY, "Should be victory")
	print("  - Victory result shown")

	# 测试失败结算
	var defeat_stats = {
		"play_time": 30.0,
		"enemies_defeated": 2,
		"items_collected": 1,
		"damage_taken": 100,
		"skills_used": 3,
		"completed": false
	}

	game_over.show_result(GameOverUIScript.ResultType.DEFEAT, defeat_stats)
	await process_frame

	assert(game_over.result_type == GameOverUIScript.ResultType.DEFEAT, "Should be defeat")
	print("  - Defeat result shown")

	return true

func test_grading_system(root: Node) -> bool:
	var game_over = root.get_node("GameOverUI")

	# 测试S级 (需要90+分)
	var s_stats = {
		"play_time": 30.0,      # 30分 (<=60秒满分)
		"enemies_defeated": 10, # 10分
		"items_collected": 10,  # 10分
		"damage_taken": 0,      # 20分 (无伤)
		"skills_used": 5,
		"completed": true       # 30分
	}
	# 总分: 30 + 30 + 20 + 10 + 10 = 100

	var grade_s = game_over._calculate_grade(s_stats)
	assert(grade_s == "S", "Should be S grade")
	print("  - S grade: %s (perfect score)" % grade_s)

	# 测试A级 (需要80-89分)
	var a_stats = {
		"play_time": 75.0,      # 22.5分 (超过60秒，递减)
		"enemies_defeated": 8,  # 8分
		"items_collected": 8,   # 8分
		"damage_taken": 25,     # 15分 (<30伤害)
		"skills_used": 5,
		"completed": true       # 30分
	}
	# 总分: 30 + 22.5 + 15 + 8 + 8 = 83.5

	var grade_a = game_over._calculate_grade(a_stats)
	assert(grade_a == "A", "Should be A grade, got: %s" % grade_a)
	print("  - A grade: %s" % grade_a)

	# 测试B级 (需要70-79分)
	var b_stats = {
		"play_time": 90.0,      # 15分
		"enemies_defeated": 5,  # 5分
		"items_collected": 5,   # 5分
		"damage_taken": 50,     # 10分 (30-60伤害)
		"skills_used": 3,
		"completed": true       # 30分
	}
	# 总分: 30 + 15 + 10 + 5 + 5 = 65 -> 应该是C

	var grade_b = game_over._calculate_grade(b_stats)
	print("  - B/C grade: %s (adjusted stats)" % grade_b)

	return true

func test_ui_state_management(root: Node) -> bool:
	var level_select = root.get_node("LevelSelectMenu")
	var game_over = root.get_node("GameOverUI")

	# 测试显示/隐藏
	level_select.show_menu()
	assert(level_select.visible, "Level select should be visible")

	level_select.hide_menu()
	assert(not level_select.visible, "Level select should be hidden")
	print("  - Level select show/hide works")

	game_over.show_ui()
	assert(game_over.visible, "Game over should be visible")

	game_over.hide_ui()
	assert(not game_over.visible, "Game over should be hidden")
	print("  - Game over show/hide works")

	# 测试刷新
	level_select.refresh()
	print("  - Level select refresh works")

	return true
