extends CPUParticles3D
class_name PickupParticles
## 道具拾取粒子特效
## 可配置颜色的向上爆发效果

enum ParticleType {
	GOLD,    # 金色（金币）
	GREEN    # 绿色（药水）
}

var particle_type: ParticleType = ParticleType.GOLD

func _ready() -> void:
	# 基础设置
	emitting = false
	one_shot = true
	explosiveness = 0.9
	randomness = 0.3
	lifetime = 0.4

	# 粒子数量
	amount = 20

	# 发射形状（球形）
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.3

	# 方向和速度（向上爆发）
	direction = Vector3(0, 1, 0)
	spread = 30.0
	initial_velocity_min = 4.0
	initial_velocity_max = 6.0

	# 重力
	gravity = Vector3(0, -5.0, 0)

	# 大小
	scale_amount_min = 0.12
	scale_amount_max = 0.18
	scale_amount_curve = _create_scale_curve()

	# 根据类型设置颜色
	_setup_color()

	print("[PickupParticles] Initialized (type: %s)" % ParticleType.keys()[particle_type])

func _setup_color() -> void:
	match particle_type:
		ParticleType.GOLD:
			color = Color(1.0, 0.9, 0.2, 1.0)
			color_ramp = _create_gold_ramp()
		ParticleType.GREEN:
			color = Color(0.2, 1.0, 0.3, 1.0)
			color_ramp = _create_green_ramp()

func _create_gold_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.2, 1.0))  # 金色
	gradient.set_color(0.5, Color(1.0, 0.8, 0.1, 0.7))  # 深金半透明
	gradient.set_color(1, Color(0.9, 0.7, 0.0, 0.0))  # 暗金透明
	return gradient

func _create_green_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.2, 1.0, 0.3, 1.0))  # 绿色
	gradient.set_color(0.5, Color(0.1, 0.8, 0.2, 0.7))  # 深绿半透明
	gradient.set_color(1, Color(0.0, 0.6, 0.1, 0.0))  # 暗绿透明
	return gradient

func _create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

## 设置粒子类型
func set_type(type: ParticleType) -> void:
	particle_type = type
	if is_inside_tree():
		_setup_color()

## 播放粒子特效
func play_at(position: Vector3, type: ParticleType = ParticleType.GOLD) -> void:
	set_type(type)
	global_position = position
	restart()

	# 自动清理
	await get_tree().create_timer(lifetime + 0.1).timeout
	if is_instance_valid(self):
		queue_free()
