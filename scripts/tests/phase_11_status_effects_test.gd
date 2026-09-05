extends SceneTree
## Phase 11 状态效果系统测试

# 预加载脚本
const StatusEffectClass = preload("res://scripts/status/status_effect.gd")
const StatusEffectInstanceClass = preload("res://scripts/status/status_effect_instance.gd")
const StatusEffectSystemClass = preload("res://scripts/status/status_effect_system.gd")
const StatusEffectDatabaseClass = preload("res://scripts/status/status_effect_database.gd")

var test_passed = 0
var test_failed = 0
var status_system
var status_database
var test_entity

func _initialize():
	print("\n" + "=".repeat(60))
	print("Phase 11 - 状态效果系统测试")
	print("=".repeat(60) + "\n")

	# 创建根节点
	var root = Node.new()
	root.name = "Root"
	get_root().add_child(root)

	# 创建测试实体
	test_entity = Node.new()
	test_entity.name = "TestEntity"
	root.add_child(test_entity)

	# 初始化系统
	status_database = StatusEffectDatabaseClass.new()
	root.add_child(status_database)

	# 手动触发加载（因为_ready还没调用）
	status_database._load_effects()

	status_system = StatusEffectSystemClass.new()
	status_system.set_database(status_database)
	root.add_child(status_system)

	# 运行测试
	test_status_effect_data()
	test_status_effect_instance()
	test_status_effect_database()
	test_status_effect_system()
	test_stacking_rules()
	test_status_removal()
	test_status_duration()

	# 打印测试结果
	print_test_summary()

	# 退出
	quit()

## 测试 StatusEffect 数据类
func test_status_effect_data() -> void:
	print("\n[测试] StatusEffect 数据类")

	var poison = StatusEffectClass.new()
	poison.effect_id = "poison"
	poison.name = "中毒"
	poison.description = "持续受到伤害"
	poison.effect_type = StatusEffectClass.EffectType.DEBUFF
	poison.icon = "res://assets/icons/poison.png"
	poison.duration = 5.0
	poison.tick_interval = 1.0
	poison.max_stacks = 5
	poison.stack_behavior = StatusEffectClass.StackBehavior.REFRESH_TIME

	assert_equal(poison.effect_id, "poison", "Effect ID 正确")
	assert_equal(poison.effect_type, StatusEffectClass.EffectType.DEBUFF, "Effect Type 正确")
	assert_equal(poison.duration, 5.0, "Duration 正确")
	assert_equal(poison.max_stacks, 5, "最大堆叠层数正确")

## 测试 StatusEffectInstance 实例类
func test_status_effect_instance() -> void:
	print("\n[测试] StatusEffectInstance 实例类")

	var poison_data = StatusEffectClass.new()
	poison_data.effect_id = "poison"
	poison_data.duration = 5.0
	poison_data.tick_interval = 1.0

	var caster = Node.new()
	var target = Node.new()

	var instance = StatusEffectInstanceClass.new(poison_data, caster, target)

	assert_equal(instance.effect_data.effect_id, "poison", "Instance 引用正确的 effect data")
	assert_equal(instance.caster, caster, "Caster 正确")
	assert_equal(instance.target, target, "Target 正确")
	assert_equal(instance.remaining_time, 5.0, "剩余持续时间正确")
	assert_equal(instance.stacks, 1, "初始堆叠层数为1")

	# 测试刷新
	instance.refresh_duration()
	assert_equal(instance.remaining_duration, 5.0, "刷新后持续时间重置")

	# 测试堆叠
	instance.add_stack()
	assert_equal(instance.current_stacks, 2, "堆叠层数增加")

	caster.queue_free()
	target.queue_free()

## 测试 StatusEffectDatabase
func test_status_effect_database() -> void:
	print("\n[测试] StatusEffectDatabase")

	# 测试数据库加载
	assert_true(status_database.effects.size() > 0, "数据库加载了状态效果")

	# 测试获取效果
	var poison = status_database.get_effect("poison")
	assert_not_null(poison, "能够获取 poison 效果")
	assert_equal(poison.effect_id, "poison", "Poison ID 正确")

	var stun = status_database.get_effect("stun")
	assert_not_null(stun, "能够获取 stun 效果")

	var speed_boost = status_database.get_effect("speed_boost")
	assert_not_null(speed_boost, "能够获取 speed_boost 效果")

## 测试 StatusEffectSystem
func test_status_effect_system() -> void:
	print("\n[测试] StatusEffectSystem")

	var caster = Node.new()
	var target = Node.new()
	get_root().get_child(0).add_child(target)

	# 测试应用效果
	var success = status_system.apply_effect("poison", caster, target)
	assert_true(success, "成功应用 poison 效果")

	# 测试获取效果
	var has_poison = status_system.has_effect(target, "poison")
	assert_true(has_poison, "Target 有 poison 效果")

	var poison_instance = status_system.get_effect(target, "poison")
	assert_not_null(poison_instance, "能够获取 poison 实例")

	# 测试移除效果
	status_system.remove_effect(target, "poison")
	assert_false(status_system.has_effect(target, "poison"), "Poison 已被移除")

	caster.queue_free()
	target.queue_free()

## 测试堆叠规则
func test_stacking_rules() -> void:
	print("\n[测试] 堆叠规则")

	var caster = Node.new()
	var target = Node.new()
	get_root().get_child(0).add_child(target)

	# 测试可堆叠效果 (poison, max 5 stacks)
	status_system.apply_effect("poison", caster, target)
	status_system.apply_effect("poison", caster, target)
	status_system.apply_effect("poison", caster, target)

	var poison = status_system.get_effect(target, "poison")
	assert_equal(poison.current_stacks, 3, "Poison 堆叠到3层")

	# 测试不可堆叠效果 (stun)
	status_system.apply_effect("stun", caster, target)
	status_system.apply_effect("stun", caster, target)

	var stun = status_system.get_effect(target, "stun")
	assert_equal(stun.current_stacks, 1, "Stun 不堆叠")

	# 清理
	status_system.clear_all_effects(target)
	caster.queue_free()
	target.queue_free()

## 测试状态移除
func test_status_removal() -> void:
	print("\n[测试] 状态移除")

	var caster = Node.new()
	var target = Node.new()
	get_root().get_child(0).add_child(target)

	# 应用多个效果
	status_system.apply_effect("poison", caster, target)
	status_system.apply_effect("stun", caster, target)
	status_system.apply_effect("speed_boost", caster, target)

	assert_equal(status_system.get_active_effects(target).size(), 3, "Target 有3个活跃效果")

	# 移除所有减益
	var removed = status_system.remove_effects_by_type(target, StatusEffectClass.EffectType.DEBUFF)
	assert_equal(removed, 2, "移除了2个减益效果")
	assert_equal(status_system.get_active_effects(target).size(), 1, "剩余1个效果")

	# 清除所有
	status_system.clear_all_effects(target)
	assert_equal(status_system.get_active_effects(target).size(), 0, "所有效果已清除")

	caster.queue_free()
	target.queue_free()

## 测试持续时间
func test_status_duration() -> void:
	print("\n[测试] 持续时间")

	var caster = Node.new()
	var target = Node.new()
	get_root().get_child(0).add_child(target)

	# 应用短时效果
	status_system.apply_effect("stun", caster, target)

	var stun = status_system.get_effect(target, "stun")
	var initial_duration = stun.remaining_duration

	assert_true(initial_duration > 0, "初始持续时间 > 0")

	# 模拟时间流逝
	status_system._process(1.0)

	stun = status_system.get_effect(target, "stun")
	if stun:
		assert_true(stun.remaining_duration < initial_duration, "持续时间递减")

	# 清理
	status_system.clear_all_effects(target)
	caster.queue_free()
	target.queue_free()

## 断言辅助函数
func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ " + message)
		test_passed += 1
	else:
		print("  ✗ " + message)
		test_failed += 1

func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)

func assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		print("  ✓ " + message + " (%s)" % str(actual))
		test_passed += 1
	else:
		print("  ✗ " + message + " (期望: %s, 实际: %s)" % [str(expected), str(actual)])
		test_failed += 1

func assert_not_null(value, message: String) -> void:
	if value != null:
		print("  ✓ " + message)
		test_passed += 1
	else:
		print("  ✗ " + message + " (值为 null)")
		test_failed += 1

func print_test_summary() -> void:
	print("\n" + "=".repeat(60))
	print("测试总结")
	print("=".repeat(60))
	print("通过: %d" % test_passed)
	print("失败: %d" % test_failed)
	print("总计: %d" % (test_passed + test_failed))

	if test_failed == 0:
		print("\n✨ 所有测试通过！Phase 11 状态效果系统运行正常！")
	else:
		print("\n⚠️  有 %d 个测试失败" % test_failed)

	print("=".repeat(60) + "\n")
