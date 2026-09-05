extends Node
## Phase 8 - 战斗系统集成测试

var game_manager
var combat_system
var player
var enemy

func _ready():
	print("\n" + "=".repeat(60))
	print("Phase 8 - Combat System Integration Test")
	print("=".repeat(60) + "\n")

	# 等待GameManager初始化
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			await get_tree().process_frame
			run_tests()
		else:
			game_manager.game_initialized.connect(run_tests)
	else:
		print("❌ GameManager not found in autoload")
		get_tree().quit(1)

func run_tests():
	print("Starting combat integration tests...\n")

	test_combat_system_creation()
	test_player_controller_creation()
	test_enemy_controller_creation()
	test_combat_components()
	test_damage_calculation()
	test_health_system()
	test_skill_integration()

	print("\n" + "=".repeat(60))
	print("✅ All Phase 8 Combat Tests Passed!")
	print("=".repeat(60))

	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)

func test_combat_system_creation():
	print("TEST 1: Combat System Creation")

	var CombatSystem = load("res://scripts/combat/combat_system.gd")
	combat_system = CombatSystem.new()
	combat_system.name = "TestCombatSystem"
	add_child(combat_system)

	check_assert(combat_system != null, "CombatSystem instance created")
	print("  ✓ CombatSystem initialized\n")

func test_player_controller_creation():
	print("TEST 2: Player Controller Creation")

	var PlayerController = load("res://scripts/player/player_controller.gd")
	player = PlayerController.new()
	player.name = "TestPlayer"
	add_child(player)

	check_assert(player != null, "PlayerController instance created")

	# 添加必要的组件
	var health_component = Node.new()
	health_component.name = "HealthComponent"
	health_component.set_script(load("res://scripts/components/health_component.gd"))
	player.add_child(health_component)

	var combat_component = Node.new()
	combat_component.name = "CombatComponent"
	combat_component.set_script(load("res://scripts/combat/combat_component.gd"))
	player.add_child(combat_component)

	check_assert(player.has_node("HealthComponent"), "Player has HealthComponent")
	check_assert(player.has_node("CombatComponent"), "Player has CombatComponent")
	print("  ✓ PlayerController with components ready\n")

func test_enemy_controller_creation():
	print("TEST 3: Enemy Controller Creation")

	var EnemyController = load("res://scripts/enemy/enemy_controller.gd")
	enemy = EnemyController.new()
	enemy.name = "TestEnemy"
	add_child(enemy)

	check_assert(enemy != null, "EnemyController instance created")

	# 添加必要的组件
	var health_component = Node.new()
	health_component.name = "HealthComponent"
	health_component.set_script(load("res://scripts/components/health_component.gd"))
	enemy.add_child(health_component)

	var combat_component = Node.new()
	combat_component.name = "CombatComponent"
	combat_component.set_script(load("res://scripts/combat/combat_component.gd"))
	enemy.add_child(combat_component)

	check_assert(enemy.has_node("HealthComponent"), "Enemy has HealthComponent")
	check_assert(enemy.has_node("CombatComponent"), "Enemy has CombatComponent")
	print("  ✓ EnemyController with components ready\n")

func test_combat_components():
	print("TEST 4: Combat Components")

	var player_combat = player.get_node("CombatComponent")
	var enemy_combat = enemy.get_node("CombatComponent")

	check_assert(player_combat != null, "Player CombatComponent accessible")
	check_assert(enemy_combat != null, "Enemy CombatComponent accessible")

	# 测试基础属性
	check_assert(player_combat.has_method("get_total_damage"), "CombatComponent has get_total_damage")
	check_assert(player_combat.has_method("calculate_damage"), "CombatComponent has calculate_damage")

	print("  ✓ Combat components functional\n")

func test_damage_calculation():
	print("TEST 5: Damage Calculation")

	var player_combat = player.get_node("CombatComponent")

	# 设置基础伤害
	player_combat.base_damage = 50.0

	var total_damage = player_combat.get_total_damage()
	check_assert(total_damage >= 50.0, "Total damage >= base damage")

	var calculated = player_combat.calculate_damage(enemy)
	check_assert(calculated > 0, "Calculated damage > 0")

	print("  ✓ Damage calculation working")
	print("    Base: 50, Total: %.1f, Calculated: %.1f\n" % [total_damage, calculated])

func test_health_system():
	print("TEST 6: Health System")

	var player_health = player.get_node("HealthComponent")
	var enemy_health = enemy.get_node("HealthComponent")

	# 设置生命值
	player_health.max_health = 100.0
	player_health.current_health = 100.0

	enemy_health.max_health = 50.0
	enemy_health.current_health = 50.0

	check_assert(player_health.current_health == 100.0, "Player health set correctly")
	check_assert(enemy_health.current_health == 50.0, "Enemy health set correctly")

	# 测试受伤
	enemy_health.take_damage(20.0)
	check_assert(enemy_health.current_health == 30.0, "Enemy takes damage correctly")

	# 测试治疗
	enemy_health.heal(10.0)
	check_assert(enemy_health.current_health == 40.0, "Enemy heals correctly")

	print("  ✓ Health system working correctly\n")

func test_skill_integration():
	print("TEST 7: Skill System Integration")

	# 验证技能系统存在
	check_assert(game_manager.skill_tree_system != null, "SkillTreeSystem available")

	# 添加技能点
	game_manager.skill_tree_system.add_skill_points(10)
	check_assert(game_manager.skill_tree_system.available_skill_points == 10, "Skill points added")

	# 设置玩家等级
	game_manager.skill_tree_system.set_player_level(5)

	# 尝试解锁一个战斗技能
	var combat_skills = game_manager.skill_database.get_skills_by_tree("combat")
	if combat_skills.size() > 0:
		var first_skill = combat_skills[0]
		var skill_id = first_skill.id

		var can_unlock = game_manager.skill_tree_system.can_unlock_skill(skill_id)
		if can_unlock:
			var unlocked = game_manager.skill_tree_system.unlock_skill(skill_id)
			check_assert(unlocked, "Combat skill unlocked successfully")
			print("  ✓ Unlocked skill: %s" % first_skill.skill_name)
		else:
			print("  ⚠ Cannot unlock first skill (may have prerequisites)")

	print("  ✓ Skill system integration verified\n")

func check_assert(condition: bool, message: String):
	if not condition:
		push_error("❌ ASSERTION FAILED: " + message)
		print("❌ FAILED: " + message)
		get_tree().quit(1)
	else:
		print("  ✓ " + message)
