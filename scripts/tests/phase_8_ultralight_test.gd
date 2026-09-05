extends SceneTree
## Phase 8 - 超轻量级验证测试

func _init():
	print("\n" + "=".repeat(60))
	print("PHASE 8 - COMBAT SYSTEM VALIDATION")
	print("=".repeat(60) + "\n")

	var all_passed = true

	# Test 1: 脚本加载
	print("1. Testing Script Loading...")
	if not test_script_loading():
		all_passed = false

	# Test 2: 类实例化
	print("\n2. Testing Class Instantiation...")
	if not test_class_instantiation():
		all_passed = false

	# Test 3: 基础功能
	print("\n3. Testing Basic Functionality...")
	if not test_basic_functionality():
		all_passed = false

	# 总结
	print("\n" + "=".repeat(60))
	if all_passed:
		print("✅ PHASE 8 COMPLETE - ALL TESTS PASSED")
		print("=".repeat(60))
		quit(0)
	else:
		print("❌ PHASE 8 FAILED - SOME TESTS DID NOT PASS")
		print("=".repeat(60))
		quit(1)

func test_script_loading() -> bool:
	var scripts = [
		"res://scripts/combat/combat_system.gd",
		"res://scripts/combat/combat_component.gd",
		"res://scripts/player/player_controller.gd",
		"res://scripts/enemy/enemy_controller.gd",
		"res://scripts/components/health_component.gd"
	]

	for path in scripts:
		var script = load(path)
		if script == null:
			print("  ❌ Failed to load: %s" % path)
			return false
		print("  ✓ Loaded: %s" % path.get_file())

	return true

func test_class_instantiation() -> bool:
	# 测试HealthComponent
	var HealthComp = load("res://scripts/components/health_component.gd")
	var health = HealthComp.new()
	if health == null:
		print("  ❌ Failed to create HealthComponent")
		return false
	print("  ✓ HealthComponent instantiated")
	health.free()

	# 测试CombatComponent
	var CombatComp = load("res://scripts/combat/combat_component.gd")
	var combat = CombatComp.new()
	if combat == null:
		print("  ❌ Failed to create CombatComponent")
		return false
	print("  ✓ CombatComponent instantiated")
	combat.free()

	# 测试PlayerController
	var PlayerCtrl = load("res://scripts/player/player_controller.gd")
	var player = PlayerCtrl.new()
	if player == null:
		print("  ❌ Failed to create PlayerController")
		return false
	print("  ✓ PlayerController instantiated")
	player.free()

	# 测试EnemyController
	var EnemyCtrl = load("res://scripts/enemy/enemy_controller.gd")
	var enemy = EnemyCtrl.new()
	if enemy == null:
		print("  ❌ Failed to create EnemyController")
		return false
	print("  ✓ EnemyController instantiated")
	enemy.free()

	# 测试CombatSystem
	var CombatSys = load("res://scripts/combat/combat_system.gd")
	var combat_system = CombatSys.new()
	if combat_system == null:
		print("  ❌ Failed to create CombatSystem")
		return false
	print("  ✓ CombatSystem instantiated")
	combat_system.free()

	return true

func test_basic_functionality() -> bool:
	# 测试HealthComponent功能
	var HealthComp = load("res://scripts/components/health_component.gd")
	var health = HealthComp.new()

	health.max_health = 100.0
	health.current_health = 100.0

	if health.current_health != 100.0:
		print("  ❌ Health initialization failed")
		health.free()
		return false
	print("  ✓ Health initialized: 100/100")

	health.take_damage(30.0)
	if health.current_health != 70.0:
		print("  ❌ Damage application failed (expected 70, got %.1f)" % health.current_health)
		health.free()
		return false
	print("  ✓ Damage applied: 70/100")

	health.heal(20.0)
	if health.current_health != 90.0:
		print("  ❌ Healing failed (expected 90, got %.1f)" % health.current_health)
		health.free()
		return false
	print("  ✓ Healing applied: 90/100")

	health.free()

	# 测试CombatComponent功能
	var CombatComp = load("res://scripts/combat/combat_component.gd")
	var combat = CombatComp.new()

	combat.base_damage = 50.0
	var total_damage = combat.get_total_damage()

	if total_damage < 50.0:
		print("  ❌ Damage calculation failed (expected >= 50, got %.1f)" % total_damage)
		combat.free()
		return false
	print("  ✓ Damage calculated: %.1f" % total_damage)

	combat.free()

	return true
