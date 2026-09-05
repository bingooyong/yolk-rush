extends RefCounted
class_name ChunkData
## 区块数据 - 存储单个区块的信息

## 区块位置（格子坐标）
var chunk_position: Vector2i = Vector2i.ZERO

## 区块内容
var tiles: Array = []  # 地块类型数组
var tile_size: int = 16  # 区块大小

## 区块内的实体
var static_objects: Array[Dictionary] = []  # 静态物体：{type, position, rotation, scale}
var spawn_points: Array[Vector3] = []  # 生成点
var waypoints: Array[Vector3] = []  # 路径点

## 区块状态
var is_generated: bool = false
var is_loaded: bool = false
var generation_seed: int = 0

## 地块类型枚举
enum TileType {
	EMPTY = 0,
	GROUND = 1,
	WALL = 2,
	OBSTACLE = 3,
	SPAWN = 4,
	OBJECTIVE = 5
}

func _init(pos: Vector2i = Vector2i.ZERO, size: int = 16):
	chunk_position = pos
	tile_size = size
	_initialize_tiles()

## 初始化地块数组
func _initialize_tiles() -> void:
	tiles.clear()
	tiles.resize(tile_size * tile_size)
	tiles.fill(TileType.EMPTY)

## 设置地块类型
func set_tile(local_x: int, local_y: int, tile_type: int) -> void:
	if local_x < 0 or local_x >= tile_size or local_y < 0 or local_y >= tile_size:
		return
	var index = local_y * tile_size + local_x
	tiles[index] = tile_type

## 获取地块类型
func get_tile(local_x: int, local_y: int) -> int:
	if local_x < 0 or local_x >= tile_size or local_y < 0 or local_y >= tile_size:
		return TileType.EMPTY
	var index = local_y * tile_size + local_x
	return tiles[index]

## 检查位置是否可通行
func is_walkable(local_x: int, local_y: int) -> bool:
	var tile = get_tile(local_x, local_y)
	return tile != TileType.WALL and tile != TileType.OBSTACLE

## 添加静态物体
func add_static_object(obj_type: String, position: Vector3, rotation: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> void:
	static_objects.append({
		"type": obj_type,
		"position": position,
		"rotation": rotation,
		"scale": scale
	})

## 添加生成点
func add_spawn_point(position: Vector3) -> void:
	spawn_points.append(position)

## 添加路径点
func add_waypoint(position: Vector3) -> void:
	waypoints.append(position)

## 填充区域
func fill_area(start_x: int, start_y: int, width: int, height: int, tile_type: int) -> void:
	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			set_tile(x, y, tile_type)

## 绘制矩形边框
func draw_rectangle(start_x: int, start_y: int, width: int, height: int, tile_type: int) -> void:
	# 顶部和底部
	for x in range(start_x, start_x + width):
		set_tile(x, start_y, tile_type)
		set_tile(x, start_y + height - 1, tile_type)

	# 左侧和右侧
	for y in range(start_y, start_y + height):
		set_tile(start_x, y, tile_type)
		set_tile(start_x + width - 1, y, tile_type)

## 获取世界坐标
func get_world_position(local_x: int, local_y: int) -> Vector3:
	var chunk_world_x = chunk_position.x * tile_size
	var chunk_world_z = chunk_position.y * tile_size
	return Vector3(chunk_world_x + local_x, 0, chunk_world_z + local_y)

## 序列化
func to_dict() -> Dictionary:
	return {
		"chunk_position": [chunk_position.x, chunk_position.y],
		"tile_size": tile_size,
		"tiles": tiles.duplicate(),
		"static_objects": static_objects.duplicate(),
		"spawn_points": spawn_points.map(func(v): return [v.x, v.y, v.z]),
		"waypoints": waypoints.map(func(v): return [v.x, v.y, v.z]),
		"is_generated": is_generated,
		"generation_seed": generation_seed
	}

## 反序列化
static func from_dict(data: Dictionary):
	var ChunkDataScript = load("res://scripts/map/chunk_data.gd")
	var pos_arr = data.get("chunk_position", [0, 0])
	var chunk = ChunkDataScript.new(Vector2i(pos_arr[0], pos_arr[1]), data.get("tile_size", 16))

	chunk.tiles = data.get("tiles", []).duplicate()
	chunk.static_objects = data.get("static_objects", []).duplicate()

	var spawn_data = data.get("spawn_points", [])
	for sp in spawn_data:
		chunk.spawn_points.append(Vector3(sp[0], sp[1], sp[2]))

	var wp_data = data.get("waypoints", [])
	for wp in wp_data:
		chunk.waypoints.append(Vector3(wp[0], wp[1], wp[2]))

	chunk.is_generated = data.get("is_generated", false)
	chunk.generation_seed = data.get("generation_seed", 0)

	return chunk

## 清空区块
func clear() -> void:
	_initialize_tiles()
	static_objects.clear()
	spawn_points.clear()
	waypoints.clear()
	is_generated = false
	is_loaded = false
