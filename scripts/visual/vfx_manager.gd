extends Node
class_name VFXManager
## VFX 特效管理器
## Phase 4.5: 为技能和战斗添加粒子特效

## 播放技能特效
static func play_skill_vfx(skill_id: String, position: Vector3, parent: Node3D) -> void:
	match skill_id:
		"whirlwind_slash":
			_spawn_whirlwind_vfx(position, parent)
		"dash":
			_spawn_dash_vfx(position, parent)
		"shield":
			_spawn_shield_vfx(position, parent)
		"devastate":
			_spawn_devastate_vfx(position, parent)
		_:
			push_warning("[VFXManager] Unknown skill VFX: %s" % skill_id)

## 旋风斩特效（黄色旋转刀光）
static func _spawn_whirlwind_vfx(pos: Vector3, parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "WhirlwindVFX"
	particles.position = pos
	particles.amount = 32
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.8

	# 粒子材质
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 180.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 5.0
	material.angular_velocity_min = -720.0
	material.angular_velocity_max = 720.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.1
	material.scale_max = 0.3

	particles.process_material = material

	# 视觉材质（黄色光点）
	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.2, 0.2)
	particles.draw_pass_1 = draw_pass

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.0)  # 黄色
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.0) * 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = mat

	parent.add_child(particles)
	particles.emitting = true

	# 1秒后自动删除
	await parent.get_tree().create_timer(1.5).timeout
	particles.queue_free()

## 冲刺特效（速度线拖尾）
static func _spawn_dash_vfx(pos: Vector3, parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "DashVFX"
	particles.position = pos
	particles.amount = 20
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.BACK
	material.spread = 30.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.3
	material.scale_max = 0.5

	particles.process_material = material

	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.8, 0.1)
	particles.draw_pass_1 = draw_pass

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	mat.emission_enabled = true
	mat.emission = Color.WHITE * 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = mat

	parent.add_child(particles)
	particles.emitting = true

	await parent.get_tree().create_timer(1.0).timeout
	particles.queue_free()

## 护盾特效（蓝色光球）
static func _spawn_shield_vfx(pos: Vector3, parent: Node3D) -> Node3D:
	var shield_visual := Node3D.new()
	shield_visual.name = "ShieldVFX"
	shield_visual.position = pos

	# 半透明球体
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.5
	sphere.height = 3.0
	mesh_instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0) * 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat

	shield_visual.add_child(mesh_instance)

	# 环绕粒子
	var particles := GPUParticles3D.new()
	particles.amount = 16
	particles.lifetime = 2.0
	particles.explosiveness = 0.0

	var p_mat := ParticleProcessMaterial.new()
	p_mat.direction = Vector3.UP
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 0.5
	p_mat.initial_velocity_max = 1.0
	p_mat.gravity = Vector3.ZERO
	p_mat.scale_min = 0.1
	p_mat.scale_max = 0.2

	particles.process_material = p_mat

	var p_draw := QuadMesh.new()
	p_draw.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = p_draw

	var p_visual := StandardMaterial3D.new()
	p_visual.albedo_color = Color(0.5, 0.8, 1.0)
	p_visual.emission_enabled = true
	p_visual.emission = Color(0.5, 0.8, 1.0) * 2.0
	p_visual.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_visual.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = p_visual

	shield_visual.add_child(particles)
	particles.emitting = true

	parent.add_child(shield_visual)
	return shield_visual

## 毁灭一击特效（爆炸）
static func _spawn_devastate_vfx(pos: Vector3, parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "DevastateVFX"
	particles.position = pos
	particles.amount = 64
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3(0, -9.8, 0)
	material.scale_min = 0.2
	material.scale_max = 0.6

	particles.process_material = material

	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.4, 0.4)
	particles.draw_pass_1 = draw_pass

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0)  # 橙红色
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0) * 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = mat

	parent.add_child(particles)
	particles.emitting = true

	# 冲击波（扩散圈）
	_spawn_shockwave(pos, parent)

	await parent.get_tree().create_timer(2.0).timeout
	particles.queue_free()

## 冲击波效果
static func _spawn_shockwave(pos: Vector3, parent: Node3D) -> void:
	var shockwave := MeshInstance3D.new()
	shockwave.name = "Shockwave"
	shockwave.position = pos + Vector3(0, 0.1, 0)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.5
	shockwave.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.5, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.3) * 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.material_override = mat

	parent.add_child(shockwave)

	# 动画：扩大 + 淡出
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "scale", Vector3(8, 1, 8), 0.5)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)

	await tween.finished
	shockwave.queue_free()

## 打击特效（命中时的火花）
static func spawn_hit_vfx(pos: Vector3, parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "HitVFX"
	particles.position = pos
	particles.amount = 16
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 180.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -5.0, 0)
	material.scale_min = 0.05
	material.scale_max = 0.15

	particles.process_material = material

	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = draw_pass

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color.WHITE * 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = mat

	parent.add_child(particles)
	particles.emitting = true

	await parent.get_tree().create_timer(0.8).timeout
	particles.queue_free()

## 受击闪光（角色受伤时）
static func flash_hit_feedback(target: Node3D, duration: float = 0.2) -> void:
	# 找到目标的所有 MeshInstance3D
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(target, meshes)

	if meshes.is_empty():
		return

	# 保存原始材质
	var original_mats: Array = []
	for mesh in meshes:
		original_mats.append(mesh.material_override)

	# 应用红色闪光材质
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.3, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color.RED * 2.0

	for mesh in meshes:
		mesh.material_override = flash_mat

	# 等待后恢复
	await target.get_tree().create_timer(duration).timeout

	for i in range(meshes.size()):
		meshes[i].material_override = original_mats[i]

## 递归收集所有 MeshInstance3D
static func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)

	for child in node.get_children():
		_collect_meshes(child, result)
