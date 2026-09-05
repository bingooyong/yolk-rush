extends Node
class_name LevelManager
## 关卡管理器 - 管理关卡加载、卸载和状态

# 预加载依赖
const MapDataScript = preload("res://scripts/map/map_data.gd")
const ProceduralMapGeneratorScript = preload("res://scripts/map/procedural_map_generator.gd")

signal level_loaded(map_data)
signal level_unloaded()
signal objective_completed(objective_index: int)
signal all_objectives_completed()
signal enemy_wave_spawned(wave: int)
signal level_completed(victory: bool)

## 当前关卡数据
var current_map: MapDataScript = null
var current_level_id: String = ""

## 关卡状态
var is_level_active: bool = false
var completed_objectives: Array[int] = []
var spawned_enemies: Array[Node] = []
var current_wave: int = 0

## 关卡配置
var level_config: Dictionary = {
	"map_size": Vector2i(10, 10),
	"chunk_size": 16,
	"enemy_density": 0.3,
	"obstacle_density": 0.1,
	"max_waves": 3
}

## 场景根节点
var level_root: Node3D = null

func _ready() -> void:
	print("[LevelManager] Initialized")

## 加载关卡
func load_level(config: Dictionary = {}) -> void:
	if is_level_active:
		unload_level()

	print("[LevelManager] Loading level...")

	# 合并配置
	var merged_config = level_config.duplicate()
	for key in config:
		merged_config[key] = config[key]

	# 生成地图
	var generator = ProceduralMapGeneratorScript.new(merged_config)
	current_map = generator.generate_map()
	current_level_id = current_map.map_id

	# 重置状态
	completed_objectives.clear()
	spawned_enemies.clear()
	current_wave = 0
	is_level_active = true

	# 创建关卡场景
	_create_level_scene()

	print("[LevelManager] Level loaded: %s" % current_level_id)
	level_loaded.emit(current_map)

## 卸载关卡
func unload_level() -> void:
	if not is_level_active:
		return

	print("[LevelManager] Unloading level...")

	# 清理生成的敌人
	_cleanup_spawned_enemies()

	# 清理场景
	if level_root:
		level_root.queue_free()
		level_root = null

	current_map = null
	current_level_id = ""
	is_level_active = false
	completed_objectives.clear()
	current_wave = 0

	level_unloaded.emit()
	print("[LevelManager] Level unloaded")

## 创建关卡场景
func _create_level_scene() -> void:
	# 创建根节点
	level_root = Node3D.new()
	level_root.name = "Level_%s" % current_level_id
	add_child(level_root)

	# 创建地面
	_create_ground_mesh()

	# 创建碰撞体
	_create_collision_bodies()

	# 创建视觉元素（简化版）
	_create_visual_elements()

	print("[LevelManager] Level scene created")

## 创建地面网格
func _create_ground_mesh() -> void:
	if not current_map:
		return

	var ground = MeshInstance3D.new()
	ground.name = "Ground"

	# 创建平面网格
	var plane_mesh = PlaneMesh.new()
	var map_world_size = current_map.map_size * current_map.chunk_size
	plane_mesh.size = Vector2(map_world_size.x, map_world_size.y)
	ground.mesh = plane_mesh

	# 设置位置（地面在y=0）
	ground.position = Vector3(map_world_size.x / 2.0, 0, map_world_size.y / 2.0)

	# 创建简单材质
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.3)  # 绿色地面
	ground.material_override = material

	level_root.add_child(ground)

## 创建碰撞体
func _create_collision_bodies() -> void:
	if not current_map:
		return

	for collision_area in current_map.collision_areas:
		var static_body = StaticBody3D.new()
		static_body.name = "Collision"

		# 创建碰撞形状
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = collision_area["size"]
		collision_shape.shape = box_shape

		static_body.add_child(collision_shape)
		static_body.position = collision_area["position"]

		level_root.add_child(static_body)

## 创建视觉元素
func _create_visual_elements() -> void:
	if not current_map:
		return

	# 为障碍物创建简单的立方体
	for collision_area in current_map.collision_areas:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Obstacle"

		var box_mesh = BoxMesh.new()
		box_mesh.size = collision_area["size"]
		mesh_instance.mesh = box_mesh

		# 材质
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.4, 0.4, 0.4)  # 灰色障碍物
		mesh_instance.material_override = material

		mesh_instance.position = collision_area["position"]
		level_root.add_child(mesh_instance)

	# 为目标点创建标记
	for i in range(current_map.objective_points.size()):
		var objective = current_map.objective_points[i]
		var marker = MeshInstance3D.new()
		marker.name = "Objective_%d" % i

		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.5
		sphere_mesh.height = 1.0
		marker.mesh = sphere_mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.0)  # 金色目标
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.0)
		material.emission_energy_multiplier = 2.0
		marker.material_override = material

		marker.position = objective["position"]
		level_root.add_child(marker)

## 生成敌人波次
func spawn_enemy_wave(wave: int = -1) -> void:
	if not current_map:
		return

	if wave == -1:
		wave = current_wave

	var spawns = current_map.get_enemy_spawns_for_wave(wave)
	print("[LevelManager] Spawning wave %d: %d enemies" % [wave, spawns.size()])

	for spawn in spawns:
		_spawn_enemy(spawn["position"], spawn["type"])

	current_wave = wave + 1
	enemy_wave_spawned.emit(wave)

## 生成单个敌人
func _spawn_enemy(position: Vector3, enemy_type: String) -> void:
	# 这里需要实际的敌人预制体
	# 暂时创建占位符节点
	var enemy = Node3D.new()
	enemy.name = "Enemy_%s" % enemy_type
	enemy.position = position

	# TODO: 实例化实际的敌人场景
	# var enemy_scene = load("res://scenes/enemies/%s.tscn" % enemy_type)
	# var enemy = enemy_scene.instantiate()

	level_root.add_child(enemy)
	spawned_enemies.append(enemy)

## 清理生成的敌人
func _cleanup_spawned_enemies() -> void:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()

## 完成目标
func complete_objective(objective_index: int) -> void:
	if objective_index in completed_objectives:
		return

	if objective_index < 0 or objective_index >= current_map.objective_points.size():
		return

	completed_objectives.append(objective_index)
	current_map.objective_points[objective_index]["completed"] = true

	print("[LevelManager] Objective %d completed" % objective_index)
	objective_completed.emit(objective_index)

	# 检查是否所有目标完成
	if completed_objectives.size() == current_map.objective_points.size():
		all_objectives_completed.emit()
		_complete_level(true)

## 完成关卡
func _complete_level(victory: bool) -> void:
	print("[LevelManager] Level completed: %s" % ("Victory" if victory else "Defeat"))
	is_level_active = false
	level_completed.emit(victory)

## 获取玩家生成点
func get_player_spawn_point() -> Vector3:
	if current_map:
		return current_map.player_spawn
	return Vector3.ZERO

## 获取最近的路径点
func get_nearest_waypoint(position: Vector3) -> int:
	if not current_map or current_map.waypoints.is_empty():
		return -1

	var nearest_idx = 0
	var min_distance = position.distance_to(current_map.waypoints[0])

	for i in range(1, current_map.waypoints.size()):
		var distance = position.distance_to(current_map.waypoints[i])
		if distance < min_distance:
			min_distance = distance
			nearest_idx = i

	return nearest_idx

## 获取关卡统计
func get_level_stats() -> Dictionary:
	if not current_map:
		return {}

	return {
		"level_id": current_level_id,
		"is_active": is_level_active,
		"current_wave": current_wave,
		"total_objectives": current_map.objective_points.size(),
		"completed_objectives": completed_objectives.size(),
		"active_enemies": spawned_enemies.size(),
		"map_stats": current_map.get_stats()
	}

## 保存关卡数据
func save_level(file_path: String) -> bool:
	if not current_map:
		return false

	var save_data = {
		"level_id": current_level_id,
		"map_data": current_map.to_dict(),
		"completed_objectives": completed_objectives,
		"current_wave": current_wave
	}

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[LevelManager] Level saved to: %s" % file_path)
		return true

	return false

## 加载关卡数据
func load_level_from_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return false

	var save_data = json.data
	current_level_id = save_data.get("level_id", "")
	current_map = MapDataScript.from_dict(save_data.get("map_data", {}))
	completed_objectives = save_data.get("completed_objectives", [])
	current_wave = save_data.get("current_wave", 0)
	is_level_active = true

	_create_level_scene()

	print("[LevelManager] Level loaded from: %s" % file_path)
	level_loaded.emit(current_map)
	return true
