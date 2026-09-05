extends PowerUpBase
class_name ShieldPowerUp
## 护盾道具 - 吸收一定次数的伤害

@export var shield_hits: int = 3  # 可吸收的伤害次数

var remaining_hits: int = 0

func _initialize_power_up() -> void:
	power_up_name = "Shield"
	power_up_type = PowerUpType.SHIELD
	rarity = PowerUpRarity.UNCOMMON
	duration = 15.0  # 护盾持续较长时间，但有次数限制
	effect_value = shield_hits
	can_stack = false

	_customize_visual()

func _customize_visual() -> void:
	# 八面体形状
	if mesh_instance:
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh_instance.mesh = mesh

		# 蓝色半透明
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.5, 1.0, 0.8)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0.2, 0.5, 1.0) * 0.7
		material.metallic = 0.5
		material.roughness = 0.3
		mesh_instance.material_override = material

func _apply_effect(player: Node) -> void:
	if not player:
		return

	remaining_hits = shield_hits

	# 设置护盾状态
	if player.has_method("add_shield"):
		player.add_shield(self)
	else:
		player.set_meta("shield", self)

	# 连接伤害信号
	if player.has_signal("damage_taken"):
		if not player.damage_taken.is_connected(_on_player_damaged):
			player.damage_taken.connect(_on_player_damaged)

	# 视觉反馈
	_apply_visual_feedback(player)

	print("[Shield] Applied with %d hits" % remaining_hits)

func _remove_effect(player: Node) -> void:
	if not player:
		return

	# 移除护盾状态
	if player.has_method("remove_shield"):
		player.remove_shield()
	else:
		player.remove_meta("shield")

	# 断开信号
	if player.has_signal("damage_taken"):
		if player.damage_taken.is_connected(_on_player_damaged):
			player.damage_taken.disconnect(_on_player_damaged)

	# 移除视觉反馈
	_remove_visual_feedback(player)

	print("[Shield] Removed")

func _on_player_damaged(damage: float, is_critical: bool) -> void:
	if remaining_hits <= 0:
		return

	# 吸收伤害
	remaining_hits -= 1
	print("[Shield] Absorbed hit! Remaining: %d" % remaining_hits)

	# 播放护盾被击中效果
	_play_hit_effect()

	# 更新护盾视觉
	_update_shield_visual()

	# 护盾耗尽
	if remaining_hits <= 0:
		print("[Shield] Depleted!")
		_deactivate()

func _play_hit_effect() -> void:
	if not current_holder or not current_holder.has_node("ShieldBubble"):
		return

	var shield = current_holder.get_node("ShieldBubble")

	# 闪烁效果
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shield, "scale", Vector3.ONE * 1.2, 0.1)
	tween.tween_property(shield, "scale", Vector3.ONE, 0.2).set_delay(0.1)

	var material = shield.material_override as StandardMaterial3D
	if material:
		tween.tween_property(material, "emission_energy_multiplier", 3.0, 0.1)
		tween.tween_property(material, "emission_energy_multiplier", 1.0, 0.2).set_delay(0.1)

func _update_shield_visual() -> void:
	if not current_holder or not current_holder.has_node("ShieldBubble"):
		return

	var shield = current_holder.get_node("ShieldBubble")
	var material = shield.material_override as StandardMaterial3D

	if material:
		# 根据剩余次数调整透明度
		var alpha = 0.3 + (remaining_hits / float(shield_hits)) * 0.5
		var color = material.albedo_color
		material.albedo_color = Color(color.r, color.g, color.b, alpha)

func _apply_visual_feedback(player: Node) -> void:
	# 添加护盾气泡
	if player.has_node("ShieldBubble"):
		return

	var shield = MeshInstance3D.new()
	shield.name = "ShieldBubble"

	var mesh = SphereMesh.new()
	mesh.radius = 1.2
	mesh.height = 2.4
	shield.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 1.0, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.2, 0.5, 1.0)
	material.emission_energy_multiplier = 1.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # 双面渲染
	shield.material_override = material

	player.add_child(shield)

	# 护盾呼吸动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(shield, "scale", Vector3.ONE * 1.05, 1.0)
	tween.tween_property(shield, "scale", Vector3.ONE, 1.0)

func _remove_visual_feedback(player: Node) -> void:
	if player.has_node("ShieldBubble"):
		var shield = player.get_node("ShieldBubble")

		# 破碎效果
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(shield, "scale", Vector3.ONE * 1.5, 0.3)
		tween.tween_property(shield, "modulate:a", 0.0, 0.3)
		tween.tween_callback(shield.queue_free)

## 获取剩余次数
func get_remaining_hits() -> int:
	return remaining_hits

## 设置护盾次数
func set_shield_hits(hits: int) -> void:
	shield_hits = hits
	remaining_hits = hits
	effect_value = hits
