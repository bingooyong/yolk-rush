extends Node
class_name AIController
## AI控制器基类 - 所有AI行为的基础

signal state_changed(old_state: String, new_state: String)
signal target_acquired(target: Node)
signal target_lost()

enum AIState {
	IDLE,       # 空闲
	PATROL,     # 巡逻
	ALERT,      # 警戒
	COMBAT,     # 战斗
	FLEE,       # 逃跑
	DEAD        # 死亡
}

## 配置
@export var update_interval: float = 0.1  # AI更新间隔（秒）
@export var perception_radius: float = 10.0  # 感知半径
@export var attack_range: float = 2.0  # 攻击范围
@export var flee_health_threshold: float = 0.2  # 逃跑血量阈值

## 状态
var current_state: AIState = AIState.IDLE
var current_target: Node = null
var entity: Node = null  # 拥有此AI的实体

## 黑板（存储AI状态数据）
var blackboard: Dictionary = {}

## 内部
var update_timer: float = 0.0

func _ready() -> void:
	# 获取父实体
	entity = get_parent()
	_initialize()

func _initialize() -> void:
	# 子类重写此方法进行初始化
	pass

func _process(delta: float) -> void:
	update_timer += delta

	if update_timer >= update_interval:
		update_timer = 0.0
		_update_ai(delta)

## AI更新逻辑（子类重写）
func _update_ai(delta: float) -> void:
	match current_state:
		AIState.IDLE:
			_state_idle(delta)
		AIState.PATROL:
			_state_patrol(delta)
		AIState.ALERT:
			_state_alert(delta)
		AIState.COMBAT:
			_state_combat(delta)
		AIState.FLEE:
			_state_flee(delta)
		AIState.DEAD:
			_state_dead(delta)

## 状态处理方法（子类重写）
func _state_idle(_delta: float) -> void:
	pass

func _state_patrol(_delta: float) -> void:
	pass

func _state_alert(_delta: float) -> void:
	pass

func _state_combat(_delta: float) -> void:
	pass

func _state_flee(_delta: float) -> void:
	pass

func _state_dead(_delta: float) -> void:
	pass

## 切换状态
func change_state(new_state: AIState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)

	state_changed.emit(AIState.keys()[old_state], AIState.keys()[new_state])

## 进入状态（子类可重写）
func _enter_state(state: AIState) -> void:
	match state:
		AIState.IDLE:
			_enter_idle()
		AIState.PATROL:
			_enter_patrol()
		AIState.ALERT:
			_enter_alert()
		AIState.COMBAT:
			_enter_combat()
		AIState.FLEE:
			_enter_flee()
		AIState.DEAD:
			_enter_dead()

## 退出状态（子类可重写）
func _exit_state(state: AIState) -> void:
	match state:
		AIState.IDLE:
			_exit_idle()
		AIState.PATROL:
			_exit_patrol()
		AIState.ALERT:
			_exit_alert()
		AIState.COMBAT:
			_exit_combat()
		AIState.FLEE:
			_exit_flee()
		AIState.DEAD:
			_exit_dead()

## 状态进入/退出钩子（子类重写）
func _enter_idle() -> void: pass
func _exit_idle() -> void: pass
func _enter_patrol() -> void: pass
func _exit_patrol() -> void: pass
func _enter_alert() -> void: pass
func _exit_alert() -> void: pass
func _enter_combat() -> void: pass
func _exit_combat() -> void: pass
func _enter_flee() -> void: pass
func _exit_flee() -> void: pass
func _enter_dead() -> void: pass
func _exit_dead() -> void: pass

## 感知系统 - 检测范围内的目标
func detect_targets(detection_radius: float = 0.0) -> Array:
	if detection_radius <= 0:
		detection_radius = perception_radius

	var targets = []
	var space_state = entity.get_world_3d().direct_space_state if entity is Node3D else entity.get_world_2d().direct_space_state

	# 获取范围内的所有物体
	# 这里简化处理，实际应该使用物理查询
	var all_entities = get_tree().get_nodes_in_group("entities")

	for target in all_entities:
		if target == entity:
			continue

		var distance = _get_distance_to(target)
		if distance <= detection_radius:
			targets.append(target)

	return targets

## 获取到目标的距离
func _get_distance_to(target: Node) -> float:
	if entity is Node3D and target is Node3D:
		return entity.global_position.distance_to(target.global_position)
	elif entity is Node2D and target is Node2D:
		return entity.global_position.distance_to(target.global_position)
	return INF

## 设置目标
func set_target(target: Node) -> void:
	if current_target == target:
		return

	current_target = target

	if target:
		target_acquired.emit(target)
	else:
		target_lost.emit()

## 清除目标
func clear_target() -> void:
	set_target(null)

## 检查目标是否有效
func is_target_valid() -> bool:
	if current_target == null:
		return false

	if not is_instance_valid(current_target):
		clear_target()
		return false

	# 检查目标是否死亡
	if current_target.has_method("is_dead") and current_target.is_dead():
		clear_target()
		return false

	return true

## 检查是否在攻击范围内
func is_in_attack_range() -> bool:
	if not is_target_valid():
		return false

	return _get_distance_to(current_target) <= attack_range

## 检查实体血量是否低
func is_health_low() -> bool:
	if not entity.has_method("get_health_percentage"):
		return false

	return entity.get_health_percentage() <= flee_health_threshold

## 移动到目标
func move_towards(target_position: Vector3) -> void:
	if entity.has_method("move_to"):
		entity.move_to(target_position)

## 攻击当前目标
func attack_target() -> void:
	if not is_target_valid():
		return

	if entity.has_method("attack"):
		entity.attack(current_target)

## 使用技能
func use_skill(skill_id: String) -> bool:
	if entity.has_method("use_skill"):
		return entity.use_skill(skill_id, current_target)
	return false

## 黑板操作
func set_blackboard_value(key: String, value) -> void:
	blackboard[key] = value

func get_blackboard_value(key: String, default_value = null):
	return blackboard.get(key, default_value)

func has_blackboard_value(key: String) -> bool:
	return blackboard.has(key)

func clear_blackboard() -> void:
	blackboard.clear()

## 获取实体名称
func get_entity_name() -> String:
	if entity.has_method("get_display_name"):
		return entity.get_display_name()
	return entity.name if entity else "Unknown"
