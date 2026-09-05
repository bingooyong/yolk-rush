extends CharacterBody3D
## 玩家控制器 - 集成所有游戏系统

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

# 玩家状态
var health: float = 100.0
var max_health: float = 100.0
var score: int = 0
var is_attacking: bool = false
var attack_cooldown: float = 0.0

# 战斗属性
var attack_damage: int = 20
var attack_range: float = 2.0
var attack_angle: float = 90.0

# 引用
@onready var camera: Camera3D = $Camera3D
@onready var attack_area: Area3D = $AttackArea

signal health_changed(current: float, maximum: float)
signal player_died()
signal score_changed(new_score: int)

func _ready() -> void:
	# 添加到玩家组
	add_to_group("player")

	# 捕获鼠标
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 设置玩家引用到系统
	if GameManager and GameManager.level_system:
		GameManager.level_system.set_player(self)

	# 更新最大生命值
	_update_stats()
	health = max_health

	print("[Player] Initialized - HP: %d/%d" % [health, max_health])

func _physics_process(delta: float) -> void:
	# 重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 跳跃
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 移动
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _input(event: InputEvent) -> void:
	# 鼠标视角
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# 攻击
	if event.is_action_pressed("attack") and attack_cooldown <= 0:
		_perform_attack()

	# 释放鼠标
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## 执行攻击
func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown = 1.0  # 1秒攻击间隔

	print("[Player] Attack! Damage: %d" % attack_damage)

	# 使用战斗系统执行近战攻击
	var hit_targets = CombatSystem.perform_melee_attack(self, attack_damage, attack_range, attack_angle)

	if hit_targets.size() > 0:
		print("[Player] Hit %d enemies" % hit_targets.size())
	else:
		print("[Player] Attack missed")

## 受到伤害
func take_damage(amount: float) -> void:
	health -= amount
	health = max(0, health)

	print("[Player] Took %d damage - HP: %d/%d" % [amount, health, max_health])
	health_changed.emit(health, max_health)

	if health <= 0:
		_die()

## 治疗
func heal(amount: float) -> void:
	health += amount
	health = min(health, max_health)

	print("[Player] Healed %d - HP: %d/%d" % [amount, health, max_health])
	health_changed.emit(health, max_health)

## 死亡
func _die() -> void:
	print("[Player] Died!")
	player_died.emit()

	# 重生或游戏结束
	await get_tree().create_timer(2.0).timeout
	_respawn()

## 重生
func _respawn() -> void:
	health = max_health
	global_position = Vector3(0, 2, 0)
	print("[Player] Respawned")
	health_changed.emit(health, max_health)

## 更新属性
func _update_stats() -> void:
	if not GameManager:
		max_health = 100.0
		return

	var stats = GameManager.get_total_player_stats()

	# 更新最大生命值
	var base_health = 100.0
	var vitality_bonus = stats.get("max_health", 0)
	max_health = base_health + vitality_bonus

	# 更新攻击力
	attack_damage = stats.get("physical_damage", 20)

	# 确保当前生命值不超过最大值
	health = min(health, max_health)

## 增加分数
func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
	print("[Player] Score: %d (+%d)" % [score, amount])

## 升级时更新属性
func _on_level_up(new_level: int) -> void:
	_update_stats()
	# 升级时恢复满血
	heal(max_health)

	print("[Player] Level up to %d! HP restored" % new_level)

## 使用物品
func use_item(item_id: String) -> void:
	var item = GameManager.item_database.get_item_by_id(item_id)
	if not item:
		return

	match item.item_type:
		"CONSUMABLE":
			_use_consumable(item)
		"MATERIAL":
			print("[Player] Cannot use material item")

func _use_consumable(item: Resource) -> void:
	# 生命药水
	if "health_potion" in item.item_id:
		var heal_amount = 0
		if "small" in item.item_id:
			heal_amount = 30
		elif "medium" in item.item_id:
			heal_amount = 60
		elif "large" in item.item_id:
			heal_amount = 100

		heal(heal_amount)
		print("[Player] Used %s, healed %d HP" % [item.item_name, heal_amount])
