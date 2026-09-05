extends SceneTree
## 教学系统测试

const TutorialControllerScript = preload("res://scripts/tutorial/tutorial_controller.gd")
const TutorialUIScript = preload("res://scripts/tutorial/tutorial_ui.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Tutorial System Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: TutorialController 初始化
	print("\n[Test 1] TutorialController Initialization")
	if await test_tutorial_controller_init(root):
		tests_passed += 1
		print("  ✓ TutorialController init test passed")
	else:
		tests_failed += 1
		print("  ✗ TutorialController init test failed")

	# Test 2: 教学配置加载
	print("\n[Test 2] Tutorial Config Loading")
	if await test_tutorial_config_loading(root):
		tests_passed += 1
		print("  ✓ Tutorial config loading test passed")
	else:
		tests_failed += 1
		print("  ✗ Tutorial config loading test failed")

	# Test 3: 教学步骤触发
	print("\n[Test 3] Tutorial Step Triggering")
	if await test_tutorial_step_triggering(root):
		tests_passed += 1
		print("  ✓ Tutorial step triggering test passed")
	else:
		tests_failed += 1
		print("  ✗ Tutorial step triggering test failed")

	# Test 4: 教学进度追踪
	print("\n[Test 4] Tutorial Progress Tracking")
	if await test_tutorial_progress(root):
		tests_passed += 1
		print("  ✓ Tutorial progress test passed")
	else:
		tests_failed += 1
		print("  ✗ Tutorial progress test failed")

	# Test 5: TutorialUI
	print("\n[Test 5] TutorialUI")
	if await test_tutorial_ui(root):
		tests_passed += 1
		print("  ✓ TutorialUI test passed")
	else:
		tests_failed += 1
		print("  ✗ TutorialUI test failed")

	# Test 6: 关卡1配置验证
	print("\n[Test 6] Level 1 Config Validation")
	if await test_level_1_config():
		tests_passed += 1
		print("  ✓ Level 1 config test passed")
	else:
		tests_failed += 1
		print("  ✗ Level 1 config test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Tutorial System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_tutorial_controller_init(root: Node) -> bool:
	var controller = TutorialControllerScript.new()
	controller.name = "TutorialController"
	root.add_child(controller)

	await process_frame

	# 测试初始化
	assert(controller != null, "TutorialController should be created")
	print("  - TutorialController created")

	# 测试初始状态
	assert(controller.tutorial_enabled == true, "Tutorial should be enabled by default")
	print("  - Tutorial enabled: %s" % controller.tutorial_enabled)

	assert(controller.current_step_index == 0, "Initial step index should be 0")
	print("  - Initial step index: 0")

	return true

func test_tutorial_config_loading(root: Node) -> bool:
	var controller = root.get_node("TutorialController")

	# 加载测试配置
	var test_config = {
		"tutorial_steps": [
			{
				"id": "step1",
				"trigger": "start",
				"message": "Welcome!",
				"duration": 2.0
			},
			{
				"id": "step2",
				"trigger": "player_moved",
				"message": "Move around",
				"wait_for": "player_moved"
			}
		]
	}

	controller.load_tutorial(test_config)

	# 验证加载
	assert(not controller.tutorial_config.is_empty(), "Config should be loaded")
	print("  - Tutorial config loaded")

	assert(controller.step_states.size() == 2, "Should have 2 step states")
	print("  - Step states initialized: %d" % controller.step_states.size())

	return true

func test_tutorial_step_triggering(root: Node) -> bool:
	var controller = root.get_node("TutorialController")

	var step_completed = false
	controller.tutorial_step_completed.connect(func(_step_id): step_completed = true)

	# 开始教学
	controller.start_tutorial()

	await process_frame
	await create_timer(0.1).timeout

	# 验证第一个步骤被激活
	var active_step = controller.get_active_step()
	assert(not active_step.is_empty(), "Should have an active step")
	print("  - Active step: %s" % active_step.id)

	# 等待步骤完成
	await create_timer(2.2).timeout

	assert(step_completed, "Step should be completed")
	print("  - Step completed signal received")

	return true

func test_tutorial_progress(root: Node) -> bool:
	var controller = root.get_node("TutorialController")

	# 完成所有步骤
	for step_id in controller.step_states.keys():
		controller.complete_step(step_id)

	# 检查进度
	var progress = controller.get_progress()
	assert(progress == 1.0, "Progress should be 100%")
	print("  - Progress: %.1f%%" % (progress * 100))

	# 检查完成状态
	assert(controller.is_completed(), "Tutorial should be completed")
	print("  - Tutorial completed: true")

	# 获取统计
	var stats = controller.get_statistics()
	assert(stats.completed_steps == 2, "Should have 2 completed steps")
	print("  - Statistics: %d/%d steps completed" % [stats.completed_steps, stats.total_steps])

	return true

func test_tutorial_ui(root: Node) -> bool:
	var ui = TutorialUIScript.new()
	ui.name = "TutorialUI"
	root.add_child(ui)

	await process_frame

	# 测试初始化
	assert(ui != null, "TutorialUI should be created")
	print("  - TutorialUI created")

	# 测试显示消息
	ui.show_tutorial_ui()
	assert(ui.visible, "UI should be visible")
	print("  - UI visible: true")

	ui.show_tutorial_message("Test message", 0.5)
	await process_frame

	assert(ui.is_showing_message, "Should be showing message")
	print("  - Message displayed")

	# 测试进度更新
	ui.update_progress(50.0)
	print("  - Progress updated")

	# 测试隐藏
	ui.hide_tutorial_ui()
	assert(not ui.visible, "UI should be hidden")
	print("  - UI hidden: true")

	return true

func test_level_1_config() -> bool:
	# 加载关卡1配置
	var config_path = "res://data/levels/level_01_tutorial.json"

	if not FileAccess.file_exists(config_path):
		print("  ✗ Level 1 config file not found")
		return false

	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("  ✗ Failed to open config file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		print("  ✗ Failed to parse JSON: %s" % json.get_error_message())
		return false

	var config = json.data

	# 验证配置结构
	assert(config.has("name"), "Config should have name")
	print("  - Level name: %s" % config.name)

	assert(config.has("objectives"), "Config should have objectives")
	print("  - Objectives: %d" % config.objectives.size())

	assert(config.has("tutorial_steps"), "Config should have tutorial steps")
	print("  - Tutorial steps: %d" % config.tutorial_steps.size())

	assert(config.has("enemies"), "Config should have enemies")
	print("  - Enemies: %d" % config.enemies.size())

	assert(config.has("items"), "Config should have items")
	print("  - Items: %d" % config.items.size())

	assert(config.has("obstacles"), "Config should have obstacles")
	print("  - Obstacles: %d" % config.obstacles.size())

	# 验证教学步骤
	for step in config.tutorial_steps:
		assert(step.has("id"), "Step should have id")
		assert(step.has("trigger"), "Step should have trigger")
		assert(step.has("message"), "Step should have message")

	print("  - All tutorial steps valid")

	return true
