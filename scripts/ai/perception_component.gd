extends Node
class_name PerceptionComponent
## 感知组件 - 处理AI的视觉和听觉感知

signal target_detected(target: Node)
signal target_lost(target: Node)
signal sound_heard(source: Node, position: Vector3)

## 视觉配置
@export var sight_range: float = 15.0  # 视野范围
@export var sight_angle: float = 120.0  # 视野角度（度）
@export var sight_height: float = 1.5  # 视线高度

## 听觉配置
@export var hearing_range: float = 20.0  # 听觉范围

## 检测配置
@export var detection_interval: float = 0.2  # 检测间隔
@export var target_groups: Array[String] = ["player", "enemy"]  # 检测的目标组

## 状态
var detected_targets: Array[Node] = []
var entity: Node = null
var detection_timer: float = 0.0

func _ready() -> void:
	entity = get_parent()

func _process(delta: float) -> void:
	detection_timer += delta

	if detection_timer >= detection_interval:
		detection_timer = 0.0
		_update_perception()

func _update_perception() -> void:
	var new_targets = _detect_visible_targets()

	# 检查新发现的目标
	for target in new_targets:
		if target not in detected_targets:
			detected_targets.append(target)
			target_detected.emit(target)

	# 检查丢失的目标
	var lost_targets = []
	for target in detected_targets:
		if target not in new_targets:
			lost_targets.append(target)

	for target in lost_targets:
		detected_targets.erase(target)
		target_lost.emit(target)

func _detect_visible_targets() -> Array[Node]:
	var visible_targets: Array[Node] = []

	# 获取范围内的所有潜在目标
	var potential_targets = _get_potential_targets()

	for target in potential_targets:
		if _is_target_visible(target):
			visible_targets.append(target)

	return visible_targets

func _get_potential_targets() -> Array[Node]:
	var targets: Array[Node] = []

	for group_name in target_groups:
		var group_nodes = get_tree().get_nodes_in_group(group_name)
		for node in group_nodes:
			if node != entity and node not in targets:
				targets.append(node)

	return targets

func _is_target_visible(target: Node) -> bool:
	if not is_instance_valid(target):
		return false

	# 检查目标是否死亡
	if target.has_method("is_dead") and target.is_dead():
		return false

	# 检查距离
	var distance = _get_distance_to(target)
	if distance > sight_range:
		return false

	# 检查视野角度
	if not _is_in_sight_angle(target):
		return false

	# 检查是否有遮挡
	if not _has_line_of_sight(target):
		return false

	return true

func _get_distance_to(target: Node) -> float:
	if entity is Node3D and target is Node3D:
		return entity.global_position.distance_to(target.global_position)
	elif entity is Node2D and target is Node2D:
		return entity.global_position.distance_to(target.global_position)
	return INF

func _is_in_sight_angle(target: Node) -> bool:
	if entity is Node3D and target is Node3D:
		var to_target = (target.global_position - entity.global_position).normalized()
		var forward = -entity.global_transform.basis.z  # Godot中 -Z 是前方

		var angle = rad_to_deg(acos(forward.dot(to_target)))
		return angle <= sight_angle / 2.0

	elif entity is Node2D and target is Node2D:
		var to_target = (target.global_position - entity.global_position).normalized()
		var forward = Vector2(cos(entity.global_rotation), sin(entity.global_rotation))

		var angle = rad_to_deg(acos(forward.dot(to_target)))
		return angle <= sight_angle / 2.0

	return false

func _has_line_of_sight(target: Node) -> bool:
	# 简化版本：总是返回 true
	# 实际应该使用射线检测检查是否有遮挡
	# TODO: 实现射线检测

	if entity is Node3D and target is Node3D:
		var space_state = entity.get_world_3d().direct_space_state
		var origin = entity.global_position + Vector3(0, sight_height, 0)
		var target_pos = target.global_position + Vector3(0, sight_height, 0)

		var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
		query.exclude = [entity]

		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return true

		# 检查碰撞的是不是目标本身
		return result.get("collider") == target

	return true

## 听到声音
func hear_sound(source: Node, position: Vector3, loudness: float = 1.0) -> void:
	var distance = _get_distance_to_position(position)
	var effective_range = hearing_range * loudness

	if distance <= effective_range:
		sound_heard.emit(source, position)

func _get_distance_to_position(position: Vector3) -> float:
	if entity is Node3D:
		return entity.global_position.distance_to(position)
	return INF

## 获取所有检测到的目标
func get_detected_targets() -> Array[Node]:
	return detected_targets

## 获取最近的目标
func get_closest_target() -> Node:
	if detected_targets.is_empty():
		return null

	var closest = detected_targets[0]
	var closest_distance = _get_distance_to(closest)

	for target in detected_targets:
		var distance = _get_distance_to(target)
		if distance < closest_distance:
			closest = target
			closest_distance = distance

	return closest

## 检查是否检测到某个目标
func is_target_detected(target: Node) -> bool:
	return target in detected_targets

## 清除所有检测到的目标
func clear_detected_targets() -> void:
	var targets_copy = detected_targets.duplicate()
	detected_targets.clear()

	for target in targets_copy:
		target_lost.emit(target)
