extends Node3D
class_name ObstacleCourseLevel
## 关卡 1: 障碍竞速
## 密集障碍赛道，考验操作和速度

## 关卡配置
const LEVEL_ID = 1
const LEVEL_NAME = "障碍竞速"
const TIME_LIMIT = 120.0

## 节点引用
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var obstacles_container: Node3D = $Obstacles
@onready var enemies_container: Node3D = $Enemies
@onready var items_container: Node3D = $Items
@onready var finish_trigger: Area3D = $FinishTrigger

## 管理器引用
var game_state_manager: Node = null
var level_flow_controller: Node = null

## 玩家引用
var player: Node3D = null

func _ready() -> void:
	print("[ObstacleCourseLevel] Initializing...")

	# 查找管理器
	_find_managers()

	# 生成关卡内容
	_spawn_obstacles()
	_spawn_enemies()
	_spawn_items()

	# 等待玩家
	await get_tree().create_timer(0.5).timeout
	_find_player()

	print("[ObstacleCourseLevel] Initialized")

## 查找管理器
func _find_managers() -> void:
	if has_node("/root/GameStateManager"):
		game_state_manager = get_node("/root/GameStateManager")

	var root = get_tree().root
	if root:
		level_flow_controller = root.find_child("LevelFlowController", true, false)

## 查找玩家
func _find_player() -> void:
	player = get_tree().root.find_child("Player", true, false)
	if player:
		print("[ObstacleCourseLevel] Player found")

## 生成障碍物
func _spawn_obstacles() -> void:
	# 6个移动平台（交错）
	for i in range(6):
		var z_pos = 10 + i * 8
		var start_x = -4.0 if i % 2 == 0 else 4.0
		var end_x = 4.0 if i % 2 == 0 else -4.0
		_create_moving_platform(
			Vector3(start_x, 1, z_pos),
			Vector3(end_x, 1, z_pos),
			3.0
		)

	# 4个旋转锤（不同高度）
	_create_rotating_hammer(Vector3(0, 2, 60), 2.5, 0.0)
	_create_rotating_hammer(Vector3(0, 2, 70), 2.5, PI/2)
	_create_rotating_hammer(Vector3(0, 2, 80), 2.5, PI)
	_create_rotating_hammer(Vector3(0, 2, 90), 2.5, 3*PI/2)

	# 3个滑动墙
	_create_sliding_wall(Vector3(-5, 1, 100), Vector3(5, 1, 100), 2.0)
	_create_sliding_wall(Vector3(5, 1, 110), Vector3(-5, 1, 110), 2.0)
	_create_sliding_wall(Vector3(-5, 1, 120), Vector3(5, 1, 120), 2.0)

	# 2个跳跃区域（需要连续跳跃的平台）
	_create_jumping_section(Vector3(0, 0, 130), 5)
	_create_jumping_section(Vector3(0, 0, 145), 4)

	print("[ObstacleCourseLevel] Spawned obstacles")

## 创建移动平台
func _create_moving_platform(start_pos: Vector3, end_pos: Vector3, duration: float) -> void:
	var platform = CSGBox3D.new()
	platform.size = Vector3(2, 0.3, 2)
	platform.position = start_pos

	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 0.3, 2)
	collision.shape = shape

	static_body.add_child(collision)
	platform.add_child(static_body)
	obstacles_container.add_child(platform)

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(platform, "position", end_pos, duration)
	tween.tween_property(platform, "position", start_pos, duration)

## 创建旋转锤
func _create_rotating_hammer(pos: Vector3, radius: float, start_angle: float) -> void:
	var pivot = Node3D.new()
	pivot.position = pos
	pivot.rotation.y = start_angle
	obstacles_container.add_child(pivot)

	# 锤臂
	var arm = CSGBox3D.new()
	arm.size = Vector3(0.3, 0.3, radius)
	arm.position = Vector3(0, 0, radius / 2)

	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.3, radius)
	collision.shape = shape

	static_body.add_child(collision)
	arm.add_child(static_body)
	pivot.add_child(arm)

	# 锤头
	var hammer = CSGSphere3D.new()
	hammer.radius = 0.8
	hammer.position = Vector3(0, 0, radius)

	var hammer_body = StaticBody3D.new()
	var hammer_collision = CollisionShape3D.new()
	var hammer_shape = SphereShape3D.new()
	hammer_shape.radius = 0.8
	hammer_collision.shape = hammer_shape

	hammer_body.add_child(hammer_collision)
	hammer.add_child(hammer_body)
	pivot.add_child(hammer)

	# 旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(pivot, "rotation:y", start_angle + TAU, 3.0)

## 创建滑动墙
func _create_sliding_wall(start_pos: Vector3, end_pos: Vector3, duration: float) -> void:
	var wall = CSGBox3D.new()
	wall.size = Vector3(0.5, 2, 1)
	wall.position = start_pos

	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 2, 1)
	collision.shape = shape

	static_body.add_child(collision)
	wall.add_child(static_body)
	obstacles_container.add_child(wall)

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(wall, "position", end_pos, duration).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(wall, "position", start_pos, duration).set_ease(Tween.EASE_IN_OUT)

## 创建跳跃区域
func _create_jumping_section(start_pos: Vector3, platform_count: int) -> void:
	for i in range(platform_count):
		var platform = CSGBox3D.new()
		platform.size = Vector3(1.5, 0.3, 1.5)
		platform.position = start_pos + Vector3(
			randf_range(-2, 2),
			randf_range(0, 1),
			i * 2.5
		)

		var static_body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.5, 0.3, 1.5)
		collision.shape = shape

		static_body.add_child(collision)
		platform.add_child(static_body)
		obstacles_container.add_child(platform)

## 生成敌人
func _spawn_enemies() -> void:
	# 5个基础敌人
	for i in range(5):
		_create_enemy_spawn_point(
			Vector3(randf_range(-4, 4), 0, 20 + i * 15),
			"basic",
			50.0,
			10.0,
			3.0
		)

	# 3个快速敌人
	_create_enemy_spawn_point(Vector3(-3, 0, 75), "fast", 30.0, 8.0, 5.0)
	_create_enemy_spawn_point(Vector3(3, 0, 95), "fast", 30.0, 8.0, 5.0)
	_create_enemy_spawn_point(Vector3(0, 0, 125), "fast", 30.0, 8.0, 5.0)

	print("[ObstacleCourseLevel] Enemy spawn points created")

## 创建敌人生成点
func _create_enemy_spawn_point(pos: Vector3, type: String, health: float, damage: float, speed: float) -> void:
	var marker = Marker3D.new()
	marker.position = pos
	marker.set_meta("enemy_type", type)
	marker.set_meta("enemy_health", health)
	marker.set_meta("enemy_damage", damage)
	marker.set_meta("enemy_speed", speed)
	enemies_container.add_child(marker)

## 生成道具
func _spawn_items() -> void:
	# 10个金币（散布在困难位置）
	for i in range(10):
		_create_coin(Vector3(
			randf_range(-5, 5),
			randf_range(1, 3),
			15 + i * 12
		))

	# 3个加速道具
	_create_speed_boost(Vector3(0, 1, 55))
	_create_speed_boost(Vector3(0, 1, 85))
	_create_speed_boost(Vector3(0, 1, 115))

	# 1个护盾道具
	_create_shield(Vector3(0, 1, 140))

	print("[ObstacleCourseLevel] Spawned items")

## 创建金币
func _create_coin(pos: Vector3) -> void:
	var coin = CSGSphere3D.new()
	coin.radius = 0.3
	coin.position = pos
	coin.set_meta("item_type", "coin")
	coin.set_meta("item_value", 10)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape

	area.add_child(collision)
	coin.add_child(area)
	items_container.add_child(coin)

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(coin, "rotation:y", TAU, 2.0)

## 创建加速道具
func _create_speed_boost(pos: Vector3) -> void:
	var boost = CSGCylinder3D.new()
	boost.radius = 0.3
	boost.height = 0.6
	boost.position = pos
	boost.set_meta("item_type", "speed_boost")
	boost.set_meta("boost_multiplier", 1.5)
	boost.set_meta("boost_duration", 5.0)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 0.8
	collision.shape = shape

	area.add_child(collision)
	boost.add_child(area)
	items_container.add_child(boost)

## 创建护盾道具
func _create_shield(pos: Vector3) -> void:
	var shield = CSGTorus3D.new()
	shield.inner_radius = 0.3
	shield.outer_radius = 0.5
	shield.position = pos
	shield.set_meta("item_type", "shield")
	shield.set_meta("shield_duration", 8.0)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.6
	collision.shape = shape

	area.add_child(collision)
	shield.add_child(area)
	items_container.add_child(shield)

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(shield, "rotation:y", TAU, 3.0)

## 获取关卡配置
func get_level_config() -> Dictionary:
	return {
		"id": LEVEL_ID,
		"name": LEVEL_NAME,
		"time_limit": TIME_LIMIT,
		"spawn_point": spawn_point.global_position if spawn_point else Vector3.ZERO
	}
