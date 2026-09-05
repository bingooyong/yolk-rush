extends SceneTree
## UI组件测试套件

const UIThemeScript = preload("res://scripts/ui/ui_theme.gd")
const AnimatedButtonScript = preload("res://scripts/ui/animated_button.gd")
const AnimatedHealthBarScript = preload("res://scripts/ui/animated_health_bar.gd")
const SkillCooldownDisplayScript = preload("res://scripts/ui/skill_cooldown_display.gd")
const VictoryScreenScript = preload("res://scripts/ui/victory_screen.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("UI Components Test Suite")
	print("=".repeat(60) + "\n")

	await run_all_tests()

	quit()

func run_all_tests() -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: UITheme
	print("\n[Test 1] UITheme System")
	if await test_ui_theme():
		tests_passed += 1
		print("  ✓ UITheme test passed")
	else:
		tests_failed += 1
		print("  ✗ UITheme test failed")

	# Test 2: AnimatedButton
	print("\n[Test 2] Animated Button")
	if await test_animated_button():
		tests_passed += 1
		print("  ✓ Animated button test passed")
	else:
		tests_failed += 1
		print("  ✗ Animated button test failed")

	# Test 3: AnimatedHealthBar
	print("\n[Test 3] Animated Health Bar")
	if await test_animated_health_bar():
		tests_passed += 1
		print("  ✓ Animated health bar test passed")
	else:
		tests_failed += 1
		print("  ✗ Animated health bar test failed")

	# Test 4: SkillCooldownDisplay
	print("\n[Test 4] Skill Cooldown Display")
	if await test_skill_cooldown():
		tests_passed += 1
		print("  ✓ Skill cooldown test passed")
	else:
		tests_failed += 1
		print("  ✗ Skill cooldown test failed")

	# Test 5: VictoryScreen
	print("\n[Test 5] Victory Screen")
	if await test_victory_screen():
		tests_passed += 1
		print("  ✓ Victory screen test passed")
	else:
		tests_failed += 1
		print("  ✗ Victory screen test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! UI components are working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_ui_theme() -> bool:
	# 测试颜色常量
	assert(UIThemeScript.Colors.PRIMARY != null, "PRIMARY color should exist")
	print("  - Colors defined: ✓")

	# 测试尺寸常量
	assert(UIThemeScript.Sizes.FONT_TITLE == 48, "Title font size should be 48")
	print("  - Sizes defined: ✓")

	# 测试动画常量
	assert(UIThemeScript.Animations.DURATION_NORMAL == 0.3, "Normal duration should be 0.3")
	print("  - Animation values defined: ✓")

	# 测试主题创建
	var theme = UIThemeScript.create_theme()
	assert(theme != null, "Theme should be created")
	assert(theme.has_stylebox("normal", "Button"), "Button style should exist")
	print("  - Theme creation: ✓")

	# 测试辅助函数
	var rank_color = UIThemeScript.get_rank_color("S")
	assert(rank_color != Color.WHITE, "Rank color should be defined")
	print("  - Helper functions: ✓")

	return true

func test_animated_button() -> bool:
	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	# 创建按钮
	var button = AnimatedButtonScript.new()
	button.text = "Test Button"
	button.size = Vector2(200, 60)
	root.add_child(button)

	await process_frame

	# 测试初始化
	assert(button != null, "Button should be created")
	assert(button.scale == Vector2.ONE, "Initial scale should be 1.0")
	print("  - Button created: ✓")

	# 测试属性
	assert(button.hover_scale > 1.0, "Hover scale should be > 1.0")
	assert(button.press_scale < 1.0, "Press scale should be < 1.0")
	print("  - Properties configured: ✓")

	return true

func test_animated_health_bar() -> bool:
	var root = get_root().get_node("TestRoot")

	# 创建生命条
	var health_bar = AnimatedHealthBarScript.new()
	health_bar.size = Vector2(200, 20)
	root.add_child(health_bar)

	await process_frame

	# 测试初始化
	assert(health_bar != null, "Health bar should be created")
	assert(health_bar.value == 100.0, "Initial value should be 100")
	print("  - Health bar created: ✓")

	# 测试设置数值
	health_bar.set_health(50.0, false)
	assert(health_bar.value == 50.0, "Value should be 50")
	print("  - Value setting: ✓")

	# 测试百分比
	var percent = health_bar.get_health_percent()
	assert(percent == 0.5, "Percent should be 0.5")
	print("  - Percentage calculation: ✓")

	# 测试危险状态
	health_bar.set_health(20.0, false)
	assert(health_bar.is_in_danger(), "Should be in danger at 20%")
	print("  - Danger detection: ✓")

	return true

func test_skill_cooldown() -> bool:
	var root = get_root().get_node("TestRoot")

	# 创建冷却显示（需要场景结构）
	var cooldown = SkillCooldownDisplayScript.new()
	cooldown.cooldown_time = 5.0
	root.add_child(cooldown)

	# 添加必需的子节点
	var icon_rect = TextureRect.new()
	icon_rect.name = "IconRect"
	cooldown.add_child(icon_rect)

	var overlay = ColorRect.new()
	overlay.name = "CooldownOverlay"
	cooldown.add_child(overlay)

	var label = Label.new()
	label.name = "CooldownLabel"
	cooldown.add_child(label)

	var effect = Control.new()
	effect.name = "AvailableEffect"
	cooldown.add_child(effect)

	await process_frame

	# 测试初始化
	assert(cooldown != null, "Cooldown display should be created")
	assert(cooldown.is_available(), "Should be available initially")
	print("  - Cooldown display created: ✓")

	# 测试开始冷却
	cooldown.start_cooldown(2.0)
	assert(cooldown.is_cooling_down, "Should be cooling down")
	assert(not cooldown.is_available(), "Should not be available")
	print("  - Cooldown started: ✓")

	# 测试进度
	await create_timer(1.0).timeout
	var progress = cooldown.get_cooldown_progress()
	assert(progress > 0.0 and progress < 1.0, "Progress should be between 0 and 1")
	print("  - Progress tracking: ✓")

	return true

func test_victory_screen() -> bool:
	var root = get_root().get_node("TestRoot")

	# 创建结算界面（需要场景结构）
	var victory = VictoryScreenScript.new()
	root.add_child(victory)

	# 添加必需的子节点结构
	var panel = Panel.new()
	panel.name = "Panel"
	victory.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)

	var rank_label = Label.new()
	rank_label.name = "RankLabel"
	vbox.add_child(rank_label)

	var star_container = HBoxContainer.new()
	star_container.name = "StarContainer"
	vbox.add_child(star_container)

	var stats_container = VBoxContainer.new()
	stats_container.name = "Stats"
	vbox.add_child(stats_container)

	var time_label = Label.new()
	time_label.name = "TimeLabel"
	stats_container.add_child(time_label)

	var coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	stats_container.add_child(coins_label)

	var enemies_label = Label.new()
	enemies_label.name = "EnemiesLabel"
	stats_container.add_child(enemies_label)

	var buttons_container = HBoxContainer.new()
	buttons_container.name = "Buttons"
	vbox.add_child(buttons_container)

	var next_btn = Button.new()
	next_btn.name = "NextButton"
	buttons_container.add_child(next_btn)

	var retry_btn = Button.new()
	retry_btn.name = "RetryButton"
	buttons_container.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.name = "MenuButton"
	buttons_container.add_child(menu_btn)

	await process_frame

	# 测试初始化
	assert(victory != null, "Victory screen should be created")
	assert(not victory.visible, "Should be hidden initially")
	print("  - Victory screen created: ✓")

	# 测试数据
	var stats = {
		"play_time": 120.0,
		"items_collected": 8,
		"enemies_defeated": 5,
		"damage_taken": 20
	}

	victory.show_victory(stats)
	await process_frame

	# 验证评分计算
	assert(victory.rank != "", "Rank should be calculated")
	assert(victory.stars > 0, "Stars should be awarded")
	print("  - Rank calculation: %s (%d stars)" % [victory.rank, victory.stars])

	return true
