extends CharacterBody3D
class_name PlayerController
## 玩家控制器 - 3D 角色移动和战斗

# 移动参数
const SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const ACCELERATION = 10.0
const FRICTION = 8.0
const AIR_CONTROL = 0.3

# 战斗参数
var base_attack_damage = 10.0
var attack_cooldown = 1.0
var can_attack = true

# 技能参数
var active_skills = []
var skill_cooldowns = {}

# 组件引用
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: MeshInstance3D = $PlayerMesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

# 相机参数
var mouse_sensitivity = 0.002
var camera_x_rotation = 0.0

# 状态
var is_sprinting = false
var is_attacking = false

func _ready():
	# 捕获鼠标
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 连接到 GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.is_initialized:
			_connect_to_game_manager()
		else:
			game_manager.game_initialized.connect(_connect_to_game_manager)

	print("[PlayerController] Initialized")

func _connect_to_game_manager():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return

	# 设置玩家引用
	if game_manager.level_system:
		game_manager.level_system.set_player(self)
	if game_manager.equipment_system:
		game_manager.equipment_system.set_player(self)

	print("[PlayerController] Connected to GameManager")

func _input(event):
	# 鼠标视角控制
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# 水平旋转（玩家本体）
		rotate_y(-event.relative.x * mouse_sensitivity)

		# 垂直旋转（相机枢轴）
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, -PI/2, PI/2)
		if camera_pivot:
			camera_pivot.rotation.x = camera_x_rotation

	# 切换鼠标捕获
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# 重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 冲刺
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor()

	# 移动输入
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 计算目标速度
	var target_speed = SPRINT_SPEED if is_sprinting else SPEED
	var control_factor = AIR_CONTROL if not is_on_floor() else 1.0

	if direction:
		# 加速
		var acceleration_rate = ACCELERATION * control_factor
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration_rate * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration_rate * delta)
	else:
		# 摩擦力
		var friction_rate = FRICTION if is_on_floor() else FRICTION * AIR_CONTROL
		velocity.x = move_toward(velocity.x, 0, friction_rate * delta)
		velocity.z = move_toward(velocity.z, 0, friction_rate * delta)

	# 攻击
	if Input.is_action_pressed("attack") and can_attack and not is_attacking:
		_perform_attack()

	# 使用技能（1-8 对应快捷栏）
	for i in range(8):
		if Input.is_action_just_pressed("use_skill_%d" % (i + 1)):
			_use_quick_bar_skill(i)

	move_and_slide()

	# 更新动画状态
	_update_animation_state()

func _update_animation_state():
	if not animation_player:
		return

	var speed = Vector2(velocity.x, velocity.z).length()

	if not is_on_floor():
		if animation_player.has_animation("jump"):
			animation_player.play("jump")
	elif is_attacking:
		# 攻击动画由 _perform_attack 控制
		pass
	elif speed > 0.1:
		if is_sprinting:
			if animation_player.has_animation("sprint"):
				animation_player.play("sprint")
		else:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")
	else:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

func _perform_attack():
	is_attacking = true
	can_attack = false

	# 播放攻击动画
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")

	# 计算总伤害（基础 + 装备 + 属性）
	var total_damage = base_attack_damage

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# 装备加成
		if game_manager.equipment_system:
			var equipment_stats = game_manager.equipment_system.get_total_stats()
			total_damage += equipment_stats.get("physical_damage", 0)

		# 属性加成
		if game_manager.stats_system:
			var stat_bonus = game_manager.stats_system.get_stat_bonus("physical_damage")
			total_damage += stat_bonus

	# 检测攻击范围内的敌人
	_deal_damage_to_nearby_enemies(total_damage)

	# 冷却
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	is_attacking = false

func _deal_damage_to_nearby_enemies(damage: float):
	# 射线检测前方的敌人
	var space_state = get_world_3d().direct_space_state
	var attack_range = 2.0
	var attack_direction = -global_transform.basis.z

	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		global_position + Vector3.UP + attack_direction * attack_range
	)
	query.collision_mask = 4  # 敌人层（Layer 3）

	var result = space_state.intersect_ray(query)

	if result:
		var enemy = result.collider
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			print("[PlayerController] Hit enemy for %.1f damage" % damage)

func _use_quick_bar_skill(slot_index: int):
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.quick_bar_system:
		return

	# 使用快捷栏物品/技能
	var success = game_manager.quick_bar_system.use_quick_bar_item(slot_index)

	if success:
		print("[PlayerController] Used quick bar slot %d" % slot_index)

## 受到伤害
func take_damage(damage: float):
	print("[PlayerController] Took %.1f damage" % damage)

	# TODO: 实现生命值系统
	# if has_node("HealthComponent"):
	#     $HealthComponent.take_damage(damage)

## 治疗
func heal(amount: float):
	print("[PlayerController] Healed %.1f HP" % amount)

	# TODO: 实现生命值系统

## 获取玩家统计
func get_player_stats() -> Dictionary:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		return game_manager.get_total_player_stats()
	return {}

## 调试：传送到位置
func _debug_teleport(pos: Vector3):
	global_position = pos
	velocity = Vector3.ZERO
