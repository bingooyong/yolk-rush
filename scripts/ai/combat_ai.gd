extends AIController
class_name CombatAI
## 战斗AI - 具体实现战斗行为的AI控制器

## 战斗配置
@export_group("战斗参数")
@export var attack_range: float = 2.0  # 攻击范围
@export var attack_cooldown: float = 1.5  # 攻击冷却
@export var skill_usage_chance: float = 0.3  # 使用技能的概率
@export var flee_health_threshold: float = 0.2  # 逃跑血量阈值

@export_group("移动参数")
@export var move_speed: float = 3.0  # 移动速度
@export var chase_distance: float = 10.0  # 追击距离
@export var lost_target_time: float = 5.0  # 失去目标后多久放弃

## 战斗状态
var last_attack_time: float = 0.0
var target_lost_timer: float = 0.0

## 技能系统引用
var skill_system: Node = null

func _ready() -> void:
	super._ready()

	# 查找技能系统
	if controlled_entity and controlled_entity.has_node("SkillSystem"):
		skill_system = controlled_entity.get_node("SkillSystem")

## 获取战斗范围
func _get_combat_range() -> float:
	return attack_range

## 待机状态处理
func _process_idle_state() -> void:
	super._process_idle_state()

	# 如果有感知组件，监听威胁
	if perception:
		perception.threat_detected.connect(_on_threat_detected, CONNECT_ONE_SHOT)

## 追击状态处理
func _process_chase_state() -> void:
	if not is_instance_valid(current_target):
		target_lost_timer += update_interval

		if target_lost_timer >= lost_target_time:
			change_state(State.IDLE)
			target_lost_timer = 0.0
		return

	# 重置失去目标计时器
	target_lost_timer = 0.0

	# 检查是否进入战斗范围
	var distance = _get_distance_to_target()
	if distance <= attack_range * 1.2:
		change_state(State.COMBAT)
		return

	# 移动向目标
	_move_towards_target()

## 战斗状态处理
func _process_combat_state() -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return

	# 检查是否应该逃跑
	if _should_flee():
		change_state(State.FLEE)
		return

	var distance = _get_distance_to_target()

	# 距离过远，追击
	if distance > attack_range * 1.5:
		change_state(State.CHASE)
		return

	# 距离过近，后退
	if distance < attack_range * 0.5:
		_move_away_from_target()
		return

	# 在合适范围内，攻击
	_try_attack()

## 逃跑状态处理
func _process_flee_state() -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return

	# 检查血量是否恢复
	if not _should_flee():
		change_state(State.COMBAT)
		return

	# 远离目标
	_move_away_from_target()

	# 距离足够远，回到待机
	var distance = _get_distance_to_target()
	if distance > chase_distance:
		clear_target()
		change_state(State.IDLE)

## 尝试攻击
func _try_attack() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0

	# 检查冷却
	if current_time - last_attack_time < attack_cooldown:
		return

	# 面向目标
	_face_target()

	# 决定使用普通攻击还是技能
	if skill_system and randf() < skill_usage_chance:
		_try_use_skill()
	else:
		_perform_basic_attack()

	last_attack_time = current_time

## 执行普通攻击
func _perform_basic_attack() -> void:
	if not controlled_entity or not current_target:
		return

	# 调用实体的攻击方法
	if controlled_entity.has_method("attack"):
		controlled_entity.attack(current_target)

	if debug_mode:
		print("[CombatAI] %s: Basic attack on %s" % [controlled_entity.name, current_target.name])

## 尝试使用技能
func _try_use_skill() -> void:
	if not skill_system or not current_target:
		return

	# 获取可用技能
	var available_skills = _get_available_skills()
	if available_skills.is_empty():
		_perform_basic_attack()
		return

	# 选择合适的技能
	var skill = _choose_best_skill(available_skills)
	if skill:
		_use_skill(skill)
	else:
		_perform_basic_attack()

## 获取可用技能
func _get_available_skills() -> Array:
	if not skill_system:
		return []

	var skills: Array = []

	if skill_system.has_method("get_ready_skills"):
		skills = skill_system.get_ready_skills()

	return skills

## 选择最佳技能
func _choose_best_skill(available_skills: Array):
	if available_skills.is_empty():
		return null

	# 简单策略：优先使用伤害高的技能
	var best_skill = null
	var best_damage = 0.0

	for skill in available_skills:
		if not skill or not skill.has_method("get_total_damage"):
			continue

		var damage = skill.get_total_damage()
		if damage > best_damage:
			best_damage = damage
			best_skill = skill

	return best_skill if best_skill else available_skills[0]

## 使用技能
func _use_skill(skill) -> void:
	if not skill or not skill_system:
		return

	if skill_system.has_method("use_skill"):
		skill_system.use_skill(skill.skill_id, current_target)

	if debug_mode:
		print("[CombatAI] %s: Used skill on %s" % [controlled_entity.name, current_target.name])

## 移动向目标
func _move_towards_target() -> void:
	if not controlled_entity or not current_target:
		return

	var direction = _get_direction_to_target()
	_move_in_direction(direction)

## 远离目标移动
func _move_away_from_target() -> void:
	if not controlled_entity or not current_target:
		return

	var direction = _get_direction_to_target()
	_move_in_direction(-direction)

## 获取到目标的方向
func _get_direction_to_target() -> Vector3:
	if not controlled_entity or not current_target:
		return Vector3.ZERO

	if controlled_entity is Node3D and current_target is Node3D:
		return (current_target.global_position - controlled_entity.global_position).normalized()

	return Vector3.ZERO

## 在指定方向移动
func _move_in_direction(direction: Vector3) -> void:
	if not controlled_entity:
		return

	if controlled_entity.has_method("move"):
		controlled_entity.move(direction * move_speed)
	elif controlled_entity is CharacterBody3D:
		controlled_entity.velocity = direction * move_speed
		controlled_entity.move_and_slide()

## 面向目标
func _face_target() -> void:
	if not controlled_entity or not current_target:
		return

	if controlled_entity is Node3D and current_target is Node3D:
		var look_pos = current_target.global_position
		look_pos.y = controlled_entity.global_position.y  # 保持Y轴不变
		controlled_entity.look_at(look_pos, Vector3.UP)

## 检查是否应该逃跑
func _should_flee() -> bool:
	if not controlled_entity:
		return false

	# 检查血量
	var health_component = null
	if controlled_entity.has_node("HealthComponent"):
		health_component = controlled_entity.get_node("HealthComponent")

	if health_component and health_component.has_method("get_health_percentage"):
		var health_percent = health_component.get_health_percentage()
		return health_percent <= flee_health_threshold

	return false

## 威胁检测回调
func _on_threat_detected(threat: Node) -> void:
	if current_state == State.IDLE:
		set_target(threat)
		change_state(State.CHASE)

## 进入状态
func _enter_state(state: State) -> void:
	super._enter_state(state)

	match state:
		State.COMBAT:
			last_attack_time = 0.0  # 重置攻击时间，允许立即攻击
		State.CHASE:
			target_lost_timer = 0.0

## 退出状态
func _exit_state(state: State) -> void:
	super._exit_state(state)

## 获取当前血量百分比
func get_health_percentage() -> float:
	if not controlled_entity:
		return 0.0

	if controlled_entity.has_node("HealthComponent"):
		var health = controlled_entity.get_node("HealthComponent")
		if health.has_method("get_health_percentage"):
			return health.get_health_percentage()

	return 1.0
