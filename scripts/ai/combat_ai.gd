extends AIController
class_name CombatAI
## 战斗AI控制器 - 处理战斗相关的AI行为

## 战斗配置
@export var chase_speed_multiplier: float = 1.2  # 追击速度倍率
@export var attack_cooldown: float = 1.5  # 攻击冷却时间
@export var skill_usage_chance: float = 0.3  # 使用技能的概率
@export var flee_distance: float = 15.0  # 逃跑距离

## 巡逻配置
@export var patrol_points: Array[Vector3] = []  # 巡逻点
@export var patrol_wait_time: float = 2.0  # 巡逻点等待时间

## 战斗状态
var last_attack_time: float = 0.0
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var alert_timer: float = 0.0
var alert_duration: float = 5.0  # 警戒持续时间

func _initialize() -> void:
	super._initialize()

	# 如果没有设置巡逻点，创建默认巡逻点
	if patrol_points.is_empty() and entity is Node3D:
		_generate_default_patrol_points()

func _generate_default_patrol_points() -> void:
	var start_pos = entity.global_position
	patrol_points = [
		start_pos,
		start_pos + Vector3(5, 0, 0),
		start_pos + Vector3(5, 0, 5),
		start_pos + Vector3(0, 0, 5),
	]

## 空闲状态
func _enter_idle() -> void:
	set_blackboard_value("idle_time", 0.0)

func _state_idle(delta: float) -> void:
	# 检测附近的敌人
	var targets = detect_targets()
	if not targets.is_empty():
		var closest_target = _find_closest_target(targets)
		if closest_target:
			set_target(closest_target)
			change_state(AIState.ALERT)
			return

	# 空闲一段时间后开始巡逻
	var idle_time = get_blackboard_value("idle_time", 0.0) + delta
	set_blackboard_value("idle_time", idle_time)

	if idle_time > 3.0 and not patrol_points.is_empty():
		change_state(AIState.PATROL)

## 巡逻状态
func _enter_patrol() -> void:
	current_patrol_index = 0
	patrol_wait_timer = 0.0

func _state_patrol(delta: float) -> void:
	# 检测敌人
	var targets = detect_targets()
	if not targets.is_empty():
		var closest_target = _find_closest_target(targets)
		if closest_target:
			set_target(closest_target)
			change_state(AIState.ALERT)
			return

	# 巡逻逻辑
	if patrol_points.is_empty():
		change_state(AIState.IDLE)
		return

	var target_point = patrol_points[current_patrol_index]
	var distance = _get_distance_to_position(target_point)

	if distance < 1.0:
		# 到达巡逻点，等待
		patrol_wait_timer += delta
		if patrol_wait_timer >= patrol_wait_time:
			patrol_wait_timer = 0.0
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		# 移动到巡逻点
		move_towards(target_point)

## 警戒状态
func _enter_alert() -> void:
	alert_timer = 0.0

func _state_alert(delta: float) -> void:
	alert_timer += delta

	# 检查目标是否有效
	if not is_target_valid():
		if alert_timer >= alert_duration:
			change_state(AIState.IDLE)
		return

	# 目标在感知范围内，进入战斗
	var distance = _get_distance_to(current_target)
	if distance <= perception_radius:
		change_state(AIState.COMBAT)
		return

	# 警戒超时
	if alert_timer >= alert_duration:
		clear_target()
		change_state(AIState.IDLE)

## 战斗状态
func _enter_combat() -> void:
	last_attack_time = 0.0

func _state_combat(delta: float) -> void:
	# 检查是否应该逃跑
	if is_health_low():
		change_state(AIState.FLEE)
		return

	# 检查目标是否有效
	if not is_target_valid():
		change_state(AIState.IDLE)
		return

	var distance = _get_distance_to(current_target)

	# 目标太远，返回警戒
	if distance > perception_radius * 1.5:
		change_state(AIState.ALERT)
		return

	# 在攻击范围内
	if distance <= attack_range:
		_try_attack(delta)
	else:
		# 追击目标
		if entity is Node3D:
			move_towards(current_target.global_position)

func _try_attack(delta: float) -> void:
	last_attack_time += delta

	if last_attack_time >= attack_cooldown:
		last_attack_time = 0.0

		# 随机决定使用普通攻击还是技能
		if randf() < skill_usage_chance:
			_try_use_skill()
		else:
			attack_target()

func _try_use_skill() -> void:
	# 获取可用技能
	if not entity.has_method("get_available_skills"):
		attack_target()
		return

	var skills = entity.get_available_skills()
	if skills.is_empty():
		attack_target()
		return

	# 随机选择一个技能
	var skill = skills[randi() % skills.size()]
	if not use_skill(skill):
		attack_target()

## 逃跑状态
func _enter_flee() -> void:
	set_blackboard_value("flee_start_time", Time.get_ticks_msec())

func _state_flee(delta: float) -> void:
	# 血量恢复，返回战斗
	if not is_health_low() and is_target_valid():
		change_state(AIState.COMBAT)
		return

	# 没有目标，返回空闲
	if not is_target_valid():
		change_state(AIState.IDLE)
		return

	# 逃离目标
	var flee_direction = _get_flee_direction()
	if entity is Node3D:
		var flee_target = entity.global_position + flee_direction * flee_distance
		move_towards(flee_target)

func _get_flee_direction() -> Vector3:
	if not is_target_valid():
		return Vector3.BACK

	if entity is Node3D and current_target is Node3D:
		var direction = entity.global_position - current_target.global_position
		return direction.normalized()

	return Vector3.BACK

## 死亡状态
func _enter_dead() -> void:
	clear_target()
	set_process(false)

func _state_dead(_delta: float) -> void:
	# 死亡状态不做任何事
	pass

## 工具方法

func _find_closest_target(targets: Array) -> Node:
	if targets.is_empty():
		return null

	var closest = targets[0]
	var closest_distance = _get_distance_to(closest)

	for target in targets:
		var distance = _get_distance_to(target)
		if distance < closest_distance:
			closest = target
			closest_distance = distance

	return closest

func _get_distance_to_position(position: Vector3) -> float:
	if entity is Node3D:
		return entity.global_position.distance_to(position)
	return INF

## 公共接口

## 设置巡逻路径
func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points
	current_patrol_index = 0

## 强制进入战斗状态
func enter_combat_with_target(target: Node) -> void:
	set_target(target)
	change_state(AIState.COMBAT)

## 受到伤害时的回调
func on_damage_taken(attacker: Node, _damage: float) -> void:
	# 如果空闲或巡逻，立即进入战斗
	if current_state in [AIState.IDLE, AIState.PATROL]:
		set_target(attacker)
		change_state(AIState.ALERT)
