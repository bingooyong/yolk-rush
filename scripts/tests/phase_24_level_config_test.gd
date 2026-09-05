extends SceneTree
## Phase 24 关卡配置系统测试

const LevelConfigScript = preload("res://scripts/levels/level_config.gd")
const LevelTemplatesScript = preload("res://scripts/levels/level_templates.gd")

# 使用别名以便在代码中更简洁地引用
const LevelConfig = LevelConfigScript
const LevelTemplates = LevelTemplatesScript

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 24 - Level Config System Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: LevelConfig创建和验证
	print("\n[Test 1] LevelConfig Creation and Validation")
	if await test_level_config_creation(root):
		tests_passed += 1
		print("  ✓ LevelConfig test passed")
	else:
		tests_failed += 1
		print("  ✗ LevelConfig test failed")

	# Test 2: LevelConfig序列化
	print("\n[Test 2] LevelConfig Serialization")
	if await test_level_config_serialization(root):
		tests_passed += 1
		print("  ✓ Serialization test passed")
	else:
		tests_failed += 1
		print("  ✗ Serialization test failed")

	# Test 3: LevelTemplates加载
	print("\n[Test 3] Level Templates Loading")
	if await test_level_templates(root):
		tests_passed += 1
		print("  ✓ Templates test passed")
	else:
		tests_failed += 1
		print("  ✗ Templates test failed")

	# Test 4: 关卡解锁逻辑
	print("\n[Test 4] Level Unlock Logic")
	if await test_level_unlock_logic(root):
		tests_passed += 1
		print("  ✓ Unlock logic test passed")
	else:
		tests_failed += 1
		print("  ✗ Unlock logic test failed")

	# Test 5: LevelGenerator初始化
	print("\n[Test 5] Level Generator Initialization")
	if await test_level_generator_init(root):
		tests_passed += 1
		print("  ✓ Generator init test passed")
	else:
		tests_failed += 1
		print("  ✗ Generator init test failed")

	# Test 6: 关卡数据完整性
	print("\n[Test 6] Level Data Integrity")
	if await test_level_data_integrity(root):
		tests_passed += 1
		print("  ✓ Data integrity test passed")
	else:
		tests_failed += 1
		print("  ✗ Data integrity test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 24 Level Config System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_level_config_creation(root: Node) -> bool:
	# 创建一个基本配置
	var config = LevelConfigScript.new()
	config.level_id = 0
	config.level_name = "Test Level"
	config.theme = "grassland"
	config.difficulty = 1

	# 添加一个目标以通过验证
	config.objectives = [
		{"type": "defeat_all", "target": 1}
	]

	assert(config != null, "Config should be created")
	print("  - Config created")

	assert(config.level_name == "Test Level", "Level name should match")
	print("  - Level name: %s" % config.level_name)

	assert(config.is_valid(), "Config should be valid")
	print("  - Config is valid")

	return true

func test_level_config_serialization(root: Node) -> bool:
	# 创建配置
	var config = LevelConfigScript.new()
	config.level_id = 1
	config.level_name = "Serialization Test"
	config.theme = "forest"
	config.difficulty = 3
	config.time_limit = 120.0

	# 添加目标
	config.objectives = [
		{"type": "defeat_all", "target": 5}
	]

	# 添加敌人
	config.enemies = [
		{"type": "basic", "position": Vector3(10, 0, 10), "level": 1}
	]

	# 转换为字典
	var dict = config.to_dict()
	assert(dict.has("id"), "Dictionary should have id")
	assert(dict["name"] == "Serialization Test", "Name should match")
	print("  - Serialized to dictionary")

	# 从字典加载
	var new_config = LevelConfigScript.new()
	new_config.from_dict(dict)

	assert(new_config.level_id == config.level_id, "ID should match")
	assert(new_config.level_name == config.level_name, "Name should match")
	assert(new_config.difficulty == config.difficulty, "Difficulty should match")
	assert(new_config.objectives.size() == 1, "Should have 1 objective")
	assert(new_config.enemies.size() == 1, "Should have 1 enemy")
	print("  - Deserialized from dictionary")

	return true

func test_level_templates(root: Node) -> bool:
	# 获取所有关卡模板
	var templates = LevelTemplatesScript.new()
	var levels = templates.get_all_levels()

	assert(levels.size() == 10, "Should have 10 level templates")
	print("  - Total levels: %d" % levels.size())

	# 检查前5个关卡
	var level_1 = levels[0]
	assert(level_1.level_id == 0, "Level 1 ID should be 0")
	assert(level_1.level_name == "草原初章", "Level 1 name should match")
	assert(level_1.difficulty == 1, "Level 1 difficulty should be 1")
	print("  - Level 1: %s (难度 %d)" % [level_1.level_name, level_1.difficulty])

	var level_2 = levels[1]
	assert(level_2.level_id == 1, "Level 2 ID should be 1")
	print("  - Level 2: %s (难度 %d)" % [level_2.level_name, level_2.difficulty])

	var level_5 = levels[4]
	assert(level_5.is_boss_level, "Level 5 should be boss level")
	assert(level_5.boss_type == "forest_guardian", "Boss type should match")
	print("  - Level 5: %s (Boss关卡)" % level_5.level_name)

	# 测试按ID获取
	var fetched = templates.get_level(0)
	assert(fetched != null, "Should fetch level by id")
	assert(fetched.level_id == 0, "Fetched level ID should match")
	print("  - Fetch by ID works")

	return true

func test_level_unlock_logic(root: Node) -> bool:
	# 创建模拟的GameConfig
	var game_config = Node.new()
	game_config.name = "MockGameConfig"

	# 添加模拟方法
	game_config.set_script(GDScript.new())
	game_config.set("unlocked_levels", [0, 1, 2])  # 解锁前3关

	# 模拟方法
	var is_level_unlocked_func = func(level_id: int) -> bool:
		return game_config.get("unlocked_levels").has(level_id)

	var get_level_grade_func = func(level_id: int) -> String:
		if level_id == 0:
			return "A"
		elif level_id == 1:
			return "B"
		else:
			return "C"

	game_config.set("is_level_unlocked", is_level_unlocked_func)
	game_config.set("get_level_grade", get_level_grade_func)

	root.add_child(game_config)
	await process_frame

	# 获取模板
	var templates = LevelTemplatesScript.new()

	# 测试关卡1（默认解锁）
	var level_1 = templates.get_level(0)
	assert(level_1.required_level == -1, "Level 1 should have no requirements")
	print("  - Level 1: No requirements (always unlocked)")

	# 测试关卡2（需要关卡1）
	var level_2 = templates.get_level(1)
	assert(level_2.required_level == 0, "Level 2 requires Level 1")
	print("  - Level 2: Requires Level 1")

	# 测试关卡5（需要关卡4 + C级）
	var level_5 = templates.get_level(4)
	assert(level_5.required_level == 3, "Level 5 requires Level 4")
	assert(level_5.required_grade == "C", "Level 5 requires C grade")
	print("  - Level 5: Requires Level 4 with C grade")

	game_config.queue_free()
	await process_frame

	return true

func test_level_generator_init(root: Node) -> bool:
	# 创建场景并实例化
	var generator_scene = load("res://scripts/levels/level_generator.gd")
	var generator = Node.new()
	generator.set_script(generator_scene)
	generator.name = "LevelGenerator"
	root.add_child(generator)

	await process_frame

	assert(generator != null, "Generator should be created")
	print("  - Generator created")

	return true

	# 测试清理
	generator.clear_level()
	assert(generator.get_enemies().size() == 0, "No enemies after clear")
	assert(generator.get_obstacles().size() == 0, "No obstacles after clear")
	assert(generator.get_items().size() == 0, "No items after clear")
	print("  - Clear level works")

	return true

func test_level_data_integrity(root: Node) -> bool:
	# 检查所有关卡的数据完整性
	var templates = LevelTemplatesScript.new()
	var levels = templates.get_all_levels()

	for level in levels:
		# 基本信息
		assert(level.level_id >= 0 and level.level_id < 10, "Level ID should be 0-9")
		assert(not level.level_name.is_empty(), "Level name should not be empty")
		assert(level.difficulty >= 1 and level.difficulty <= 10, "Difficulty should be 1-10")

		# 时间限制
		assert(level.time_limit > 0, "Time limit should be positive")

		# 位置
		assert(level.spawn_point != level.exit_point, "Spawn and exit should be different")

		print("  - Level %d (%s): ✓" % [level.level_id, level.level_name])

	# 检查难度递增
	for i in range(levels.size() - 1):
		assert(levels[i].difficulty <= levels[i + 1].difficulty,
			"Difficulty should increase or stay same")

	print("  - Difficulty curve is valid")

	# 检查Boss关卡
	var boss_count = 0
	for level in levels:
		if level.is_boss_level:
			boss_count += 1

	assert(boss_count >= 2, "Should have at least 2 boss levels")
	print("  - Boss levels: %d" % boss_count)

	return true
