extends SceneTree
## Phase 11 - 状态效果系统测试

# 预加载脚本
const StatusEffectScript = preload("res://scripts/status/status_effect.gd")
const StatusEffectSystemScript = preload("res://scripts/status/status_effect_system.gd")

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	print("\n============================================================")
	print("Phase 11 - 状态效果系统测试")
	print("============================================================\n")

	# 创建测试环境
	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	# 运行测试
	test_status_effect_basic(root)
	test_status_effect_dot(root)
	test_status_effect_hot(root)
	test_status_effect_system(root)
	test_effect_stacking(root)
	test_control_effects(root)
	test_stat_modifiers(root)
	test_integration(root)

	# 清理
	root.queue_free()

	# 总结
	print("\n============================================================")
	print("测试完成: %d/%d 通过" % [passed, passed + failed])
	print("============================================================\n")

	quit()

## 测试 StatusEffect 基础功能
func test_status_effect_basic(root: Node) -> void:
	print("\n[测试1] StatusEffect基础功能")

	# 创建效果
	var effect = StatusEffectScript.new({
		"id": "test_buff",
		"name": "Test Buff",
		"type": StatusEffectScript.EffectType.BUFF,
		"duration": 5.0,
		"value": 10.0
	})

	assert_true(effect.effect_id == "test_buff", "效果ID应该正确")
	assert_true(effect.effect_name == "Test Buff", "效果名称应该正确")
	assert_true(effect.duration == 5.0, "持续时间应该是5秒")
	assert_true(effect.remaining_time == 5.0, "剩余时间初始化正确")
	assert_true(effect.value == 10.0, "效果数值应该是10")

	# 测试更新
	var still_active = effect.update(1.0)
	assert_true(still_active, "效果应该仍然活跃")
	assert_true(effect.remaining_time == 4.0, "剩余时间应该减少到4秒")

	# 测试过期
	effect.update(10.0)
	still_active = effect.update(0.1)
	assert_true(not still_active, "效果应该已过期")

## 测试 DOT（持续伤害）
func test_status_effect_dot(root: Node) -> void:
	print("\n[测试2] 持续伤害效果(DOT)")

	# 创建测试目标
	var target = Node.new()
	target.name = "Target"
	var target_health = 100.0

	# 给目标添加 take_damage 方法
	target.set_script(GDScript.new())
	target.set("health", target_health)

	# 创建中毒效果
	var poison = StatusEffectScript.new({
		"id": "poison",
		"name": "Poison",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.DAMAGE_OVER_TIME,
		"duration": 3.0,
		"value": 5.0,
		"tick_interval": 1.0
	})

	poison.apply(target, null)
	assert_true(poison.target == target, "目标应该被设置")

	# 模拟tick（需要目标有 take_damage 方法）
	assert_true(poison.effect_category == StatusEffectScript.EffectCategory.DAMAGE_OVER_TIME, "应该是DOT效果")
	assert_true(poison.tick_interval == 1.0, "Tick间隔应该是1秒")

	target.queue_free()

## 测试 HOT（持续治疗）
func test_status_effect_hot(root: Node) -> void:
	print("\n[测试3] 持续治疗效果(HOT)")

	var target = Node.new()
	target.name = "Target"

	var regen = StatusEffectScript.new({
		"id": "regeneration",
		"name": "Regeneration",
		"type": StatusEffectScript.EffectType.BUFF,
		"category": StatusEffectScript.EffectCategory.HEAL_OVER_TIME,
		"duration": 5.0,
		"value": 3.0,
		"tick_interval": 1.0
	})

	regen.apply(target, null)
	assert_true(regen.effect_type == StatusEffectScript.EffectType.BUFF, "应该是Buff类型")
	assert_true(regen.value == 3.0, "每次治疗3点")

	target.queue_free()

## 测试 StatusEffectSystem
func test_status_effect_system(root: Node) -> void:
	print("\n[测试4] StatusEffectSystem")

	# 创建实体
	var entity = Node.new()
	entity.name = "TestEntity"
	root.add_child(entity)

	# 添加状态系统
	var status_system = StatusEffectSystemScript.new()
	status_system.name = "StatusEffectSystem"
	entity.add_child(status_system)

	# 等待 _ready 调用
	await get_root().process_frame

	assert_true(status_system.entity == entity, "应该找到父实体")
	assert_true(status_system.get_effect_count() == 0, "初始应该没有效果")

	# 添加效果
	var buff = StatusEffectScript.new({
		"id": "test_buff",
		"name": "Test Buff",
		"duration": 5.0,
		"value": 10.0
	})

	status_system.call("add_effect", buff)
	assert_true(status_system.call("get_effect_count") == 1, "应该有1个效果")
	assert_true(status_system.call("has_effect", "test_buff"), "应该能找到效果")

	# 移除效果
	status_system.call("remove_effect_by_id", "test_buff")
	assert_true(status_system.call("get_effect_count") == 0, "效果应该被移除")

	entity.queue_free()

## 测试效果堆叠
func test_effect_stacking(root: Node) -> void:
	print("\n[测试5] 效果堆叠")

	var entity = Node.new()
	entity.name = "StackEntity"
	root.add_child(entity)

	var status_system = StatusEffectSystemScript.new()
	status_system.name = "StatusEffectSystem"
	entity.add_child(status_system)

	await get_root().process_frame

	# 创建可堆叠的效果
	var effect1 = StatusEffectScript.new({
		"id": "stackable_buff",
		"name": "Stackable Buff",
		"duration": 5.0,
		"value": 10.0,
		"max_stacks": 3,
		"stack_mode": "add"
	})

	status_system.call("add_effect", effect1)
	assert_true(status_system.call("get_effect_count") == 1, "应该有1个效果")

	var existing = status_system.call("find_effect_by_id", "stackable_buff")
	assert_true(existing.current_stacks == 1, "初始堆叠层数为1")

	# 再次添加相同效果
	var effect2 = StatusEffectScript.new({
		"id": "stackable_buff",
		"name": "Stackable Buff",
		"duration": 5.0,
		"value": 10.0,
		"max_stacks": 3,
		"stack_mode": "add"
	})

	status_system.call("add_effect", effect2)
	assert_true(status_system.call("get_effect_count") == 1, "应该还是1个效果（堆叠）")

	existing = status_system.call("find_effect_by_id", "stackable_buff")
	assert_true(existing.current_stacks == 2, "堆叠层数应该是2")
	assert_true(existing.get_total_value() == 10.0, "总数值考虑堆叠")

	entity.queue_free()

## 测试控制效果
func test_control_effects(root: Node) -> void:
	print("\n[测试6] 控制效果")

	var entity = Node.new()
	entity.name = "ControlEntity"
	root.add_child(entity)

	var status_system = StatusEffectSystemScript.new()
	status_system.name = "StatusEffectSystem"
	entity.add_child(status_system)

	await get_root().process_frame

	# 测试眩晕
	var stun = StatusEffectScript.new({
		"id": "stun",
		"name": "Stun",
		"type": StatusEffectScript.EffectType.CONTROL,
		"category": StatusEffectScript.EffectCategory.STUN,
		"duration": 2.0
	})
	status_system.call("add_effect", stun)
	assert_true(status_system.call("is_stunned"), "应该被眩晕")

	# 测试减速
	var slow = StatusEffectScript.new({
		"id": "slow",
		"name": "Slow",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.SLOW,
		"duration": 3.0,
		"value": -0.5
	})
	status_system.call("add_effect", slow)
	assert_true(status_system.call("is_slowed"), "应该被减速")

	var speed_mod = status_system.call("get_movement_speed_modifier")
	assert_true(speed_mod < 1.0, "移动速度应该降低")

	entity.queue_free()

## 测试属性修改器
func test_stat_modifiers(root: Node) -> void:
	print("\n[测试7] 属性修改器")

	var entity = Node.new()
	entity.name = "ModEntity"
	root.add_child(entity)

	var status_system = StatusEffectSystemScript.new()
	status_system.name = "StatusEffectSystem"
	entity.add_child(status_system)

	await get_root().process_frame

	# 添加攻击力提升
	var attack_boost = StatusEffectScript.new({
		"id": "attack_boost",
		"name": "Attack Boost",
		"type": StatusEffectScript.EffectType.BUFF,
		"category": StatusEffectScript.EffectCategory.STAT_MODIFIER,
		"duration": 10.0,
		"value": 0.5
	})
	status_system.call("add_effect", attack_boost)

	var attack_mod = status_system.call("get_stat_modifier", "attack")
	assert_true(attack_mod == 0.5, "攻击力修改器应该是+50%")

	entity.queue_free()

## 测试系统集成
func test_integration(root: Node) -> void:
	print("\n[测试8] 系统集成")

	var entity = Node.new()
	entity.name = "IntegrationEntity"
	root.add_child(entity)

	var status_system = StatusEffectSystemScript.new()
	status_system.name = "StatusEffectSystem"
	entity.add_child(status_system)

	await get_root().process_frame

	# 添加多个效果
	var poison = StatusEffectScript.new({
		"id": "poison",
		"name": "Poison",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.DAMAGE_OVER_TIME,
		"duration": 5.0,
		"value": 5.0
	})
	var attack_boost = StatusEffectScript.new({
		"id": "attack_boost",
		"name": "Attack Boost",
		"type": StatusEffectScript.EffectType.BUFF,
		"category": StatusEffectScript.EffectCategory.STAT_MODIFIER,
		"duration": 10.0,
		"value": 0.3
	})
	var slow = StatusEffectScript.new({
		"id": "slow",
		"name": "Slow",
		"type": StatusEffectScript.EffectType.DEBUFF,
		"category": StatusEffectScript.EffectCategory.SLOW,
		"duration": 3.0,
		"value": -0.5
	})

	status_system.call("add_effect", poison)
	status_system.call("add_effect", attack_boost)
	status_system.call("add_effect", slow)

	assert_true(status_system.call("get_effect_count") == 3, "应该有3个效果")
	assert_true(status_system.call("get_buff_count") == 1, "应该有1个Buff")
	assert_true(status_system.call("get_debuff_count") == 2, "应该有2个Debuff")

	# 清除所有Debuff
	status_system.call("clear_effects_by_type", StatusEffectScript.EffectType.DEBUFF)
	assert_true(status_system.call("get_effect_count") == 1, "应该只剩1个Buff")
	assert_true(status_system.call("get_debuff_count") == 0, "Debuff应该被清除")

	entity.queue_free()

## 断言辅助函数
func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("✓ %s" % message)
		passed += 1
	else:
		print("✗ %s" % message)
		failed += 1
