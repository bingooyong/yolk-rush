extends SceneTree
## Phase 17 保存系统测试

const SaveManagerScript = preload("res://scripts/core/save_manager.gd")
const GameConfigScript = preload("res://scripts/core/game_config.gd")
const SaveLoadUIScript = preload("res://scripts/ui/save_load_ui.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 17 - Save System Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: SaveManager 初始化
	print("\n[Test 1] SaveManager Initialization")
	if await test_save_manager_init(root):
		tests_passed += 1
		print("  ✓ SaveManager init test passed")
	else:
		tests_failed += 1
		print("  ✗ SaveManager init test failed")

	# Test 2: 保存目录创建
	print("\n[Test 2] Save Directory Creation")
	if await test_save_directory(root):
		tests_passed += 1
		print("  ✓ Save directory test passed")
	else:
		tests_failed += 1
		print("  ✗ Save directory test failed")

	# Test 3: 保存游戏
	print("\n[Test 3] Save Game")
	if await test_save_game(root):
		tests_passed += 1
		print("  ✓ Save game test passed")
	else:
		tests_failed += 1
		print("  ✗ Save game test failed")

	# Test 4: 加载游戏
	print("\n[Test 4] Load Game")
	if await test_load_game(root):
		tests_passed += 1
		print("  ✓ Load game test passed")
	else:
		tests_failed += 1
		print("  ✗ Load game test failed")

	# Test 5: 存档槽管理
	print("\n[Test 5] Save Slot Management")
	if await test_save_slots(root):
		tests_passed += 1
		print("  ✓ Save slots test passed")
	else:
		tests_failed += 1
		print("  ✗ Save slots test failed")

	# Test 6: 删除存档
	print("\n[Test 6] Delete Save")
	if await test_delete_save(root):
		tests_passed += 1
		print("  ✓ Delete save test passed")
	else:
		tests_failed += 1
		print("  ✗ Delete save test failed")

	# Test 7: 数据持久化
	print("\n[Test 7] Data Persistence")
	if await test_data_persistence(root):
		tests_passed += 1
		print("  ✓ Data persistence test passed")
	else:
		tests_failed += 1
		print("  ✗ Data persistence test failed")

	# Test 8: 自动保存
	print("\n[Test 8] Auto Save")
	if await test_auto_save(root):
		tests_passed += 1
		print("  ✓ Auto save test passed")
	else:
		tests_failed += 1
		print("  ✗ Auto save test failed")

	# Test 9: SaveLoadUI
	print("\n[Test 9] SaveLoadUI")
	if await test_save_load_ui(root):
		tests_passed += 1
		print("  ✓ SaveLoadUI test passed")
	else:
		tests_failed += 1
		print("  ✗ SaveLoadUI test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 17 Save System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_save_manager_init(root: Node) -> bool:
	var save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)

	await process_frame

	# 测试初始化
	assert(save_manager != null, "SaveManager should be created")
	print("  - SaveManager created")

	# 测试配置
	assert(save_manager.MAX_SAVE_SLOTS == 3, "Should support 3 save slots")
	print("  - Save slots: %d" % save_manager.MAX_SAVE_SLOTS)

	# 测试当前槽
	assert(save_manager.current_slot == -1, "Should have no current slot")
	print("  - Initial slot: -1")

	return true

func test_save_directory(root: Node) -> bool:
	# 检查保存目录是否存在
	var dir = DirAccess.open("user://")
	assert(dir != null, "Should be able to access user directory")

	var has_saves_dir = dir.dir_exists("saves")
	assert(has_saves_dir, "Save directory should exist")
	print("  - Save directory exists: user://saves/")

	return true

func test_save_game(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 创建GameConfig用于测试
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 设置SaveManager的直接引用
	save_manager.game_config_override = game_config

	# 解锁第一个关卡
	game_config.unlock_level(0)

	# 保存到槽位0
	var save_result = save_manager.save_game(0)
	assert(save_result, "Save should succeed")
	print("  - Saved to slot 0")

	# 检查存档文件是否存在
	var save_path = "user://saves/save_0.dat"
	assert(FileAccess.file_exists(save_path), "Save file should exist")
	print("  - Save file created: %s" % save_path)

	# 检查当前槽
	assert(save_manager.current_slot == 0, "Current slot should be 0")
	print("  - Current slot: 0")

	# 清理
	game_config.queue_free()
	await process_frame

	return true

func test_load_game(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 创建新的GameConfig
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 设置SaveManager的直接引用
	save_manager.game_config_override = game_config

	# 加载槽位0
	var load_result = save_manager.load_game(0)
	assert(load_result, "Load should succeed")
	print("  - Loaded from slot 0")

	# 检查当前槽
	assert(save_manager.current_slot == 0, "Current slot should be 0")
	print("  - Current slot: 0")

	# 检查关卡解锁状态
	assert(game_config.is_level_unlocked(0), "Level 0 should be unlocked")
	print("  - Level 0 unlocked after load")

	# 清理
	game_config.queue_free()
	await process_frame

	return true

func test_save_slots(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 创建GameConfig
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 设置SaveManager的直接引用
	save_manager.game_config_override = game_config

	# 保存到多个槽位
	save_manager.save_game(0)
	save_manager.save_game(1)
	save_manager.save_game(2)

	# 获取所有存档信息
	var saves_info = save_manager.get_all_saves_info()
	assert(saves_info.size() == 3, "Should have 3 save slots")
	print("  - Total save slots: %d" % saves_info.size())

	# 检查每个槽位
	var exists_count = 0
	for save_info in saves_info:
		if save_info["exists"]:
			exists_count += 1

	assert(exists_count == 3, "All 3 slots should have saves")
	print("  - Saves exist in %d slots" % exists_count)

	# 清理
	game_config.queue_free()
	await process_frame

	return true

func test_delete_save(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 删除槽位1
	var delete_result = save_manager.delete_save(1)
	assert(delete_result, "Delete should succeed")
	print("  - Deleted save in slot 1")

	# 检查文件是否删除
	var save_path = "user://saves/save_1.dat"
	assert(not FileAccess.file_exists(save_path), "Save file should be deleted")
	print("  - Save file removed")

	# 检查是否还有存档
	assert(not save_manager.has_save(1), "Slot 1 should not have save")
	print("  - Slot 1 marked as empty")

	return true

func test_data_persistence(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 创建GameConfig并解锁关卡
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 设置SaveManager的直接引用
	save_manager.game_config_override = game_config

	game_config.unlock_level(0)
	game_config.unlock_level(1)

	# 保存
	save_manager.save_game(2)
	print("  - Saved with 2 unlocked levels")

	# 清空GameConfig
	game_config.queue_free()
	await process_frame

	# 创建新的GameConfig
	game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 更新SaveManager的直接引用
	save_manager.game_config_override = game_config

	# 加载
	save_manager.load_game(2)

	# 验证数据
	assert(game_config.is_level_unlocked(0), "Level 0 should be unlocked")
	assert(game_config.is_level_unlocked(1), "Level 1 should be unlocked")
	assert(not game_config.is_level_unlocked(2), "Level 2 should be locked")
	print("  - Data persisted correctly")

	return true

func test_auto_save(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")

	# 设置当前槽
	save_manager.current_slot = 0

	# 创建GameConfig
	var game_config = GameConfigScript.new()
	game_config.name = "GameConfig"
	root.add_child(game_config)

	await process_frame

	# 设置SaveManager的直接引用
	save_manager.game_config_override = game_config

	# 自动保存
	var auto_save_result = save_manager.auto_save()
	assert(auto_save_result, "Auto save should succeed")
	print("  - Auto save to slot 0 succeeded")

	# 验证文件存在
	assert(FileAccess.file_exists("user://saves/save_0.dat"), "Auto save file should exist")
	print("  - Auto save file created")

	# 清理
	game_config.queue_free()
	await process_frame

	return true

func test_save_load_ui(root: Node) -> bool:
	var save_manager = root.get_node("SaveManager")
	
	# 创建SaveLoadUI
	var save_load_ui = SaveLoadUIScript.new()
	save_load_ui.name = "SaveLoadUI"
	root.add_child(save_load_ui)
	
	await process_frame
	
	# 测试初始化
	assert(save_load_ui != null, "SaveLoadUI should be created")
	print("  - SaveLoadUI created")
	
	# 测试SaveManager查找
	assert(save_load_ui.save_manager != null, "Should find SaveManager")
	print("  - SaveManager found")
	
	# 测试UI组件创建
	assert(save_load_ui.title_label != null, "Title label should exist")
	assert(save_load_ui.slots_container != null, "Slots container should exist")
	assert(save_load_ui.back_button != null, "Back button should exist")
	print("  - UI components created")
	
	# 测试模式切换
	save_load_ui.set_mode(SaveLoadUIScript.UIMode.SAVE)
	assert(save_load_ui.title_label.text == "保存游戏", "Should show save title")
	print("  - Save mode works")
	
	save_load_ui.set_mode(SaveLoadUIScript.UIMode.LOAD)
	assert(save_load_ui.title_label.text == "加载游戏", "Should show load title")
	print("  - Load mode works")
	
	# 测试存档槽显示
	save_load_ui.refresh_slots()
	assert(save_load_ui.slot_buttons.size() == 3, "Should have 3 slot buttons")
	print("  - Slot buttons created: %d" % save_load_ui.slot_buttons.size())

	# 测试显示/隐藏
	save_load_ui.show_menu()
	assert(save_load_ui.visible, "Should be visible after show_menu")
	print("  - Show menu works")

	save_load_ui.hide_menu()
	assert(not save_load_ui.visible, "Should be hidden after hide_menu")
	print("  - Hide menu works")

	# 清理
	save_load_ui.queue_free()
	await process_frame
	
	return true
