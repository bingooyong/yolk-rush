extends Node3D
## CameraController - 相机控制器
## Phase 6: 完整相机效果（平滑跟随 + 震动 + FOV + 慢动作）

@export var follow_target: Node3D
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 3.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var shake_strength: float = 0.0
var shake_decay: float = 5.0
var base_fov: float = 75.0
var target_fov: float = 75.0
var fov_transition_speed: float = 5.0

func _ready() -> void:
	base_fov = camera.fov
	target_fov = base_fov
	print("[CameraController] Initialized - FOV: %.1f" % base_fov)

func _process(delta: float) -> void:
	if follow_target:
		_update_follow(delta)

	_update_shake(delta)
	_update_fov(delta)

func _update_follow(delta: float) -> void:
	# 平滑跟随目标位置
	var target_position := follow_target.global_position
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# 可选：平滑跟随目标旋转
	# var target_rotation := follow_target.global_rotation
	# global_rotation = global_rotation.lerp(target_rotation, rotation_speed * delta)

func _update_shake(delta: float) -> void:
	if shake_strength > 0:
		# 生成随机偏移
		var shake_offset := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength

		# 应用到相机
		camera.position = shake_offset

		# 衰减震动
		shake_strength = max(0.0, shake_strength - shake_decay * delta)
	else:
		# 恢复相机位置
		camera.position = camera.position.lerp(Vector3.ZERO, 10.0 * delta)

func _update_fov(delta: float) -> void:
	if abs(camera.fov - target_fov) > 0.1:
		camera.fov = lerp(camera.fov, target_fov, fov_transition_speed * delta)

## 添加相机震动
func add_shake(strength: float) -> void:
	shake_strength += strength
	shake_strength = min(shake_strength, 2.0)  # 限制最大震动
	print("[CameraController] Shake added: %.2f" % strength)

## 设置 FOV 增强（冲刺/慢动作效果）
func set_fov_boost(multiplier: float, duration: float) -> void:
	target_fov = base_fov * multiplier

	# 持续时间后恢复
	await get_tree().create_timer(duration).timeout
	target_fov = base_fov

	print("[CameraController] FOV boost: %.1f for %.1fs" % [multiplier, duration])

## 设置时间缩放（慢动作效果）
func set_time_scale(scale: float, duration: float) -> void:
	Engine.time_scale = scale
	print("[CameraController] Time scale: %.2f for %.1fs" % [scale, duration])

	# 持续时间后恢复
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	print("[CameraController] Time scale restored")

## 设置跟随目标
func set_target(target: Node3D) -> void:
	follow_target = target
	print("[CameraController] Follow target set: %s" % target.name)
