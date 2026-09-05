extends ObstacleBase
class_name MovingPlatform
## 移动平台 - 可站立的移动障碍

@export var move_speed: float = 2.0  # 移动速度
@export var move_distance: float = 5.0  # 移动距离
@export var move_direction: Vector3 = Vector3.RIGHT  # 移动方向
@export var pause_time: float = 1.0  # 两端停留时间
@export var platform_size: Vector3 = Vector3(3.0, 0.5, 3.0)  # 平台尺寸

var start_position: Vector3
var end_position: Vector3
var current_target: Vector3
var is_paused: bool = false
var pause_timer: float = 0.0

var platform_mesh: MeshInstance3D
var platform_body: StaticBody3D
var platform_collision: CollisionShape3D

func _initialize_obstacle() -> void:
	obstacle_name = "Moving Platform"
	damage_type = DamageType.NONE  # 平台本身不造成伤害
	damage_amount = 0.0
	knockback_force = 0.0

	_create_platform()
	_setup_movement()

func _create_platform() -> void:
	# 创建平台视觉
	platform_mesh = MeshInstance3D.new()
	platform_mesh.name = "PlatformMesh"

	var mesh = BoxMesh.new()
	mesh.size = platform_size
	platform_mesh.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.7)  # 蓝灰色
	material.metallic = 0.2
	material.roughness = 0.8
	platform_mesh.material_override = material

	add_child(platform_mesh)

	# 创建物理体（让玩家可以站立）
	platform_body = StaticBody3D.new()
	platform_body.name = "PlatformBody"
	add_child(platform_body)

	platform_collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = platform_size
	platform_collision.shape = shape
	platform_body.add_child(platform_collision)

func _setup_movement() -> void:
	start_position = global_position
	end_position = start_position + (move_direction.normalized() * move_distance)
	current_target = end_position

func _process(delta: float) -> void:
	if not is_active:
		return

	if is_paused:
		pause_timer -= delta
		if pause_timer <= 0:
			is_paused = false
			# 切换目标
			if current_target == end_position:
				current_target = start_position
			else:
				current_target = end_position
		return

	# 移动平台
	var direction = (current_target - global_position).normalized()
	var distance_to_target = global_position.distance_to(current_target)

	if distance_to_target < 0.1:
		# 到达目标，开始暂停
		is_paused = true
		pause_timer = pause_time
		global_position = current_target
	else:
		# 继续移动
		var move_amount = move_speed * delta
		global_position += direction * move_amount

func _physics_process(delta: float) -> void:
	# 移动站在平台上的玩家
	_move_riders(delta)

func _move_riders(delta: float) -> void:
	# 检测平台上方的物体
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsShapeQueryParameters3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(platform_size.x * 0.9, 0.2, platform_size.z * 0.9)
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position + Vector3(0, platform_size.y / 2 + 0.1, 0))
	query.collision_mask = 1  # 玩家层

	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result["collider"]
		if _is_player(body):
			# 让玩家跟随平台移动
			if body.is_on_floor():
				var velocity = (current_target - global_position).normalized() * move_speed
				if body.has_method("add_platform_velocity"):
					body.add_platform_velocity(velocity)

## 设置移动速度
func set_move_speed(speed: float) -> void:
	move_speed = speed

## 设置移动距离
func set_move_distance(distance: float) -> void:
	move_distance = distance
	_setup_movement()

## 设置移动方向
func set_move_direction(direction: Vector3) -> void:
	move_direction = direction
	_setup_movement()

## 反转移动方向
func reverse_direction() -> void:
	var temp = start_position
	start_position = end_position
	end_position = temp
	current_target = end_position if current_target == start_position else start_position

func _on_reset() -> void:
	global_position = start_position
	current_target = end_position
	is_paused = false
	pause_timer = 0.0
