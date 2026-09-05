extends CPUParticles3D
class_name HitParticles
## 攻击命中粒子特效
## 白色火花爆发效果

func _ready() -> void:
	# 基础设置
	emitting = false
	one_shot = true
	explosiveness = 1.0
	randomness = 0.3
	lifetime = 0.3

	# 粒子数量
	amount = 16

	# 发射形状（球形）
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.2

	# 方向和速度
	direction = Vector3.UP
	spread = 180.0
	initial_velocity_min = 3.0
	initial_velocity_max = 5.0

	# 重力
	gravity = Vector3(0, -9.8, 0)

	# 颜色（白色到透明）
	color = Color.WHITE
	color_ramp = _create_color_ramp()

	# 大小（从大到小）
	scale_amount_min = 0.1
	scale_amount_max = 0.2
	scale_amount_curve = _create_scale_curve()

	print("[HitParticles] Initialized")

func _create_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))  # 透明
	return gradient

func _create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
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
