extends "res://scripts/objects/obstacle_base.gd"
class_name SpikeObstacle
## 尖刺障碍物
## 造成伤害的尖刺陷阱

func _ready() -> void:
	obstacle_type = "spike"
	damage = 15
	damage_cooldown = 1.0

	# 创建尖刺视觉（灰色尖锥）
	_create_spike_visual()

	# 配置碰撞
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 0.5, 1.0)
	collision.shape = shape
	collision.position.y = 0.25
	add_child(collision)

	super._ready()

func _create_spike_visual() -> void:
	## 创建尖刺视觉
	# 基座
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.0, 0.2, 1.0)
	base.mesh = base_mesh

	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.3, 0.3, 0.3)  # 深灰色
	base.material_override = base_material
	base.position.y = 0.1
	add_child(base)

	# 尖刺（4个小锥体）
	var spike_positions = [
		Vector3(-0.3, 0.2, -0.3),
		Vector3(0.3, 0.2, -0.3),
		Vector3(-0.3, 0.2, 0.3),
		Vector3(0.3, 0.2, 0.3)
	]

	for pos in spike_positions:
		var spike = MeshInstance3D.new()
		var spike_mesh = BoxMesh.new()  # 使用Box暂时代替
		spike_mesh.size = Vector3(0.2, 0.4, 0.2)
		spike.mesh = spike_mesh

		var spike_material = StandardMaterial3D.new()
		spike_material.albedo_color = Color(0.5, 0.5, 0.5)  # 灰色
		spike.material_override = spike_material
		spike.position = pos
		add_child(spike)

	print("[SpikeObstacle] Visual created")
