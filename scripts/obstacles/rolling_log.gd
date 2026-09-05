extends ObstacleBase
class_name RollingLog
## 滚动圆木障碍 - 会滚过来碾压玩家

@export var roll_speed: float = 5.0  # 滚动速度
@export var roll_distance: float = 10.0  # 滚动距离
@export var log_radius: float = 0.8  # 圆木半径
@export var log_length: float = 6.0  # 圆木长度
@export var auto_return: bool = true  # 自动返回起点
@export var return_speed: float = 2.0  # 返回速度

enum RollState {
	WAITING,    # 等待
	ROLLING,    # 滚动中
	RETURNING   # 返回中
}

var roll_state: RollState = RollState.WAITING
var start_position: Vector3
var end_position: Vector3
var roll_direction: Vector3 = Vector3.FORWARD

var log_mesh: MeshInstance3D
var log_body: RigidBody3D

func _initialize_obstacle() -> void:
	obstacle_name = "Rolling Log"
	damage_type = DamageType.HEAVY
	damage_amount = 40.0
	knockback_force = 20.0

	_create_log()

func _create_log() -> void:
	# 创建圆木视觉
	log_mesh = MeshInstance3D.new()
	log_mesh.name = "LogMesh"

	var mesh = CylinderMesh.new()
	mesh.height = log_length
	mesh.top_radius = log_radius
	mesh.bottom_radius = log_radius
	log_mesh.mesh = mesh

	# 旋转90度使其横向
	log_mesh.rotation_degrees = Vector3(0, 0, 90)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.25, 0.1)  # 木质棕色
	material.roughness = 0.9
	log_mesh.material_override = material

	add_child(log_mesh)

	# 创建碰撞
	var shape = CylinderShape3D.new()
	shape.height = log_length
	shape.radius = log_radius

	collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	collision_shape.rotation_degrees = Vector3(0, 0, 90)
	collision_area.add_child(collision_shape)

	# 设置位置
	start_position = global_position
	end_position = start_position + roll_direction.normalized() * roll_distance

func _process(delta: float) -> void:
	if not is_active:
		return

	match roll_state:
		RollState.WAITING:
			_check_trigger()

		RollState.ROLLING:
			_roll_forward(delta)

		RollState.RETURNING:
			_return_to_start(delta)

	# 旋转动画
	if roll_state == RollState.ROLLING:
		var rotation_speed = (roll_speed / (2.0 * PI * log_radius)) * 360.0
		log_mesh.rotate_y(deg_to_rad(rotation_speed * delta))

func _check_trigger() -> void:
	# 检测附近是否有玩家
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 5.0  # 触发范围
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1  # 玩家层

	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result["collider"]
		if _is_player(body):
			start_rolling()
			break

func _roll_forward(delta: float) -> void:
	var direction = (end_position - global_position).normalized()
	var distance_to_end = global_position.distance_to(end_position)

	if distance_to_end < 0.5:
		# 到达终点
		if auto_return:
			roll_state = RollState.RETURNING
		else:
			roll_state = RollState.WAITING
		return

	global_position += direction * roll_speed * delta

func _return_to_start(delta: float) -> void:
	var direction = (start_position - global_position).normalized()
	var distance_to_start = global_position.distance_to(start_position)

	if distance_to_start < 0.5:
		# 回到起点
		global_position = start_position
		roll_state = RollState.WAITING
		return

	global_position += direction * return_speed * delta

## 开始滚动
func start_rolling() -> void:
	if roll_state != RollState.WAITING:
		return

	roll_state = RollState.ROLLING
	set_state(ObstacleState.ACTIVE)
	print("[RollingLog] Started rolling!")

## 设置滚动方向
func set_roll_direction(direction: Vector3) -> void:
	roll_direction = direction.normalized()
	end_position = start_position + roll_direction * roll_distance

## 设置滚动速度
func set_roll_speed(speed: float) -> void:
	roll_speed = speed

func _on_triggered(player: Node) -> void:
	print("[RollingLog] Crushed player: %s" % player.name)

func _on_reset() -> void:
	global_position = start_position
	roll_state = RollState.WAITING
	log_mesh.rotation = Vector3(0, 0, 90)
