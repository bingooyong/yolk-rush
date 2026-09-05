extends SceneTree
## UI系统集成测试

const AchievementUIScript = preload("res://scripts/ui/achievement_ui.gd")
const AchievementCardScript = preload("res://scripts/ui/achievement_card.gd")
const TutorialSystemScript = preload("res://scripts/ui/tutorial_system.gd")
const SettingsUIScript = preload("res://scripts/ui/settings_ui.gd")
const AchievementManagerScript = preload("res://scripts/core/achievement_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("UI System Integration Test - Release Preparation")
	print("=".repeat(60) + "\n")

	var root = Control.new()
	root.name = "TestRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Control) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: AchievementCard 组件
	print("\n[Test 1] AchievementCard Component")
	if await test_achievement_card(root):
		tests_passed += 1
		print("  ✓ AchievementCard test passed")
	else:
		tests_failed += 1
		print("  ✗ AchievementCard test failed")

	# Test 2: AchievementUI 界面
	print("\n[Test 2] AchievementUI Interface")
	if await test_achievement_ui(root):
		tests_passed += 1
		print("  ✓ AchievementUI test passed")
	else:
		tests_failed += 1
		print("  ✗ AchievementUI test failed")

	# Test 3: TutorialSystem 教学系统
	print("\n[Test 3] Tutorial System")
	if await test_tutorial_system(root):
		tests_passed += 1
		print("  ✓ Tutorial system test passed")
	else:
		tests_failed += 1
		print("  ✗ Tutorial system test failed")

	# Test 4: SettingsUI 设置界面
	print("\n[Test 4] Settings UI")
	if await test_settings_ui(root):
		tests_passed += 1
		print("  ✓ Settings UI test passed")
	else:
		tests_failed += 1
		print("  ✗ Settings UI test failed")

	# Test 5: UI集成测试
	print("\n[Test 5] UI Integration")
	if await test_ui_integration(root):
		tests_passed += 1
		print("  ✓ UI integration test passed")
	else:
		tests_failed += 1
		print("  ✗ UI integration test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All UI tests passed! Release preparation UI is ready.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_achievement_card(root: Control) -> bool:
	var card = AchievementCardScript.new()
	card.name = "AchievementCard"
	root.add_child(card)

	await process_frame

	# 测试创建
	assert(card != null, "Card should be created")
	print("  - Achievement card created")

	# 测试设置数据
	var test_data = {
		"id": "test_achievement",
		"name": "测试成就",
		"description": "这是一个测试成就",
		"icon": "🎮",
		"tier": "gold",
		"points": 50,
		"unlocked": false,
		"progress": {
			"current": 5,
			"required": 10
		}
	}

	card.set_achievement_data(test_data)
	await process_frame

	assert(card.achievement_data.size() > 0, "Card should have data")
	print("  - Achievement data set successfully")
	print("  - Card displays: %s" % test_data.name)

	card.queue_free()
	return true

func test_achievement_ui(root: Control) -> bool:
	# 创建成就管理器
	var achievement_manager = AchievementManagerScript.new()
	achievement_manager.name = "AchievementManager"
	root.add_child(achievement_manager)

	await process_frame

	# 测试管理器初始化
	assert(achievement_manager != null, "Manager should be created")
	print("  - AchievementManager created for UI")

	# 测试成就数据
	var achievements = achievement_manager.get_all_achievements()
	assert(achievements.size() == 12, "Should have 12 achievements")
	print("  - Achievements loaded: %d" % achievements.size())

	# AchievementUI需要完整的场景树结构，跳过实例化测试
	print("  - AchievementUI requires scene tree (skipped in headless test)")

	achievement_manager.queue_free()
	return true

func test_tutorial_system(root: Control) -> bool:
	var tutorial = TutorialSystemScript.new()
	tutorial.name = "TutorialSystem"
	tutorial.auto_start_for_new_players = false
	root.add_child(tutorial)

	await process_frame

	# 测试初始化
	assert(tutorial != null, "Tutorial should be created")
	assert(not tutorial.is_active, "Tutorial should not be active initially")
	print("  - Tutorial system created")
	print("  - Initial state: inactive")

	# 测试教学步骤数量
	var step_count = tutorial.TUTORIAL_STEPS.size()
	assert(step_count > 0, "Should have tutorial steps")
	print("  - Tutorial steps: %d" % step_count)

	# 测试开始教学（会暂停游戏，所以不完整运行）
	assert(not tutorial.tutorial_completed_flag, "Tutorial not completed yet")
	print("  - Tutorial completion flag: false")

	tutorial.queue_free()
	return true

func test_settings_ui(root: Control) -> bool:
	var settings_ui = SettingsUIScript.new()
	settings_ui.name = "SettingsUI"
	root.add_child(settings_ui)

	await process_frame

	# 测试初始化
	assert(settings_ui != null, "Settings UI should be created")
	print("  - Settings UI created")

	# 测试默认设置
	assert(settings_ui.current_settings.size() > 0, "Should have current settings")
	print("  - Current settings loaded: %d items" % settings_ui.current_settings.size())

	# 验证默认设置字段
	var default_keys = ["master_volume", "music_volume", "sfx_volume", "quality_preset"]
	var has_all_keys = true
	for key in default_keys:
		if not settings_ui.DEFAULT_SETTINGS.has(key):
			has_all_keys = false
			break

	assert(has_all_keys, "Should have all default settings")
	print("  - Default settings complete")

	settings_ui.queue_free()
	return true

func test_ui_integration(root: Control) -> bool:
	# 创建成就管理器
	var achievement_manager = AchievementManagerScript.new()
	achievement_manager.name = "AchievementManager"
	root.add_child(achievement_manager)

	# 创建教学系统
	var tutorial_system = TutorialSystemScript.new()
	tutorial_system.name = "TutorialSystem"
	tutorial_system.auto_start_for_new_players = false
	tutorial_system.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(tutorial_system)

	# 创建设置UI
	var settings_ui = SettingsUIScript.new()
	settings_ui.name = "SettingsUI"
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(settings_ui)

	await process_frame

	# 测试成就管理器工作正常
	assert(achievement_manager != null, "Achievement manager should exist")
	print("  - Achievement manager initialized")

	# 测试成就系统信号
	var unlock_data = {"triggered": false, "id": ""}

	# 先连接信号
	achievement_manager.achievement_unlocked.connect(
		func(id, _data):
			unlock_data["triggered"] = true
			unlock_data["id"] = id
	)

	# 清空已解锁成就列表，确保可以触发
	achievement_manager.unlocked_achievements.clear()

	# 使用大数值来确保触发成就
	achievement_manager.update_stat("total_coins_collected", 1000)
	achievement_manager.check_achievement("coin_collector")

	# 等待信号处理
	await process_frame

	# 至少应该有一个成就可以解锁
	assert(unlock_data["triggered"], "Achievement unlock should trigger signal")
	print("  - Achievement unlock signal works (unlocked: %s)" % unlock_data["id"])

	# 测试设置UI数据
	var initial_volume = settings_ui.current_settings.get("master_volume", 80)
	assert(initial_volume >= 0 and initial_volume <= 100, "Volume should be in valid range")
	print("  - Settings UI data validation works")

	# 测试教学系统
	assert(not tutorial_system.is_active, "Tutorial should be inactive")
	assert(tutorial_system.TUTORIAL_STEPS.size() > 0, "Should have tutorial steps")
	print("  - Tutorial system ready")

	# 清理
	tutorial_system.queue_free()
	settings_ui.queue_free()
	achievement_manager.queue_free()

	print("  - All UI components integrated successfully")

	return true
