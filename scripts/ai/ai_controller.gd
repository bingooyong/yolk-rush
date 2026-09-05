extends Node
class_name AIController
## AI控制器基类 - 管理AI实体的行为和决策

signal state_changed(old_state: String, new_state: String)
signal target_acquired(target: Node)
signal target_lost()
signal perception_updated()

## AI状态枚举
enum State {
	IDLE,      # 待机
	PATROL,    # 巡逻
	CHASE,     # 追击
	COMBAT,    # 战斗
	FLEE,      # 逃跑
	DEAD       # 死亡
}

## 当前状态
var current_state: State = State.IDLE

## 受控实体
@export var controlled_entity: Node

## 当前目标
var current_target: Node = null

## 感知组件
var perception: Node = null

## 配置参数
@export_group("AI配置")
@export var update_interval: float = 0.1  # AI更新间隔
@export var debug_mode: bool = false

## 内部计时器
var update_timer: float = 0.0

func _ready() -> void:
	if not controlled_entity:
		controlled_entity = get_parent()

	# 创建感知组件
	perception = _create_perception_component()
	if perception:
		add_child(perception)

	print("[AIController] Initialized for: %s" % controlled_entity.name)

func _process(delta: float) -> void:
	update_timer += delta

	if update_timer >= update_interval:
		update_timer = 0.0
		_update_ai()

## AI主更新循环
func _update_ai() -> void:
	# 更新感知
	if perception and perception.has_method("update_perception"):
		perception.update_perception()

	# 根据当前状态执行行为
	match current_state:
		State.IDLE:
			_process_idle_state()
		State.PATROL:
			_process_patrol_state()
		State.CHASE:
			_process_chase_state()
		State.COMBAT:
			_process_combat_state()
		State.FLEE:
			_process_flee_state()
		State.DEAD:
			_process_dead_state()

## 创建感知组件（子类可覆盖）
func _create_perception_component() -> Node:
	# 预加载 PerceptionComponent
	var PerceptionScript = load("res://scripts/ai/perception_component.gd")
	if PerceptionScript:
		return PerceptionScript.new()
	return null

## 状态处理方法（子类应实现）
func _process_idle_state() -> void:
	# 待机状态：检测周围威胁
	if perception and perception.has_method("get_nearest_threat"):
		var threat = perception.get_nearest_threat()
		if threat:
			set_target(threat)
			change_state(State.CHASE)

func _process_patrol_state() -> void:
	# 巡逻状态：沿路径移动
	pass

func _process_chase_state() -> void:
	# 追击状态：接近目标
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return

	# 检查是否进入战斗范围
	var distance = _get_distance_to_target()
	if distance < _get_combat_range():
		change_state(State.COMBAT)

func _process_combat_state() -> void:
	# 战斗状态：攻击目标
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return

	# 检查是否脱离战斗范围
	var distance = _get_distance_to_target()
	if distance > _get_combat_range() * 1.5:
		change_state(State.CHASE)

func _process_flee_state() -> void:
	# 逃跑状态：远离威胁
	pass

func _process_dead_state() -> void:
	# 死亡状态：停止所有行为
	pass

## 改变状态
func change_state(new_state: State) -> void:
	if new_state == current_state:
		return

	var old_state_name = State.keys()[current_state]
	var new_state_name = State.keys()[new_state]

	# 退出旧状态
	_exit_state(current_state)

	# 切换状态
	var old_state = current_state
	current_state = new_state

	# 进入新状态
	_enter_state(new_state)

	if debug_mode:
		print("[AIController] %s: %s → %s" % [controlled_entity.name, old_state_name, new_state_name])

	state_changed.emit(old_state_name, new_state_name)

## 进入状态（子类可覆盖）
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.PATROL:
			pass
		State.CHASE:
			pass
		State.COMBAT:
			pass
		State.FLEE:
			pass
		State.DEAD:
			pass

## 退出状态（子类可覆盖）
func _exit_state(state: State) -> void:
	match state:
		State.COMBAT:
			# 退出战斗时清理
			pass

## 设置目标
func set_target(target: Node) -> void:
	if current_target == target:
		return

	var had_target = current_target != null
	current_target = target

	if target:
		target_acquired.emit(target)
		if debug_mode:
			print("[AIController] %s: Target acquired - %s" % [controlled_entity.name, target.name])
	elif had_target:
		target_lost.emit()
		if debug_mode:
			print("[AIController] %s: Target lost" % controlled_entity.name)

## 清除目标
func clear_target() -> void:
	set_target(null)

## 获取与目标的距离
func _get_distance_to_target() -> float:
	if not current_target or not controlled_entity:
		return INF

	if controlled_entity is Node3D and current_target is Node3D:
		return controlled_entity.global_position.distance_to(current_target.global_position)
	elif controlled_entity is Node2D and current_target is Node2D:
		return controlled_entity.global_position.distance_to(current_target.global_position)

	return INF

## 获取战斗范围（子类应覆盖）
func _get_combat_range() -> float:
	return 3.0  # 默认3米

## 检查实体是否存活
func is_alive() -> bool:
	if not controlled_entity:
		return false

	if controlled_entity.has_method("is_alive"):
		return controlled_entity.is_alive()

	# 检查健康组件
	if controlled_entity.has_node("HealthComponent"):
		var health = controlled_entity.get_node("HealthComponent")
		if health.has_method("is_alive"):
			return health.is_alive()

	return current_state != State.DEAD

## 处理实体死亡
func on_entity_died() -> void:
	change_state(State.DEAD)
	clear_target()

	if debug_mode:
		print("[AIController] %s: Died" % controlled_entity.name)

## 获取当前状态名称
func get_current_state_name() -> String:
	return State.keys()[current_state]

## 是否在战斗中
func is_in_combat() -> bool:
	return current_state == State.COMBAT

## 是否有目标
func has_target() -> bool:
	return current_target != null and is_instance_valid(current_target)
