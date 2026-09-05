extends CPUParticles3D
class_name DeathParticles
## 敌人死亡粒子特效
## 红色消散效果

func _ready() -> void:
	# 基础设置
	emitting = false
	one_shot = true
	explosiveness = 0.8
	randomness = 0.4
	lifetime = 0.6

	# 粒子数量
	amount = 24

	# 发射形状（球形）
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.5

	# 方向和速度（向上飘散）
	direction = Vector3(0, 1, 0)
	spread = 45.0
	initial_velocity_min = 2.0
	initial_velocity_max = 4.0

	# 重力（轻微下落）
	gravity = Vector3(0, -2.0, 0)

	# 颜色（红色到透明）
	color = Color(1.0, 0.2, 0.2, 1.0)
	color_ramp = _create_color_ramp()

	# 大小（从中到小）
	scale_amount_min = 0.15
	scale_amount_max = 0.25
	scale_amount_curve = _create_scale_curve()

	print("[DeathParticles] Initialized")

func _create_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.2, 0.2, 1.0))  # 红色
	gradient.set_color(0.5, Color(0.8, 0.1, 0.1, 0.6))  # 深红半透明
	gradient.set_color(1, Color(0.5, 0.0, 0.0, 0.0))  # 暗红透明
	return gradient

func _create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

## 播放粒子特效
func play_at(position: Vector3) -> void:
	global_position = position
	restart()

	# 自动清理
	await get_tree().create_timer(lifetime + 0.1).timeout
	if is_instance_valid(self):
		queue_free()
