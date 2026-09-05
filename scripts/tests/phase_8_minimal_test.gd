extends Node
## 最小化测试 - 验证脚本可以加载

func _ready():
	print("=== Minimal Test Start ===")

	print("\n1. Testing CombatSystem import")
	var CombatSystem = load("res://scripts/combat/combat_system.gd")
	if CombatSystem:
		print("  ✓ CombatSystem loaded")
	else:
		print("  ✗ CombatSystem failed to load")
		get_tree().quit(1)
		return

	print("\n2. Testing PlayerController import")
	var PlayerController = load("res://scripts/player/player_controller.gd")
	if PlayerController:
		print("  ✓ PlayerController loaded")
	else:
		print("  ✗ PlayerController failed to load")
		get_tree().quit(1)
		return

	print("\n3. Testing EnemyController import")
	var EnemyController = load("res://scripts/enemy/enemy_controller.gd")
	if EnemyController:
		print("  ✓ EnemyController loaded")
	else:
		print("  ✗ EnemyController failed to load")
		get_tree().quit(1)
		return

	print("\n4. Creating CombatSystem instance")
	var combat_system = CombatSystem.new()
	if combat_system:
		print("  ✓ CombatSystem instance created")
		add_child(combat_system)
		print("  ✓ CombatSystem added to tree")
	else:
		print("  ✗ CombatSystem instance failed")
		get_tree().quit(1)
		return

	print("\n5. Creating PlayerController instance")
	var player = PlayerController.new()
	if player:
		print("  ✓ PlayerController instance created")
		player.name = "TestPlayer"
		add_child(player)
		print("  ✓ PlayerController added to tree")
	else:
		print("  ✗ PlayerController instance failed")
		get_tree().quit(1)
		return

	print("\n✅ All basic tests passed!")
	print("Waiting 1 second before exit...")

	await get_tree().create_timer(1.0).timeout
	print("Exiting...")
	get_tree().quit(0)
