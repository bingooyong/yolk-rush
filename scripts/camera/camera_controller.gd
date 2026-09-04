extends Node3D
class_name CameraController
## 相机控制器
## Phase 6: 相机系统

@export var target: Node3D
@export var follow_speed: float = 10.0
@export var look_ahead_distance: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 15.0
@export var height_offset: float = 3.0

## 相机臂
@onready var camera_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

## 目标位置
var target_position: Vector3
var velocity: Vector3 = Vector3.ZERO

## 震动状态
var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	if camera_arm:
		camera_arm.spring_length = 8.0
		camera_arm.collision_mask = 1  # 只与环境碰撞

func _process(delta: float) -> void:
	if not target:
		return

	# 平滑跟随
	_update_follow(delta)

	# 相机震动
	_update_shake(delta)

## 更新跟随
func _update_follow(delta: float) -> void:
	# 计算目标位置（带前瞻）
	var target_forward := -target.global_basis.z
	target_position = target.global_position + target_forward * look_ahead_distance
	target_position.y += height_offset

	# 平滑移动
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# 看向目标
	var look_at_pos := target.global_position + Vector3.UP * 1.5
	camera_arm.look_at(look_at_pos, Vector3.UP)

## 更新震动
func _update_shake(delta: float) -> void:
	if shake_strength <= 0:
		return

	# 随机偏移
	var offset := Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		0
	) * shake_strength

	camera.position = offset

	# 衰减
	shake_strength = maxf(0, shake_strength - shake_decay * delta)

	# 归位
	if shake_strength <= 0:
		camera.position = Vector3.ZERO

## 触发震动
func add_shake(strength: float) -> void:
	shake_strength += strength

## 设置跟随目标
func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		global_position = target.global_position
		target_position = global_position

## 调整距离（战斗时拉远）
func set_distance(distance: float, duration: float = 0.5) -> void:
	if not camera_arm:
		return

	distance = clampf(distance, min_distance, max_distance)

	var tween := create_tween()
	tween.tween_property(camera_arm, "spring_length", distance, duration)

## FOV 变化（冲刺时）
func set_fov(fov: float, duration: float = 0.3) -> void:
	if not camera:
		return

	var tween := create_tween()
	tween.tween_property(camera, "fov", fov, duration)

## 慢动作效果
func slow_motion(duration: float, time_scale: float = 0.3) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0

## 死亡效果（黑白 + 缩放）
func death_effect() -> void:
	if not camera:
		return

	# 黑白滤镜（需要后处理）
	# TODO: 添加后处理效果

	# 拉远相机
	set_distance(max_distance, 2.0)

	# FOV 缩小
	set_fov(50, 2.0)
