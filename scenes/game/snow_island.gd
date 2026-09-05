extends Node3D
## Snow Island: Phase 2 golden scene - 可玩关卡 + Phase 6 系统集成

@onready var level_builder: Node3D = $LevelBuilder
@onready var input_manager: Node = $InputManager
@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var game_hud: CanvasLayer = $GameHUD

var movement_controller: Node

func _ready() -> void:
	print("[SnowIsland] Initializing Phase 2 golden scene + Phase 6 systems")

	# Initialize GameManager
	if GameManager:
		GameManager.initialize()
		GameManager.set_hud(game_hud)
		GameManager.set_camera(camera_rig)
		print("[SnowIsland] GameManager initialized")

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
		input_manager.attack_pressed.connect(_on_attack_pressed)
		input_manager.skill_pressed.connect(_on_skill_pressed)

	# Setup camera
	if camera_rig:
		camera_rig.target = player

	# Setup skill system
	_setup_skill_system()

	# Setup combat system
	_setup_combat_system()

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
		_setup_enemy_callbacks(enemy)

	# 远程射手 x2 (后方)
	for i in range(2):
		var enemy := RangedScene.instantiate()
		enemy.global_position = player.global_position + Vector3(8.0 + i * 4.0, 0, 5.0)
		add_child(enemy)
		_setup_enemy_callbacks(enemy)

	# 坦克守卫 x1 (中央)
	var tank := TankScene.instantiate()
	tank.global_position = player.global_position + Vector3(10.0, 0, 0)
	add_child(tank)
	_setup_enemy_callbacks(tank)

	print("[SnowIsland] 生成高级敌人: 2 刺客, 2 射手, 1 守卫")

func _setup_enemy_callbacks(enemy: Node3D) -> void:
	## 为敌人设置回调，连接到 GameManager
	if enemy.has_node("HealthComponent"):
		var health = enemy.get_node("HealthComponent")
		health.damaged.connect(func(amount: float, _current: float, _max: float):
			GameManager.on_enemy_damaged(amount, enemy.global_position)
		)
		health.died.connect(func():
			GameManager.on_enemy_died(enemy.global_position)
		)

func _setup_skill_system() -> void:
	## 为玩家添加技能系统
	var SkillSystem := preload("res://scripts/systems/skill_system.gd")
	var skill_system := SkillSystem.new()
	skill_system.name = "SkillSystem"
	player.add_child(skill_system)

	# 连接技能信号到 GameManager
	skill_system.skill_cast.connect(func(skill_id: String):
		GameManager.on_skill_cast(skill_id)
		print("[SnowIsland] 释放技能: %s" % skill_id)
	)
	skill_system.skill_cooldown_started.connect(func(skill_id: String, duration: float):
		GameManager.on_skill_cooldown(skill_id, duration)
		print("[SnowIsland] 技能冷却: %s (%.1fs)" % [skill_id, duration])
	)
	skill_system.skill_ready.connect(func(skill_id: String):
		print("[SnowIsland] 技能就绪: %s" % skill_id)
	)

	# 连接冷却更新到 HUD
	skill_system.cooldown_updated.connect(func(skill_key: String, remaining: float, total: float):
		if game_hud and game_hud.has_method("update_skill_cooldown"):
			game_hud.update_skill_cooldown(skill_key, remaining, total)
	)

	print("[SnowIsland] Skill system initialized")

func _setup_combat_system() -> void:
	## 为玩家添加战斗系统回调
	if player.has_node("CombatComponent"):
		var combat = player.get_node("CombatComponent")
		combat.attack_performed.connect(func(combo_stage: int):
			GameManager.on_player_attack(combo_stage)
		)

		# 连接 combo 更新到 HUD
		if combat.has_signal("combo_updated"):
			combat.combo_updated.connect(func(combo_count: int):
				if game_hud and game_hud.has_method("update_combo"):
					game_hud.update_combo(combo_count)
			)

	if player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		health.damaged.connect(func(amount: float, current: float, max_hp: float):
			GameManager.on_player_damaged(amount, current, max_hp)
			# 更新 HUD 血条
			if game_hud and game_hud.has_method("update_health"):
				game_hud.update_health(current, max_hp)
		)
		health.died.connect(func():
			GameManager.on_player_died()
		)

		# 连接护盾变化
		if health.has_signal("shield_changed"):
			health.shield_changed.connect(func(current: float, max_shield: float):
				GameManager.on_player_shield_changed(current, max_shield)
			)

		# 初始化 HUD 血条显示
		if game_hud and game_hud.has_method("update_health"):
			var current_hp = health.current_health if "current_health" in health else 100.0
			var max_hp = health.max_health if "max_health" in health else 100.0
			game_hud.update_health(current_hp, max_hp)

	print("[SnowIsland] Combat system callbacks connected")
