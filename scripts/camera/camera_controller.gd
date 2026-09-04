extends Node3D
## Camera Controller: 第三人称跟随相机

@export var target: Node3D
@export var distance: float = 8.0
@export var height_offset: float = 3.0
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 3.0

@onready var camera: Camera3D = $Camera3D

var current_rotation: float = 0.0
var camera_angle: float = -25.0  # 俯视角度

func _ready() -> void:
	if not camera:
		camera = Camera3D.new()
		add_child(camera)

	camera.position = Vector3(0, 0, distance)
	camera.rotation_degrees.x = camera_angle

	print("[CameraController] Ready - Distance: %.1f, Height: %.1f" % [distance, height_offset])

func _process(delta: float) -> void:
	if not target:
		return

	_follow_target(delta)

func _follow_target(delta: float) -> void:
	# 计算目标位置（角色位置 + 高度偏移）
	var target_pos := target.global_position + Vector3.UP * height_offset

	# 相机环绕目标旋转
	var offset := Vector3.BACK * distance
	offset = offset.rotated(Vector3.UP, current_rotation)

	var desired_pos := target_pos + offset

	# 平滑跟随
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# 始终看向目标
	look_at(target_pos, Vector3.UP)

func rotate_camera(delta_angle: float) -> void:
	current_rotation += delta_angle

func get_camera_basis() -> Basis:
	return camera.global_transform.basis if camera else Basis.IDENTITY

func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		global_position = target.global_position + Vector3(0, height_offset, distance)
