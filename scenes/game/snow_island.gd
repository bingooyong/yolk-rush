extends Node3D
## Snow Island: Phase 2 golden scene - 可玩关卡

@onready var level_builder: Node3D = $LevelBuilder
@onready var input_manager: Node = $InputManager
@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var combat_ui: Control = $CombatUI

var movement_controller: Node

func _ready() -> void:
	print("[SnowIsland] Initializing Phase 2 golden scene")

	# Load level
	if level_builder:
		level_builder.level_loaded.connect(_on_level_loaded)
		level_builder.load_level("snow_island_01")

	# Setup movement controller
	_setup_movement_controller()

	# Connect input
	if input_manager:
		input_manager.move_input.connect(_on_move_input)
		input_manager.jump_pressed.connect(_on_jump_pressed)
		input_manager.attack_pressed.connect(_on_attack_pressed)  ## 连接攻击输入

	# Setup camera
	if camera_rig:
		camera_rig.target = player

	# Setup combat UI
	if combat_ui:
		combat_ui.set_player(player)

func _setup_movement_controller() -> void:
	var MovementController := preload("res://scripts/gameplay/movement_controller.gd")
	movement_controller = MovementController.new()
	movement_controller.set("character_body", player)
	movement_controller.set("move_speed", 5.0)
	movement_controller.set("jump_velocity", 7.5)
	add_child(movement_controller)

func _on_level_loaded(level_id: String) -> void:
	print("[SnowIsland] Level loaded: %s" % level_id)

	# Position player at spawn point
	if player and level_builder:
		var spawn: Vector3 = level_builder.get_spawn_point()
		player.global_position = spawn
		print("[SnowIsland] Player spawned at: %s" % spawn)

	# Spawn test enemies for combat testing
	_spawn_test_enemies()

func _on_move_input(direction: Vector2) -> void:
	if movement_controller:
		movement_controller.set_move_input(direction)

func _on_jump_pressed() -> void:
	if movement_controller:
		movement_controller.jump()

func _on_attack_pressed() -> void:
	if movement_controller:
		movement_controller.attack()

func _process(_delta: float) -> void:
	# Update camera basis for movement controller
	if movement_controller and camera_rig:
		movement_controller.set_camera_basis(camera_rig.get_camera_basis())

func _spawn_test_enemies() -> void:
	var TestEnemyScene := preload("res://scenes/gameplay/test_enemy.tscn")

	# Spawn 3 enemies in front of player
	for i in range(3):
		var enemy := TestEnemyScene.instantiate()
		enemy.global_position = player.global_position + Vector3(5.0 + i * 3.0, 0, 0)
		add_child(enemy)

	print("[SnowIsland] Spawned 3 test enemies")
