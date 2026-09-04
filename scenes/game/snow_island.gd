extends Node3D
## Snow Island: Phase 2 golden scene - 可玩关卡

@onready var level_builder: Node3D = $LevelBuilder
@onready var input_manager: Node = $InputManager
@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var combat_ui: Control = $CombatUI
@onready var skill_ui: Control = $SkillUI

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
		input_manager.skill_pressed.connect(_on_skill_pressed)  ## 连接技能输入

	# Setup camera
	if camera_rig:
		camera_rig.target = player

	# Setup combat UI
	if combat_ui:
		combat_ui.set_player(player)

	# Setup skill UI
	if skill_ui:
		skill_ui.set_player(player)

	# Setup skill system
	_setup_skill_system()

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
	_spawn_advanced_enemies()

func _on_move_input(direction: Vector2) -> void:
	if movement_controller:
		movement_controller.set_move_input(direction)

func _on_jump_pressed() -> void:
	if movement_controller:
		movement_controller.jump()

func _on_attack_pressed() -> void:
	if movement_controller:
		movement_controller.attack()

func _on_skill_pressed(skill_key: String) -> void:
	## 技能输入处理
	if player and player.has_node("SkillSystem"):
		var skill_system = player.get_node("SkillSystem")
		skill_system.cast_skill(skill_key)

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

func _spawn_advanced_enemies() -> void:
	## 生成 3 种类型的高级敌人
	var MeleeScene := preload("res://scenes/enemies/melee_assassin.tscn")
	var RangedScene := preload("res://scenes/enemies/ranged_archer.tscn")
	var TankScene := preload("res://scenes/enemies/tank_guardian.tscn")

	# 近战刺客 x2 (前方)
	for i in range(2):
		var enemy := MeleeScene.instantiate()
		enemy.global_position = player.global_position + Vector3(5.0 + i * 3.0, 0, -2.0)
		add_child(enemy)

	# 远程射手 x2 (后方)
	for i in range(2):
		var enemy := RangedScene.instantiate()
		enemy.global_position = player.global_position + Vector3(8.0 + i * 4.0, 0, 5.0)
		add_child(enemy)

	# 坦克守卫 x1 (中央)
	var tank := TankScene.instantiate()
	tank.global_position = player.global_position + Vector3(10.0, 0, 0)
	add_child(tank)

	print("[SnowIsland] 生成高级敌人: 2 刺客, 2 射手, 1 守卫")

func _setup_skill_system() -> void:
	## 为玩家添加技能系统
	var SkillSystem := preload("res://scripts/game/skill_system.gd")
	var skill_system := SkillSystem.new()
	skill_system.name = "SkillSystem"
	player.add_child(skill_system)

	# 连接技能信号
	skill_system.skill_cast.connect(_on_skill_cast)
	skill_system.skill_cooldown_started.connect(_on_skill_cooldown_started)
	skill_system.skill_ready.connect(_on_skill_ready)

	print("[SnowIsland] Skill system initialized")

func _on_skill_cast(skill_id: String) -> void:
	print("[SnowIsland] 释放技能: %s" % skill_id)

func _on_skill_cooldown_started(skill_id: String, duration: float) -> void:
	print("[SnowIsland] 技能冷却: %s (%.1fs)" % [skill_id, duration])

func _on_skill_ready(skill_id: String) -> void:
	print("[SnowIsland] 技能就绪: %s" % skill_id)
