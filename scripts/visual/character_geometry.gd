extends Node3D
class_name CharacterGeometry
## 程序化角色几何体生成器
## Phase 4.5: 为游戏生成视觉上有辨识度的角色

## 创建蛋黄英雄（Yolk Hero）
static func create_yolk_hero() -> Node3D:
	var root := Node3D.new()
	root.name = "YolkHero"

	# 身体（椭球）
	var body := _create_body()
	root.add_child(body)

	# 头部（球体，稍微偏上）
	var head := _create_head()
	head.position = Vector3(0, 0.6, 0)
	root.add_child(head)

	# 左臂
	var left_arm := _create_arm()
	left_arm.position = Vector3(-0.35, 0.3, 0)
	left_arm.rotation_degrees = Vector3(0, 0, -20)
	root.add_child(left_arm)

	# 右臂
	var right_arm := _create_arm()
	right_arm.position = Vector3(0.35, 0.3, 0)
	right_arm.rotation_degrees = Vector3(0, 0, 20)
	root.add_child(right_arm)

	# 左腿
	var left_leg := _create_leg()
	left_leg.position = Vector3(-0.2, -0.3, 0)
	root.add_child(left_leg)

	# 右腿
	var right_leg := _create_leg()
	right_leg.position = Vector3(0.2, -0.3, 0)
	root.add_child(right_leg)

	# 围巾（可选装饰）
	var scarf := _create_scarf()
	scarf.position = Vector3(0, 0.5, 0)
	root.add_child(scarf)

	return root

## 创建身体（椭球）
static func _create_body() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Body"

	var sphere := SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.radius = 0.4
	sphere.height = 0.6  # 椭球（压扁）

	mesh_instance.mesh = sphere

	# 蛋黄色材质
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)  # #FFD700
	mat.metallic = 0.0
	mat.roughness = 0.6
	mesh_instance.material_override = mat

	return mesh_instance

## 创建头部（球体 + 眼睛）
static func _create_head() -> Node3D:
	var head_root := Node3D.new()
	head_root.name = "Head"

	# 头部球体
	var head_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	sphere.radial_segments = 16
	sphere.rings = 8
	head_mesh.mesh = sphere

	# 稍微浅一点的蛋黄色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.metallic = 0.0
	mat.roughness = 0.5
	head_mesh.material_override = mat

	head_root.add_child(head_mesh)

	# 左眼
	var left_eye := _create_eye()
	left_eye.position = Vector3(-0.12, 0.08, 0.25)
	head_root.add_child(left_eye)

	# 右眼
	var right_eye := _create_eye()
	right_eye.position = Vector3(0.12, 0.08, 0.25)
	head_root.add_child(right_eye)

	return head_root

## 创建眼睛（小黑球）
static func _create_eye() -> MeshInstance3D:
	var eye := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	eye.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mat.metallic = 1.0
	mat.roughness = 0.2
	eye.material_override = mat

	return eye

## 创建手臂（细胶囊）
static func _create_arm() -> MeshInstance3D:
	var arm := MeshInstance3D.new()
	arm.name = "Arm"

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.08
	capsule.height = 0.5
	arm.mesh = capsule

	# 稍微深一点的黄色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.75, 0.0)
	mat.metallic = 0.0
	mat.roughness = 0.7
	arm.material_override = mat

	return arm

## 创建腿（短粗胶囊）
static func _create_leg() -> MeshInstance3D:
	var leg := MeshInstance3D.new()
	leg.name = "Leg"

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.12
	capsule.height = 0.4
	leg.mesh = capsule

	# 和手臂相同颜色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.75, 0.0)
	mat.metallic = 0.0
	mat.roughness = 0.7
	leg.material_override = mat

	return leg

## 创建围巾（装饰）
static func _create_scarf() -> MeshInstance3D:
	var scarf := MeshInstance3D.new()
	scarf.name = "Scarf"

	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.08, 0.1)
	scarf.mesh = box

	# 红色围巾
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.27, 0.27)  # #FF4444
	mat.metallic = 0.0
	mat.roughness = 0.8
	scarf.material_override = mat

	return scarf

## ============================================
## 敌人角色生成
## ============================================

## 创建暗影刺客（Shadow Assassin）
static func create_shadow_assassin() -> Node3D:
	var root := Node3D.new()
	root.name = "ShadowAssassin"

	# 瘦长身体
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.25
	capsule.height = 1.4
	body.mesh = capsule

	# 深紫黑色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.0, 0.2)  # #1a0033
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.0, 0.5) * 0.3  # 微弱紫光
	mat.metallic = 0.3
	mat.roughness = 0.4
	body.material_override = mat

	root.add_child(body)

	# 尖刺发型（顶部锥体）
	var spike := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.2
	cone.height = 0.4
	spike.mesh = cone
	spike.position = Vector3(0, 0.9, 0)
	spike.material_override = mat  # 同样材质
	root.add_child(spike)

	# 红眼发光
	var left_eye := _create_glowing_eye(Color.RED)
	left_eye.position = Vector3(-0.1, 0.5, 0.2)
	root.add_child(left_eye)

	var right_eye := _create_glowing_eye(Color.RED)
	right_eye.position = Vector3(0.1, 0.5, 0.2)
	root.add_child(right_eye)

	return root

## 创建冰霜射手（Frost Archer）
static func create_frost_archer() -> Node3D:
	var root := Node3D.new()
	root.name = "FrostArcher"

	# 中等身材
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule

	# 冰蓝色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 1.0)  # #00ffff
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.8, 1.0) * 0.2  # 冰蓝光
	mat.metallic = 0.5
	mat.roughness = 0.3
	body.material_override = mat

	root.add_child(body)

	# 弓（简化 - L形）
	var bow := Node3D.new()
	bow.name = "Bow"
	bow.position = Vector3(0.4, 0.3, 0)

	var bow_mesh := MeshInstance3D.new()
	var bow_shape := BoxMesh.new()
	bow_shape.size = Vector3(0.1, 0.6, 0.05)
	bow_mesh.mesh = bow_shape
	bow_mesh.material_override = mat
	bow.add_child(bow_mesh)

	root.add_child(bow)

	# 冰晶装饰（小方块）
	for i in range(3):
		var crystal := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 0.08)
		crystal.mesh = box
		crystal.material_override = mat
		crystal.position = Vector3(randf_range(-0.2, 0.2), 0.3 + i * 0.2, 0.3)
		crystal.rotation_degrees = Vector3(45, 45, 45)
		root.add_child(crystal)

	return root

## 创建岩石守卫（Rock Guardian）
static func create_rock_guardian() -> Node3D:
	var root := Node3D.new()
	root.name = "RockGuardian"

	# 矮胖身材（方块）
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 1.0, 0.6)
	body.mesh = box

	# 岩石灰
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)  # #666666
	mat.metallic = 0.0
	mat.roughness = 1.0  # 非常粗糙
	body.material_override = mat

	root.add_child(body)

	# 巨大盾牌
	var shield := MeshInstance3D.new()
	var shield_box := BoxMesh.new()
	shield_box.size = Vector3(0.8, 1.2, 0.1)
	shield.mesh = shield_box
	shield.position = Vector3(-0.5, 0, 0.3)

	# 稍微浅一点的灰色
	var shield_mat := StandardMaterial3D.new()
	shield_mat.albedo_color = Color(0.5, 0.5, 0.5)
	shield_mat.metallic = 0.7
	shield_mat.roughness = 0.4
	shield.material_override = shield_mat

	root.add_child(shield)

	# 方形头盔（小方块）
	var helmet := MeshInstance3D.new()
	var helmet_box := BoxMesh.new()
	helmet_box.size = Vector3(0.4, 0.3, 0.4)
	helmet.mesh = helmet_box
	helmet.position = Vector3(0, 0.65, 0)
	helmet.material_override = mat
	root.add_child(helmet)

	return root

## 发光眼睛（用于敌人）
static func _create_glowing_eye(color: Color) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.5
	light.omni_range = 1.0
	return light

## ============================================
## 工厂方法（统一接口）
## ============================================

## 根据类型创建敌人
static func create_enemy(enemy_type: String) -> Node3D:
	match enemy_type:
		"assassin", "melee_assassin":
			return create_shadow_assassin()
		"archer", "ranged_archer":
			return create_frost_archer()
		"guardian", "tank_guardian":
			return create_rock_guardian()
		_:
			push_error("[CharacterGeometry] Unknown enemy type: %s" % enemy_type)
			return create_shadow_assassin()  # 默认
