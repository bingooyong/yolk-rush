extends CharacterBody3D
## 敌人AI - 简单的追击和攻击

@export var enemy_type: String = "goblin"
@export var enemy_level: int = 1
@export var max_health: float = 50.0
@export var damage: float = 5.0
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var move_speed: float = 3.0

var health: float = 50.0
var player: Node3D = null
var attack_cooldown: float = 0.0

enum State { IDLE, CHASE, ATTACK, DEAD }
var current_state: State = State.IDLE

func _ready() -> void:
	health = max_health
	print("[Enemy] %s Level %d spawned - HP: %d" % [enemy_type, enemy_level, health])

	# 查找玩家
	_find_player()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# 状态机
	match current_state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack()

## 查找玩家
func _find_player() -> void:
	# 延迟查找，等待场景加载完成
	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("[Enemy] Found player")

## 空闲状态
func _state_idle() -> void:
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance <= detection_range:
		current_state = State.CHASE
		print("[Enemy] Player detected! Chasing...")

## 追击状态
func _state_chase(delta: float) -> void:
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# 太远了，回到空闲
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# 进入攻击范围
	if distance <= attack_range:
		current_state = State.ATTACK
		return

	# 朝玩家移动
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # 只在XZ平面移动

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# 应用重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	# 面向玩家
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

## 攻击状态
func _state_attack() -> void:
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# 玩家逃出攻击范围
	if distance > attack_range * 1.2:
		current_state = State.CHASE
		return

	# 执行攻击
	if attack_cooldown <= 0:
		_perform_attack()
		attack_cooldown = 2.0  # 2秒攻击间隔

## 执行攻击
func _perform_attack() -> void:
	if not player or not player.has_method("take_damage"):
		return

	print("[Enemy] Attacking player for %d damage" % damage)
	player.take_damage(damage)

## 受到伤害
func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return

	health -= amount
	health = max(0, health)

	print("[Enemy] Took %d damage - HP: %d/%d" % [amount, health, max_health])

	# 受击时进入追击状态
	if current_state == State.IDLE:
		current_state = State.CHASE

	if health <= 0:
		_die()

## 死亡
func _die() -> void:
	current_state = State.DEAD
	print("[Enemy] %s died!" % enemy_type)

	# 调用GameManager处理掉落
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.on_enemy_killed(enemy_type, enemy_level)

	# 播放死亡动画/特效
	_spawn_death_effects()

	# 2秒后移除
	await get_tree().create_timer(2.0).timeout
	queue_free()

## 生成死亡特效
func _spawn_death_effects() -> void:
	# TODO: 添加粒子特效

	# 临时：改变颜色表示死亡
	if has_node("MeshInstance3D"):
		var mesh = get_node("MeshInstance3D")
		if mesh.get_surface_override_material_count() > 0:
			var mat = mesh.get_surface_override_material(0)
			if mat:
				mat.albedo_color = Color.GRAY
