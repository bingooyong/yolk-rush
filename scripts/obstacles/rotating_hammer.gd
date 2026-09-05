extends ObstacleBase
class_name RotatingHammer
## 旋转锤障碍 - 经典派对游戏障碍

@export var rotation_speed: float = 60.0  # 度/秒
@export var rotation_axis: Vector3 = Vector3.UP  # 旋转轴
@export var hammer_length: float = 3.0  # 锤子长度
@export var hammer_width: float = 1.0   # 锤子宽度
@export var reverse_direction: bool = false  # 反向旋转

var hammer_arm: Node3D
var hammer_head: MeshInstance3D
var rotation_pivot: Node3D

func _initialize_obstacle() -> void:
	obstacle_name = "Rotating Hammer"
	damage_type = DamageType.HEAVY
	damage_amount = 30.0
	knockback_force = 15.0

	_create_visual()
	_setup_physics()

func _create_visual() -> void:
	# 旋转中心点
	rotation_pivot = Node3D.new()
	rotation_pivot.name = "RotationPivot"
	add_child(rotation_pivot)

	# 锤臂
	hammer_arm = MeshInstance3D.new()
	hammer_arm.name = "HammerArm"
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.3, hammer_length, 0.3)
	hammer_arm.mesh = arm_mesh

	# 创建材质
	var arm_material = StandardMaterial3D.new()
	arm_material.albedo_color = Color(0.4, 0.3, 0.2)  # 木质颜色
	hammer_arm.material_override = arm_material

	hammer_arm.position = Vector3(0, hammer_length / 2, 0)
	rotation_pivot.add_child(hammer_arm)

	# 锤头
	hammer_head = MeshInstance3D.new()
	hammer_head.name = "HammerHead"
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(hammer_width, hammer_width * 0.8, hammer_width)
	hammer_head.mesh = head_mesh

	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.6, 0.6, 0.65)  # 金属颜色
	head_material.metallic = 0.8
	head_material.roughness = 0.3
	hammer_head.material_override = head_material

	hammer_head.position = Vector3(0, hammer_length, 0)
	rotation_pivot.add_child(hammer_head)

func _setup_physics() -> void:
	# 在锤头位置设置碰撞
	var shape = BoxShape3D.new()
	shape.size = Vector3(hammer_width, hammer_width * 0.8, hammer_width)

	collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, hammer_length, 0)

	collision_area.add_child(collision_shape)

func _process(delta: float) -> void:
	if not is_active:
		return

	# 旋转
	var rotation_amount = rotation_speed * delta
	if reverse_direction:
		rotation_amount = -rotation_amount

	rotation_pivot.rotate(rotation_axis.normalized(), deg_to_rad(rotation_amount))

func _on_triggered(player: Node) -> void:
	# 播放音效（如果有）
	print("[RotatingHammer] Hit player: %s" % player.name)

## 设置旋转速度
func set_rotation_speed(speed: float) -> void:
	rotation_speed = speed

## 反转旋转方向
func reverse_rotation() -> void:
	reverse_direction = not reverse_direction

## 获取当前旋转角度
func get_current_angle() -> float:
	return rotation_pivot.rotation.y
