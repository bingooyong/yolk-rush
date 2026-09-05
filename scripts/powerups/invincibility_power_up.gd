extends PowerUpBase
class_name InvincibilityPowerUp
## 无敌道具 - 免疫所有伤害和障碍

var flash_timer: float = 0.0
var flash_interval: float = 0.1

func _initialize_power_up() -> void:
	power_up_name = "Invincibility"
	power_up_type = PowerUpType.INVINCIBILITY
	rarity = PowerUpRarity.RARE
	duration = 6.0
	can_stack = false  # 无敌不可叠加

	_customize_visual()

func _customize_visual() -> void:
	# 星星形状（用多个柱体组合）
	if mesh_instance:
		mesh_instance.queue_free()

	_create_star_shape()

func _create_star_shape() -> void:
	var star_container = Node3D.new()
	star_container.name = "StarMesh"
	add_child(star_container)

	# 创建5个点的星星
	for i in range(5):
		var point = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.05
		mesh.bottom_radius = 0.15
		mesh.height = 0.4
		point.mesh = mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.0)  # 金色
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.0) * 1.5
		material.metallic = 1.0
		material.roughness = 0.1
		point.material_override = material

		var angle = (PI * 2 / 5) * i
		point.position = Vector3(cos(angle) * 0.3, 0, sin(angle) * 0.3)
		point.look_at(global_position, Vector3.UP)
		point.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))

		star_container.add_child(point)

	mesh_instance = star_container

func _update_active_effect(delta: float) -> void:
	super._update_active_effect(delta)

	# 闪烁警告（最后2秒）
	if is_active and time_remaining < 2.0:
		flash_timer += delta
		if flash_timer >= flash_interval:
			flash_timer = 0.0
			_flash_player_warning()

func _apply_effect(player: Node) -> void:
	if not player:
		return

	# 设置无敌标记
	if player.has_method("set_invincible"):
		player.set_invincible(true)
	else:
		player.set_meta("invincible", true)

	# 视觉反馈
	_apply_visual_feedback(player)

	# 禁用受击碰撞层（如果有）
	if player is CharacterBody3D:
		player.set_collision_mask_value(16, false)  # 障碍层

	print("[Invincibility] Applied - Player is now invincible!")

func _remove_effect(player: Node) -> void:
	if not player:
		return

	# 移除无敌标记
	if player.has_method("set_invincible"):
		player.set_invincible(false)
	else:
		player.remove_meta("invincible")

	# 移除视觉反馈
	_remove_visual_feedback(player)

	# 恢复受击碰撞层
	if player is CharacterBody3D:
		player.set_collision_mask_value(16, true)

	print("[Invincibility] Removed - Player is vulnerable again")

func _apply_visual_feedback(player: Node) -> void:
	# 添加金色光环
	if player.has_node("InvincibilityAura"):
		return

	var aura = MeshInstance3D.new()
	aura.name = "InvincibilityAura"

	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.8
	mesh.outer_radius = 1.0
	aura.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.8, 0.0) * 2.0
	material.emission_energy_multiplier = 3.0
	aura.material_override = material

	aura.position = Vector3(0, 0.5, 0)
	player.add_child(aura)

	# 添加旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(aura, "rotation:y", TAU, 2.0)

func _remove_visual_feedback(player: Node) -> void:
	if player.has_node("InvincibilityAura"):
		var aura = player.get_node("InvincibilityAura")

		# 淡出动画
		var tween = create_tween()
		tween.tween_property(aura, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(aura.queue_free)

func _flash_player_warning() -> void:
	if not current_holder:
		return

	if current_holder.has_node("InvincibilityAura"):
		var aura = current_holder.get_node("InvincibilityAura")
		var material = aura.material_override as StandardMaterial3D

		if material:
			# 切换可见性
			aura.visible = not aura.visible
