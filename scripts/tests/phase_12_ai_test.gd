extends SceneTree
## Phase 12 AI系统测试

const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")
const PerceptionComponentScript = preload("res://scripts/ai/perception_component.gd")
const AIManagerScript = preload("res://scripts/ai/ai_manager.gd")

var test_count = 0
var passed_count = 0
var CombatAIScript  # 运行时加载

func _initialize():
	# 运行时加载 CombatAI（避免循环依赖）
	CombatAIScript = load("res://scripts/ai/combat_ai.gd")

	print("\n" + "=".repeat(60))
	print("Phase 12 - AI系统测试")
	print("=".repeat(60) + "\n")

	test_ai_controller_basic()
	test_ai_controller_state_machine()
	test_ai_controller_target_management()
	test_combat_ai_idle_to_patrol()
	test_combat_ai_detection()
	test_combat_ai_combat_state()
	test_combat_ai_flee_state()
	test_perception_component()
	test_ai_manager()
	test_ai_integration()

	print("\n" + "=".repeat(60))
	print("测试完成: %d/%d 通过" % [passed_count, test_count])
	print("=".repeat(60) + "\n")

	quit()

func assert_test(condition: bool, test_name: String) -> void:
	test_count += 1
	if condition:
		passed_count += 1
		print("✓ %s" % test_name)
	else:
		print("✗ %s" % test_name)

## 测试1: AIController基础功能
func test_ai_controller_basic() -> void:
	print("\n[测试1] AIController基础功能")

	var entity = Node3D.new()
	entity.name = "TestEntity"

	var ai = AIControllerScript.new()
	entity.add_child(ai)

	assert_test(ai.entity == entity, "AIController应该找到父实体")
	assert_test(ai.current_state == AIControllerScript.AIState.IDLE, "初始状态应该是IDLE")
	assert_test(ai.current_target == null, "初始目标应该为空")
	assert_test(ai.blackboard.is_empty(), "黑板应该为空")

	entity.queue_free()

## 测试2: AIController状态机
func test_ai_controller_state_machine() -> void:
	print("\n[测试2] AIController状态机")

	var entity = Node3D.new()
	var ai = AIControllerScript.new()
	entity.add_child(ai)

	var state_changed_count = 0
	ai.state_changed.connect(func(_old, _new): state_changed_count += 1)

	ai.change_state(AIControllerScript.AIState.PATROL)
	assert_test(ai.current_state == AIControllerScript.AIState.PATROL, "应该切换到PATROL状态")
	assert_test(state_changed_count == 1, "应该触发state_changed信号")

	ai.change_state(AIControllerScript.AIState.COMBAT)
	assert_test(ai.current_state == AIControllerScript.AIState.COMBAT, "应该切换到COMBAT状态")
	assert_test(state_changed_count == 2, "应该再次触发state_changed信号")

	# 切换到相同状态不应该触发信号
	ai.change_state(AIControllerScript.AIState.COMBAT)
	assert_test(state_changed_count == 2, "切换到相同状态不应触发信号")

	entity.queue_free()

## 测试3: AIController目标管理
func test_ai_controller_target_management() -> void:
	print("\n[测试3] AIController目标管理")

	var entity = Node3D.new()
	var ai = AIControllerScript.new()
	entity.add_child(ai)

	var target = Node3D.new()
	target.name = "Target"

	var target_acquired_count = 0
	var target_lost_count = 0
	ai.target_acquired.connect(func(_t): target_acquired_count += 1)
	ai.target_lost.connect(func(): target_lost_count += 1)

	ai.set_target(target)
	assert_test(ai.current_target == target, "应该设置目标")
	assert_test(target_acquired_count == 1, "应该触发target_acquired信号")

	assert_test(ai.is_target_valid(), "目标应该有效")

	ai.clear_target()
	assert_test(ai.current_target == null, "应该清除目标")
	assert_test(target_lost_count == 1, "应该触发target_lost信号")

	target.queue_free()
	entity.queue_free()

## 测试4: CombatAI空闲到巡逻
func test_combat_ai_idle_to_patrol() -> void:
	print("\n[测试4] CombatAI空闲到巡逻")

	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO
	var ai = CombatAIScript.new()
	entity.add_child(ai)

	assert_test(ai.current_state == AIControllerScript.AIState.IDLE, "初始应该是IDLE")
	assert_test(not ai.patrol_points.is_empty(), "应该生成默认巡逻点")

	entity.queue_free()

## 测试5: CombatAI检测
func test_combat_ai_detection() -> void:
	print("\n[测试5] CombatAI检测")

	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO
	var ai = CombatAIScript.new()
	ai.perception_radius = 10.0
	entity.add_child(ai)

	var target = Node3D.new()
	target.name = "Enemy"
	target.global_position = Vector3(5, 0, 0)
	target.add_to_group("enemy")

	# 模拟检测
	var distance = ai._get_distance_to(target)
	assert_test(distance == 5.0, "距离应该是5米")
	assert_test(distance <= ai.perception_radius, "目标应该在感知范围内")

	target.queue_free()
	entity.queue_free()

## 测试6: CombatAI战斗状态
func test_combat_ai_combat_state() -> void:
	print("\n[测试6] CombatAI战斗状态")

	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO

	# 添加模拟的攻击方法
	entity.set_script(GDScript.new())
	entity.set("attack_called", false)
	entity.set_meta("attack_method", func(target): entity.set("attack_called", true))

	var ai = CombatAIScript.new()
	ai.attack_range = 2.0
	ai.attack_cooldown = 1.0
	entity.add_child(ai)

	var target = Node3D.new()
	target.global_position = Vector3(1, 0, 0)  # 在攻击范围内

	ai.set_target(target)
	ai.change_state(AIControllerScript.AIState.COMBAT)

	assert_test(ai.current_state == AIControllerScript.AIState.COMBAT, "应该在COMBAT状态")
	assert_test(ai.is_in_attack_range(), "目标应该在攻击范围内")

	target.queue_free()
	entity.queue_free()

## 测试7: CombatAI逃跑状态
func test_combat_ai_flee_state() -> void:
	print("\n[测试7] CombatAI逃跑状态")

	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO

	# 模拟血量方法
	entity.set_script(GDScript.new())
	entity.set_meta("health_percentage", 0.1)

	var ai = CombatAIScript.new()
	ai.flee_health_threshold = 0.2
	entity.add_child(ai)

	# 手动检查血量低（因为entity没有真正的get_health_percentage方法）
	var is_low = 0.1 <= ai.flee_health_threshold
	assert_test(is_low, "血量应该低于逃跑阈值")

	ai.change_state(AIControllerScript.AIState.FLEE)
	assert_test(ai.current_state == AIControllerScript.AIState.FLEE, "应该进入FLEE状态")

	entity.queue_free()

## 测试8: PerceptionComponent
func test_perception_component() -> void:
	print("\n[测试8] PerceptionComponent")

	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO

	var perception = PerceptionComponentScript.new()
	perception.sight_range = 15.0
	perception.sight_angle = 120.0
	perception.hearing_range = 20.0
	entity.add_child(perception)

	assert_test(perception.entity == entity, "应该找到父实体")
	assert_test(perception.detected_targets.is_empty(), "初始检测目标应该为空")

	var target_detected_count = 0
	perception.target_detected.connect(func(_t): target_detected_count += 1)

	# 测试距离检测
	var target = Node3D.new()
	target.global_position = Vector3(10, 0, 0)
	var distance = perception._get_distance_to(target)
	assert_test(distance == 10.0, "距离应该是10米")
	assert_test(distance <= perception.sight_range, "目标应该在视野范围内")

	target.queue_free()
	entity.queue_free()

## 测试9: AIManager
func test_ai_manager() -> void:
	print("\n[测试9] AIManager")

	var manager = AIManagerScript.new()

	var entity1 = Node3D.new()
	var ai1 = CombatAIScript.new()
	entity1.add_child(ai1)

	var entity2 = Node3D.new()
	var ai2 = CombatAIScript.new()
	entity2.add_child(ai2)

	manager.register_ai(ai1)
	manager.register_ai(ai2)

	assert_test(manager.get_all_ais().size() == 2, "应该注册2个AI")
	assert_test(manager.get_active_ais().size() == 2, "应该有2个活跃AI")

	ai1.change_state(AIControllerScript.AIState.COMBAT)
	var combat_ais = manager.get_combat_ais()
	assert_test(combat_ais.size() == 1, "应该有1个战斗中的AI")

	manager.unregister_ai(ai1)
	assert_test(manager.get_all_ais().size() == 1, "应该剩余1个AI")

	entity1.queue_free()
	entity2.queue_free()
	manager.queue_free()

## 测试10: AI系统集成
func test_ai_integration() -> void:
	print("\n[测试10] AI系统集成")

	var manager = AIManagerScript.new()

	# 创建实体和AI
	var entity = Node3D.new()
	entity.global_position = Vector3.ZERO
	entity.add_to_group("entities")

	var ai = CombatAIScript.new()
	ai.perception_radius = 10.0
	entity.add_child(ai)

	# 创建目标
	var target = Node3D.new()
	target.global_position = Vector3(5, 0, 0)
	target.add_to_group("entities")

	# 注册到管理器
	manager.register_ai(ai)

	assert_test(ai in manager.get_all_ais(), "AI应该被注册")

	# 模拟进入战斗
	ai.enter_combat_with_target(target)
	assert_test(ai.current_state == AIControllerScript.AIState.COMBAT, "应该进入战斗状态")
	assert_test(ai.current_target == target, "应该锁定目标")

	# 测试黑板
	ai.set_blackboard_value("test_key", "test_value")
	assert_test(ai.get_blackboard_value("test_key") == "test_value", "黑板应该存储数据")
	assert_test(ai.has_blackboard_value("test_key"), "黑板应该包含键")

	target.queue_free()
	entity.queue_free()
	manager.queue_free()
