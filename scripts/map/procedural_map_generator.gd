extends RefCounted
class_name ProceduralMapGenerator
## 程序化地图生成器 - 生成随机地图

# 预加载依赖
const MapDataScript = preload("res://scripts/map/map_data.gd")
const ChunkDataScript = preload("res://scripts/map/chunk_data.gd")

## 生成配置
var config: Dictionary = {
	"map_size": Vector2i(10, 10),  # 区块数量
	"chunk_size": 16,
	"seed": 0,
	"room_count": 5,
	"corridor_width": 2,
	"enemy_density": 0.3,
	"obstacle_density": 0.1
}

## 随机数生成器
var rng: RandomNumberGenerator

## 地图模板
enum RoomTemplate {
	SMALL_SQUARE,
	LARGE_SQUARE,
	RECTANGLE_H,
	RECTANGLE_V,
	L_SHAPE,
	T_SHAPE
}

func _init(generation_config: Dictionary = {}):
	# 合并配置
	for key in generation_config:
		config[key] = generation_config[key]

	# 初始化随机数生成器
	rng = RandomNumberGenerator.new()
	if config["seed"] == 0:
		config["seed"] = randi()
	rng.seed = config["seed"]

## 生成完整地图
func generate_map():
	var start_time = Time.get_ticks_msec()

	print("[ProceduralMapGenerator] Starting generation with seed: %d" % config["seed"])

	var map = MapDataScript.new(config)

	# 生成所有区块
	_generate_chunks(map)

	# 生成路径点网络
	_generate_waypoint_network(map)

	# 放置玩家生成点
	_place_player_spawn(map)

	# 放置敌人生成点
	_place_enemy_spawns(map)

	# 放置目标点
	_place_objectives(map)

	# 生成碰撞和导航数据
	_generate_collision_data(map)

	var end_time = Time.get_ticks_msec()
	map.generation_time = (end_time - start_time) / 1000.0

	print("[ProceduralMapGenerator] Generation completed in %.2fs" % map.generation_time)
	print("  Stats: %s" % str(map.get_stats()))

	return map

## 生成区块
func _generate_chunks(map: MapDataScript) -> void:
	var map_size = config["map_size"]
	var chunk_size = config["chunk_size"]

	for cy in range(map_size.y):
		for cx in range(map_size.x):
			var chunk_pos = Vector2i(cx, cy)
			var chunk = ChunkDataScript.new(chunk_pos, chunk_size)
			chunk.generation_seed = rng.randi()

			# 生成区块内容
			_generate_chunk_content(chunk)

			chunk.is_generated = true
			map.add_chunk(chunk_pos, chunk)

	print("  Generated %d chunks" % (map_size.x * map_size.y))

## 生成区块内容
func _generate_chunk_content(chunk: ChunkDataScript) -> void:
	var size = chunk.tile_size

	# 默认填充地面
	chunk.fill_area(0, 0, size, size, ChunkDataScript.TileType.GROUND)

	# 边界墙壁（部分区块）
	if rng.randf() < 0.3:
		chunk.draw_rectangle(0, 0, size, size, ChunkDataScript.TileType.WALL)
		# 在墙壁上开洞作为出口
		var gap_x = rng.randi_range(2, size - 3)
		var gap_y = rng.randi_range(2, size - 3)
		chunk.set_tile(gap_x, 0, ChunkDataScript.TileType.GROUND)
		chunk.set_tile(gap_x, size - 1, ChunkDataScript.TileType.GROUND)
		chunk.set_tile(0, gap_y, ChunkDataScript.TileType.GROUND)
		chunk.set_tile(size - 1, gap_y, ChunkDataScript.TileType.GROUND)

	# 随机障碍物
	var obstacle_count = int(size * size * config["obstacle_density"])
	for i in range(obstacle_count):
		var x = rng.randi_range(1, size - 2)
		var y = rng.randi_range(1, size - 2)
		chunk.set_tile(x, y, ChunkDataScript.TileType.OBSTACLE)

		# 添加3D障碍物数据
		var world_pos = chunk.get_world_position(x, y)
		chunk.add_static_object("obstacle", world_pos, Vector3.ZERO, Vector3.ONE)

## 生成路径点网络
func _generate_waypoint_network(map: MapDataScript) -> void:
	var map_size = config["map_size"]
	var chunk_size = config["chunk_size"]

	# 在每个区块中心创建路径点
	for cy in range(map_size.y):
		for cx in range(map_size.x):
			var chunk_pos = Vector2i(cx, cy)
			var chunk = map.get_chunk(chunk_pos)
			if not chunk:
				continue

			# 区块中心点
			var center_x = chunk_size / 2
			var center_y = chunk_size / 2
			var world_pos = chunk.get_world_position(center_x, center_y)

			var wp_idx = map.add_waypoint(world_pos)
			chunk.add_waypoint(world_pos)

			# 连接到相邻区块的路径点
			if cx > 0:
				var left_idx = cy * map_size.x + (cx - 1)
				map.connect_waypoints(wp_idx, left_idx)
				map.connect_waypoints(left_idx, wp_idx)

			if cy > 0:
				var top_idx = (cy - 1) * map_size.x + cx
				map.connect_waypoints(wp_idx, top_idx)
				map.connect_waypoints(top_idx, wp_idx)

	print("  Generated %d waypoints" % map.waypoints.size())

## 放置玩家生成点
func _place_player_spawn(map: MapDataScript) -> void:
	var map_size = config["map_size"]
	var chunk_size = config["chunk_size"]

	# 在地图中心附近放置玩家
	var center_chunk = Vector2i(map_size.x / 2, map_size.y / 2)
	var chunk = map.get_chunk(center_chunk)

	if chunk:
		var spawn_x = chunk_size / 2
		var spawn_y = chunk_size / 2
		map.player_spawn = chunk.get_world_position(spawn_x, spawn_y)
		map.player_spawn.y = 1.0  # 提升高度避免嵌入地面
		print("  Player spawn at: %s" % str(map.player_spawn))

## 放置敌人生成点
func _place_enemy_spawns(map: MapDataScript) -> void:
	var map_size = config["map_size"]
	var total_chunks = map_size.x * map_size.y
	var enemy_count = int(total_chunks * config["enemy_density"])

	var enemy_types = ["basic_enemy", "strong_enemy", "fast_enemy"]

	for i in range(enemy_count):
		# 随机选择区块
		var cx = rng.randi_range(0, map_size.x - 1)
		var cy = rng.randi_range(0, map_size.y - 1)
		var chunk_pos = Vector2i(cx, cy)
		var chunk = map.get_chunk(chunk_pos)

		if chunk:
			# 在区块内随机位置
			var local_x = rng.randi_range(2, chunk.tile_size - 3)
			var local_y = rng.randi_range(2, chunk.tile_size - 3)

			if chunk.is_walkable(local_x, local_y):
				var world_pos = chunk.get_world_position(local_x, local_y)
				world_pos.y = 1.0

				var enemy_type = enemy_types[rng.randi_range(0, enemy_types.size() - 1)]
				var wave = rng.randi_range(0, 2)  # 0-2波次

				map.add_enemy_spawn(world_pos, enemy_type, wave)
				chunk.add_spawn_point(world_pos)

	print("  Placed %d enemy spawns" % map.enemy_spawns.size())

## 放置目标点
func _place_objectives(map: MapDataScript) -> void:
	var map_size = config["map_size"]

	# 放置1-3个目标点
	var objective_count = rng.randi_range(1, 3)

	for i in range(objective_count):
		var cx = rng.randi_range(0, map_size.x - 1)
		var cy = rng.randi_range(0, map_size.y - 1)
		var chunk = map.get_chunk(Vector2i(cx, cy))

		if chunk:
			var local_x = rng.randi_range(3, chunk.tile_size - 4)
			var local_y = rng.randi_range(3, chunk.tile_size - 4)
			var world_pos = chunk.get_world_position(local_x, local_y)
			world_pos.y = 1.0

			map.add_objective(world_pos, "collect", {"item": "key", "count": 1})

	print("  Placed %d objectives" % map.objective_points.size())

## 生成碰撞数据
func _generate_collision_data(map: MapDataScript) -> void:
	var map_size = config["map_size"]

	# 遍历所有区块，为墙壁和障碍物创建碰撞数据
	for cy in range(map_size.y):
		for cx in range(map_size.x):
			var chunk = map.get_chunk(Vector2i(cx, cy))
			if not chunk:
				continue

			for y in range(chunk.tile_size):
				for x in range(chunk.tile_size):
					var tile = chunk.get_tile(x, y)

					if tile == ChunkDataScript.TileType.WALL or tile == ChunkDataScript.TileType.OBSTACLE:
						var world_pos = chunk.get_world_position(x, y)
						world_pos.y = 1.0  # 碰撞体高度
						map.add_collision_area(world_pos, Vector3(1, 2, 1), "box")
						map.add_navigation_obstacle(world_pos, Vector3(1, 2, 1))

	print("  Generated %d collision areas" % map.collision_areas.size())
