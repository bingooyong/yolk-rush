extends CharacterBody3D
class_name EnemyController
## 敌人控制器 - AI 和战斗

# 敌人类型
enum EnemyType {
	MELEE,      # 近战
	RANGED,     # 远程
	ELITE       # 精英
}

# 敌人状态
enum State {
	IDLE,       # 待机
	PATROL,     # 巡逻
	CHASE,      # 追击
	ATTACK,     # 攻击
	DEAD        # 死亡
}

# 基础属性
@export var enemy_type: EnemyType = EnemyType.MELEE
@export var enemy_level: int = 1
@export var max_health: float = 100.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 1.5
@export var detection_range: float = 10.0
@export var attack_cooldown: float = 1.5

# 掉落配置
@export var drop_table_id: String = "common_enemy"
@export var exp_reward: int = 50
@export var gold_reward: int = 10

# 当前状态
var current_state: State = State.IDLE
var current_health: float = 100.0
var target_player: Node3D = null
var can_attack: bool = true
var is_dead: bool = false

# 巡逻
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 2.0
var patrol_timer: float = 0.0

# 组件引用
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null
@onready var mesh: MeshInstance3D = $EnemyMesh if has_node("EnemyMesh") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

func _ready():
	current_health = max_health

	# 根据类型调整属性
	_setup_enemy_type()

	# 设置导航
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5

	# 生成巡逻点
	_generate_patrol_points()

	current_state = State.PATROL

	print("[EnemyController] Spawned level %d %s enemy" % [enemy_level, EnemyType.keys()[enemy_type]])

func _setup_enemy_type():
	match enemy_type:
		EnemyType.MELEE:
			attack_range = 1.5
			attack_damage = 10.0
			move_speed = 3.5
		EnemyType.RANGED:
			attack_range = 8.0
			attack_damage = 8.0
			move_speed = 2.5
		EnemyType.ELITE:
			max_health = 300.0
			current_health = 300.0
			attack_damage = 25.0
			move_speed = 4.0
			attack_range = 2.0
			exp_reward = 200
			gold_reward = 50

func _generate_patrol_points():
	# 在当前位置周围生成 3-5 个巡逻点
	var num_points = randi() % 3 + 3
	var radius = 5.0

	for i in range(num_points):
		var angle = (TAU / num_points) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * radius
		patrol_points.append(global_position + offset)

func _physics_process(delta):
	if is_dead:
		return

	# 重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 寻找玩家
	if not target_player:
		_find_player()

	# 状态机
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)

	move_and_slide()

func _find_player():
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _state_idle(delta):
	velocity.x = 0
	velocity.z = 0

	patrol_timer += delta
	if patrol_timer >= patrol_wait_time:
		patrol_timer = 0
		current_state = State.PATROL

func _state_patrol(delta):
	if patrol_points.is_empty():
		current_state = State.IDLE
		return

	# 检测玩家
	if target_player and _can_see_player():
		current_state = State.CHASE
		return

	# 移动到巡逻点
	var target_point = patrol_points[current_patrol_index]
	var direction = (target_point - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * move_speed * 0.5
	velocity.z = direction.z * move_speed * 0.5

	# 到达巡逻点
	if global_position.distance_to(target_point) < 1.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		current_state = State.IDLE
		patrol_timer = 0

func _state_chase(delta):
	if not target_player or not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var distance = global_position.distance_to(target_player.global_position)

	# 失去视野
	if distance > detection_range * 1.5:
		current_state = State.PATROL
		return

	# 进入攻击范围
	if distance <= attack_range:
		current_state = State.ATTACK
		velocity.x = 0
		velocity.z = 0
		return

	# 追击玩家
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# 面向玩家
	look_at(target_player.global_position, Vector3.UP)

func _state_attack(delta):
	if not target_player or not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var distance = global_position.distance_to(target_player.global_position)

	# 玩家逃离
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return

	# 停止移动
	velocity.x = 0
	velocity.z = 0

	# 面向玩家
	look_at(target_player.global_position, Vector3.UP)

	# 攻击
	if can_attack:
		_perform_attack()

func _can_see_player() -> bool:
	if not target_player or not is_instance_valid(target_player):
		return false

	var distance = global_position.distance_to(target_player.global_position)
	return distance <= detection_range

func _perform_attack():
	can_attack = false

	# 播放攻击动画
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")

	# 对玩家造成伤害
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		print("[EnemyController] Attacked player for %.1f damage" % attack_damage)

	# 攻击冷却
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

## 受到伤害
func take_damage(damage: float):
	if is_dead:
		return

	current_health -= damage
	print("[EnemyController] Took %.1f damage (%.1f/%.1f HP)" % [damage, current_health, max_health])

	# 进入追击状态
	if current_state != State.ATTACK and target_player:
		current_state = State.CHASE

	# 死亡
	if current_health <= 0:
		_die()

func _die():
	is_dead = true
	current_state = State.DEAD

	print("[EnemyController] Died")

	# 播放死亡动画
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")

	# 生成掉落
	_generate_drops()

	# 给予经验和金币
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# 经验值
		if game_manager.level_system:
			game_manager.level_system.add_exp(exp_reward)

		# 金币
		if game_manager.shop_system:
			var current_gold = game_manager.shop_system.get_player_gold()
			game_manager.shop_system.set_player_gold(current_gold + gold_reward)

		# 成就进度
		if game_manager.achievement_system:
			game_manager.achievement_system.increment_progress("kill_100_enemies", 1)
			game_manager.achievement_system.increment_progress("kill_1000_enemies", 1)

	# 延迟后移除
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _generate_drops():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.drop_system:
		return

	# 获取幸运值
	var luck_bonus = 0.0
	if game_manager.stats_system:
		luck_bonus = game_manager.stats_system.get_stat_bonus("drop_rate")

	# 生成掉落
	var drops = game_manager.drop_system.generate_loot(drop_table_id, luck_bonus)

	# 添加到背包
	for drop in drops:
		if game_manager.item_database and game_manager.inventory_system:
			var item = game_manager.item_database.get_item_by_id(drop.item_id)
			if item:
				game_manager.inventory_system.add_item(item, drop.quantity)
				print("[EnemyController] Dropped %dx %s" % [drop.quantity, item.item_name])

## 设置等级
func set_level(level: int):
	enemy_level = level

	# 根据等级缩放属性
	var level_scale = 1.0 + (level - 1) * 0.2
	max_health *= level_scale
	current_health = max_health
	attack_damage *= level_scale
	exp_reward = int(exp_reward * level_scale)
	gold_reward = int(gold_reward * level_scale)
