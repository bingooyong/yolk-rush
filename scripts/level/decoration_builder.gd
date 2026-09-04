extends Node3D
class_name DecorationBuilder
## 场景装饰构建器
## Phase 4.5: 为关卡添加视觉装饰物

## 装饰类型
enum DecorationType {
	TREE,
	ROCK,
	SNOW_PILE,
	ICE_CRYSTAL,
	GRASS,
}

## 添加装饰物到关卡
static func add_decorations(level_data: Dictionary, parent: Node3D) -> void:
	var decorations := level_data.get("decorations", [])

	for deco in decorations:
		_spawn_decoration(deco, parent)

	# 如果没有装饰数据，生成默认装饰
	if decorations.is_empty():
		_generate_default_decorations(parent)

## 生成装饰物
static func _spawn_decoration(deco_data: Dictionary, parent: Node3D) -> void:
	var type: DecorationType = deco_data.get("type", DecorationType.ROCK)
	var pos := Vector3(
		deco_data.get("x", 0.0),
		deco_data.get("y", 0.0),
		deco_data.get("z", 0.0)
	)
	var scale := deco_data.get("scale", 1.0)

	match type:
		DecorationType.TREE:
			_create_tree(pos, scale, parent)
		DecorationType.ROCK:
			_create_rock(pos, scale, parent)
		DecorationType.SNOW_PILE:
			_create_snow_pile(pos, scale, parent)
		DecorationType.ICE_CRYSTAL:
			_create_ice_crystal(pos, scale, parent)
		DecorationType.GRASS:
			_create_grass(pos, scale, parent)

## 生成默认装饰（雪岛主题）
static func _generate_default_decorations(parent: Node3D) -> void:
	# 在关卡边缘随机放置装饰物
	for i in range(20):
		var angle := randf() * TAU
		var distance := randf_range(10.0, 30.0)
		var pos := Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)

		var rand := randf()
		if rand < 0.4:
			_create_rock(pos, randf_range(0.5, 2.0), parent)
		elif rand < 0.7:
			_create_snow_pile(pos, randf_range(0.8, 1.5), parent)
		else:
			_create_ice_crystal(pos, randf_range(0.5, 1.2), parent)

## 创建树
static func _create_tree(pos: Vector3, scale_value: float, parent: Node3D) -> void:
	var tree := Node3D.new()
	tree.name = "Tree"
	tree.position = pos

	# 树干
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.2 * scale_value
	trunk_mesh.bottom_radius = 0.3 * scale_value
	trunk_mesh.height = 3.0 * scale_value
	trunk.mesh = trunk_mesh

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.3, 0.2)
	trunk.material_override = trunk_mat
	trunk.position.y = 1.5 * scale_value

	tree.add_child(trunk)

	# 树冠（三层锥形）
	for i in range(3):
		var foliage := MeshInstance3D.new()
		var cone := ConeMesh.new()
		cone.radius = (1.5 - i * 0.3) * scale_value
		cone.height = 2.0 * scale_value
		foliage.mesh = cone

		var foliage_mat := StandardMaterial3D.new()
		foliage_mat.albedo_color = Color(0.1, 0.4, 0.2)
		foliage.material_override = foliage_mat
		foliage.position.y = (3.0 + i * 1.5) * scale_value

		tree.add_child(foliage)

	parent.add_child(tree)

## 创建岩石
static func _create_rock(pos: Vector3, scale_value: float, parent: Node3D) -> void:
	var rock := MeshInstance3D.new()
	rock.name = "Rock"
	rock.position = pos

	var mesh := SphereMesh.new()
	mesh.radius = 0.8 * scale_value
	mesh.height = 1.2 * scale_value
	rock.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.55)
	mat.roughness = 0.9
	rock.material_override = mat

	# 随机旋转
	rock.rotation = Vector3(
		randf_range(-0.2, 0.2),
		randf() * TAU,
		randf_range(-0.2, 0.2)
	)

	parent.add_child(rock)

## 创建雪堆
static func _create_snow_pile(pos: Vector3, scale_value: float, parent: Node3D) -> void:
	var pile := MeshInstance3D.new()
	pile.name = "SnowPile"
	pile.position = pos

	var mesh := SphereMesh.new()
	mesh.radius = 1.0 * scale_value
	mesh.height = 0.6 * scale_value
	pile.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 1.0)
	mat.roughness = 0.8
	pile.material_override = mat

	pile.scale.y = 0.4

	parent.add_child(pile)

## 创建冰晶
static func _create_ice_crystal(pos: Vector3, scale_value: float, parent: Node3D) -> void:
	var crystal := MeshInstance3D.new()
	crystal.name = "IceCrystal"
	crystal.position = pos

	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.3, 1.5, 0.3) * scale_value
	crystal.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.9, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0) * 0.3
	mat.roughness = 0.1
	mat.metallic = 0.8
	crystal.material_override = mat

	# 随机旋转
	crystal.rotation.y = randf() * TAU
	crystal.rotation.x = randf_range(-0.1, 0.1)

	parent.add_child(crystal)

## 创建草丛
static func _create_grass(pos: Vector3, scale_value: float, parent: Node3D) -> void:
	var grass := MeshInstance3D.new()
	grass.name = "Grass"
	grass.position = pos

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.6, 0.1) * scale_value
	grass.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 0.3, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = mat

	# 十字交叉的草片
	var grass2 := grass.duplicate()
	grass2.rotation.y = PI / 2
	grass.add_child(grass2)

	parent.add_child(grass)
