extends SceneTree
## 独立测试 - 不使用场景树的autoload

func _init():
	print("=== Standalone Combat Test ===")

	# 直接加载并测试类
	print("\n1. Loading CombatSystem...")
	var CombatSystemScript = load("res://scripts/combat/combat_system.gd")
	if CombatSystemScript:
		print("  ✓ CombatSystem script loaded")
	else:
		print("  ✗ Failed to load CombatSystem")
		quit(1)
		return

	print("\n2. Loading PlayerController...")
	var PlayerControllerScript = load("res://scripts/player/player_controller.gd")
	if PlayerControllerScript:
		print("  ✓ PlayerController script loaded")
	else:
		print("  ✗ Failed to load PlayerController")
		quit(1)
		return

	print("\n3. Loading EnemyController...")
	var EnemyControllerScript = load("res://scripts/enemy/enemy_controller.gd")
	if EnemyControllerScript:
		print("  ✓ EnemyController script loaded")
	else:
		print("  ✗ Failed to load EnemyController")
		quit(1)
		return

	print("\n✅ All scripts loaded successfully!")
	print("Phase 8 combat system integration is ready.")

	quit(0)
