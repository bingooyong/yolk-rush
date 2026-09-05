extends Node3D
## 游戏示例场景 - 完整的游戏流程演示

@onready var game_manager: GameManager
@onready var camera: Camera3D

func _ready() -> void:
	print("=== Game Example Scene ===")
	_setup_scene()
	_setup_game_manager()
	print("[GameExample] Scene ready")

func _setup_scene() -> void:
	# 设置相机
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 15, 15)
	camera.rotation_degrees = Vector3(-45, 0, 0)
	camera.fov = 60
	add_child(camera)

	# 添加环境光
	var env_light = DirectionalLight3D.new()
	env_light.name = "DirectionalLight"
	env_light.position = Vector3(0, 10, 0)
	env_light.rotation_degrees = Vector3(-45, 45, 0)
	env_light.light_energy = 0.8
	env_light.shadow_enabled = true
	add_child(env_light)

	# 添加环境光照
	var ambient = WorldEnvironment.new()
	ambient.name = "WorldEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.3
	ambient.environment = environment
	add_child(ambient)

func _setup_game_manager() -> void:
	# 创建游戏管理器
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

	# 连接信号
	game_manager.game_started.connect(_on_game_started)
	game_manager.game_paused.connect(_on_game_paused)
	game_manager.game_resumed.connect(_on_game_resumed)
	game_manager.state_changed.connect(_on_state_changed)

func _on_game_started() -> void:
	print("[GameExample] Game started!")

func _on_game_paused() -> void:
	print("[GameExample] Game paused")

func _on_game_resumed() -> void:
	print("[GameExample] Game resumed")

func _on_state_changed(old_state, new_state) -> void:
	print("[GameExample] State changed: %d -> %d" % [old_state, new_state])
