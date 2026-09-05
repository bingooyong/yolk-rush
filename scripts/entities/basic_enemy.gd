extends CharacterBody3D
class_name BasicEnemy
## 基础敌人
## 最简单的敌人类型，会追踪并攻击玩家

const VFXManagerScript = preload("res://scripts/vfx/vfx_manager.gd")

signal died(enemy: BasicEnemy)
signal damaged(amount: int, remaining_hp: int)

## 敌人属性
@export var max_hp: int = 50
@export var current_hp: int = 50
@export var damage: int = 10
@export var move_speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 15.0

## 内部状态
var target: Node3D = null
var can_attack: bool = true
var is_dead: bool = false
var attack_timer: float = 0.0

## 视觉节点（占位符）
var visual_body: MeshInstance3D = null
var visual_head: MeshInstance3D = null

func _ready() -> void:
	# 创建占位符视觉（红色胶囊）
	_create_placeholder_visual()

	# 配置碰撞
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 1.5
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 0.75
	add_child(collision)

	# 配置物理
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(45)

	print("[BasicEnemy] Initialized: HP=%d, Damage=%d" % [max_hp, damage])

func _create_placeholder_visual() -> void:
	## 创建占位符视觉表现
	# 身体（红色胶囊）
	visual_body = MeshInstance3D.new()
	var body_mesh = CapsuleMesh.new()
	body_mesh.height = 1.5
	body_mesh.radius = 0.4
	visual_body.mesh = body_mesh

	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.8, 0.2, 0.2)  # 红色
	visual_body.material_override = body_material
	visual_body.position.y = 0.75
	add_child(visual_body)

	# 头部标记（深红色球体）
	visual_head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.25
	visual_head.mesh = head_mesh

	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.6, 0.1, 0.1)  # 深红色
	visual_head.material_override = head_material
	visual_head.position.y = 1.4
	add_child(visual_head)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 更新攻击冷却
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

	# 寻找目标（玩家）
	if target == null:
		_find_target()

	# AI行为
	if target and is_instance_valid(target):
		_pursue_target(delta)
	else:
		# 应用重力
		if not is_on_floor():
			velocity.y -= 20.0 * delta

	move_and_slide()

func _find_target() -> void:
	## 寻找玩家作为目标
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var distance = global_position.distance_to(player.global_position)
		if distance <= detection_range:
			target = player

func _pursue_target(delta: float) -> void:
	## 追踪目标
	if not is_instance_valid(target):
		target = null
		return

	var distance = global_position.distance_to(target.global_position)

	# 超出检测范围，放弃目标
	if distance > detection_range * 1.5:
		target = null
		return

	# 在攻击范围内
	if distance <= attack_range:
		_try_attack()
		# 停止移动，但应用重力
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		return

	# 追踪移动
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0.0  # 只在水平面移动

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# 应用重力
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	# 面向目标
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _try_attack() -> void:
	## 尝试攻击目标
	if not can_attack or not target:
		return

	# 执行攻击
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("[BasicEnemy] Attacked target for %d damage" % damage)

	# 进入冷却
	can_attack = false
	attack_timer = attack_cooldown

	# 攻击视觉反馈（红色闪烁）
	_flash_red()

func _flash_red() -> void:
	## 攻击时闪红光
	if visual_body:
		var material = visual_body.material_override as StandardMaterial3D
		if material:
			# 简单的颜色变化
			material.albedo_color = Color(1.0, 0.5, 0.5)
			await get_tree().create_timer(0.1).timeout
			if visual_body:
				material.albedo_color = Color(0.8, 0.2, 0.2)

## 受到伤害
func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	damaged.emit(amount, current_hp)

	print("[BasicEnemy] Took %d damage, HP: %d/%d" % [amount, current_hp, max_hp])

	# 播放受击粒子特效
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.play_hit_effect(global_position + Vector3(0, 0.75, 0))

	# 受击视觉反馈（白色闪烁）
	_flash_white()

	if current_hp <= 0:
		_die()

func _flash_white() -> void:
	## 受击时闪白光
	if visual_body:
		var material = visual_body.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color(1.0, 1.0, 1.0)
			await get_tree().create_timer(0.1).timeout
			if visual_body:
				material.albedo_color = Color(0.8, 0.2, 0.2)

func _die() -> void:
	## 死亡处理
	is_dead = true
	died.emit(self)

	print("[BasicEnemy] Died")

	# 播放死亡粒子特效
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.play_death_effect(global_position + Vector3(0, 0.75, 0))

	# 死亡动画（缩放消失）
	if visual_body:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
		tween.finished.connect(_on_death_animation_finished)

func _on_death_animation_finished() -> void:
	queue_free()

## 设置敌人等级（调整属性）
func set_level(level: int) -> void:
	max_hp = 50 + (level - 1) * 20
	current_hp = max_hp
	damage = 10 + (level - 1) * 5
	move_speed = 3.0 + (level - 1) * 0.2
	print("[BasicEnemy] Level set to %d (HP=%d, Damage=%d)" % [level, max_hp, damage])
