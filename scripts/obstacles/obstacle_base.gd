extends Node3D
class_name ObstacleBase
## 障碍物基类 - 所有障碍的通用行为

signal obstacle_triggered(player: Node)
signal obstacle_state_changed(new_state: int)

enum ObstacleState {
	IDLE,       # 待机
	ACTIVE,     # 激活
	TRIGGERED,  # 已触发
	DISABLED    # 禁用
}

enum DamageType {
	NONE,       # 无伤害
	LIGHT,      # 轻度伤害
	MEDIUM,     # 中度伤害
	HEAVY,      # 重度伤害
	INSTANT_KILL # 秒杀
}

## 障碍属性
@export var obstacle_name: String = "Obstacle"
@export var damage_type: DamageType = DamageType.MEDIUM
@export var damage_amount: float = 20.0
@export var knockback_force: float = 10.0
@export var can_respawn: bool = true
@export var respawn_time: float = 3.0

## 状态
var current_state: ObstacleState = ObstacleState.IDLE
var is_active: bool = true
var affected_players: Dictionary = {}  # 追踪已影响的玩家

## 碰撞组件
var collision_area: Area3D
var collision_shape: CollisionShape3D

func _ready() -> void:
	_setup_collision()
	_initialize_obstacle()
	print("[%s] Initialized" % obstacle_name)

## 设置碰撞检测
func _setup_collision() -> void:
	collision_area = Area3D.new()
	collision_area.name = "CollisionArea"
	collision_area.collision_layer = 8  # 障碍层
	collision_area.collision_mask = 1   # 玩家层
	add_child(collision_area)

	collision_area.body_entered.connect(_on_body_entered)
	collision_area.body_exited.connect(_on_body_exited)

## 初始化障碍（子类重写）
func _initialize_obstacle() -> void:
	pass

## 碰撞进入
func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	if _is_player(body):
		_apply_effect(body)

## 碰撞退出
func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		affected_players.erase(body)

## 判断是否为玩家
func _is_player(body: Node) -> bool:
	return body.is_in_group("player")

## 应用效果到玩家
func _apply_effect(player: Node3D) -> void:
	# 避免重复触发
	if player in affected_players:
		var last_trigger = affected_players[player]
		if Time.get_ticks_msec() - last_trigger < 500:  # 0.5秒冷却
			return

	affected_players[player] = Time.get_ticks_msec()

	# 应用伤害
	if damage_type != DamageType.NONE:
		_apply_damage(player)

	# 应用击退
	if knockback_force > 0:
		_apply_knockback(player)

	# 触发信号
	obstacle_triggered.emit(player)
	_on_triggered(player)

## 应用伤害
func _apply_damage(player: Node) -> void:
	var actual_damage = damage_amount

	match damage_type:
		DamageType.LIGHT:
			actual_damage = damage_amount * 0.5
		DamageType.MEDIUM:
			actual_damage = damage_amount
		DamageType.HEAVY:
			actual_damage = damage_amount * 2.0
		DamageType.INSTANT_KILL:
			actual_damage = 9999.0

	if player.has_method("take_damage"):
		player.take_damage(actual_damage)
		print("[%s] Dealt %.1f damage to %s" % [obstacle_name, actual_damage, player.name])

## 应用击退
func _apply_knockback(player: Node) -> void:
	if not player is CharacterBody3D:
		return

	# 计算击退方向
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0.3  # 添加垂直分量

	var knockback_velocity = direction * knockback_force

	# 应用击退
	if player.has_method("apply_knockback"):
		player.apply_knockback(knockback_velocity)
	elif player.has_method("set_velocity"):
		player.velocity = knockback_velocity
		print("[%s] Applied knockback to %s" % [obstacle_name, player.name])

## 触发回调（子类重写）
func _on_triggered(player: Node) -> void:
	pass

## 设置状态
func set_state(new_state: ObstacleState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	obstacle_state_changed.emit(new_state)
	_on_state_changed(new_state)

## 状态改变回调（子类重写）
func _on_state_changed(new_state: ObstacleState) -> void:
	pass

## 激活障碍
func activate() -> void:
	is_active = true
	set_state(ObstacleState.ACTIVE)
	print("[%s] Activated" % obstacle_name)

## 禁用障碍
func deactivate() -> void:
	is_active = false
	set_state(ObstacleState.DISABLED)
	print("[%s] Deactivated" % obstacle_name)

## 重置障碍
func reset_obstacle() -> void:
	is_active = true
	affected_players.clear()
	set_state(ObstacleState.IDLE)
	_on_reset()

## 重置回调（子类重写）
func _on_reset() -> void:
	pass
