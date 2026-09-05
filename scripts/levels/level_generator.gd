extends Node
class_name LevelGenerator
## 关卡生成器
## 根据LevelConfig动态生成关卡内容

signal generation_started()
signal generation_progress(progress: float, message: String)
signal generation_completed()
signal generation_failed(error: String)

## 场景引用
var level_scene: Node3D = null
var player: Node3D = null

## 生成的对象容器
var generated_enemies: Array[Node] = []
var generated_obstacles: Array[Node] = []
var generated_items: Array[Node] = []

## 当前配置
var current_config = null

## 敌人场景路径（运行时加载）
var ENEMY_SCENES = {
	"basic": preload("res://scenes/entities/basic_enemy.tscn"),
	# 后续添加其他敌人类型
	# "flying": "res://scenes/entities/flying_enemy.tscn",
	# "tank": "res://scenes/entities/tank_enemy.tscn",
	# "mage": "res://scenes/entities/mage_enemy.tscn",
}

## 障碍场景路径（运行时加载）
var OBSTACLE_SCENES = {
	"spike": preload("res://scenes/objects/spike_obstacle.tscn"),
	# 后续添加其他障碍类型
}

## 道具场景路径（运行时加载）
var ITEM_SCENES = {
	"coin": preload("res://scenes/objects/coin_item.tscn"),
	"health_potion": preload("res://scenes/objects/health_potion.tscn"),
	# 后续添加其他道具类型
}

func _ready() -> void:
	print("[LevelGenerator] Initialized")

## 生成关卡
func generate_level(config, scene: Node3D) -> bool:
	if not config.is_valid():
		generation_failed.emit("Invalid level config")
		return false

	current_config = config
	level_scene = scene

	generation_started.emit()
	print("[LevelGenerator] Generating level: %s" % config.level_name)

	# 清理旧内容
	clear_level()

	# 生成步骤
	generation_progress.emit(0.1, "Setting up environment...")
	await get_tree().process_frame
	_setup_environment()

	generation_progress.emit(0.3, "Spawning enemies...")
	await get_tree().process_frame
	_spawn_enemies()

	generation_progress.emit(0.5, "Placing obstacles...")
	await get_tree().process_frame
	_spawn_obstacles()

	generation_progress.emit(0.7, "Placing items...")
	await get_tree().process_frame
	_spawn_items()

	generation_progress.emit(0.9, "Finalizing...")
	await get_tree().process_frame
	_finalize_generation()

	generation_progress.emit(1.0, "Complete!")
	generation_completed.emit()

	print("[LevelGenerator] Level generated successfully")
	print("  - Enemies: %d" % generated_enemies.size())
	print("  - Obstacles: %d" % generated_obstacles.size())
	print("  - Items: %d" % generated_items.size())

	return true

## 设置环境
func _setup_environment() -> void:
	if not level_scene:
		return

	# 设置环境光
	var env = level_scene.get_node_or_null("WorldEnvironment")
	if env and env is WorldEnvironment:
		var environment = env.environment
		if environment:
			environment.ambient_light_color = current_config.ambient_color

			# 设置雾效
			if current_config.fog_enabled:
				environment.fog_enabled = true
				environment.fog_density = current_config.fog_density
			else:
				environment.fog_enabled = false

	# 播放背景音乐
	if AudioManager and not current_config.bgm.is_empty():
		AudioManager.play_bgm(current_config.bgm)

## 生成敌人
func _spawn_enemies() -> void:
	for enemy_data in current_config.enemies:
		var enemy_type = enemy_data.get("type", "basic")
		var position = enemy_data.get("position", Vector3.ZERO)
		var level = enemy_data.get("level", 1)

		var enemy = _create_enemy(enemy_type, position, level)
		if enemy:
			generated_enemies.append(enemy)

## 创建敌人
func _create_enemy(enemy_type: String, position: Vector3, level: int) -> Node:
	if not ENEMY_SCENES.has(enemy_type):
		push_error("[LevelGenerator] Unknown enemy type: %s" % enemy_type)
		return null

	var enemy_scene = ENEMY_SCENES[enemy_type]
	var enemy = enemy_scene.instantiate()

	if not level_scene:
		push_error("[LevelGenerator] No level scene set")
		return null

	level_scene.add_child(enemy)
	enemy.global_position = position

	# 添加到敌人组
	enemy.add_to_group("enemies")

	# 设置敌人等级（如果支持）
	if enemy.has_method("set_level"):
		enemy.set_level(level)

	return enemy

## 生成障碍
func _spawn_obstacles() -> void:
	for obstacle_data in current_config.obstacles:
		var obstacle_type = obstacle_data.get("type", "spike")
		var position = obstacle_data.get("position", Vector3.ZERO)
		var rotation = obstacle_data.get("rotation", Vector3.ZERO)

		var obstacle = _create_obstacle(obstacle_type, position, rotation)
		if obstacle:
			generated_obstacles.append(obstacle)

## 创建障碍
func _create_obstacle(obstacle_type: String, position: Vector3, rotation: Vector3) -> Node:
	if not OBSTACLE_SCENES.has(obstacle_type):
		push_error("[LevelGenerator] Unknown obstacle type: %s" % obstacle_type)
		return null

	var obstacle_scene = OBSTACLE_SCENES[obstacle_type]
	var obstacle = obstacle_scene.instantiate()

	if not level_scene:
		push_error("[LevelGenerator] No level scene set")
		return null

	level_scene.add_child(obstacle)
	obstacle.global_position = position
	obstacle.rotation_degrees = rotation

	return obstacle

## 生成道具
func _spawn_items() -> void:
	for item_data in current_config.items:
		var item_type = item_data.get("type", "coin")
		var position = item_data.get("position", Vector3.ZERO)

		var item = _create_item(item_type, position)
		if item:
			generated_items.append(item)

## 创建道具
func _create_item(item_type: String, position: Vector3) -> Node:
	if not ITEM_SCENES.has(item_type):
		push_error("[LevelGenerator] Unknown item type: %s" % item_type)
		return null

	var item_scene = ITEM_SCENES[item_type]
	var item = item_scene.instantiate()

	if not level_scene:
		push_error("[LevelGenerator] No level scene set")
		return null

	level_scene.add_child(item)
	item.global_position = position

	return item

## 完成生成
func _finalize_generation() -> void:
	# 设置玩家出生点
	if player:
		player.global_position = current_config.spawn_point

	# 可以在这里添加其他最终处理

## 清理关卡
func clear_level() -> void:
	# 清理敌人
	for enemy in generated_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	generated_enemies.clear()

	# 清理障碍
	for obstacle in generated_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	generated_obstacles.clear()

	# 清理道具
	for item in generated_items:
		if is_instance_valid(item):
			item.queue_free()
	generated_items.clear()

	print("[LevelGenerator] Level cleared")

## 设置玩家引用
func set_player(p: Node3D) -> void:
	player = p

## 获取生成的敌人
func get_enemies() -> Array[Node]:
	return generated_enemies

## 获取生成的障碍
func get_obstacles() -> Array[Node]:
	return generated_obstacles

## 获取生成的道具
func get_items() -> Array[Node]:
	return generated_items

## 获取当前配置
func get_config():
	return current_config
