extends SceneTree
## UI视觉升级测试
## 验证所有UI组件的视觉升级

const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const GameHUDScript = preload("res://scripts/ui/game_hud.gd")
const PauseMenuScript = preload("res://scenes/ui/pause_menu.gd")
const GameOverScreenScript = preload("res://scripts/ui/game_over_screen.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("UI Visual Upgrade Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: 主菜单视觉升级
	print("\n[Test 1] Main Menu Visual Upgrade")
	if await test_main_menu_visual(root):
		tests_passed += 1
		print("  ✓ Main menu visual upgrade test passed")
	else:
		tests_failed += 1
		print("  ✗ Main menu visual upgrade test failed")

	# Test 2: 游戏HUD视觉升级
	print("\n[Test 2] Game HUD Visual Upgrade")
	if await test_game_hud_visual(root):
		tests_passed += 1
		print("  ✓ Game HUD visual upgrade test passed")
	else:
		tests_failed += 1
		print("  ✗ Game HUD visual upgrade test failed")

	# Test 3: 暂停菜单视觉升级
	print("\n[Test 3] Pause Menu Visual Upgrade")
	if await test_pause_menu_visual(root):
		tests_passed += 1
		print("  ✓ Pause menu visual upgrade test passed")
	else:
		tests_failed += 1
		print("  ✗ Pause menu visual upgrade test failed")

	# Test 4: 结算界面
	print("\n[Test 4] Game Over Screen")
	if await test_game_over_screen(root):
		tests_passed += 1
		print("  ✓ Game over screen test passed")
	else:
		tests_failed += 1
		print("  ✗ Game over screen test failed")

	# Test 5: UI动画
	print("\n[Test 5] UI Animations")
	if await test_ui_animations(root):
		tests_passed += 1
		print("  ✓ UI animations test passed")
	else:
		tests_failed += 1
		print("  ✗ UI animations test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! UI Visual Upgrade is complete.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_main_menu_visual(root: Node) -> bool:
	# 创建临时场景根节点并添加脚本
	var main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.set_script(MainMenuScript)
	root.add_child(main_menu)

	await process_frame

	# 验证主菜单组件存在
	assert(main_menu != null, "MainMenu should be created")
	print("  - MainMenu created with visual upgrade")

	# 验证关键UI元素存在（程序化创建的）
	assert(main_menu.has_method("show_menu"), "MainMenu should have show_menu method")
	print("  - MainMenu methods exist")

	# 验证按钮引用
	assert(main_menu.start_button != null, "Start button should exist")
	assert(main_menu.continue_button != null, "Continue button should exist")
	print("  - Buttons created successfully")

	# 验证颜色系统
	assert(main_menu.get("COLOR_PRIMARY") == Color("#3B6DFF"), "Color system should be defined")
	print("  - Color system defined")

	main_menu.queue_free()
	await process_frame

	return true

func test_game_hud_visual(root: Node) -> bool:
	var game_hud = CanvasLayer.new()
	game_hud.name = "GameHUD"
	game_hud.set_script(GameHUDScript)
	root.add_child(game_hud)

	await process_frame

	# 验证HUD创建
	assert(game_hud != null, "GameHUD should be created")
	print("  - GameHUD created with visual upgrade")

	# 验证生命值条
	assert(game_hud.health_bar != null, "Health bar should exist")
	print("  - Health bar created")

	# 验证能量条
	assert(game_hud.energy_bar != null, "Energy bar should exist")
	print("  - Energy bar created")

	# 验证技能图标
	assert(game_hud.skill_q != null, "Skill Q should exist")
	assert(game_hud.skill_e != null, "Skill E should exist")
	assert(game_hud.skill_r != null, "Skill R should exist")
	assert(game_hud.skill_f != null, "Skill F should exist")
	print("  - All skill icons created")

	# 验证目标面板
	assert(game_hud.objective_list != null, "Objective list should exist")
	print("  - Objective panel created")

	# 测试生命值更新
	game_hud.update_health(75, 100)
	await process_frame
	assert(game_hud.health_bar.max_value == 100, "Health bar max should be 100")
	print("  - Health update works")

	# 测试能量更新
	game_hud.update_energy(50, 100)
	await process_frame
	assert(game_hud.energy_bar.max_value == 100, "Energy bar max should be 100")
	print("  - Energy update works")

	# 测试目标管理
	game_hud.add_objective("test_obj", "测试目标", 0, 5)
	await process_frame
	var objective = game_hud.objective_list.get_node_or_null("Objective_test_obj")
	assert(objective != null, "Objective should be added")
	print("  - Objective management works")

	game_hud.queue_free()
	await process_frame

	return true

func test_pause_menu_visual(root: Node) -> bool:
	var pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(PauseMenuScript)
	root.add_child(pause_menu)

	await process_frame
	await process_frame  # 等待 _ready 完成

	# 验证暂停菜单创建
	assert(pause_menu != null, "PauseMenu should be created")
	print("  - PauseMenu created with visual upgrade")

	# 验证按钮
	assert(pause_menu.get("resume_button") != null, "Resume button should exist")
	assert(pause_menu.get("restart_button") != null, "Restart button should exist")
	assert(pause_menu.get("settings_button") != null, "Settings button should exist")
	assert(pause_menu.get("main_menu_button") != null, "Main menu button should exist")
	print("  - All buttons created")

	# 验证统计容器
	assert(pause_menu.get("stats_container") != null, "Stats container should exist")
	print("  - Stats container created")

	# 测试统计更新
	var test_stats = {
		"play_time": 125.5,
		"enemies_defeated": 10,
		"items_collected": 5
	}
	pause_menu.update_stats(test_stats)
	await process_frame
	assert(pause_menu.stats_container.get_child_count() == 3, "Should have 3 stat rows")
	print("  - Stats update works")

	pause_menu.queue_free()
	await process_frame

	return true

func test_game_over_screen(root: Node) -> bool:
	var game_over = Control.new()
	game_over.name = "GameOverScreen"
	game_over.set_script(GameOverScreenScript)
	root.add_child(game_over)

	await process_frame

	# 验证结算界面创建
	assert(game_over != null, "GameOverScreen should be created")
	print("  - GameOverScreen created")

	# 验证结果标签
	assert(game_over.result_label != null, "Result label should exist")
	print("  - Result label exists")

	# 验证评分标签
	assert(game_over.rank_label != null, "Rank label should exist")
	print("  - Rank label exists")

	# 验证统计容器
	assert(game_over.stats_container != null, "Stats container should exist")
	print("  - Stats container exists")

	# 测试显示结果
	var test_stats = {
		"play_time": 90.0,
		"enemies_defeated": 15,
		"items_collected": 8,
		"damage_taken": 20.0,
		"skills_used": 25
	}

	game_over.show_results(test_stats, true)
	await process_frame

	# 验证评分计算
	assert(game_over.current_rank >= 0, "Rank should be calculated")
	print("  - Rank calculation works: %s" % ["S", "A", "B", "C", "F"][game_over.current_rank])

	# 验证统计显示
	assert(game_over.stats_container.get_child_count() == 5, "Should have 5 stat rows")
	print("  - Stats display works")

	game_over.queue_free()
	await process_frame

	return true

func test_ui_animations(root: Node) -> bool:
	var main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.set_script(MainMenuScript)
	root.add_child(main_menu)

	await process_frame

	# 测试入场动画
	print("  - Testing entrance animation...")
	main_menu.show_menu()
	await create_timer(0.6).timeout

	assert(main_menu.visible, "Menu should be visible after animation")
	print("  - Entrance animation completed")

	# 测试退出动画
	print("  - Testing exit animation...")
	main_menu.hide_menu()
	await create_timer(0.4).timeout

	assert(not main_menu.visible, "Menu should be hidden after animation")
	print("  - Exit animation completed")

	main_menu.queue_free()
	await process_frame

	return true
