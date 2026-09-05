extends SceneTree
## Phase 12 AI系统测试运行器

func _init():
	print("=" * 60)
	print("Phase 12 - AI System Test")
	print("=" * 60)

	# 预加载所有需要的脚本
	var AIControllerScript = load("res://scripts/ai/ai_controller.gd")
	var PerceptionComponentScript = load("res://scripts/ai/perception_component.gd")
	var CombatAIScript = load("res://scripts/ai/combat_ai.gd")

	print("\n✓ All scripts loaded successfully")

	# 运行测试
	var success = true
	success = test_ai_controller(AIControllerScript) and success
	success = test_perception_component(PerceptionComponentScript) and success
	success = test_combat_ai(CombatAIScript) and success

	print("\n" + "=" * 60)
	if success:
		print("✅ All tests PASSED")
	else:
		print("❌ Some tests FAILED")
	print("=" * 60)

	quit(0 if success else 1)

func test_ai_controller(AIControllerScript) -> bool:
	print("\n[Test 1] AIController Basic Functionality")

	var root = Node.new()
	var ai = AIControllerScript.new()
	root.add_child(ai)

	# 测试初始状态
	if ai.current_state != "idle":
		print("  ❌ Initial state should be 'idle', got '%s'" % ai.current_state)
		return false
	print("  ✓ Initial state is 'idle'")

	# 测试状态转换
	var state_changed = false
	ai.state_changed.connect(func(_old, _new): state_changed = true)

	ai.change_state("patrol")
	if ai.current_state != "patrol" or not state_changed:
		print("  ❌ State transition failed")
		return false
	print("  ✓ State transition works")

	# 测试目标管理
	var target = Node3D.new()
	target.name = "TestTarget"
	root.add_child(target)

	var target_acquired = false
	ai.target_acquired.connect(func(_t): target_acquired = true)

	ai.set_target(target)
	if ai.current_target != target or not target_acquired:
		print("  ❌ Target management failed")
		return false
	print("  ✓ Target management works")

	# 清理
	root.queue_free()
	print("  ✅ AIController tests passed")
	return true

func test_perception_component(PerceptionComponentScript) -> bool:
	print("\n[Test 2] PerceptionComponent")

	var root = Node3D.new()
	var perception = PerceptionComponentScript.new()
	root.add_child(perception)

	perception.sight_range = 10.0
	perception.sight_angle = 90.0
	perception.hearing_range = 15.0

	# 创建测试目标
	var target = Node3D.new()
	target.position = Vector3(5, 0, 0)  # 在视野范围内
	root.add_child(target)

	# 测试感知
	var detected_targets = perception.detect_targets([target])

	if detected_targets.size() == 0:
		print("  ❌ Should detect target in range")
		return false
	print("  ✓ Target detection works")

	# 测试范围外
	target.position = Vector3(20, 0, 0)  # 超出范围
	detected_targets = perception.detect_targets([target])

	if detected_targets.size() > 0:
		print("  ❌ Should not detect target out of range")
		return false
	print("  ✓ Range detection works")

	# 清理
	root.queue_free()
	print("  ✅ PerceptionComponent tests passed")
	return true

func test_combat_ai(CombatAIScript) -> bool:
	print("\n[Test 3] CombatAI")

	var root = Node3D.new()
	var ai = CombatAIScript.new()
	root.add_child(ai)

	# 配置AI参数
	ai.attack_range = 3.0
	ai.move_speed = 4.0
	ai.attack_cooldown = 1.0
	ai.skill_usage_chance = 0.5

	# 测试初始化
	if ai.current_state != "idle":
		print("  ❌ CombatAI should start in idle state")
		return false
	print("  ✓ CombatAI initialized")

	# 测试战斗状态转换
	var enemy = Node3D.new()
	enemy.position = Vector3(2, 0, 0)
	root.add_child(enemy)

	ai.set_target(enemy)
	ai.change_state("combat")

	if ai.current_state != "combat":
		print("  ❌ Failed to enter combat state")
		return false
	print("  ✓ Combat state transition works")

	# 清理
	root.queue_free()
	print("  ✅ CombatAI tests passed")
	return true
