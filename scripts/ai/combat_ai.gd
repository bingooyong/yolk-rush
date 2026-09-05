extends Node
class_name CombatAI
## 战斗AI - 用于敌人战斗行为

# 预加载AIController脚本
const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")

## AI配置
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var flee_health_threshold: float = 0.3
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 4.0

## 内部AI控制器
var ai_controller: Node
var entity: Node
var perception: Node

func _ready() -> void:
	# 创建AI控制器
	ai_controller = AIControllerScript.new()
	add_child(ai_controller)

	# 获取实体引用
	entity = get_parent()
	if entity:
		ai_controller.entity = entity

	# 获取感知组件
	if entity and entity.has_node("PerceptionComponent"):
		perception = entity.get_node("PerceptionComponent")

	print("[CombatAI] Initialized for: %s" % (entity.name if entity else "Unknown"))

func _process(delta: float) -> void:
	if not ai_controller or not entity:
		return

	# 根据当前状态执行行为
	match ai_controller.current_state:
		0:  # IDLE
			_update_idle(delta)
		1:  # PATROL
			_update_patrol(delta)
		2:  # CHASE
			_update_chase(delta)
		3:  # COMBAT
			_update_combat(delta)
		4:  # ALERT
			_update_alert(delta)

## 空闲状态
func _update_idle(_delta: float) -> void:
	# 检测周围是否有目标
	if perception:
		var detected = perception.detect_nearby_entities()
		if not detected.is_empty():
			var target = detected[0]
			ai_controller.set_target(target)
			ai_controller.change_state(2)  # CHASE

## 巡逻状态
func _update_patrol(_delta: float) -> void:
	# 检测目标
	if perception:
		var detected = perception.detect_nearby_entities()
		if not detected.is_empty():
			var target = detected[0]
			ai_controller.set_target(target)
			ai_controller.change_state(2)  # CHASE
			return

	# 简单巡逻逻辑（可以后续扩展）
	pass

## 追击状态
func _update_chase(_delta: float) -> void:
	var target = ai_controller.current_target
	if not is_instance_valid(target):
		ai_controller.change_state(0)  # IDLE
		return

	var distance = _get_distance_to_target(target)

	# 进入攻击范围
	if distance <= attack_range:
		ai_controller.change_state(3)  # COMBAT
		return

	# 目标太远，放弃追击
	if distance > detection_range * 1.5:
		ai_controller.clear_target()
		ai_controller.change_state(0)  # IDLE
		return

	# 继续追击
	_move_towards_target(target, chase_speed)

## 战斗状态
func _update_combat(_delta: float) -> void:
	var target = ai_controller.current_target
	if not is_instance_valid(target):
		ai_controller.change_state(0)  # IDLE
		return

	var distance = _get_distance_to_target(target)

	# 目标逃离，切换到追击
	if distance > attack_range * 1.5:
		ai_controller.change_state(2)  # CHASE
		return

	# 检查是否需要逃跑
	if entity.has_method("get_health_percentage"):
		var health_percent = entity.get_health_percentage()
		if health_percent < flee_health_threshold:
			ai_controller.change_state(5)  # DEAD (暂用，后续可以加FLEE状态)
			return

	# 执行攻击
	_perform_attack(target)

## 警戒状态
func _update_alert(_delta: float) -> void:
	# 警戒状态可以快速响应
	var target = ai_controller.current_target
	if is_instance_valid(target):
		ai_controller.change_state(2)  # CHASE
	else:
		ai_controller.change_state(1)  # PATROL

## 获取到目标的距离
func _get_distance_to_target(target: Node) -> float:
	if entity is Node3D and target is Node3D:
		return entity.global_position.distance_to(target.global_position)
	elif entity is Node2D and target is Node2D:
		return entity.global_position.distance_to(target.global_position)
	return 999.0

## 向目标移动
func _move_towards_target(target: Node, speed: float) -> void:
	if entity is Node3D and target is Node3D:
		var direction = (target.global_position - entity.global_position).normalized()
		entity.global_position += direction * speed * get_process_delta_time()
	elif entity is Node2D and target is Node2D:
		var direction = (target.global_position - entity.global_position).normalized()
		entity.global_position += direction * speed * get_process_delta_time()

## 执行攻击
func _perform_attack(target: Node) -> void:
	# 简单攻击逻辑
	if target.has_method("take_damage"):
		target.take_damage(10.0)
		print("[CombatAI] %s attacked %s" % [entity.name, target.name])

## 便捷方法 - 获取当前状态
func get_state() -> int:
	return ai_controller.current_state if ai_controller else 0

## 便捷方法 - 设置目标
func set_target(target: Node) -> void:
	if ai_controller:
		ai_controller.set_target(target)

## 便捷方法 - 切换状态
func change_state(new_state: int) -> void:
	if ai_controller:
		ai_controller.change_state(new_state)

## 便捷方法 - 获取实体名称
func get_entity_name() -> String:
	if ai_controller:
		return ai_controller.get_entity_name()
	return entity.name if entity else "Unknown"

## 属性代理 - 暴露 current_state
var current_state: int:
	get:
		return ai_controller.current_state if ai_controller else 0
	set(value):
		if ai_controller:
			ai_controller.change_state(value)

## 属性代理 - 暴露 current_target
var current_target: Node:
	get:
		return ai_controller.current_target if ai_controller else null
	set(value):
		if ai_controller:
			ai_controller.set_target(value)
