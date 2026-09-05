extends Node3D
## Level 01 Tutorial Scene
## 新手训练场关卡场景

## 关卡配置
@export var level_config_path: String = "res://data/levels/level_01_tutorial.json"

## 管理器引用
var level_flow_controller: Node = null
var tutorial_controller: Node = null
var game_state_manager: Node = null

## 关卡配置数据
var level_config: Dictionary = {}

## 场景组件
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var environment_node: WorldEnvironment = $WorldEnvironment
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D

func _ready() -> void:
	print("[Level01Tutorial] Initializing...")

	# 加载关卡配置
	_load_level_config()

	# 查找管理器
	_find_managers()

	# 设置环境
	_setup_environment()

	# 生成关卡内容
	_spawn_level_content()

	# 初始化教学系统
	_initialize_tutorial()

	print("[Level01Tutorial] Initialized")

## 加载关卡配置
func _load_level_config() -> void:
	if not FileAccess.file_exists(level_config_path):
		push_error("[Level01Tutorial] Config file not found: %s" % level_config_path)
		return

	var file = FileAccess.open(level_config_path, FileAccess.READ)
	if not file:
		push_error("[Level01Tutorial] Failed to open config file")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[Level01Tutorial] Failed to parse JSON: %s" % json.get_error_message())
		return

	level_config = json.data
	print("[Level01Tutorial] Config loaded: %s" % level_config.name)

## 查找管理器
func _find_managers() -> void:
	var tree = get_tree()
	if not tree:
		return

	# 查找GameStateManager
	if tree.root.has_node("GameStateManager"):
		game_state_manager = tree.root.get_node("GameStateManager")

	# 查找或创建LevelFlowController
	level_flow_controller = tree.root.find_child("LevelFlowController", true, false)
	if not level_flow_controller:
		level_flow_controller = load("res://scripts/core/level_flow_controller.gd").new()
		level_flow_controller.name = "LevelFlowController"
		add_child(level_flow_controller)

	# 查找或创建TutorialController
	tutorial_controller = tree.root.find_child("TutorialController", true, false)
	if not tutorial_controller:
		tutorial_controller = load("res://scripts/tutorial/tutorial_controller.gd").new()
		tutorial_controller.name = "TutorialController"
		add_child(tutorial_controller)

## 设置环境
func _setup_environment() -> void:
	if level_config.is_empty():
		return

	var env_config = level_config.get("environment", {})

	# 设置光照
	if directional_light and env_config.has("lighting"):
		match env_config.lighting:
			"daytime":
				directional_light.light_energy = 1.0
				directional_light.rotation_degrees = Vector3(-45, 45, 0)
			"sunset":
				directional_light.light_energy = 0.8
				directional_light.light_color = Color(1.0, 0.8, 0.6)
				directional_light.rotation_degrees = Vector3(-15, 60, 0)
			"night":
				directional_light.light_energy = 0.3
				directional_light.light_color = Color(0.6, 0.7, 1.0)
				directional_light.rotation_degrees = Vector3(-75, 0, 0)

	print("[Level01Tutorial] Environment setup: %s" % env_config.get("lighting", "default"))

## 生成关卡内容
func _spawn_level_content() -> void:
	if level_config.is_empty():
		return

	# 生成地板
	_create_ground_plane()

	# 生成检查点
	_spawn_checkpoints()

	# 生成道具
	_spawn_items()

	# 生成敌人
	_spawn_enemies()

	# 生成障碍物
	_spawn_obstacles()

## 创建地板
func _create_ground_plane() -> void:
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)

	# 碰撞形状
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(200, 1, 50)
	collision.shape = box
	collision.position = Vector3(75, -0.5, 0)
	ground.add_child(collision)

	# 视觉网格
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(200, 1, 50)
	mesh_instance.mesh = plane_mesh
	mesh_instance.position = Vector3(75, -0.5, 0)
	ground.add_child(mesh_instance)

	# 材质
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.3)
	mesh_instance.material_override = material

	print("[Level01Tutorial] Ground plane created")

## 生成检查点
func _spawn_checkpoints() -> void:
	if not level_config.has("checkpoints"):
		return

	var checkpoints_parent = Node3D.new()
	checkpoints_parent.name = "Checkpoints"
	add_child(checkpoints_parent)

	for cp in level_config.checkpoints:
		var marker = Marker3D.new()
		marker.name = cp.id
		marker.position = Vector3(cp.position[0], cp.position[1], cp.position[2])
		checkpoints_parent.add_child(marker)

		# 添加视觉标记（简单立方体）
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(2, 3, 2)
		mesh_instance.mesh = box_mesh
		mesh_instance.position = Vector3(0, 1.5, 0)
		marker.add_child(mesh_instance)

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = material

	print("[Level01Tutorial] Spawned %d checkpoints" % level_config.checkpoints.size())

## 生成道具
func _spawn_items() -> void:
	if not level_config.has("items"):
		return

	var items_parent = Node3D.new()
	items_parent.name = "Items"
	add_child(items_parent)

	for item in level_config.items:
		var item_node = _create_item_placeholder(item.type)
		item_node.position = Vector3(item.position[0], item.position[1], item.position[2])
		items_parent.add_child(item_node)

	print("[Level01Tutorial] Spawned %d items" % level_config.items.size())

## 创建道具占位符
func _create_item_placeholder(item_type: String) -> Node3D:
	var item = Area3D.new()
	item.name = "Item_" + item_type

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	mesh_instance.mesh = sphere_mesh
	item.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3
	collision.shape = sphere_shape
	item.add_child(collision)

	# 根据类型设置颜色
	var material = StandardMaterial3D.new()
	match item_type:
		"coin":
			material.albedo_color = Color(1.0, 0.8, 0.0)
		"health_pack":
			material.albedo_color = Color(1.0, 0.2, 0.2)
		"speed_boost":
			material.albedo_color = Color(0.2, 1.0, 0.2)
		_:
			material.albedo_color = Color(0.5, 0.5, 0.5)

	mesh_instance.material_override = material

	return item

## 生成敌人
func _spawn_enemies() -> void:
	if not level_config.has("enemies"):
		return

	var enemies_parent = Node3D.new()
	enemies_parent.name = "Enemies"
	add_child(enemies_parent)

	for enemy in level_config.enemies:
		var enemy_node = _create_enemy_placeholder(enemy.type)
		enemy_node.position = Vector3(enemy.position[0], enemy.position[1], enemy.position[2])
		enemies_parent.add_child(enemy_node)

	print("[Level01Tutorial] Spawned %d enemies" % level_config.enemies.size())

## 创建敌人占位符
func _create_enemy_placeholder(enemy_type: String) -> CharacterBody3D:
	var enemy = CharacterBody3D.new()
	enemy.name = "Enemy_" + enemy_type

	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.6
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position = Vector3(0, 0.8, 0)
	enemy.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.4
	capsule_shape.height = 1.6
	collision.shape = capsule_shape
	collision.position = Vector3(0, 0.8, 0)
	enemy.add_child(collision)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.3, 0.3)
	mesh_instance.material_override = material

	return enemy

## 生成障碍物
func _spawn_obstacles() -> void:
	if not level_config.has("obstacles"):
		return

	var obstacles_parent = Node3D.new()
	obstacles_parent.name = "Obstacles"
	add_child(obstacles_parent)

	for obstacle in level_config.obstacles:
		var obstacle_node = _create_obstacle_placeholder(obstacle.type)
		obstacle_node.position = Vector3(obstacle.position[0], obstacle.position[1], obstacle.position[2])
		obstacles_parent.add_child(obstacle_node)

	print("[Level01Tutorial] Spawned %d obstacles" % level_config.obstacles.size())

## 创建障碍物占位符
func _create_obstacle_placeholder(obstacle_type: String) -> StaticBody3D:
	var obstacle = StaticBody3D.new()
	obstacle.name = "Obstacle_" + obstacle_type

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2, 2, 2)
	mesh_instance.mesh = box_mesh
	mesh_instance.position = Vector3(0, 1, 0)
	obstacle.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2, 2, 2)
	collision.shape = box_shape
	collision.position = Vector3(0, 1, 0)
	obstacle.add_child(collision)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.1)
	mesh_instance.material_override = material

	return obstacle

## 初始化教学系统
func _initialize_tutorial() -> void:
	if not tutorial_controller:
		return

	if level_config.is_empty():
		return

	# 加载教学配置
	tutorial_controller.load_tutorial(level_config)

	# 开始教学
	tutorial_controller.start_tutorial()

	print("[Level01Tutorial] Tutorial initialized")

## 获取出生点位置
func get_spawn_position() -> Vector3:
	if spawn_point:
		return spawn_point.global_position

	if level_config.has("spawn_point"):
		var pos = level_config.spawn_point.position
		return Vector3(pos[0], pos[1], pos[2])

	return Vector3.ZERO
