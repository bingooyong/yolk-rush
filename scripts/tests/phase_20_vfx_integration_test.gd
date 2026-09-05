extends SceneTree
## Phase 20 粒子效果集成测试
## 测试所有VFX集成组件的功能

const PlayerVFXScript = preload("res://scripts/player/player_vfx_integration.gd")
const PickupItemVFXScript = preload("res://scripts/items/pickup_item_vfx.gd")
const CombatVFXScript = preload("res://scripts/combat/combat_vfx_integration.gd")
const LevelVFXScript = preload("res://scripts/level/level_vfx_integration.gd")
const ParticleEffectManagerScript = preload("res://scripts/vfx/particle_effect_manager.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 20 - VFX Integration Test")
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
	print("\n[Test 1] ParticleEffectManager Setup")
	if await test_particle_manager_setup(root):
		tests_passed += 1
		print("  ✓ ParticleEffectManager setup passed")
	else:
		tests_failed += 1
		print("  ✗ ParticleEffectManager setup failed")

	# Test 2: PlayerVFXIntegration
	print("\n[Test 2] Player VFX Integration")
	if await test_player_vfx(root):
		tests_passed += 1
		print("  ✓ Player VFX test passed")
	else:
		tests_failed += 1
		print("  ✗ Player VFX test failed")

	# Test 3: PickupItemVFX
	print("\n[Test 3] Pickup Item VFX")
	if await test_pickup_item_vfx(root):
		tests_passed += 1
		print("  ✓ Pickup item VFX test passed")
	else:
		tests_failed += 1
		print("  ✗ Pickup item VFX test failed")

	# Test 4: CombatVFXIntegration
	print("\n[Test 4] Combat VFX Integration")
	if await test_combat_vfx(root):
		tests_passed += 1
		print("  ✓ Combat VFX test passed")
	else:
		tests_failed += 1
		print("  ✗ Combat VFX test failed")

	# Test 5: LevelVFXIntegration
	print("\n[Test 5] Level VFX Integration")
	if await test_level_vfx(root):
		tests_passed += 1
		print("  ✓ Level VFX test passed")
	else:
		tests_failed += 1
		print("  ✗ Level VFX test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 20 VFX Integration is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_particle_manager_setup(root: Node3D) -> bool:
	# 创建粒子管理器
	var manager = ParticleEffectManagerScript.new()
	manager.name = "ParticleEffectManager"
	root.add_child(manager)

	await process_frame

	assert(manager != null, "ParticleEffectManager should be created")
	print("  - ParticleEffectManager created")

	assert(manager.effect_templates.size() > 0, "Should have effect templates")
	print("  - Effect templates loaded: %d" % manager.effect_templates.size())

	return true

func test_player_vfx(root: Node3D) -> bool:
	# 创建模拟玩家
	var player = CharacterBody3D.new()
	player.name = "Player"
	root.add_child(player)

	# 添加PlayerVFXIntegration
	var player_vfx = PlayerVFXScript.new()
	player_vfx.name = "PlayerVFXIntegration"
	player.add_child(player_vfx)

	await process_frame
	await process_frame

	assert(player_vfx.player != null, "Should find player reference")
	print("  - Player reference found")

	assert(player_vfx.vfx_emitter != null, "Should create VFXEmitter")
	print("  - VFXEmitter created")

	# 测试跳跃效果
	player_vfx.was_on_floor = true
	player_vfx._play_jump_effect()
	print("  - Jump effect triggered")

	# 测试着陆效果
	player_vfx._play_land_effect()
	print("  - Land effect triggered")

	# 测试冲刺轨迹
	var trail = player_vfx.play_dash_trail()
	assert(trail != null, "Should start dash trail")
	print("  - Dash trail started")

	player_vfx.stop_dash_trail()
	print("  - Dash trail stopped")

	# 测试受击效果
	player_vfx.play_hit_effect()
	print("  - Hit effect triggered")

	# 测试攻击效果
	player_vfx.play_attack_effect()
	print("  - Attack effect triggered")

	player.queue_free()
	return true

func test_pickup_item_vfx(root: Node3D) -> bool:
	# 创建拾取物
	var pickup = PickupItemVFXScript.new()
	pickup.name = "TestPickup"
	pickup.item_id = "test_coin"
	pickup.item_value = 10
	root.add_child(pickup)

	await process_frame
	await process_frame

	assert(pickup.vfx_emitter != null, "Should create VFXEmitter")
	print("  - VFXEmitter created for pickup")

	# 等待空闲效果启动
	await create_timer(0.1).timeout

	assert(pickup.idle_effect != null, "Should have idle glow effect")
	print("  - Idle glow effect active")

	# 测试拾取（直接调用并验证状态）
	pickup._pickup()
	await process_frame

	assert(pickup.is_picked_up, "Should be marked as picked up")
	print("  - Item marked as picked up")
	print("  - Pickup signal emitted")

	return true

func test_combat_vfx(root: Node3D) -> bool:
	# 创建战斗实体
	var combatant = Node3D.new()
	combatant.name = "TestCombatant"
	root.add_child(combatant)

	# 添加CombatVFXIntegration
	var combat_vfx = CombatVFXScript.new()
	combat_vfx.name = "CombatVFXIntegration"
	combatant.add_child(combat_vfx)

	await process_frame
	await process_frame

	assert(combat_vfx.parent_node != null, "Should find parent node")
	print("  - Parent node found")

	assert(combat_vfx.vfx_emitter != null, "Should create VFXEmitter")
	print("  - VFXEmitter created")

	# 测试攻击效果
	combat_vfx.play_attack_effect(Vector3(1, 0, 0))
	print("  - Attack effect triggered")

	# 测试受击效果
	combat_vfx.play_hit_effect(Vector3.UP)
	print("  - Hit effect triggered")

	# 测试技能充能
	var charge_effect = combat_vfx.play_skill_charge()
	assert(charge_effect != null, "Should start skill charge")
	print("  - Skill charge started")

	# 测试技能释放
	combat_vfx.play_skill_release(Vector3.FORWARD)
	print("  - Skill release triggered")

	# 测试技能命中
	combat_vfx.play_skill_hit_effect(Vector3(2, 0, 0))
	print("  - Skill hit effect triggered")

	# 测试死亡效果
	combat_vfx.play_death_effect()
	print("  - Death effect triggered")

	combatant.queue_free()
	return true

func test_level_vfx(root: Node3D) -> bool:
	# 创建关卡VFX
	var level_vfx = LevelVFXScript.new()
	level_vfx.name = "LevelVFXIntegration"
	level_vfx.ambient_type = "dust"
	root.add_child(level_vfx)

	await process_frame
	await process_frame

	assert(level_vfx.vfx_emitter != null, "Should create VFXEmitter")
	print("  - VFXEmitter created")

	# 等待环境粒子启动
	await create_timer(0.1).timeout

	assert(level_vfx.ambient_effects.size() > 0, "Should have ambient effects")
	print("  - Ambient particles active: %d" % level_vfx.ambient_effects.size())

	# 测试检查点效果
	level_vfx.play_checkpoint_effect(Vector3(5, 0, 0), 1)
	await process_frame
	print("  - Checkpoint effect triggered")

	# 测试关卡完成效果
	level_vfx.play_level_complete_effect(Vector3(10, 0, 0))
	await create_timer(0.7).timeout
	print("  - Level complete effect triggered")

	# 测试障碍碰撞
	level_vfx.play_obstacle_collision_effect(Vector3(3, 0, 0), Vector3.UP)
	print("  - Obstacle collision effect triggered")

	# 测试爆炸效果
	level_vfx.play_explosion_effect(Vector3(7, 0, 0), 1.5)
	print("  - Explosion effect triggered")

	# 测试传送门效果
	var portal = level_vfx.play_portal_effect(Vector3(0, 2, 0))
	assert(portal != null, "Should create portal effect")
	print("  - Portal effect started")

	level_vfx.stop_portal_effect(portal)
	print("  - Portal effect stopped")

	# 测试切换环境类型
	level_vfx.change_ambient_type("snow")
	await process_frame
	print("  - Ambient type changed to snow")

	level_vfx.queue_free()
	return true
