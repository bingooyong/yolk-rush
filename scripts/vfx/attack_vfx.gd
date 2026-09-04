extends CPUParticles3D
## Attack VFX: 攻击粒子特效（能量波）

func _ready() -> void:
	_setup_attack_particles()
	emitting = false

func _setup_attack_particles() -> void:
	# 基础设置
	amount = 20
	lifetime = 0.4
	one_shot = true
	explosiveness = 0.8

	# 发射形状 - 圆锥形向前
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.3

	# 速度 - 快速向前
	direction = Vector3(0, 0, -1)  # 向前
	spread = 30.0
	initial_velocity_min = 5.0
	initial_velocity_max = 8.0

	# 颜色渐变 - 蓝色到青色到透明
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.8, 1.0, 1.0))  # 浅蓝色
	gradient.add_point(0.5, Color(0.2, 1.0, 1.0, 0.8))  # 青色
	gradient.add_point(1.0, Color(0.0, 0.5, 1.0, 0.0))  # 透明

	color_gradient = gradient

	# 大小变化 - 从小变大
	scale_amount_min = 0.1
	scale_amount_max = 0.2
	scale_amount_curve = _create_scale_curve()

	# 重力 - 轻微下坠
	gravity = Vector3(0, -2.0, 0)

	# 材质
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0)
	mat.emission_energy_multiplier = 2.0
	draw_pass_1 = SphereMesh.new()
	(draw_pass_1 as SphereMesh).radius = 0.1
	(draw_pass_1 as SphereMesh).height = 0.2
	(draw_pass_1 as SphereMesh).material = mat

func _create_scale_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	return curve

func play_effect() -> void:
	emitting = true
	await get_tree().create_timer(lifetime).timeout
