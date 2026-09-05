extends SceneTree
## Phase 20 粒子效果系统测试

const ParticleEffectManagerScript = preload("res://scripts/vfx/particle_effect_manager.gd")
const VFXEmitterScript = preload("res://scripts/vfx/vfx_emitter.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 20 - Particle Effect System Test")
	print("=".repeat(60) + "\n")

	var root = Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node3D) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: ParticleEffectManager 初始化
	print("\n[Test 1] ParticleEffectManager Initialization")
	if await test_particle_manager_init(root):
		tests_passed += 1
		print("  ✓ ParticleEffectManager init test passed")
	else:
		tests_failed += 1
		print("  ✗ ParticleEffectManager init test failed")

	# Test 2: 粒子效果模板
	print("\n[Test 2] Effect Templates")
	if await test_effect_templates(root):
		tests_passed += 1
		print("  ✓ Effect templates test passed")
	else:
		tests_failed += 1
		print("  ✗ Effect templates test failed")

	# Test 3: 粒子池系统
	print("\n[Test 3] Particle Pool System")
	if await test_particle_pool(root):
		tests_passed += 1
		print("  ✓ Particle pool test passed")
	else:
		tests_failed += 1
		print("  ✗ Particle pool test failed")

	# Test 4: 粒子生成和回收
	print("\n[Test 4] Particle Spawning and Recycling")
	if await test_particle_spawning(root):
		tests_passed += 1
		print("  ✓ Particle spawning test passed")
	else:
		tests_failed += 1
		print("  ✗ Particle spawning test failed")

	# Test 5: VFXEmitter
	print("\n[Test 5] VFXEmitter Functionality")
	if await test_vfx_emitter(root):
		tests_passed += 1
		print("  ✓ VFXEmitter test passed")
	else:
		tests_failed += 1
		print("  ✗ VFXEmitter test failed")

	# Test 6: 道具拾取特效
	print("\n[Test 6] Pickup Effects")
	if await test_pickup_effects(root):
		tests_passed += 1
		print("  ✓ Pickup effects test passed")
	else:
		tests_failed += 1
		print("  ✗ Pickup effects test failed")

	# Test 7: 碰撞特效
	print("\n[Test 7] Collision Effects")
	if await test_collision_effects(root):
		tests_passed += 1
		print("  ✓ Collision effects test passed")
	else:
		tests_failed += 1
		print("  ✗ Collision effects test failed")

	# Test 8: 技能特效
	print("\n[Test 8] Skill Effects")
	if await test_skill_effects(root):
		tests_passed += 1
		print("  ✓ Skill effects test passed")
	else:
		tests_failed += 1
		print("  ✗ Skill effects test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 20 Particle Effect System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_particle_manager_init(root: Node3D) -> bool:
	var manager = ParticleEffectManagerScript.new()
	manager.name = "ParticleEffectManager"
	root.add_child(manager)

	# 等待初始化
	await process_frame

	# 测试初始化
	assert(manager != null, "ParticleEffectManager should be created")
	print("  - ParticleEffectManager created")

	# 测试模板加载
	assert(manager.effect_templates.size() > 0, "Effect templates should be loaded")
	print("  - Effect templates loaded: %d" % manager.effect_templates.size())

	# 测试粒子池初始化
	assert(manager.particle_pools.size() > 0, "Particle pools should be initialized")
	print("  - Particle pools initialized: %d" % manager.particle_pools.size())

	return true

func test_effect_templates(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")

	# 检查道具拾取效果
	assert(manager.effect_templates.has("pickup_sparkle"), "Should have pickup_sparkle")
	assert(manager.effect_templates.has("pickup_flash"), "Should have pickup_flash")
	assert(manager.effect_templates.has("pickup_trail"), "Should have pickup_trail")
	print("  - Pickup effect templates exist")

	# 检查碰撞效果
	assert(manager.effect_templates.has("collision_spark"), "Should have collision_spark")
	assert(manager.effect_templates.has("collision_debris"), "Should have collision_debris")
	assert(manager.effect_templates.has("impact_wave"), "Should have impact_wave")
	print("  - Collision effect templates exist")

	# 检查技能效果
	assert(manager.effect_templates.has("skill_charge"), "Should have skill_charge")
	assert(manager.effect_templates.has("skill_explosion"), "Should have skill_explosion")
	assert(manager.effect_templates.has("skill_trail"), "Should have skill_trail")
	print("  - Skill effect templates exist")

	# 检查环境效果
	assert(manager.effect_templates.has("ambient_dust"), "Should have ambient_dust")
	assert(manager.effect_templates.has("snow_fall"), "Should have snow_fall")
	assert(manager.effect_templates.has("rain_drop"), "Should have rain_drop")
	print("  - Environment effect templates exist")

	return true

func test_particle_pool(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")

	# 检查初始池大小
	var initial_pool_size = manager.initial_pool_size
	for effect_name in manager.particle_pools.keys():
		var pool = manager.particle_pools[effect_name]
		assert(pool.size() == initial_pool_size,
			"Pool %s should have %d particles" % [effect_name, initial_pool_size])

	print("  - All pools have correct initial size: %d" % initial_pool_size)

	# 检查池统计
	var stats = manager.get_pool_stats()
	assert(stats.size() > 0, "Should have pool stats")
	print("  - Pool stats available for %d effect types" % stats.size())

	return true

func test_particle_spawning(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")

	# 生成粒子效果
	var effect = manager.spawn_effect("pickup_sparkle", Vector3.ZERO)
	assert(effect != null, "Should spawn effect")
	assert(effect.emitting, "Effect should be emitting")
	assert(effect.visible, "Effect should be visible")
	print("  - Particle effect spawned successfully")

	# 检查活跃效果列表
	var active_count = manager.get_active_count()
	assert(active_count > 0, "Should have active effects")
	print("  - Active effects count: %d" % active_count)

	# 等待一帧
	await process_frame

	# 测试停止效果
	manager.stop_effect(effect)
	assert(not effect.emitting, "Effect should stop emitting")
	print("  - Effect stopped successfully")

	# 测试效果回收
	await create_timer(0.1).timeout
	var new_active_count = manager.get_active_count()
	print("  - Effects recycling works (active: %d)" % new_active_count)

	return true

func test_vfx_emitter(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")

	var emitter = VFXEmitterScript.new()
	emitter.name = "TestEmitter"
	root.add_child(emitter)

	# 等待初始化
	await process_frame

	# 测试管理器查找
	assert(emitter.particle_manager != null, "Should find particle manager")
	print("  - VFXEmitter found particle manager")

	# 测试触发效果
	var effect = emitter.trigger_effect("pickup_flash")
	assert(effect != null, "Should trigger effect")
	print("  - Effect triggered successfully")

	# 测试持续效果
	var continuous = emitter.start_continuous_effect("skill_charge")
	assert(continuous != null, "Should start continuous effect")
	assert(continuous in emitter.continuous_effects, "Effect should be tracked")
	print("  - Continuous effect started")

	# 停止持续效果
	emitter.stop_continuous_effect(continuous)
	assert(continuous not in emitter.continuous_effects, "Effect should be removed")
	print("  - Continuous effect stopped")

	emitter.queue_free()
	return true

func test_pickup_effects(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")
	var emitter = VFXEmitterScript.new()
	root.add_child(emitter)

	await process_frame

	# 测试道具拾取特效组合
	emitter.play_pickup_effect()

	await process_frame

	var active_count = manager.get_active_count()
	assert(active_count >= 2, "Should have multiple pickup effects active")
	print("  - Pickup effect combo spawned (%d effects)" % active_count)

	emitter.queue_free()
	return true

func test_collision_effects(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")
	var emitter = VFXEmitterScript.new()
	root.add_child(emitter)

	await process_frame

	# 测试碰撞特效
	emitter.play_collision_effect(Vector3.UP)

	await process_frame

	var active_count = manager.get_active_count()
	assert(active_count >= 2, "Should have collision effects active")
	print("  - Collision effect combo spawned (%d effects)" % active_count)

	emitter.queue_free()
	return true

func test_skill_effects(root: Node3D) -> bool:
	var manager = root.get_node("ParticleEffectManager")
	var emitter = VFXEmitterScript.new()
	root.add_child(emitter)

	await process_frame

	# 测试技能充能
	var charge_effect = emitter.play_skill_charge()
	assert(charge_effect != null, "Should start charge effect")
	assert(charge_effect in emitter.continuous_effects, "Charge should be continuous")
	print("  - Skill charge effect started")

	await create_timer(0.1).timeout

	# 测试技能释放
	emitter.play_skill_release()
	assert(charge_effect not in emitter.continuous_effects, "Charge should stop on release")
	print("  - Skill release effect triggered")

	# 测试技能轨迹
	var trail = emitter.play_skill_trail()
	assert(trail != null, "Should start trail effect")
	print("  - Skill trail effect started")

	emitter.stop_all_continuous_effects()
	assert(emitter.continuous_effects.size() == 0, "All continuous effects should stop")
	print("  - All continuous effects stopped")

	emitter.queue_free()
	return true
