extends ObstacleBase
class_name FallingPlatform
## 掉落平台 - 玩家站上后会掉落

@export var fall_delay: float = 0.8  # 掉落延迟（秒）
@export var fall_speed: float = 8.0  # 掉落速度
@export var respawn_delay: float = 3.0  # 重生延迟
@export var platform_size: Vector3 = Vector3(2.0, 0.3, 2.0)  # 平台尺寸
@export var shake_before_fall: bool = true  # 掉落前是否抖动

enum PlatformState {
	STABLE,      # 稳定
	TRIGGERED,   # 已触发（倒计时）
	FALLING,     # 掉落中
	RESPAWNING   # 重生中
}

var platform_state: PlatformState = PlatformState.STABLE
var state_timer: float = 0.0
var original_position: Vector3

var platform_mesh: MeshInstance3D
var platform_body: StaticBody3D
var platform_collision: CollisionShape3D
var shake_offset: Vector3 = Vector3.ZERO

func _initialize_obstacle() -> void:
	obstacle_name = "Falling Platform"
	damage_type = DamageType.NONE  # 不直接造成伤害
	damage_amount = 0.0
	knockback_force = 0.0

	original_position = global_position
	_create_platform()

func _create_platform() -> void:
	# 创建平台视觉
	platform_mesh = MeshInstance3D.new()
	platform_mesh.name = "PlatformMesh"

	var mesh = BoxMesh.new()
	mesh.size = platform_size
	platform_mesh.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.5, 0.3)  # 橙棕色
	material.roughness = 0.8
	platform_mesh.material_override = material

	add_child(platform_mesh)

	# 创建物理体
	platform_body = StaticBody3D.new()
	platform_body.name = "PlatformBody"
	add_child(platform_body)

	platform_collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = platform_size
	platform_collision.shape = shape
	platform_body.add_child(platform_collision)

	# 设置触发区域
	var trigger_shape = BoxShape3D.new()
	trigger_shape.size = Vector3(platform_size.x * 0.9, platform_size.y + 0.5, platform_size.z * 0.9)

	collision_shape = CollisionShape3D.new()
	collision_shape.shape = trigger_shape
	collision_shape.position = Vector3(0, platform_size.y / 2, 0)
	collision_area.add_child(collision_shape)

func _process(delta: float) -> void:
	if not is_active:
		return

	match platform_state:
		PlatformState.TRIGGERED:
			_handle_triggered(delta)

		PlatformState.FALLING:
			_handle_falling(delta)

		PlatformState.RESPAWNING:
			_handle_respawning(delta)

func _handle_triggered(delta: float) -> void:
	state_timer -= delta

	# 抖动效果
	if shake_before_fall:
		var shake_intensity = (1.0 - state_timer / fall_delay) * 0.1
		shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			0,
			randf_range(-shake_intensity, shake_intensity)
		)
		platform_mesh.position = shake_offset

		# 颜色变化警告
		var material = platform_mesh.material_override as StandardMaterial3D
		if material:
			var warning_lerp = 1.0 - (state_timer / fall_delay)
			material.albedo_color = Color(0.7, 0.5, 0.3).lerp(Color(0.9, 0.2, 0.2), warning_lerp)

	if state_timer <= 0:
		# 开始掉落
		platform_state = PlatformState.FALLING
		platform_collision.disabled = true  # 禁用碰撞
		print("[FallingPlatform] Started falling!")

func _handle_falling(delta: float) -> void:
	# 向下掉落
	global_position += Vector3.DOWN * fall_speed * delta

	# 旋转效果
	platform_mesh.rotate_y(delta * 2.0)
	platform_mesh.rotate_x(delta * 1.5)

	# 掉落一定距离后开始重生
	if global_position.y < original_position.y - 20.0:
		platform_state = PlatformState.RESPAWNING
		state_timer = respawn_delay
		visible = false
		print("[FallingPlatform] Started respawning...")

func _handle_respawning(delta: float) -> void:
	state_timer -= delta

	if state_timer <= 0:
		# 重生
		_respawn_platform()

func _respawn_platform() -> void:
	global_position = original_position
	platform_mesh.position = Vector3.ZERO
	platform_mesh.rotation = Vector3.ZERO
	shake_offset = Vector3.ZERO

	# 恢复颜色
	var material = platform_mesh.material_override as StandardMaterial3D
	if material:
		material.albedo_color = Color(0.7, 0.5, 0.3)

	# 重新启用碰撞
	platform_collision.disabled = false

	# 重生动画
	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	platform_state = PlatformState.STABLE
	print("[FallingPlatform] Respawned!")

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	if platform_state != PlatformState.STABLE:
		return

	if _is_player(body):
		# 触发掉落
		platform_state = PlatformState.TRIGGERED
		state_timer = fall_delay
		print("[FallingPlatform] Triggered by: %s" % body.name)

		obstacle_triggered.emit(body)

## 立即掉落（无延迟）
func fall_immediately() -> void:
	if platform_state == PlatformState.STABLE:
		platform_state = PlatformState.FALLING
		platform_collision.disabled = true

## 设置掉落延迟
func set_fall_delay(delay: float) -> void:
	fall_delay = delay

## 设置重生延迟
func set_respawn_delay(delay: float) -> void:
	respawn_delay = delay

func _on_reset() -> void:
	_respawn_platform()
