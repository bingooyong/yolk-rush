extends PowerUpBase
class_name SpeedBoostPowerUp
## 加速道具 - 提升玩家移动速度

@export var speed_multiplier: float = 1.5  # 速度倍率

var original_speed: float = 0.0

func _initialize_power_up() -> void:
	power_up_name = "Speed Boost"
	power_up_type = PowerUpType.SPEED_BOOST
	rarity = PowerUpRarity.COMMON
	duration = 5.0
	effect_value = speed_multiplier
	can_stack = true

	_customize_visual()

func _customize_visual() -> void:
	# 自定义为胶囊形状
	if mesh_instance:
		var mesh = CapsuleMesh.new()
		mesh.radius = 0.2
		mesh.height = 0.6
		mesh_instance.mesh = mesh

		# 黄色发光
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color(1.0, 0.9, 0.2)
			material.emission = Color(1.0, 0.9, 0.2) * 0.8

	# 添加速度线条效果
	_add_speed_lines()

func _add_speed_lines() -> void:
	# 创建简单的速度线条视觉效果
	var lines_container = Node3D.new()
	lines_container.name = "SpeedLines"
	add_child(lines_container)

	for i in range(4):
		var line = MeshInstance3D.new()
		var line_mesh = BoxMesh.new()
		line_mesh.size = Vector3(0.05, 0.3, 0.05)
		line.mesh = line_mesh

		var line_material = StandardMaterial3D.new()
		line_material.albedo_color = Color(1.0, 0.9, 0.2, 0.5)
		line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = line_material

		var angle = (PI * 2 / 4) * i
		line.position = Vector3(cos(angle) * 0.4, 0, sin(angle) * 0.4)
		lines_container.add_child(line)

func _apply_effect(player: Node) -> void:
	if not player:
		return

	# 保存原始速度
	if player.has_method("get_move_speed"):
		original_speed = player.get_move_speed()
	elif player.has_property("move_speed"):
		original_speed = player.move_speed
	else:
		original_speed = 5.0  # 默认值

	# 应用加速
	var new_speed = original_speed * speed_multiplier

	if player.has_method("set_move_speed"):
		player.set_move_speed(new_speed)
	elif player.has_property("move_speed"):
		player.move_speed = new_speed

	# 视觉反馈
	_apply_visual_feedback(player)

	print("[SpeedBoost] Applied %.1fx speed (%.1f -> %.1f)" %
		[speed_multiplier, original_speed, new_speed])

func _remove_effect(player: Node) -> void:
	if not player:
		return

	# 恢复原始速度
	if player.has_method("set_move_speed"):
		player.set_move_speed(original_speed)
	elif player.has_property("move_speed"):
		player.move_speed = original_speed

	# 移除视觉反馈
	_remove_visual_feedback(player)

	print("[SpeedBoost] Removed (speed restored to %.1f)" % original_speed)

func _apply_visual_feedback(player: Node) -> void:
	# 给玩家添加速度拖尾效果
	if player.has_node("SpeedTrail"):
		return

	var trail = MeshInstance3D.new()
	trail.name = "SpeedTrail"

	# 简单的拖尾效果
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.9, 0.2, 0.3)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.9, 0.2)

	player.add_child(trail)

func _remove_visual_feedback(player: Node) -> void:
	if player.has_node("SpeedTrail"):
		var trail = player.get_node("SpeedTrail")
		trail.queue_free()

## 设置速度倍率
func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier
	effect_value = multiplier
