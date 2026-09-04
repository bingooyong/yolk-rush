extends Node3D
## Visual Character: 程序化角色视觉（CSG 几何体）

var body: CSGCylinder3D
var head: CSGSphere3D
var eyes: Array[CSGSphere3D] = []

func _ready() -> void:
	_create_character_mesh()

func _create_character_mesh() -> void:
	# 身体 - 蓝色圆柱
	body = CSGCylinder3D.new()
	body.name = "Body"
	body.radius = 0.34
	body.height = 1.0
	body.sides = 12
	body.material = _create_material(Color(0.2, 0.5, 1.0))
	add_child(body)

	# 头部 - 浅蓝色球体
	head = CSGSphere3D.new()
	head.name = "Head"
	head.radius = 0.3
	head.radial_segments = 12
	head.rings = 8
	head.material = _create_material(Color(0.4, 0.7, 1.0))
	head.position = Vector3(0, 0.65, 0)
	add_child(head)

	# 眼睛 - 白色发光
	for i in 2:
		var eye := CSGSphere3D.new()
		eye.name = "Eye%d" % i
		eye.radius = 0.06
		eye.radial_segments = 8
		eye.rings = 6
		var eye_mat := _create_material(Color.WHITE)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(0.8, 0.9, 1.0)
		eye_mat.emission_energy_multiplier = 1.5
		eye.material = eye_mat
		eye.position = Vector3(-0.12 + i * 0.24, 0.70, -0.28)
		add_child(eye)
		eyes.append(eye)

	# 装饰：肩膀护甲
	for i in 2:
		var shoulder := CSGBox3D.new()
		shoulder.name = "Shoulder%d" % i
		shoulder.size = Vector3(0.15, 0.2, 0.15)
		shoulder.material = _create_material(Color(0.3, 0.6, 0.9))
		shoulder.position = Vector3(-0.45 + i * 0.9, 0.4, 0)
		add_child(shoulder)

func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.7
	return mat

## 播放攻击动画
func play_attack() -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	# 身体前倾
	tween.tween_property(body, "rotation:x", deg_to_rad(15), 0.1)
	tween.tween_property(body, "rotation:x", 0.0, 0.1).set_delay(0.1)

	# 头部点头
	tween.tween_property(head, "position:z", -0.2, 0.1)
	tween.tween_property(head, "position:z", 0.0, 0.1).set_delay(0.1)

## 播放受击动画
func play_hit() -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	# 整体后退
	tween.tween_property(self, "position:z", position.z + 0.2, 0.1)
	tween.tween_property(self, "position:z", position.z, 0.1).set_delay(0.1)

	# 闪白效果
	_flash_white()

func _flash_white() -> void:
	for child in get_children():
		if child is CSGPrimitive3D:
			var original_mat := child.material as StandardMaterial3D
			if original_mat:
				var flash_mat := original_mat.duplicate()
				flash_mat.albedo_color = Color.WHITE
				child.material = flash_mat

				await get_tree().create_timer(0.08).timeout
				child.material = original_mat
