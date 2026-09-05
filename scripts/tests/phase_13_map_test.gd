extends SceneTree
## Phase 13 地图系统测试运行器

func _init():
	print("============================================================")
	print("Phase 13 - Map System Test")
	print("============================================================")

	# 预加载所有需要的脚本
	var MapDataScript = load("res://scripts/map/map_data.gd")
	var ChunkDataScript = load("res://scripts/map/chunk_data.gd")
	var ProceduralMapGeneratorScript = load("res://scripts/map/procedural_map_generator.gd")
	var LevelManagerScript = load("res://scripts/map/level_manager.gd")
	var NavigationSystemScript = load("res://scripts/map/navigation_system.gd")

	print("\n✓ All scripts loaded successfully")

	# 运行测试
	var success = true
	success = test_map_data(MapDataScript) and success
	success = test_chunk_data(ChunkDataScript) and success
	success = test_procedural_generator(ProceduralMapGeneratorScript, MapDataScript) and success
	success = test_level_manager(LevelManagerScript) and success
	success = test_navigation_system(NavigationSystemScript) and success

	print("\n============================================================")
	if success:
		print("✅ All tests PASSED")
	else:
		print("❌ Some tests FAILED")
	print("============================================================")

	quit(0 if success else 1)

func test_map_data(MapDataScript) -> bool:
	print("\n[Test 1] MapData Structure")

	var config = {
		"name": "Test Map",
		"seed": 12345,
		"size": Vector2i(10, 10)
	}

	var map = MapDataScript.new(config)

	# 测试初始化
	if map.map_name != "Test Map":
		print("  ❌ Map name incorrect")
		return false
	print("  ✓ Map initialized with config")

	if map.map_seed != 12345:
		print("  ❌ Map seed incorrect")
		return false
	print("  ✓ Seed set correctly")

	# 测试路径点
	var wp1 = map.add_waypoint(Vector3(10, 0, 10))
	var wp2 = map.add_waypoint(Vector3(20, 0, 20))
	map.connect_waypoints(wp1, wp2)

	if map.waypoints.size() != 2:
		print("  ❌ Waypoint creation failed")
		return false
	print("  ✓ Waypoints created")

	var connections = map.get_waypoint_connections(wp1)
	if connections.size() != 1 or connections[0] != wp2:
		print("  ❌ Waypoint connection failed")
		return false
	print("  ✓ Waypoint connections work")

	# 测试生成点
	map.add_enemy_spawn(Vector3(5, 0, 5), "basic_enemy", 0)
	map.add_enemy_spawn(Vector3(15, 0, 15), "strong_enemy", 1)

	if map.enemy_spawns.size() != 2:
		print("  ❌ Enemy spawn creation failed")
		return false
	print("  ✓ Enemy spawns created")

	var wave0_spawns = map.get_enemy_spawns_for_wave(0)
	if wave0_spawns.size() != 1:
		print("  ❌ Wave filtering failed")
		return false
	print("  ✓ Wave filtering works")

	# 测试序列化
	var dict = map.to_dict()
	var restored = MapDataScript.from_dict(dict)

	if restored.map_name != map.map_name or restored.map_seed != map.map_seed:
		print("  ❌ Serialization failed")
		return false
	print("  ✓ Serialization works")

	print("  ✅ MapData tests passed")
	return true

func test_chunk_data(ChunkDataScript) -> bool:
	print("\n[Test 2] ChunkData")

	var chunk = ChunkDataScript.new(Vector2i(0, 0), 16)

	# 测试初始化
	if chunk.tile_size != 16:
		print("  ❌ Chunk size incorrect")
		return false
	print("  ✓ Chunk initialized")

	if chunk.tiles.size() != 256:  # 16x16
		print("  ❌ Tiles array size incorrect")
		return false
	print("  ✓ Tiles array created")

	# 测试地块操作
	chunk.set_tile(5, 5, ChunkDataScript.TileType.WALL)
	if chunk.get_tile(5, 5) != ChunkDataScript.TileType.WALL:
		print("  ❌ Tile set/get failed")
		return false
	print("  ✓ Tile operations work")

	# 测试可通行性
	if chunk.is_walkable(5, 5):
		print("  ❌ Walkability check failed (wall should not be walkable)")
		return false
	print("  ✓ Walkability check works")

	chunk.set_tile(6, 6, ChunkDataScript.TileType.GROUND)
	if not chunk.is_walkable(6, 6):
		print("  ❌ Walkability check failed (ground should be walkable)")
		return false
	print("  ✓ Ground is walkable")

	# 测试区域填充
	chunk.fill_area(0, 0, 4, 4, ChunkDataScript.TileType.GROUND)
	var all_ground = true
	for y in range(4):
		for x in range(4):
			if chunk.get_tile(x, y) != ChunkDataScript.TileType.GROUND:
				all_ground = false
				break
	if not all_ground:
		print("  ❌ Fill area failed")
		return false
	print("  ✓ Fill area works")

	# 测试世界坐标转换
	var world_pos = chunk.get_world_position(8, 8)
	if world_pos.x != 8 or world_pos.z != 8:
		print("  ❌ World position conversion failed")
		return false
	print("  ✓ World position conversion works")

	print("  ✅ ChunkData tests passed")
	return true

func test_procedural_generator(ProceduralMapGeneratorScript, MapDataScript) -> bool:
	print("\n[Test 3] Procedural Map Generator")

	var config = {
		"map_size": Vector2i(5, 5),
		"chunk_size": 16,
		"seed": 99999,
		"enemy_density": 0.2,
		"obstacle_density": 0.05
	}

	var generator = ProceduralMapGeneratorScript.new(config)
	var map = generator.generate_map()

	# 测试地图生成
	if not map:
		print("  ❌ Map generation failed")
		return false
	print("  ✓ Map generated")

	# 测试区块数量
	var stats = map.get_stats()
	if stats["total_chunks"] != 25:  # 5x5
		print("  ❌ Incorrect chunk count: %d (expected 25)" % stats["total_chunks"])
		return false
	print("  ✓ Correct number of chunks generated")

	# 测试路径点
	if stats["total_waypoints"] == 0:
		print("  ❌ No waypoints generated")
		return false
	print("  ✓ Waypoints generated: %d" % stats["total_waypoints"])

	# 测试敌人生成点
	if stats["total_enemy_spawns"] == 0:
		print("  ❌ No enemy spawns generated")
		return false
	print("  ✓ Enemy spawns generated: %d" % stats["total_enemy_spawns"])

	# 测试玩家生成点
	if map.player_spawn == Vector3.ZERO:
		print("  ❌ Player spawn not set")
		return false
	print("  ✓ Player spawn set: %s" % str(map.player_spawn))

	# 测试确定性（相同种子应生成相同地图）
	var generator2 = ProceduralMapGeneratorScript.new(config)
	var map2 = generator2.generate_map()

	if map.player_spawn.distance_to(map2.player_spawn) > 0.01:
		print("  ❌ Generation is not deterministic")
		return false
	print("  ✓ Generation is deterministic")

	print("  ✅ Procedural Generator tests passed")
	return true

func test_level_manager(LevelManagerScript) -> bool:
	print("\n[Test 4] Level Manager")

	var root = Node.new()
	var level_manager = LevelManagerScript.new()
	root.add_child(level_manager)

	# 测试初始状态
	if level_manager.is_level_active:
		print("  ❌ Level should not be active initially")
		return false
	print("  ✓ Initial state correct")

	# 测试关卡加载
	var config = {
		"map_size": Vector2i(3, 3),
		"chunk_size": 16,
		"enemy_density": 0.1
	}

	level_manager.load_level(config)

	if not level_manager.is_level_active:
		print("  ❌ Level failed to load")
		return false
	print("  ✓ Level loaded")

	if not level_manager.current_map:
		print("  ❌ Map not created")
		return false
	print("  ✓ Map created")

	# 测试玩家生成点
	var spawn = level_manager.get_player_spawn_point()
	if spawn == Vector3.ZERO:
		print("  ❌ Player spawn point not set")
		return false
	print("  ✓ Player spawn point available")

	# 测试统计信息
	var stats = level_manager.get_level_stats()
	if not stats.has("level_id"):
		print("  ❌ Stats not available")
		return false
	print("  ✓ Stats available")

	# 测试关卡卸载
	level_manager.unload_level()

	if level_manager.is_level_active:
		print("  ❌ Level failed to unload")
		return false
	print("  ✓ Level unloaded")

	# 清理
	root.queue_free()
	print("  ✅ Level Manager tests passed")
	return true

func test_navigation_system(NavigationSystemScript) -> bool:
	print("\n[Test 5] Navigation System")

	var root = Node3D.new()
	var nav_system = NavigationSystemScript.new()
	root.add_child(nav_system)

	# 测试初始化
	if nav_system.is_initialized:
		print("  ❌ Should not be initialized yet")
		return false
	print("  ✓ Initial state correct")

	# 测试导航区域创建
	nav_system.setup_navigation_region(root)

	if not nav_system.is_initialized:
		print("  ❌ Navigation system failed to initialize")
		return false
	print("  ✓ Navigation region created")

	if not nav_system.navigation_region:
		print("  ❌ Navigation region not created")
		return false
	print("  ✓ Navigation region available")

	if not nav_system.navigation_mesh:
		print("  ❌ Navigation mesh not created")
		return false
	print("  ✓ Navigation mesh created")

	# 测试配置
	var stats = nav_system.get_navigation_stats()
	if not stats["is_initialized"]:
		print("  ❌ Stats show not initialized")
		return false
	print("  ✓ Navigation stats available")

	# 测试路径计算（简单测试，无实际地图）
	var path = nav_system.calculate_path(Vector3.ZERO, Vector3(10, 0, 10))
	# 没有烘焙的导航网格，路径可能为空，这是正常的
	print("  ✓ Path calculation callable (result: %d points)" % path.size())

	# 清理
	root.queue_free()
	print("  ✅ Navigation System tests passed")
	return true
