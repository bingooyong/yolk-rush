extends CharacterBody3D

## 高级敌人 AI - 支持多种行为模式

signal died
signal took_damage(amount: float)
signal ability_used(ability_id: String)

@export var enemy_type_id: String = "melee_assassin"

# 状态
var current_health: float
var max_health: float
var is_dead: bool = false
var target: Node3D = null

# 数据
var enemy_data: Dictionary
var stats: Dictionary
var ai_behavior: Dictionary

# AI 状态
enum AIState { IDLE, PATROL, CHASE, ATTACK, RETREAT, USE_ABILITY }
var current_state: AIState = AIState.IDLE

# 计时器
var attack_timer: float = 0.0
var ability_cooldowns: Dictionary = {}
var state_timer: float = 0.0

# 移动
var patrol_target: Vector3
var patrol_wait_time: float = 0.0

func _ready() -> void:
	_load_enemy_data()
	_initialize_stats()
	_setup_visual()

func _load_enemy_data() -> void:
	var file := FileAccess.open("res://data/enemies/enemy_types.json", FileAccess.READ)
	if not file:
		push_error("[AdvancedEnemy] 无法加载敌人数据")
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[AdvancedEnemy] JSON 解析失败")
		return

	var data: Dictionary = json.data
	for enemy in data.enemy_types:
		if enemy.id == enemy_type_id:
			enemy_data = enemy
			stats = enemy.stats
			ai_behavior = enemy.ai_behavior
			break

	if enemy_data.is_empty():
		push_error("[AdvancedEnemy] 未找到敌人类型: %s" % enemy_type_id)

func _initialize_stats() -> void:
	max_health = stats.get("max_health", 100.0)
	current_health = max_health

	# 初始化技能冷却
	if ai_behavior.has("special_abilities"):
		for ability in ai_behavior.special_abilities:
			ability_cooldowns[ability.id] = 0.0

func _setup_visual() -> void:
	# 创建视觉表现
	var visual := enemy_data.get("visual", {})
	var color_hex: String = visual.get("color", "#FF0000")
	var scale_value: float = visual.get("scale", 1.0)

	# 创建身体
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"

	var model_type: String = visual.get("model_type", "humanoid")
	if model_type == "humanoid":
		mesh_instance.mesh = CapsuleMesh.new()
		mesh_instance.mesh.height = 1.8 * scale_value
		mesh_instance.mesh.radius = 0.4 * scale_value
	elif model_type == "golem":
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.mesh.size = Vector3(1.0, 2.0, 1.0) * scale_value

	# 设置颜色
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_string(color_hex, Color.RED)
	mesh_instance.material_override = material

	add_child(mesh_instance)

	# 创建碰撞体
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	if model_type == "humanoid":
		var shape := CapsuleShape3D.new()
		shape.height = 1.8 * scale_value
		shape.radius = 0.4 * scale_value
		collision.shape = shape
	else:
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.0, 2.0, 1.0) * scale_value
		collision.shape = shape

	add_child(collision)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 更新计时器
	attack_timer = maxf(0.0, attack_timer - delta)
	state_timer += delta

	for ability_id in ability_cooldowns.keys():
		ability_cooldowns[ability_id] = maxf(0.0, ability_cooldowns[ability_id] - delta)

	# AI 决策
	_update_ai_state()

	# 执行当前状态
	match current_state:
		AIState.IDLE:
			_state_idle(delta)
		AIState.PATROL:
			_state_patrol(delta)
		AIState.CHASE:
			_state_chase(delta)
		AIState.ATTACK:
			_state_attack(delta)
		AIState.RETREAT:
			_state_retreat(delta)
		AIState.USE_ABILITY:
			_state_use_ability(delta)

	move_and_slide()

func _update_ai_state() -> void:
	# 查找玩家
	if not target or not is_instance_valid(target):
		target = _find_player()

	if not target:
		if current_state != AIState.IDLE and current_state != AIState.PATROL:
			_change_state(AIState.IDLE)
		return

	var distance_to_target := global_position.distance_to(target.global_position)
	var aggro_radius: float = ai_behavior.get("aggro_radius", 10.0)
	var attack_range: float = stats.get("attack_range", 2.0)

	# 检查是否需要撤退
	var retreat_percent: float = ai_behavior.get("retreat_health_percent", 0.0)
	if retreat_percent > 0.0 and current_health / max_health < retreat_percent:
		if current_state != AIState.RETREAT:
			_change_state(AIState.RETREAT)
		return

	# 检查是否可以使用技能
	if _should_use_ability():
		_change_state(AIState.USE_ABILITY)
		return

	# 根据距离决定状态
	if distance_to_target <= attack_range:
		if current_state != AIState.ATTACK:
			_change_state(AIState.ATTACK)
	elif distance_to_target <= aggro_radius:
		if current_state != AIState.CHASE:
			_change_state(AIState.CHASE)
	else:
		if current_state == AIState.CHASE:
			_change_state(AIState.IDLE)

func _change_state(new_state: AIState) -> void:
	current_state = new_state
	state_timer = 0.0

func _state_idle(delta: float) -> void:
	# 2 秒后开始巡逻
	if state_timer > 2.0:
		_change_state(AIState.PATROL)

func _state_patrol(delta: float) -> void:
	if patrol_wait_time > 0.0:
		patrol_wait_time -= delta
		return

	# 选择新的巡逻点
	if patrol_target == Vector3.ZERO or global_position.distance_to(patrol_target) < 1.0:
		patrol_target = global_position + Vector3(
			randf_range(-10.0, 10.0),
			0,
			randf_range(-10.0, 10.0)
		)
		patrol_wait_time = randf_range(1.0, 3.0)
		return

	# 移动到巡逻点
	var direction := (patrol_target - global_position).normalized()
	var move_speed: float = stats.get("move_speed", 3.0) * 0.5  # 巡逻时减速
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y -= 9.8 * delta  # 重力

func _state_chase(delta: float) -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var direction := (target.global_position - global_position).normalized()
	var move_speed: float = stats.get("move_speed", 4.0)

	# 根据 AI 类型调整行为
	var ai_type: String = ai_behavior.get("type", "aggressive_melee")
	if ai_type == "ranged_kiting":
		var keep_distance: float = ai_behavior.get("keep_distance", 8.0)
		var distance := global_position.distance_to(target.global_position)
		if distance < keep_distance:
			direction = -direction  # 后退

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y -= 9.8 * delta

func _state_attack(delta: float) -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	# 面向目标
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)

	# 攻击冷却
	if attack_timer <= 0.0:
		_perform_attack()
		var attack_cooldown: float = stats.get("attack_cooldown", 1.5)
		attack_timer = attack_cooldown

	velocity.y -= 9.8 * delta

func _state_retreat(delta: float) -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	# 远离目标
	var direction := (global_position - target.global_position).normalized()
	var move_speed: float = stats.get("move_speed", 4.0)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y -= 9.8 * delta

func _state_use_ability(delta: float) -> void:
	var ability := _get_ready_ability()
	if not ability:
		_change_state(AIState.CHASE)
		return

	# 使用技能
	_use_ability(ability)
	_change_state(AIState.CHASE)

func _perform_attack() -> void:
	if not target or not target.has_method("take_damage"):
		return

	var damage: float = stats.get("attack_damage", 20.0)
	target.take_damage(damage)

	print("[AdvancedEnemy] %s 攻击造成 %.0f 伤害" % [enemy_data.name, damage])

func _should_use_ability() -> bool:
	if not ai_behavior.has("special_abilities"):
		return false

	for ability in ai_behavior.special_abilities:
		if ability_cooldowns[ability.id] <= 0.0:
			return true

	return false

func _get_ready_ability():
	if not ai_behavior.has("special_abilities"):
		return null

	for ability in ai_behavior.special_abilities:
		if ability_cooldowns[ability.id] <= 0.0:
			return ability

	return null

func _use_ability(ability) -> void:
	var ability_id: String = ability.id
	var cooldown: float = ability.cooldown

	ability_cooldowns[ability_id] = cooldown
	ability_used.emit(ability_id)

	print("[AdvancedEnemy] %s 使用技能: %s" % [enemy_data.name, ability.name])

	# TODO: 实现具体技能效果

func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_health -= amount
	took_damage.emit(amount)

	print("[AdvancedEnemy] %s 受到 %.0f 伤害 (剩余 %.0f/%.0f)" % [
		enemy_data.name, amount, current_health, max_health
	])

	# 受击反馈
	_play_hit_feedback()

	if current_health <= 0.0:
		_die()
	else:
		# 受击后进入追击状态
		if current_state == AIState.IDLE or current_state == AIState.PATROL:
			_change_state(AIState.CHASE)

func _play_hit_feedback() -> void:
	# 闪白效果
	var visual := get_node_or_null("Visual") as MeshInstance3D
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector3(1.1, 1.1, 1.1), 0.1)
		tween.tween_property(visual, "scale", Vector3.ONE, 0.1)

func _die() -> void:
	is_dead = true
	died.emit()

	print("[AdvancedEnemy] %s 死亡" % enemy_data.name)

	# 死亡动画
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
