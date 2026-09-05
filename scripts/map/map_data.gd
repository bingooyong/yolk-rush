extends RefCounted
class_name MapData
## 地图数据结构 - 存储地图的所有静态数据

## 地图元数据
var map_id: String = ""
var map_name: String = "Untitled Map"
var map_seed: int = 0
var map_size: Vector2i = Vector2i(100, 100)  # 地图尺寸（格子数）
var chunk_size: int = 16  # 每个区块的大小

## 区块数据
var chunks: Dictionary = {}  # Vector2i -> ChunkData

## 路径点网络
var waypoints: Array[Vector3] = []
var waypoint_connections: Dictionary = {}  # int -> Array[int]

## 生成点
var player_spawn: Vector3 = Vector3.ZERO
var enemy_spawns: Array[Dictionary] = []  # {position: Vector3, type: String, wave: int}

## 目标点
var objective_points: Array[Dictionary] = []  # {position: Vector3, type: String, data: Dictionary}

## 地形数据
var collision_areas: Array[Dictionary] = []  # {position: Vector3, size: Vector3, shape: String}
var navigation_obstacles: Array[Dictionary] = []

## 元数据
var generation_time: float = 0.0
var generation_config: Dictionary = {}

func _init(config: Dictionary = {}):
	map_id = _generate_map_id()
	if config.has("name"):
		map_name = config["name"]
	if config.has("seed"):
		map_seed = config["seed"]
	else:
		map_seed = randi()
	if config.has("size"):
		map_size = config["size"]
	if config.has("chunk_size"):
		chunk_size = config["chunk_size"]

	generation_config = config.duplicate()

func _generate_map_id() -> String:
	return "map_%d_%d" % [Time.get_ticks_msec(), randi()]

## 添加区块
func add_chunk(chunk_pos: Vector2i, chunk_data) -> void:
	chunks[chunk_pos] = chunk_data

## 获取区块
func get_chunk(chunk_pos: Vector2i):
	return chunks.get(chunk_pos, null)

## 检查区块是否存在
func has_chunk(chunk_pos: Vector2i) -> bool:
	return chunks.has(chunk_pos)

## 获取世界坐标对应的区块位置
func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)

## 获取区块的世界坐标
func chunk_to_world(chunk_pos: Vector2i) -> Vector3:
	return Vector3(
		chunk_pos.x * chunk_size,
		0,
		chunk_pos.y * chunk_size
	)

## 添加路径点
func add_waypoint(position: Vector3) -> int:
	waypoints.append(position)
	var index = waypoints.size() - 1
	waypoint_connections[index] = []
	return index

## 连接路径点
func connect_waypoints(from_idx: int, to_idx: int) -> void:
	if waypoint_connections.has(from_idx):
		if to_idx not in waypoint_connections[from_idx]:
			waypoint_connections[from_idx].append(to_idx)

## 获取路径点连接
func get_waypoint_connections(idx: int) -> Array:
	return waypoint_connections.get(idx, [])

## 添加敌人生成点
func add_enemy_spawn(position: Vector3, enemy_type: String, wave: int = 0) -> void:
	enemy_spawns.append({
		"position": position,
		"type": enemy_type,
		"wave": wave
	})

## 获取指定波次的敌人生成点
func get_enemy_spawns_for_wave(wave: int) -> Array:
	var result: Array = []
	for spawn in enemy_spawns:
		if spawn["wave"] == wave:
			result.append(spawn)
	return result

## 添加目标点
func add_objective(position: Vector3, obj_type: String, data: Dictionary = {}) -> void:
	objective_points.append({
		"position": position,
		"type": obj_type,
		"data": data,
		"completed": false
	})

## 添加碰撞区域
func add_collision_area(position: Vector3, size: Vector3, shape: String = "box") -> void:
	collision_areas.append({
		"position": position,
		"size": size,
		"shape": shape
	})

## 添加导航障碍
func add_navigation_obstacle(position: Vector3, size: Vector3) -> void:
	navigation_obstacles.append({
		"position": position,
		"size": size
	})

## 序列化为字典（用于保存）
func to_dict() -> Dictionary:
	return {
		"map_id": map_id,
		"map_name": map_name,
		"map_seed": map_seed,
		"map_size": [map_size.x, map_size.y],
		"chunk_size": chunk_size,
		"player_spawn": [player_spawn.x, player_spawn.y, player_spawn.z],
		"enemy_spawns": enemy_spawns.duplicate(),
		"objective_points": objective_points.duplicate(),
		"waypoints": waypoints.map(func(v): return [v.x, v.y, v.z]),
		"waypoint_connections": waypoint_connections.duplicate(),
		"collision_areas": collision_areas.duplicate(),
		"navigation_obstacles": navigation_obstacles.duplicate(),
		"generation_config": generation_config.duplicate()
	}

## 从字典加载
static func from_dict(data: Dictionary):
	var MapDataScript = load("res://scripts/map/map_data.gd")
	var map = MapDataScript.new()
	map.map_id = data.get("map_id", "")
	map.map_name = data.get("map_name", "Untitled")
	map.map_seed = data.get("map_seed", 0)

	var size_arr = data.get("map_size", [100, 100])
	map.map_size = Vector2i(size_arr[0], size_arr[1])
	map.chunk_size = data.get("chunk_size", 16)

	var spawn_arr = data.get("player_spawn", [0, 0, 0])
	map.player_spawn = Vector3(spawn_arr[0], spawn_arr[1], spawn_arr[2])

	map.enemy_spawns = data.get("enemy_spawns", []).duplicate()
	map.objective_points = data.get("objective_points", []).duplicate()

	# 恢复路径点
	var wp_data = data.get("waypoints", [])
	for wp in wp_data:
		map.waypoints.append(Vector3(wp[0], wp[1], wp[2]))

	map.waypoint_connections = data.get("waypoint_connections", {}).duplicate()
	map.collision_areas = data.get("collision_areas", []).duplicate()
	map.navigation_obstacles = data.get("navigation_obstacles", []).duplicate()
	map.generation_config = data.get("generation_config", {}).duplicate()

	return map

## 获取地图统计信息
func get_stats() -> Dictionary:
	return {
		"total_chunks": chunks.size(),
		"total_waypoints": waypoints.size(),
		"total_enemy_spawns": enemy_spawns.size(),
		"total_objectives": objective_points.size(),
		"map_area": map_size.x * map_size.y
	}
