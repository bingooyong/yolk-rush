extends Node3D
## 地图系统示例场景 - 展示如何使用地图系统

# 预加载组件
const LevelManagerScript = preload("res://scripts/map/level_manager.gd")
const NavigationSystemScript = preload("res://scripts/map/navigation_system.gd")

## 管理器引用
var level_manager: Node = null
var navigation_system: Node = null

## 玩家引用（示例）
var player: Node3D = null

func _ready() -> void:
	print("[MapExample] Starting map system example")

	# 创建关卡管理器
	level_manager = LevelManagerScript.new()
	add_child(level_manager)

	# 连接信号
	level_manager.level_loaded.connect(_on_level_loaded)
	level_manager.level_completed.connect(_on_level_completed)
	level_manager.objective_completed.connect(_on_objective_completed)

	# 创建导航系统
	navigation_system = NavigationSystemScript.new()
	add_child(navigation_system)
	navigation_system.navigation_ready.connect(_on_navigation_ready)

	# 加载关卡
	_load_example_level()

## 加载示例关卡
func _load_example_level() -> void:
	print("[MapExample] Loading example level...")

	var config = {
		"map_size": Vector2i(8, 8),
		"chunk_size": 16,
		"seed": 42,  # 固定种子用于演示
		"enemy_density": 0.25,
		"obstacle_density": 0.08,
		"max_waves": 2
	}

	level_manager.load_level(config)

## 关卡加载完成
func _on_level_loaded(map_data) -> void:
	print("[MapExample] Level loaded successfully!")
	print("  Map ID: %s" % level_manager.current_level_id)
	print("  Stats: %s" % str(level_manager.get_level_stats()))

	# 设置导航系统
	if level_manager.level_root:
		navigation_system.setup_navigation_region(level_manager.level_root)
		navigation_system.generate_from_map_data(map_data)

	# 创建玩家
	_create_player()

	# 生成第一波敌人
	await get_tree().create_timer(1.0).timeout
	level_manager.spawn_enemy_wave(0)

## 导航准备完成
func _on_navigation_ready() -> void:
	print("[MapExample] Navigation system ready")

	# 测试寻路
	if player:
		var player_pos = player.global_position
		var target_pos = player_pos + Vector3(20, 0, 20)

		var path = navigation_system.calculate_path(player_pos, target_pos)
		print("[MapExample] Calculated path with %d points" % path.size())

		# 可视化路径
		if path.size() > 0 and level_manager.level_root:
			navigation_system.visualize_path(path, level_manager.level_root)

## 创建玩家（简化版）
func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"

	# 创建视觉表示
	var mesh_instance = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	mesh_instance.mesh = capsule

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 1.0)  # 蓝色玩家
	mesh_instance.material_override = material

	player.add_child(mesh_instance)

	# 创建碰撞体
	var collision = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.5
	capsule_shape.height = 2.0
	collision.shape = capsule_shape
	player.add_child(collision)

	# 设置位置
	var spawn_point = level_manager.get_player_spawn_point()
	player.global_position = spawn_point

	if level_manager.level_root:
		level_manager.level_root.add_child(player)

	print("[MapExample] Player created at: %s" % str(spawn_point))

## 目标完成
func _on_objective_completed(objective_index: int) -> void:
	print("[MapExample] Objective %d completed!" % objective_index)

## 关卡完成
func _on_level_completed(victory: bool) -> void:
	print("[MapExample] Level completed: %s" % ("Victory!" if victory else "Defeat..."))

	# 3秒后重新加载
	await get_tree().create_timer(3.0).timeout
	print("[MapExample] Reloading level...")
	_load_example_level()

## 处理输入（演示用）
func _unhandled_input(event: InputEvent) -> void:
	# 按 R 重新加载关卡
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("[MapExample] Manual reload requested")
			_load_example_level()

		# 按 W 生成下一波敌人
		elif event.keycode == KEY_W:
			print("[MapExample] Spawning next wave")
			level_manager.spawn_enemy_wave()

		# 按 P 打印统计信息
		elif event.keycode == KEY_P:
			var stats = level_manager.get_level_stats()
			print("[MapExample] Current Stats:")
			for key in stats:
				print("  %s: %s" % [key, str(stats[key])])

		# 按 N 测试寻路
		elif event.keycode == KEY_N and player:
			var player_pos = player.global_position
			var random_offset = Vector3(
				randf_range(-30, 30),
				0,
				randf_range(-30, 30)
			)
			var target = player_pos + random_offset

			var path = navigation_system.calculate_path(player_pos, target)
			print("[MapExample] Path to random target: %d points" % path.size())

			if path.size() > 0 and level_manager.level_root:
				navigation_system.visualize_path(path, level_manager.level_root)

func _exit_tree() -> void:
	print("[MapExample] Cleaning up...")
	if level_manager:
		level_manager.unload_level()
