extends PowerUpBase
class_name MagnetPowerUp
## 磁铁道具 - 自动吸引附近的道具

@export var magnet_range: float = 10.0  # 吸引范围
@export var magnet_force: float = 15.0  # 吸引力度

var detection_area: Area3D
var attracted_items: Array = []

func _initialize_power_up() -> void:
	power_up_name = "Magnet"
	power_up_type = PowerUpType.MAGNET
	rarity = PowerUpRarity.COMMON
	duration = 8.0
	effect_value = magnet_range
	can_stack = false

	_customize_visual()

func _customize_visual() -> void:
	# U形磁铁
	if mesh_instance:
		mesh_instance.queue_free()

	_create_magnet_shape()

func _create_magnet_shape() -> void:
	var magnet_container = Node3D.new()
	magnet_container.name = "MagnetMesh"
	add_child(magnet_container)

	# 创建U形（三个柱体组合）
	# 左臂
	var left_arm = _create_magnet_part(Vector3(-0.25, 0, 0), Color(0.9, 0.2, 0.2))
	magnet_container.add_child(left_arm)

	# 右臂
	var right_arm = _create_magnet_part(Vector3(0.25, 0, 0), Color(0.2, 0.2, 0.9))
	magnet_container.add_child(right_arm)

	# 底部
	var bottom = MeshInstance3D.new()
	var bottom_mesh = BoxMesh.new()
	bottom_mesh.size = Vector3(0.6, 0.1, 0.2)
	bottom.mesh = bottom_mesh

	var bottom_material = StandardMaterial3D.new()
	bottom_material.albedo_color = Color(0.6, 0.6, 0.6)
	bottom_material.metallic = 1.0
	bottom_material.roughness = 0.2
	bottom.material_override = bottom_material
	bottom.position = Vector3(0, -0.3, 0)

	magnet_container.add_child(bottom)

	mesh_instance = magnet_container

func _create_magnet_part(pos: Vector3, color: Color) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.15, 0.5, 0.2)
	part.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.metallic = 0.8
	material.roughness = 0.3
	part.material_override = material

	part.position = pos
	return part

func _apply_effect(player: Node) -> void:
	if not player:
		return

	# 创建检测区域
	_create_detection_area(player)

	# 视觉反馈
	_apply_visual_feedback(player)

	print("[Magnet] Applied with %.1fm range" % magnet_range)

func _remove_effect(player: Node) -> void:
	if not player:
		return

	# 移除检测区域
	if detection_area:
		detection_area.queue_free()
		detection_area = null

	attracted_items.clear()

	# 移除视觉反馈
	_remove_visual_feedback(player)

	print("[Magnet] Removed")

func _create_detection_area(player: Node) -> void:
	detection_area = Area3D.new()
	detection_area.name = "MagnetArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 16  # 道具层

	var shape = SphereShape3D.new()
	shape.radius = magnet_range

	var collision = CollisionShape3D.new()
	collision.shape = shape
	detection_area.add_child(collision)

	player.add_child(detection_area)

	# 连接信号
	detection_area.body_entered.connect(_on_item_entered)
	detection_area.body_exited.connect(_on_item_exited)

func _on_item_entered(body: Node3D) -> void:
	# 检查是否为道具
	if body is PowerUpBase and body != self:
		if body not in attracted_items:
			attracted_items.append(body)
			print("[Magnet] Attracting: %s" % body.power_up_name)

func _on_item_exited(body: Node3D) -> void:
	if body in attracted_items:
		attracted_items.erase(body)

func _update_active_effect(delta: float) -> void:
	super._update_active_effect(delta)

	# 吸引道具
	_attract_items(delta)

func _attract_items(delta: float) -> void:
	if not current_holder:
		return

	for item in attracted_items:
		if not is_instance_valid(item):
			continue

		if item.is_collected:
			continue

		# 计算方向
		var direction = current_holder.global_position - item.global_position
		var distance = direction.length()

		if distance < 0.5:
			# 足够近，直接收集
			item._collect(current_holder)
			continue

		# 施加吸引力
		direction = direction.normalized()
		var force = magnet_force * delta

		# 距离越近，吸引力越强
		var distance_factor = 1.0 - (distance / magnet_range)
		force *= (1.0 + distance_factor * 2.0)

		item.global_position += direction * force

func _apply_visual_feedback(player: Node) -> void:
	# 添加磁场圆环
	if player.has_node("MagnetField"):
		return

	var field = MeshInstance3D.new()
	field.name = "MagnetField"

	var mesh = TorusMesh.new()
	mesh.inner_radius = magnet_range * 0.9
	mesh.outer_radius = magnet_range * 1.0
	field.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.2, 0.9, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.5, 0.2, 0.9)
	material.emission_energy_multiplier = 2.0
	field.material_override = material

	field.position = Vector3(0, 0.1, 0)
	player.add_child(field)

	# 旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(field, "rotation:y", TAU, 3.0)

	# 脉冲动画
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(field, "scale", Vector3.ONE * 1.1, 0.8)
	pulse_tween.tween_property(field, "scale", Vector3.ONE, 0.8)

func _remove_visual_feedback(player: Node) -> void:
	if player.has_node("MagnetField"):
		var field = player.get_node("MagnetField")

		# 收缩消失
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(field, "scale", Vector3.ZERO, 0.5)
		tween.tween_property(field, "modulate:a", 0.0, 0.5)
		tween.tween_callback(field.queue_free)

## 设置吸引范围
func set_magnet_range(range: float) -> void:
	magnet_range = range
	effect_value = range

	# 更新检测区域
	if detection_area and detection_area.get_child_count() > 0:
		var collision = detection_area.get_child(0) as CollisionShape3D
		if collision:
			var shape = collision.shape as SphereShape3D
			if shape:
				shape.radius = range

## 获取当前吸引的道具数量
func get_attracted_count() -> int:
	return attracted_items.size()
