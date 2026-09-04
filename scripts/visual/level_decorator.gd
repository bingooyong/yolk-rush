extends Node3D
class_name LevelDecorator
## 场景装饰生成器
## Phase 4.5: 为雪岛添加视觉装饰元素

## 生成雪堆
static func spawn_snow_piles(parent: Node3D, count: int, area_size: Vector2) -> void:
	for i in range(count):
		var pile := _create_snow_pile()
		pile.position = Vector3(
			randf_range(-area_size.x / 2, area_size.x / 2),
			0,
			randf_range(-area_size.y / 2, area_size.y / 2)
		)
		pile.rotation_degrees.y = randf_range(0, 360)
		pile.scale = Vector3.ONE * randf_range(0.8, 1.5)
		parent.add_child(pile)

## 创建单个雪堆
static func _create_snow_pile() -> MeshInstance3D:
	var pile := MeshInstance3D.new()
	pile.name = "SnowPile"

	# 使用球体稍微压扁模拟雪堆
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 0.6  # 压扁
	pile.mesh = sphere

	# 白色雪材质
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 1.0)  # 淡蓝白
	mat.metallic = 0.0
	mat.roughness = 0.9
	pile.material_override = mat

	return pile

## 生成岩石
static func spawn_rocks(parent: Node3D, count: int, area_size: Vector2) -> void:
	for i in range(count):
		var rock := _create_rock()
		rock.position = Vector3(
			randf_range(-area_size.x / 2, area_size.x / 2),
			0,
			randf_range(-area_size.y / 2, area_size.y / 2)
		)
		rock.rotation_degrees = Vector3(
			randf_range(-15, 15),
			randf_range(0, 360),
			randf_range(-15, 15)
		)
		rock.scale = Vector3.ONE * randf_range(0.6, 1.2)
		parent.add_child(rock)

## 创建单个岩石
static func _create_rock() -> MeshInstance3D:
	var rock := MeshInstance3D.new()
	rock.name = "Rock"

	# 使用不规则的方块模拟岩石
	var box := BoxMesh.new()
	box.size = Vector3(
		randf_range(0.4, 0.8),
		randf_range(0.5, 1.0),
		randf_range(0.4, 0.8)
	)
	rock.mesh = box

	# 深灰色岩石材质
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)  # 深灰带蓝
	mat.metallic = 0.0
	mat.roughness = 1.0
	rock.material_override = mat

	return rock

## 生成简化树木
static func spawn_trees(parent: Node3D, count: int, area_size: Vector2) -> void:
	for i in range(count):
		var tree := _create_simple_tree()
		tree.position = Vector3(
			randf_range(-area_size.x / 2, area_size.x / 2),
			0,
			randf_range(-area_size.y / 2, area_size.y / 2)
		)
		tree.rotation_degrees.y = randf_range(0, 360)
		tree.scale = Vector3.ONE * randf_range(0.8, 1.3)
		parent.add_child(tree)

## 创建简单树木（圆锥体）
static func _create_simple_tree() -> Node3D:
	var tree_root := Node3D.new()
	tree_root.name = "Tree"

	# 树干（圆柱）
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.1
	trunk_mesh.bottom_radius = 0.15
	trunk_mesh.height = 1.0
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0, 0.5, 0)

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.3, 0.2, 0.15)  # 棕色
	trunk_mat.roughness = 1.0
	trunk.material_override = trunk_mat

	tree_root.add_child(trunk)

	# 树冠（圆锥）
	var crown := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.8
	cone.height = 1.5
	crown.mesh = cone
	crown.position = Vector3(0, 1.5, 0)

	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.1, 0.3, 0.15)  # 深绿
	crown_mat.roughness = 0.9
	crown.material_override = crown_mat

	tree_root.add_child(crown)

	return tree_root

## 生成冰柱（边缘装饰）
static func spawn_icicles(parent: Node3D, positions: Array[Vector3]) -> void:
	for pos in positions:
		var icicle := _create_icicle()
		icicle.position = pos
		icicle.rotation_degrees = Vector3(randf_range(-5, 5), randf_range(0, 360), 0)
		parent.add_child(icicle)

## 创建单个冰柱
static func _create_icicle() -> MeshInstance3D:
	var icicle := MeshInstance3D.new()
	icicle.name = "Icicle"

	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.15
	cone.height = 1.0
	icicle.mesh = cone

	# 半透明冰蓝色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.9, 1.0, 0.8)  # 带透明度
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.5
	mat.roughness = 0.2
	icicle.material_override = mat

	return icicle

## 创建主光源（太阳光）
static func create_sun_light() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"

	# 淡蓝白光（雪地氛围）
	sun.light_color = Color(0.9, 0.95, 1.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0

	# 45度斜照
	sun.rotation_degrees = Vector3(-45, -30, 0)

	return sun

## 创建环境光
static func create_environment() -> WorldEnvironment:
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var env := Environment.new()

	# 简单天空渐变
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.5, 0.7, 1.0)  # 蓝色
	sky_mat.sky_horizon_color = Color(0.8, 0.9, 1.0)  # 浅蓝
	sky_mat.ground_bottom_color = Color(0.9, 0.9, 0.95)  # 接近白
	sky_mat.ground_horizon_color = Color(0.85, 0.9, 0.95)
	sky.sky_material = sky_mat

	env.sky = sky
	env.background_mode = Environment.BG_SKY

	# 环境光
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5

	# 距离雾（增强深度感）
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.9, 0.95)
	env.fog_light_energy = 0.5
	env.fog_density = 0.001
	env.fog_sky_affect = 0.3

	world_env.environment = env

	return world_env

## 创建地面平面
static func create_ground_plane(size: Vector2) -> StaticBody3D:
	var ground := StaticBody3D.new()
	ground.name = "Ground"

	# 地面碰撞
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size.x, 0.1, size.y)
	collision.shape = box_shape
	collision.position = Vector3(0, -0.05, 0)
	ground.add_child(collision)

	# 地面视觉
	var mesh_instance := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(size.x, 0.1, size.y)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0, -0.05, 0)

	# 雪地材质
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 1.0)
	mat.metallic = 0.0
	mat.roughness = 0.9
	mesh_instance.material_override = mat

	ground.add_child(mesh_instance)

	return ground
