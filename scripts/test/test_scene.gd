extends Node3D
## 测试场景 - 用于测试玩家控制器和敌人 AI

@onready var player: PlayerController = $Player
@onready var combat_system: CombatSystem = $CombatSystem

var enemy_scene = preload("res://scenes/enemy.tscn") if ResourceLoader.exists("res://scenes/enemy.tscn") else null
var spawned_enemies: Array[Node] = []

func _ready():
	print("[TestScene] Initializing...")

	# 等待 GameManager 初始化
	if GameManager.is_initialized:
		_on_game_ready()
	else:
		GameManager.game_initialized.connect(_on_game_ready)

	# 连接战斗系统信号
	if combat_system:
		combat_system.damage_dealt.connect(_on_damage_dealt)
		combat_system.combat_started.connect(_on_combat_started)
		combat_system.entity_died.connect(_on_entity_died)

	# 设置玩家组
	if player:
		player.add_to_group("player")

	# 生成测试敌人
	_spawn_test_enemies()

	print("[TestScene] Ready")

func _on_game_ready():
	print("[TestScene] GameManager is ready")

	# 给玩家一些初始装备和物品
	_setup_player_inventory()

func _setup_player_inventory():
	if not GameManager:
		return

	# 添加一些初始物品
	if GameManager.item_database and GameManager.inventory_system:
		var health_potion = GameManager.item_database.get_item_by_id("health_potion")
		if health_potion:
			GameManager.inventory_system.add_item(health_potion, 5)

		var mana_potion = GameManager.item_database.get_item_by_id("mana_potion")
		if mana_potion:
			GameManager.inventory_system.add_item(mana_potion, 5)

	# 装备一些初始装备
	if GameManager.equipment_database and GameManager.equipment_system:
		var iron_sword = GameManager.equipment_database.get_equipment_by_id("iron_sword")
		if iron_sword:
			GameManager.equipment_system.equip_item(iron_sword)

		var leather_armor = GameManager.equipment_database.get_equipment_by_id("leather_armor")
		if leather_armor:
			GameManager.equipment_system.equip_item(leather_armor)

	# 解锁一些初始技能
	if GameManager.skill_tree_system:
		GameManager.skill_tree_system.add_skill_points(5)

	# 设置初始金币
	if GameManager.shop_system:
		GameManager.shop_system.set_player_gold(1000)

	print("[TestScene] Player inventory setup complete")

func _spawn_test_enemies():
	# 生成几个测试敌人
	var spawn_positions = [
		Vector3(5, 0, 5),
		Vector3(-5, 0, 5),
		Vector3(5, 0, -5),
		Vector3(-5, 0, -5),
		Vector3(0, 0, 10)
	]

	for i in range(min(3, spawn_positions.size())):
		_spawn_enemy(spawn_positions[i], 1 + i)

func _spawn_enemy(position: Vector3, level: int = 1):
	# 创建敌人实例
	var enemy = EnemyController.new()
	enemy.name = "Enemy_%d" % spawned_enemies.size()
	enemy.global_position = position
	enemy.enemy_level = level

	# 添加到场景
	add_child(enemy)
	spawned_enemies.append(enemy)

	# 添加简单的视觉表示（临时）
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 2, 1)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # 红色
	mesh_instance.material_override = material

	enemy.add_child(mesh_instance)

	# 添加碰撞形状
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 2, 1)
	collision.shape = shape
	enemy.add_child(collision)

	print("[TestScene] Spawned level %d enemy at %v" % [level, position])

func _on_damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool):
	var crit_text = " (CRIT!)" if is_crit else ""
	print("[TestScene] %s → %s: %.1f damage%s" % [attacker.name, target.name, damage, crit_text])

func _on_combat_started(attacker: Node, target: Node):
	print("[TestScene] Combat started: %s vs %s" % [attacker.name, target.name])

func _on_entity_died(entity: Node, killer: Node):
	print("[TestScene] %s was killed by %s" % [entity.name, killer.name])

	# 从列表中移除
	spawned_enemies.erase(entity)

	# 如果所有敌人都死了，生成新一波
	if spawned_enemies.is_empty():
		print("[TestScene] All enemies defeated! Spawning new wave...")
		await get_tree().create_timer(3.0).timeout
		_spawn_test_enemies()

func _input(event):
	# F1 - 生成敌人
	if event.is_action_pressed("debug_spawn_enemy"):
		if player:
			var spawn_pos = player.global_position + player.global_transform.basis.z * -5
			_spawn_enemy(spawn_pos, 1)

	# F2 - 治疗玩家
	if event.is_action_pressed("debug_heal_player"):
		if player and player.has_method("heal"):
			player.heal(50)
			print("[TestScene] Player healed")

	# F3 - 添加经验
	if event.is_action_pressed("debug_add_exp"):
		if GameManager and GameManager.level_system:
			GameManager.level_system.add_exp(100)
			print("[TestScene] Added 100 exp")

	# F4 - 添加金币
	if event.is_action_pressed("debug_add_gold"):
		if GameManager and GameManager.shop_system:
			var current = GameManager.shop_system.get_player_gold()
			GameManager.shop_system.set_player_gold(current + 100)
			print("[TestScene] Added 100 gold")

func _process(_delta):
	# 显示调试信息
	if Input.is_action_pressed("debug_info"):
		_show_debug_info()

func _show_debug_info():
	print("\n=== Debug Info ===")

	if player:
		print("Player Position: %v" % player.global_position)
		print("Player Velocity: %v" % player.velocity)

	if GameManager:
		if GameManager.level_system:
			print("Level: %d (%.1f/%.1f exp)" % [
				GameManager.level_system.get_current_level(),
				GameManager.level_system.get_current_exp(),
				GameManager.level_system.get_exp_for_next_level()
			])

		if GameManager.shop_system:
			print("Gold: %d" % GameManager.shop_system.get_player_gold())

		if GameManager.stats_system:
			var stats = GameManager.stats_system.get_all_allocated_stats()
			print("Stats: STR=%d AGI=%d VIT=%d INT=%d LUK=%d" % [
				stats.get("str", 0),
				stats.get("agi", 0),
				stats.get("vit", 0),
				stats.get("int", 0),
				stats.get("luk", 0)
			])

	if combat_system:
		print("Active Combats: %d" % combat_system.get_active_combat_count())

	print("Enemies Alive: %d" % spawned_enemies.size())
	print("==================\n")
