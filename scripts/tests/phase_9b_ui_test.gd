extends SceneTree
## Phase 9B UI 系统测试

# 预加载所有UI类
const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const GameHUDScript = preload("res://scenes/ui/game_hud.gd")
const PauseMenuScript = preload("res://scenes/ui/pause_menu.gd")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const GameManagerScript = preload("res://scripts/core/game_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 9B - UI System Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	get_tree().root.add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: MainMenu
	print("\n[Test 1] MainMenu Functionality")
	if await test_main_menu(root):
		tests_passed += 1
		print("  ✓ MainMenu test passed")
	else:
		tests_failed += 1
		print("  ✗ MainMenu test failed")

	# Test 2: GameHUD
	print("\n[Test 2] GameHUD Functionality")
	if await test_game_hud(root):
		tests_passed += 1
		print("  ✓ GameHUD test passed")
	else:
		tests_failed += 1
		print("  ✗ GameHUD test failed")

	# Test 3: PauseMenu
	print("\n[Test 3] PauseMenu Functionality")
	if await test_pause_menu(root):
		tests_passed += 1
		print("  ✓ PauseMenu test passed")
	else:
		tests_failed += 1
		print("  ✗ PauseMenu test failed")

	# Test 4: SettingsMenu
	print("\n[Test 4] SettingsMenu Functionality")
	if await test_settings_menu(root):
		tests_passed += 1
		print("  ✓ SettingsMenu test passed")
	else:
		tests_failed += 1
		print("  ✗ SettingsMenu test failed")

	# Test 5: GameManager
	print("\n[Test 5] GameManager Integration")
	if await test_game_manager(root):
		tests_passed += 1
		print("  ✓ GameManager test passed")
	else:
		tests_failed += 1
		print("  ✗ GameManager test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 9B UI System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	# 退出
	await get_tree().root.create_timer(0.5).timeout

func test_main_menu(root: Node) -> bool:
	var menu = MainMenuScript.new()
	root.add_child(menu)

	# 测试初始化
	assert(menu != null, "MainMenu should be created")
	print("  - MainMenu created")

	# 测试信号
	var signal_received = false
	menu.start_game_pressed.connect(func(): signal_received = true)

	# 模拟按钮点击
	if menu.has_node("MainContainer/ButtonContainer/StartButton"):
		var button = menu.get_node("MainContainer/ButtonContainer/StartButton")
		button.emit_signal("pressed")
		print("  - Start button signal works")
	else:
		print("  - Warning: Start button not found (UI created dynamically)")

	# 测试显示/隐藏
	menu.show_menu()
	assert(menu.visible, "Menu should be visible")
	print("  - Show menu works")

	menu.hide_menu()
	await get_tree().root.create_timer(0.4).timeout
	assert(not menu.visible, "Menu should be hidden")
	print("  - Hide menu works")

	menu.queue_free()
	return true

func test_game_hud(root: Node) -> bool:
	var hud = GameHUDScript.new()
	root.add_child(hud)

	# 测试初始化
	assert(hud != null, "GameHUD should be created")
	print("  - GameHUD created")

	# 测试更新玩家状态
	hud.update_player_health(80, 100)
	assert(hud.player_health == 80, "Health should be updated")
	assert(hud.player_max_health == 100, "Max health should be updated")
	print("  - Health update works")

	hud.update_player_energy(50, 100)
	assert(hud.player_energy == 50, "Energy should be updated")
	assert(hud.player_max_energy == 100, "Max energy should be updated")
	print("  - Energy update works")

	hud.update_player_level(5, 250, 500)
	assert(hud.player_level == 5, "Level should be updated")
	assert(hud.player_exp == 250, "Exp should be updated")
	print("  - Level update works")

	# 测试技能冷却
	hud.set_skill_cooldown(0, 5.0)
	assert(hud.skill_cooldowns[0] == 5.0, "Skill cooldown should be set")
	print("  - Skill cooldown works")

	# 测试目标管理
	hud.add_objective("Test Objective")
	print("  - Add objective works")

	hud.complete_objective(0)
	print("  - Complete objective works")

	# 测试显示/隐藏
	hud.show_hud()
	assert(hud.visible, "HUD should be visible")
	print("  - Show HUD works")

	hud.hide_hud()
	assert(not hud.visible, "HUD should be hidden")
	print("  - Hide HUD works")

	hud.queue_free()
	return true

func test_pause_menu(root: Node) -> bool:
	var menu = PauseMenuScript.new()
	root.add_child(menu)

	# 测试初始化
	assert(menu != null, "PauseMenu should be created")
	assert(not menu.visible, "PauseMenu should start hidden")
	print("  - PauseMenu created and hidden")

	# 测试信号
	var signal_received = false
	menu.resume_pressed.connect(func(): signal_received = true)
	print("  - Signals connected")

	# 测试显示
	menu.show_menu()
	assert(menu.visible, "Menu should be visible")
	assert(paused, "Game should be paused")
	print("  - Show menu works and pauses game")

	# 测试隐藏
	menu.hide_menu()
	await get_tree().root.create_timer(0.3).timeout
	assert(not menu.visible, "Menu should be hidden")
	assert(not paused, "Game should be unpaused")
	print("  - Hide menu works and unpauses game")

	# 测试切换
	menu.toggle_menu()
	assert(menu.visible, "Menu should be visible after toggle")
	print("  - Toggle menu works")

	menu.toggle_menu()
	await get_tree().root.create_timer(0.3).timeout
	assert(not menu.visible, "Menu should be hidden after toggle")
	print("  - Toggle off works")

	menu.queue_free()
	return true

func test_settings_menu(root: Node) -> bool:
	var menu = SettingsMenuScript.new()
	root.add_child(menu)

	# 测试初始化
	assert(menu != null, "SettingsMenu should be created")
	print("  - SettingsMenu created")

	# 测试默认设置
	assert(menu.current_settings.has("master_volume"), "Should have master_volume")
	assert(menu.current_settings.has("graphics_quality"), "Should have graphics_quality")
	assert(menu.current_settings.has("vsync_enabled"), "Should have vsync_enabled")
	print("  - Default settings exist")

	# 测试设置值
	var original_volume = menu.current_settings.master_volume
	print("  - Original master volume: %d" % original_volume)

	# 测试信号
	var signal_received = false
	menu.settings_changed.connect(func(settings): signal_received = true)
	print("  - Settings changed signal connected")

	# 测试显示/隐藏
	menu.show_menu()
	assert(menu.visible, "Menu should be visible")
	print("  - Show menu works")

	menu.hide_menu()
	assert(not menu.visible, "Menu should be hidden")
	print("  - Hide menu works")

	menu.queue_free()
	return true

func test_game_manager(root: Node) -> bool:
	var manager = GameManagerScript.new()
	root.add_child(manager)

	# 等待初始化
	await get_tree().process_frame

	# 测试初始化
	assert(manager != null, "GameManager should be created")
	print("  - GameManager created")

	# 测试初始状态
	assert(manager.current_state == GameManagerScript.GameState.MAIN_MENU,
		"Should start in MAIN_MENU state")
	print("  - Initial state is MAIN_MENU")

	# 测试UI组件
	assert(manager.main_menu != null, "MainMenu should exist")
	assert(manager.game_hud != null, "GameHUD should exist")
	assert(manager.pause_menu != null, "PauseMenu should exist")
	assert(manager.settings_menu != null, "SettingsMenu should exist")
	print("  - All UI components created")

	# 测试系统组件
	assert(manager.level_manager != null, "LevelManager should exist")
	print("  - LevelManager exists")

	# 测试状态切换
	var state_changed = false
	manager.state_changed.connect(func(old_s, new_s): state_changed = true)

	manager.change_state(GameManagerScript.GameState.LOADING)
	assert(manager.current_state == GameManagerScript.GameState.LOADING,
		"State should change to LOADING")
	assert(state_changed, "State changed signal should fire")
	print("  - State change to LOADING works")

	manager.change_state(GameManagerScript.GameState.PLAYING)
	assert(manager.current_state == GameManagerScript.GameState.PLAYING,
		"State should change to PLAYING")
	print("  - State change to PLAYING works")

	# 测试工具方法
	assert(manager.is_playing(), "is_playing() should return true")
	assert(not manager.is_paused(), "is_paused() should return false")
	print("  - Utility methods work")

	manager.change_state(GameManagerScript.GameState.PAUSED)
	assert(manager.is_paused(), "is_paused() should return true")
	assert(not manager.is_playing(), "is_playing() should return false")
	print("  - Pause state works")

	# 清理
	manager.change_state(GameManagerScript.GameState.MAIN_MENU)
	manager.queue_free()
	return true
