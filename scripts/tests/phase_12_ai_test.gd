extends SceneTree
## Phase 12 - AI系统测试

# 预加载所需脚本
const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")
const PerceptionScript = preload("res://scripts/ai/perception_component.gd")
const CombatAIScript = preload("res://scripts/ai/combat_ai.gd")

func _initialize() -> void:
	print("\n============================================================")
	print("Phase 12 - AI系统测试")
	print("============================================================\n")

	test_ai_controller()
	test_perception_component()
	test_combat_ai()
	test_state_transitions()
	test_target_management()
	test_skill_integration()

	print("\n============================================================")
	print("测试完成!")
	print("============================================================\n")

	quit()

## [测试1] AIController 基础功能
func test_ai_controller() -> void:
	print("\n[测试1] AIController 基础功能")

	# 创建测试实体
	var entity = Node3D.new()
	entity.name = "TestEntity"
	get_root().add_child(entity)

	# 创建 AI 控制器
	var ai = AIControllerScript.new()
	entity.add_child(ai)

	await get_root().get_tree().process_frame

	# 验证初始化
	assert(ai.controlled_entity == entity, "✓ AI应该控制实体")
	assert(ai.current_state == AIControllerScript.State.IDLE, "✓ 初始状态应该是IDLE")
	assert(ai.current_target == null, "✓ 初始没有目标")

	# 验证状态改变
	ai.change_state(AIControllerScript.State.COMBAT)
	assert(ai.current_state == AIControllerScript.State.COMBAT, "✓ 状态应该改变为COMBAT")

	# 验证获取状态名称
	var state_name = ai.get_current_state_name()
	assert(state_name == "COMBAT", "✓ 状态名称应该是COMBAT")

	entity.queue_free()

## [测试2] PerceptionComponent
func test_perception_component() -> void:
	print("\n[测试2] PerceptionComponent")

	var entity = Node3D.new()
	entity.name = "AIEntity"
	entity.global_position = Vector3.ZERO
	get_root().add_child(entity)

	var ai = AIControllerScript.new()
	entity.add_child(ai)

	await get_root().get_tree().process_frame

	# 获取感知组件
	var perception = ai.perception
	assert(perception != null, "✓ 感知组件应该被创建")

	# 验证配置
	assert(perception.sight_range > 0, "✓ 视野范围应该大于0")
	assert(perception.hearing_range > 0, "✓ 听觉范围应该大于0")

	# 验证威胁检测
	var nearest = perception.get_nearest_threat()
	assert(nearest == null, "✓ 初始没有检测到威胁")

	entity.queue_free()

## [测试3] CombatAI
func test_combat_ai() -> void:
	print("\n[测试3] CombatAI")

	var entity = Node3D.new()
	entity.name = "CombatEntity"
	get_root().add_child(entity)

	var combat_ai = CombatAIScript.new()
	entity.add_child(combat_ai)

	await get_root().get_tree().process_frame

	# 验证初始化
	assert(combat_ai.controlled_entity == entity, "✓ CombatAI应该控制实体")
	assert(combat_ai.attack_range > 0, "✓ 攻击范围应该大于0")
	assert(combat_ai.move_speed > 0, "✓ 移动速度应该大于0")

	# 验证战斗范围
	var combat_range = combat_ai._get_combat_range()
	assert(combat_range == combat_ai.attack_range, "✓ 战斗范围应该等于攻击范围")

	entity.queue_free()

## [测试4] 状态转换
func test_state_transitions() -> void:
	print("\n[测试4] 状态转换")

	var entity = Node3D.new()
	entity.name = "StateEntity"
	get_root().add_child(entity)

	var ai = AIControllerScript.new()
	ai.debug_mode = false  # 关闭调试输出
	entity.add_child(ai)

	await get_root().get_tree().process_frame

	# 测试状态转换
	var state_changed = false
	var on_state_changed = func(_old, _new): state_changed = true
	ai.state_changed.connect(on_state_changed)

	ai.change_state(AIControllerScript.State.PATROL)
	assert(state_changed, "✓ 状态改变应该触发信号")
	assert(ai.current_state == AIControllerScript.State.PATROL, "✓ 状态应该是PATROL")

	# 测试无效转换（相同状态）
	state_changed = false
	ai.change_state(AIControllerScript.State.PATROL)
	assert(not state_changed, "✓ 相同状态不应该触发信号")

	# 测试多个状态转换
	ai.change_state(AIControllerScript.State.CHASE)
	assert(ai.current_state == AIControllerScript.State.CHASE, "✓ 状态应该是CHASE")

	ai.change_state(AIControllerScript.State.COMBAT)
	assert(ai.current_state == AIControllerScript.State.COMBAT, "✓ 状态应该是COMBAT")

	ai.change_state(AIControllerScript.State.FLEE)
	assert(ai.current_state == AIControllerScript.State.FLEE, "✓ 状态应该是FLEE")

	entity.queue_free()

## [测试5] 目标管理
func test_target_management() -> void:
	print("\n[测试5] 目标管理")

	var entity = Node3D.new()
	entity.name = "TargetEntity"
	get_root().add_child(entity)

	var ai = AIControllerScript.new()
	ai.debug_mode = false
	entity.add_child(ai)

	await get_root().get_tree().process_frame

	# 创建目标
	var target = Node3D.new()
	target.name = "Target"
	target.global_position = Vector3(5, 0, 0)
	get_root().add_child(target)

	# 测试设置目标
	var target_acquired = false
	var on_target_acquired = func(_t): target_acquired = true
	ai.target_acquired.connect(on_target_acquired)

	ai.set_target(target)
	assert(target_acquired, "✓ 设置目标应该触发信号")
	assert(ai.current_target == target, "✓ 当前目标应该被设置")
	assert(ai.has_target(), "✓ has_target应该返回true")

	# 测试距离计算
	var distance = ai._get_distance_to_target()
	assert(distance > 0, "✓ 距离应该大于0")
	assert(abs(distance - 5.0) < 0.1, "✓ 距离应该约等于5米")

	# 测试清除目标
	var target_lost = false
	var on_target_lost = func(): target_lost = true
	ai.target_lost.connect(on_target_lost)

	ai.clear_target()
	assert(target_lost, "✓ 清除目标应该触发信号")
	assert(ai.current_target == null, "✓ 目标应该被清除")
	assert(not ai.has_target(), "✓ has_target应该返回false")

	target.queue_free()
	entity.queue_free()

## [测试6] 技能集成
func test_skill_integration() -> void:
	print("\n[测试6] 技能集成")

	var entity = Node3D.new()
	entity.name = "SkillEntity"
	get_root().add_child(entity)

	# 创建模拟技能系统
	var skill_system = Node.new()
	skill_system.name = "SkillSystem"
	entity.add_child(skill_system)

	var combat_ai = CombatAIScript.new()
	combat_ai.debug_mode = false
	entity.add_child(combat_ai)

	await get_root().get_tree().process_frame

	# 验证技能系统引用
	assert(combat_ai.skill_system == skill_system, "✓ CombatAI应该找到技能系统")

	# 验证战斗配置
	assert(combat_ai.attack_cooldown > 0, "✓ 攻击冷却应该大于0")
	assert(combat_ai.skill_usage_chance >= 0 and combat_ai.skill_usage_chance <= 1, "✓ 技能使用概率应该在0-1之间")
	assert(combat_ai.flee_health_threshold >= 0 and combat_ai.flee_health_threshold <= 1, "✓ 逃跑阈值应该在0-1之间")

	entity.queue_free()

func test_assert(condition: bool, message: String) -> void:
	if condition:
		print(message)
	else:
		print("✗ FAILED: " + message)
		push_error("Test failed: " + message)
