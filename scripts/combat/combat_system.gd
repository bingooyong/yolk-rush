## Combat System
## 管理角色的战斗行为：攻击、技能、连击等
## 与 AnimationController 和 HealthComponent 协作
class_name CombatSystem
extends Node

## 组件引用
var animation_controller: AnimationController
var health_component: HealthComponent
var character: CharacterBody3D

## 攻击配置
@export var base_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 0.5
@export var combo_window: float = 0.8  # 连击窗口时间

## 状态
var can_attack: bool = true
var attack_cooldown_timer: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0

## HitBox 配置
var hitbox_scene: PackedScene = null
var active_hitbox: HitBox = null

## 信号
signal attack_started()
signal attack_hit(target: Node)
signal combo_increased(count: int)
signal combat_state_changed(can_attack: bool)

func _ready() -> void:
	_find_components()
	_load_resources()

func _process(delta: float) -> void:
	## 更新冷却时间
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true
			combat_state_changed.emit(true)

	## 更新连击窗口
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			reset_combo()

func _find_components() -> void:
	## 查找父节点（角色）
	character = get_parent() as CharacterBody3D
	if not character:
		push_error("CombatSystem: Parent must be CharacterBody3D")
		return

	## 查找动画控制器
	animation_controller = character.find_child("AnimationController", false, false) as AnimationController
	if animation_controller:
		animation_controller.animation_finished.connect(_on_animation_finished)

	## 查找生命值组件
	health_component = character.find_child("HealthComponent", false, false) as HealthComponent
	if health_component:
		health_component.died.connect(_on_died)

func _load_resources() -> void:
	## 这里可以加载 HitBox 预制场景
	## 暂时先用代码创建
	pass

## 尝试攻击
func try_attack() -> bool:
	if not can_attack:
		return false

	if health_component and health_component.is_dead:
		return false

	## 执行攻击
	perform_attack()
	return true

## 执行攻击
func perform_attack() -> void:
	## 触发动画
	if animation_controller:
		animation_controller.trigger_attack()

	## 进入冷却
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	combat_state_changed.emit(false)

	## 增加连击计数
	combo_count += 1
	combo_timer = combo_window
	combo_increased.emit(combo_count)

	## 创建 HitBox
	create_hitbox()

	attack_started.emit()

## 创建攻击判定 HitBox
func create_hitbox() -> void:
	## 清理旧的 HitBox
	if active_hitbox:
		active_hitbox.queue_free()

	## 创建新的 HitBox
	active_hitbox = HitBox.new()
	active_hitbox.damage = calculate_damage()
	active_hitbox.knockback_force = 5.0
	active_hitbox.hit_once = false
	active_hitbox.lifetime = 0.3  # 攻击判定持续 0.3 秒

	## 添加碰撞形状
	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(attack_range, 1.0, attack_range)
	collision_shape.shape = shape
	active_hitbox.add_child(collision_shape)

	## 设置位置（角色前方）
	active_hitbox.position = character.global_position + character.global_transform.basis.z * (attack_range * 0.5)

	## 设置所有者
	active_hitbox.set_owner_node(character)
	active_hitbox.hit_target.connect(_on_hit_target)

	## 添加到场景
	get_tree().root.add_child(active_hitbox)

## 计算伤害（基础伤害 + 连击加成）
func calculate_damage() -> float:
	var combo_multiplier := 1.0 + (combo_count - 1) * 0.2  # 每次连击增加 20% 伤害
	return base_damage * combo_multiplier

## 重置连击
func reset_combo() -> void:
	if combo_count > 0:
		combo_count = 0

## 被击中时调用（从 HealthComponent 接收）
func on_hit() -> void:
	if animation_controller:
		animation_controller.trigger_hit()

	## 打断连击
	reset_combo()

	## 重置攻击状态
	can_attack = false
	attack_cooldown_timer = attack_cooldown * 0.5  # 受击后冷却时间减半

## 动画完成回调
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		## 攻击动画结束，清理 HitBox
		if active_hitbox:
			active_hitbox.queue_free()
			active_hitbox = null

## 击中目标回调
func _on_hit_target(target: Node) -> void:
	attack_hit.emit(target)
	print("Hit target: %s, Damage: %.1f, Combo: %d" % [target.name, calculate_damage(), combo_count])

## 死亡回调
func _on_died() -> void:
	can_attack = false
	reset_combo()

	if animation_controller:
		animation_controller.trigger_death()

## 获取当前是否可以攻击
func is_ready_to_attack() -> bool:
	return can_attack and not (health_component and health_component.is_dead)

## 获取连击数
func get_combo_count() -> int:
	return combo_count
