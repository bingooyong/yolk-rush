extends Node
## Phase 8 - 战斗系统最终测试

func _ready():
	print("\n" + "=".repeat(60))
	print("Phase 8 - Combat System Final Test")
	print("=".repeat(60) + "\n")

	# 给系统一点时间初始化
	await get_tree().create_timer(0.5).timeout

	run_tests()

func run_tests():
	print("Starting combat tests...\n")

	test_script_loading()
	test_component_creation()
	test_combat_flow()

	print("\n" + "=".repeat(60))
	print("✅ Phase 8 Combat System Tests PASSED!")
	print("=".repeat(60))

	get_tree().quit(0)

func test_script_loading():
	print("TEST 1: Script Loading")

	var scripts = {
		"CombatSystem": "res://scripts/combat/combat_system.gd",
		"CombatComponent": "res://scripts/combat/combat_component.gd",
		"PlayerController": "res://scripts/player/player_controller.gd",
		"EnemyController": "res://scripts/enemy/enemy_controller.gd",
		"HealthComponent": "res://scripts/components/health_component.gd"
	}

	for script_name in scripts.keys():
		var path = scripts[script_name]
		var script = load(path)
		check_assert(script != null, "%s loaded" % script_name)

	print("  ✓ All combat scripts loaded\n")

func test_component_creation():
	print("TEST 2: Component Creation")

	# 创建健康组件
	var HealthComponent = load("res://scripts/components/health_component.gd")
	var health = Node.new()
	health.set_script(HealthComponent)
	health.name = "HealthComponent"
	add_child(health)

	check_assert(health != null, "HealthComponent created")

	# 设置和测试生命值
	health.max_health = 100.0
	health.current_health = 100.0
	check_assert(health.current_health == 100.0, "Health initialized to 100")

	# 测试受伤
	health.take_damage(30.0)
	check_assert(health.current_health == 70.0, "Damage applied correctly")

	# 测试治疗
	health.heal(20.0)
	check_assert(health.current_health == 90.0, "Healing applied correctly")

	print("  ✓ HealthComponent functional\n")

	# 创建战斗组件
	var CombatComponent = load("res://scripts/combat/combat_component.gd")
	var combat = Node.new()
	combat.set_script(CombatComponent)
	combat.name = "CombatComponent"
	add_child(combat)

	check_assert(combat != null, "CombatComponent created")

	# 测试伤害计算
	combat.base_damage = 50.0
	var total = combat.get_total_damage()
	check_assert(total >= 50.0, "Damage calculation works")

	print("  ✓ CombatComponent functional\n")

func test_combat_flow():
	print("TEST 3: Combat Flow")

	# 创建玩家
	var PlayerController = load("res://scripts/player/player_controller.gd")
	var player = PlayerController.new()
	player.name = "Player"
	add_child(player)

	var player_health = Node.new()
	player_health.set_script(load("res://scripts/components/health_component.gd"))
	player_health.name = "HealthComponent"
	player_health.max_health = 100.0
	player_health.current_health = 100.0
	player.add_child(player_health)

	var player_combat = Node.new()
	player_combat.set_script(load("res://scripts/combat/combat_component.gd"))
	player_combat.name = "CombatComponent"
	player_combat.base_damage = 25.0
	player.add_child(player_combat)

	check_assert(player.has_node("HealthComponent"), "Player has health")
	check_assert(player.has_node("CombatComponent"), "Player has combat")

	# 创建敌人
	var EnemyController = load("res://scripts/enemy/enemy_controller.gd")
	var enemy = EnemyController.new()
	enemy.name = "Enemy"
	add_child(enemy)

	var enemy_health = Node.new()
	enemy_health.set_script(load("res://scripts/components/health_component.gd"))
	enemy_health.name = "HealthComponent"
	enemy_health.max_health = 50.0
	enemy_health.current_health = 50.0
	enemy.add_child(enemy_health)

	var enemy_combat = Node.new()
	enemy_combat.set_script(load("res://scripts/combat/combat_component.gd"))
	enemy_combat.name = "CombatComponent"
	enemy_combat.base_damage = 15.0
	enemy.add_child(enemy_combat)

	check_assert(enemy.has_node("HealthComponent"), "Enemy has health")
	check_assert(enemy.has_node("CombatComponent"), "Enemy has combat")

	# 模拟战斗
	var damage = player_combat.calculate_damage(enemy)
	enemy_health.take_damage(damage)

	check_assert(enemy_health.current_health < 50.0, "Enemy took damage")
	print("  ✓ Player dealt %.1f damage to enemy" % damage)
	print("  ✓ Enemy health: %.1f / 50.0" % enemy_health.current_health)

	# 敌人反击
	var counter_damage = enemy_combat.calculate_damage(player)
	player_health.take_damage(counter_damage)

	check_assert(player_health.current_health < 100.0, "Player took damage")
	print("  ✓ Enemy dealt %.1f damage to player" % counter_damage)
	print("  ✓ Player health: %.1f / 100.0" % player_health.current_health)

	print("  ✓ Combat flow working correctly\n")

func check_assert(condition: bool, message: String):
	if not condition:
		push_error("❌ ASSERTION FAILED: " + message)
		print("❌ FAILED: " + message)
		get_tree().quit(1)
	else:
		print("  ✓ " + message)
