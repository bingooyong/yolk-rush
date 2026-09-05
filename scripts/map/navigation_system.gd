extends Node
class_name NavigationSystem
## 导航系统 - 管理寻路和导航网格

signal navigation_ready()
signal path_calculated(path: PackedVector3Array)

## NavigationRegion3D 引用
var navigation_region: NavigationRegion3D = null

## 导航网格
var navigation_mesh: NavigationMesh = null

## 是否已初始化
var is_initialized: bool = false

## 寻路参数
var default_navigation_layers: int = 1
var path_postprocessing: bool = true  # 路径平滑

func _ready() -> void:
	print("[NavigationSystem] Initialized")

## 创建导航区域
func setup_navigation_region(parent: Node) -> void:
	if navigation_region:
		print("[NavigationSystem] Navigation region already exists")
		return

	# 创建 NavigationRegion3D
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion"
	parent.add_child(navigation_region)

	# 创建 NavigationMesh
	navigation_mesh = NavigationMesh.new()
	_configure_navigation_mesh()

	navigation_region.navigation_mesh = navigation_mesh

	is_initialized = true
	print("[NavigationSystem] Navigation region created")

## 配置导航网格参数
func _configure_navigation_mesh() -> void:
	if not navigation_mesh:
		return

	# 设置导航网格参数
	navigation_mesh.cell_size = 0.5  # 单元格大小
	navigation_mesh.cell_height = 0.2  # 单元格高度
	navigation_mesh.agent_height = 2.0  # 代理高度
	navigation_mesh.agent_radius = 0.5  # 代理半径
	navigation_mesh.agent_max_climb = 0.9  # 最大爬升高度
	navigation_mesh.agent_max_slope = 45.0  # 最大坡度

	# 区域设置
	navigation_mesh.region_min_size = 8.0  # 最小区域大小
	navigation_mesh.region_merge_size = 20.0  # 区域合并大小

	# 边缘设置
	navigation_mesh.edge_max_length = 12.0  # 最大边缘长度
	navigation_mesh.edge_max_error = 1.3  # 边缘最大误差

	print("[NavigationSystem] Navigation mesh configured")

## 从地图数据生成导航网格
func generate_from_map_data(map_data) -> void:
	if not navigation_region:
		push_error("[NavigationSystem] Navigation region not created")
		return

	print("[NavigationSystem] Generating navigation mesh from map data...")

	# 创建源几何体
	var source_geometry = NavigationMeshSourceGeometryData3D.new()

	# 从地图碰撞区域生成几何体
	_add_collision_geometry(source_geometry, map_data)

	# 烘焙导航网格
	NavigationServer3D.bake_from_source_geometry_data(
		navigation_mesh,
		source_geometry
	)

	navigation_region.bake_navigation_mesh()

	print("[NavigationSystem] Navigation mesh generated")
	navigation_ready.emit()

## 添加碰撞几何体到源数据
func _add_collision_geometry(source_geometry: NavigationMeshSourceGeometryData3D, map_data) -> void:
	# 为每个碰撞区域创建立方体几何体
	for collision in map_data.collision_areas:
		var position = collision["position"]
		var size = collision["size"]

		# 创建立方体的顶点
		var vertices = PackedVector3Array([
			position + Vector3(-size.x/2, -size.y/2, -size.z/2),
			position + Vector3(size.x/2, -size.y/2, -size.z/2),
			position + Vector3(size.x/2, -size.y/2, size.z/2),
			position + Vector3(-size.x/2, -size.y/2, size.z/2),
			position + Vector3(-size.x/2, size.y/2, -size.z/2),
			position + Vector3(size.x/2, size.y/2, -size.z/2),
			position + Vector3(size.x/2, size.y/2, size.z/2),
			position + Vector3(-size.x/2, size.y/2, size.z/2),
		])

		# 立方体的索引（三角形）
		var indices = PackedInt32Array([
			0, 1, 2, 0, 2, 3,  # 底面
			4, 6, 5, 4, 7, 6,  # 顶面
			0, 4, 5, 0, 5, 1,  # 前面
			2, 6, 7, 2, 7, 3,  # 后面
			0, 3, 7, 0, 7, 4,  # 左面
			1, 5, 6, 1, 6, 2   # 右面
		])

		source_geometry.add_faces(vertices, indices)

## 计算路径
func calculate_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not is_initialized or not navigation_region:
		push_warning("[NavigationSystem] Navigation not initialized")
		return PackedVector3Array()

	# 使用 NavigationServer3D 计算路径
	var map_rid = navigation_region.get_navigation_map()
	var path = NavigationServer3D.map_get_path(map_rid, from, to, true)

	if path_postprocessing and path.size() > 2:
		path = _smooth_path(path)

	path_calculated.emit(path)
	return path

## 路径平滑
func _smooth_path(path: PackedVector3Array) -> PackedVector3Array:
	if path.size() < 3:
		return path

	var smoothed = PackedVector3Array()
	smoothed.append(path[0])

	# 简单的路径平滑：移除冗余点
	for i in range(1, path.size() - 1):
		var prev = smoothed[smoothed.size() - 1]
		var current = path[i]
		var next = path[i + 1]

		# 计算角度
		var dir1 = (current - prev).normalized()
		var dir2 = (next - current).normalized()
		var dot = dir1.dot(dir2)

		# 如果角度变化足够大，保留该点
		if dot < 0.95:  # 约18度
			smoothed.append(current)

	smoothed.append(path[path.size() - 1])
	return smoothed

## 检查点是否在导航网格上
func is_point_on_navmesh(point: Vector3) -> bool:
	if not is_initialized or not navigation_region:
		return false

	var map_rid = navigation_region.get_navigation_map()
	var closest = NavigationServer3D.map_get_closest_point(map_rid, point)

	# 如果最近点距离太远，认为不在导航网格上
	return closest.distance_to(point) < 2.0

## 获取最近的导航网格点
func get_closest_point_on_navmesh(point: Vector3) -> Vector3:
	if not is_initialized or not navigation_region:
		return point

	var map_rid = navigation_region.get_navigation_map()
	return NavigationServer3D.map_get_closest_point(map_rid, point)

## 添加动态障碍物
func add_navigation_obstacle(position: Vector3, radius: float) -> RID:
	if not is_initialized:
		return RID()

	var obstacle = NavigationServer3D.obstacle_create()
	NavigationServer3D.obstacle_set_map(obstacle, navigation_region.get_navigation_map())
	NavigationServer3D.obstacle_set_position(obstacle, position)
	NavigationServer3D.obstacle_set_radius(obstacle, radius)

	return obstacle

## 移除动态障碍物
func remove_navigation_obstacle(obstacle_rid: RID) -> void:
	if obstacle_rid.is_valid():
		NavigationServer3D.free_rid(obstacle_rid)

## 重新烘焙导航网格
func rebake_navigation_mesh() -> void:
	if navigation_region and navigation_mesh:
		navigation_region.bake_navigation_mesh()
		print("[NavigationSystem] Navigation mesh rebaked")

## 获取导航统计
func get_navigation_stats() -> Dictionary:
	if not navigation_mesh:
		return {}

	return {
		"is_initialized": is_initialized,
		"cell_size": navigation_mesh.cell_size,
		"agent_radius": navigation_mesh.agent_radius,
		"agent_height": navigation_mesh.agent_height
	}

## 可视化路径（调试用）
func visualize_path(path: PackedVector3Array, parent: Node3D) -> void:
	if path.size() < 2:
		return

	var line = MeshInstance3D.new()
	line.name = "PathVisualization"

	var immediate_mesh = ImmediateMesh.new()
	line.mesh = immediate_mesh

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for point in path:
		immediate_mesh.surface_add_vertex(point + Vector3(0, 0.1, 0))  # 稍微抬高避免Z-fighting

	immediate_mesh.surface_end()

	# 材质
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.0, 1.0)  # 紫色路径
	line.material_override = material

	parent.add_child(line)

	# 5秒后自动删除
	await parent.get_tree().create_timer(5.0).timeout
	if is_instance_valid(line):
		line.queue_free()
