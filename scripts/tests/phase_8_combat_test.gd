extends Node
## Phase 8 测试脚本 - 战斗系统集成测试

# 预加载类
const CombatSystem = preload("res://scripts/combat/combat_system.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const EnemyController = preload("res://scripts/enemy/enemy_controller.gd")

func _ready():
	print("=== Phase 8: Combat System Integration Test ===\n")

	# 等待一帧确保所有 autoload 加载完成
	await get_tree().process_frame

	var success = await run_test()

	if success:
		print("\n✅ Phase 8 测试通过！")
		get_tree().quit(0)
	else:
		print("\n❌ Phase 8 测试失败！")
		get_tree().quit(1)

func run_test() -> bool:
	print("测试 1: 战斗系统初始化")

	# 创建战斗系统
	var combat_system = CombatSystem.new()
	add_child(combat_system)

	if not combat_system:
		print("  ✗ 战斗系统创建失败")
		return false

	print("  ✓ 战斗系统创建成功")

	# 测试 2: 玩家控制器
	print("\n测试 2: 玩家控制器")

	var player = PlayerController.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)

	if not player:
		print("  ✗ 玩家控制器创建失败")
		combat_system.free()
		return false

	print("  ✓ 玩家控制器创建成功")

	# 等待玩家初始化
	await get_tree().process_frame

	# 测试 3: 敌人控制器
	print("\n测试 3: 敌人控制器")

	var enemy = EnemyController.new()
	enemy.name = "Enemy"
	enemy.global_position = Vector3(5, 0, 0)
	enemy.enemy_level = 1
	add_child(enemy)

	if not enemy:
		print("  ✗ 敌人控制器创建失败")
		player.free()
		combat_system.free()
		return false

	print("  ✓ 敌人控制器创建成功")

	# 测试 4: 伤害计算
	print("\n测试 4: 伤害计算")

	var damage_info = combat_system.calculate_damage(
		player,
		enemy,
		50.0,
		CombatSystem.DamageType.PHYSICAL,
		true
	)

	if not damage_info.has("damage"):
		print("  ✗ 伤害计算失败")
		enemy.free()
		player.free()
		combat_system.free()
		return false

	print("  ✓ 伤害计算成功: %.1f 伤害" % damage_info.damage)
	if damage_info.is_crit:
		print("  ✓ 触发暴击！")
	if damage_info.is_dodged:
		print("  ✓ 攻击被闪避")

	# 测试 5: 应用伤害
	print("\n测试 5: 应用伤害")

	var initial_health = enemy.current_health
	combat_system.apply_damage(player, enemy, damage_info)

	await get_tree().process_frame

	if enemy.current_health >= initial_health:
		print("  ✗ 伤害未应用")
		enemy.free()
		player.free()
		combat_system.free()
		return false

	print("  ✓ 伤害应用成功: %.1f -> %.1f HP" % [initial_health, enemy.current_health])

	# 测试 6: 战斗状态
	print("\n测试 6: 战斗状态")

	if not combat_system.is_in_combat(player):
		print("  ✗ 玩家未进入战斗状态")
		enemy.free()
		player.free()
		combat_system.free()
		return false

	print("  ✓ 玩家已进入战斗状态")
	print("  ✓ 活跃战斗数: %d" % combat_system.get_active_combat_count())

	# 测试 7: 敌人死亡
	print("\n测试 7: 敌人死亡和掉落")

	# 检查 GameManager 是否存在
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and not game_manager.is_initialized:
		print("  等待 GameManager 初始化...")
		await game_manager.game_initialized

	# 记录初始背包大小
	var initial_item_count = 0
	if game_manager and game_manager.inventory_system:
		initial_item_count = game_manager.inventory_system.get_item_count()

	# 造成致命伤害
	var kill_damage_info = combat_system.calculate_damage(
		player,
		enemy,
		enemy.current_health + 100.0,
		CombatSystem.DamageType.TRUE,
		false
	)

	combat_system.apply_damage(player, enemy, kill_damage_info)

	# 等待死亡处理
	await get_tree().create_timer(0.5).timeout

	if not enemy.is_dead:
		print("  ✗ 敌人未死亡")
		enemy.free()
		player.free()
		combat_system.free()
		return false

	print("  ✓ 敌人已死亡")

	# 等待掉落处理
	await get_tree().create_timer(0.5).timeout

	# 检查是否有掉落
	if game_manager and game_manager.inventory_system:
		var final_item_count = game_manager.inventory_system.get_item_count()
		if final_item_count > initial_item_count:
			print("  ✓ 掉落物品已添加到背包 (%d -> %d 物品)" % [initial_item_count, final_item_count])
		else:
			print("  ! 未掉落物品（正常，掉落可能为空）")

	# 测试 8: 战斗系统与 GameManager 集成
	print("\n测试 8: GameManager 集成")

	if game_manager and game_manager.level_system:
		var player_level = game_manager.level_system.get_current_level()
		print("  ✓ 玩家等级: %d" % player_level)

	if game_manager and game_manager.stats_system:
		var total_stats = game_manager.get_total_player_stats()
		print("  ✓ 玩家总属性: 物理攻击=%.1f, 暴击率=%.1f%%" % [
			total_stats.get("physical_damage", 0),
			total_stats.get("crit_chance", 0)
		])

	if game_manager and game_manager.shop_system:
		var gold = game_manager.shop_system.get_player_gold()
		print("  ✓ 玩家金币: %d" % gold)

	# 测试 9: 信号系统
	print("\n测试 9: 信号系统")

	var signal_received = false

	var on_damage = func(attacker, target, damage, is_crit):
		signal_received = true
		print("  ✓ damage_dealt 信号触发")

	combat_system.damage_dealt.connect(on_damage)

	# 创建新敌人测试信号
	var test_enemy = EnemyController.new()
	test_enemy.name = "TestEnemy"
	test_enemy.global_position = Vector3(10, 0, 0)
	add_child(test_enemy)

	var test_damage = combat_system.calculate_damage(
		player,
		test_enemy,
		10.0,
		CombatSystem.DamageType.PHYSICAL,
		false
	)

	combat_system.apply_damage(player, test_enemy, test_damage)

	await get_tree().process_frame

	if not signal_received:
		print("  ✗ 信号未触发")
		test_enemy.free()
		enemy.free()
		player.free()
		combat_system.free()
		return false

	print("  ✓ 信号系统工作正常")

	# 测试 10: 玩家统计获取
	print("\n测试 10: 玩家统计")

	var player_stats = player.get_player_stats()
	if player_stats.is_empty():
		print("  ! 玩家统计为空（可能 GameManager 未完全初始化）")
	else:
		print("  ✓ 玩家统计获取成功")
		print("    - 物理伤害: %.1f" % player_stats.get("physical_damage", 0))
		print("    - 暴击率: %.1f%%" % player_stats.get("crit_chance", 0))
		print("    - 攻击速度: %.1f%%" % player_stats.get("attack_speed", 0))

	# 清理
	test_enemy.free()
	enemy.free()
	player.free()
	combat_system.free()

	return true
