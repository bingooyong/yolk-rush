extends Node
## Phase 8 快速测试 - 验证战斗系统基本功能

const CombatSystem = preload("res://scripts/combat/combat_system.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const EnemyController = preload("res://scripts/enemy/enemy_controller.gd")

func _ready():
	print("=== Phase 8 Quick Test ===\n")

	var success = await run_test()

	if success:
		print("\n✅ 快速测试通过！")
		get_tree().quit(0)
	else:
		print("\n❌ 快速测试失败！")
		get_tree().quit(1)

func run_test() -> bool:
	print("1. 创建战斗系统")
	var combat_system = CombatSystem.new()
	add_child(combat_system)
	print("  ✓ 战斗系统已创建")

	print("\n2. 创建玩家")
	var player = PlayerController.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)
	await get_tree().process_frame
	print("  ✓ 玩家已创建")

	print("\n3. 创建敌人")
	var enemy = EnemyController.new()
	enemy.name = "Enemy"
	enemy.global_position = Vector3(5, 0, 0)
	enemy.enemy_level = 1
	add_child(enemy)
	await get_tree().process_frame
	print("  ✓ 敌人已创建")

	print("\n4. 计算伤害")
	var damage_info = combat_system.calculate_damage(
		player,
		enemy,
		50.0,
		CombatSystem.DamageType.PHYSICAL,
		true
	)
	print("  ✓ 伤害计算: %.1f" % damage_info.damage)
	if damage_info.is_crit:
		print("  ✓ 暴击！")

	print("\n5. 应用伤害")
	var initial_health = enemy.current_health
	combat_system.apply_damage(player, enemy, damage_info)
	await get_tree().process_frame

	if enemy.current_health < initial_health:
		print("  ✓ 伤害已应用: %.1f -> %.1f" % [initial_health, enemy.current_health])
	else:
		print("  ✗ 伤害应用失败")
		return false

	print("\n6. 检查战斗状态")
	if combat_system.is_in_combat(player):
		print("  ✓ 玩家处于战斗状态")

	print("\n7. 击杀敌人")
	var kill_damage = combat_system.calculate_damage(
		player,
		enemy,
		1000.0,
		CombatSystem.DamageType.TRUE,
		false
	)
	combat_system.apply_damage(player, enemy, kill_damage)
	await get_tree().create_timer(0.5).timeout

	if enemy.is_dead:
		print("  ✓ 敌人已死亡")
	else:
		print("  ✗ 敌人未死亡")
		return false

	print("\n8. 检查 GameManager 集成")
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		print("  ✓ GameManager 存在")
		if game_manager.is_initialized:
			print("  ✓ GameManager 已初始化")
		else:
			print("  ! GameManager 未初始化")
	else:
		print("  ! GameManager 不存在（已注释）")

	# 清理
	enemy.queue_free()
	player.queue_free()
	combat_system.queue_free()

	return true
