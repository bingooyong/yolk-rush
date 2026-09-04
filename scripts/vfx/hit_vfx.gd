extends CPUParticles3D
## Hit VFX: 受击粒子特效（爆炸效果）

func _ready() -> void:
	_setup_hit_particles()
	emitting = false

func _setup_hit_particles() -> void:
	# 基础设置
	amount = 15
	lifetime = 0.5
	one_shot = true
	explosiveness = 0.9

	# 发射形状 - 球形爆炸
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.2

	# 速度 - 四散飞溅
	direction = Vector3.ZERO
	spread = 180.0
	initial_velocity_min = 3.0
	initial_velocity_max = 6.0

	# 颜色渐变 - 红色到橙色到透明
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.3, 0.3, 1.0))  # 鲜红色
	gradient.add_point(0.3, Color(1.0, 0.6, 0.2, 0.9))  # 橙色
	gradient.add_point(1.0, Color(1.0, 0.3, 0.0, 0.0))  # 透明

	color_gradient = gradient

	# 大小变化 - 从大到小
	scale_amount_min = 0.15
	scale_amount_max = 0.25
	scale_amount_curve = _create_scale_curve()

	# 重力 - 快速下坠
	gravity = Vector3(0, -9.8, 0)

	# 材质
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.2)
	mat.emission_energy_multiplier = 1.5
	draw_pass_1 = SphereMesh.new()
	(draw_pass_1 as SphereMesh).radius = 0.1
	(draw_pass_1 as SphereMesh).height = 0.2
	(draw_pass_1 as SphereMesh).material = mat

func _create_scale_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func play_effect() -> void:
	emitting = true
	await get_tree().create_timer(lifetime).timeout
