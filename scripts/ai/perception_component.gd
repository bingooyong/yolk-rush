extends Node
class_name PerceptionComponent
## AI感知组件 - 处理视野、听觉和威胁检测

signal threat_detected(threat: Node)
signal threat_lost(threat: Node)

## 感知配置
@export_group("视野配置")
@export var sight_range: float = 15.0  # 视野范围（米）
@export var sight_angle: float = 120.0  # 视野角度（度）
@export var lost_sight_time: float = 3.0  # 失去视野后多久遗忘目标

@export_group("听觉配置")
@export var hearing_range: float = 8.0  # 听觉范围（米）

@export_group("检测配置")
@export var detection_layers: int = 1  # 检测层（物理层）
@export var check_line_of_sight: bool = true  # 是否检查视线遮挡

## 当前感知到的威胁
var detected_threats: Array = []  # Array[Node]
var threat_data: Dictionary = {}  # {Node: {last_seen: float, distance: float}}

## 父AI控制器
var ai_controller: Node = null

## 实体引用
var entity: Node = null

func _ready() -> void:
	ai_controller = get_parent()
	if ai_controller and ai_controller.has("controlled_entity"):
		entity = ai_controller.controlled_entity

	if not entity:
		entity = get_parent().get_parent()

	print("[PerceptionComponent] Initialized for: %s" % (entity.name if entity else "Unknown"))

## 更新感知（由 AIController 定期调用）
func update_perception() -> void:
	if not entity:
		return

	# 更新视野检测
	_update_sight_detection()

	# 更新听觉检测
	_update_hearing_detection()

	# 清理过期威胁
	_cleanup_old_threats()

## 视野检测
func _update_sight_detection() -> void:
	# 获取范围内的所有潜在目标
	var potential_targets = _get_potential_targets()

	for target in potential_targets:
		if not is_instance_valid(target):
			continue

		# 检查距离
		var distance = _get_distance_to(target)
		if distance > sight_range:
			continue

		# 检查角度
		if not _is_in_sight_angle(target):
			continue

		# 检查视线遮挡
		if check_line_of_sight and not _has_line_of_sight(target):
			continue

		# 检测到威胁
		_on_threat_detected(target, distance)

## 听觉检测
func _update_hearing_detection() -> void:
	# 听觉检测范围更小，但不受角度限制
	var potential_targets = _get_potential_targets()

	for target in potential_targets:
		if not is_instance_valid(target):
			continue

		var distance = _get_distance_to(target)
		if distance <= hearing_range:
			_on_threat_detected(target, distance)

## 获取潜在目标（子类可覆盖以优化）
func _get_potential_targets() -> Array:
	var targets: Array = []

	# 从场景树中查找玩家和敌对实体
	var root = entity.get_tree().root
	targets.append_array(_find_nodes_with_tag(root, "player"))
	targets.append_array(_find_nodes_with_tag(root, "enemy"))

	return targets

## 递归查找带标签的节点
func _find_nodes_with_tag(node: Node, tag: String) -> Array:
	var results: Array = []

	# 检查当前节点
	if node.has_method("has_tag") and node.has_tag(tag):
		results.append(node)
	elif node.is_in_group(tag):
		results.append(node)

	# 递归检查子节点
	for child in node.get_children():
		results.append_array(_find_nodes_with_tag(child, tag))

	return results

## 获取距离
func _get_distance_to(target: Node) -> float:
	if not entity or not target:
		return INF

	if entity is Node3D and target is Node3D:
		return entity.global_position.distance_to(target.global_position)
	elif entity is Node2D and target is Node2D:
		return entity.global_position.distance_to(target.global_position)

	return INF

## 检查是否在视野角度内
func _is_in_sight_angle(target: Node) -> bool:
	if not entity or not target:
		return false

	if entity is Node3D and target is Node3D:
		# 计算到目标的方向
		var to_target = (target.global_position - entity.global_position).normalized()
		var forward = -entity.global_transform.basis.z  # Godot 中 -Z 是前方

		# 计算角度
		var dot = forward.dot(to_target)
		var angle_cos = cos(deg_to_rad(sight_angle / 2.0))

		return dot >= angle_cos

	elif entity is Node2D and target is Node2D:
		# 2D版本
		var to_target = (target.global_position - entity.global_position).normalized()
		var forward = Vector2.from_angle(entity.global_rotation)

		var dot = forward.dot(to_target)
		var angle_cos = cos(deg_to_rad(sight_angle / 2.0))

		return dot >= angle_cos

	return false

## 检查视线遮挡（使用射线检测）
func _has_line_of_sight(target: Node) -> bool:
	if not entity or not target:
		return false

	var space_state = entity.get_world_3d().direct_space_state if entity is Node3D else entity.get_world_2d().direct_space_state
	if not space_state:
		return true  # 无法检测，假设有视线

	# 3D射线检测
	if entity is Node3D and target is Node3D:
		var query = PhysicsRayQueryParameters3D.create(
			entity.global_position + Vector3(0, 1, 0),  # 从眼睛位置
			target.global_position + Vector3(0, 1, 0)   # 到目标中心
		)
		query.collision_mask = detection_layers
		query.exclude = [entity]

		var result = space_state.intersect_ray(query)

		# 如果射线击中的就是目标，或者没有击中任何东西，则有视线
		return result.is_empty() or result.collider == target

	# 2D射线检测
	elif entity is Node2D and target is Node2D:
		var query = PhysicsRayQueryParameters2D.create(
			entity.global_position,
			target.global_position
		)
		query.collision_mask = detection_layers
		query.exclude = [entity]

		var result = space_state.intersect_ray(query)

		return result.is_empty() or result.collider == target

	return true

## 威胁检测回调
func _on_threat_detected(threat: Node, distance: float) -> void:
	var was_new = false

	if threat not in detected_threats:
		detected_threats.append(threat)
		was_new = true

	# 更新威胁数据
	threat_data[threat] = {
		"last_seen": Time.get_ticks_msec() / 1000.0,
		"distance": distance
	}

	if was_new:
		threat_detected.emit(threat)

## 清理过期威胁
func _cleanup_old_threats() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var threats_to_remove: Array = []

	for threat in detected_threats:
		if not is_instance_valid(threat):
			threats_to_remove.append(threat)
			continue

		if threat in threat_data:
			var data = threat_data[threat]
			if current_time - data["last_seen"] > lost_sight_time:
				threats_to_remove.append(threat)

	for threat in threats_to_remove:
		_remove_threat(threat)

## 移除威胁
func _remove_threat(threat: Node) -> void:
	if threat in detected_threats:
		detected_threats.erase(threat)
		threat_data.erase(threat)
		threat_lost.emit(threat)

## 获取最近的威胁
func get_nearest_threat() -> Node:
	if detected_threats.is_empty():
		return null

	var nearest: Node = null
	var nearest_distance: float = INF

	for threat in detected_threats:
		if not is_instance_valid(threat):
			continue

		if threat in threat_data:
			var distance = threat_data[threat]["distance"]
			if distance < nearest_distance:
				nearest = threat
				nearest_distance = distance

	return nearest

## 获取所有威胁
func get_all_threats() -> Array:
	return detected_threats.duplicate()

## 检查是否能看到目标
func can_see(target: Node) -> bool:
	if not is_instance_valid(target):
		return false

	var distance = _get_distance_to(target)
	if distance > sight_range:
		return false

	if not _is_in_sight_angle(target):
		return false

	if check_line_of_sight and not _has_line_of_sight(target):
		return false

	return true

## 检查是否能听到目标
func can_hear(target: Node) -> bool:
	if not is_instance_valid(target):
		return false

	var distance = _get_distance_to(target)
	return distance <= hearing_range

## 清除所有威胁
func clear_all_threats() -> void:
	var threats_copy = detected_threats.duplicate()
	for threat in threats_copy:
		_remove_threat(threat)
