extends Node
class_name CombatSystem
## 战斗系统：管理攻击、伤害判定、连击

signal attack_started()
signal attack_hit(target: Node, damage: float)
signal attack_missed()
signal combo_increased(combo_count: int)
signal combo_broken()

@export var base_damage: float = 15.0
@export var attack_cooldown: float = 0.6  ## 攻击冷却时间
@export var attack_range: float = 2.0  ## 攻击范围
@export var combo_window: float = 1.5  ## 连击窗口时间

var can_attack: bool = true
var attack_timer: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0

var parent_character: CharacterBody3D

func _ready() -> void:
	parent_character = get_parent() as CharacterBody3D
	print("[CombatSystem] Ready - Damage: %.1f, Range: %.1fm" % [base_damage, attack_range])

func _physics_process(delta: float) -> void:
	## 更新攻击冷却
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

	## 更新连击计时
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			_reset_combo()

func try_attack() -> bool:
	if not can_attack or not parent_character:
		return false

	## 开始攻击
	can_attack = false
	attack_timer = attack_cooldown
	attack_started.emit()

	## 播放攻击动画
	var anim_controller := _get_animation_controller()
	if anim_controller:
		anim_controller.play_attack()
		## 等待命中帧信号
		if not anim_controller.attack_hit_frame.is_connected(_on_attack_hit_frame):
			anim_controller.attack_hit_frame.connect(_on_attack_hit_frame)

	print("[CombatSystem] Attack started")
	return true

func _on_attack_hit_frame() -> void:
	## 在攻击命中帧检测敌人
	var targets := _find_targets_in_range()

	if targets.is_empty():
		attack_missed.emit()
		print("[CombatSystem] Attack missed")
		return

	## 计算伤害（连击加成）
	var damage := base_damage * (1.0 + combo_count * 0.1)

	## 对所有目标造成伤害
	for target in targets:
		_apply_damage_to_target(target, damage)

	## 增加连击
	combo_count += 1
	combo_timer = combo_window
	combo_increased.emit(combo_count)
	print("[CombatSystem] Combo x%d" % combo_count)

func _find_targets_in_range() -> Array:
	if not parent_character:
		return []

	var targets: Array = []
	var space_state := parent_character.get_world_3d().direct_space_state
	var origin := parent_character.global_position + Vector3.UP * 0.5

	## 获取角色朝向
	var forward := -parent_character.global_transform.basis.z
	var target_pos := origin + forward * attack_range

	## 球形检测范围内的敌人
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = attack_range * 0.8
	query.shape = shape
	query.transform = Transform3D(Basis(), target_pos)
	query.collision_mask = 2  ## Layer 2 = 敌人层

	var results := space_state.intersect_shape(query, 10)

	for result in results:
		var collider := result.collider
		if collider != parent_character and collider.has_method("take_damage"):
			targets.append(collider)

	return targets

func _apply_damage_to_target(target: Node, damage: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, parent_character)
		attack_hit.emit(target, damage)
		print("[CombatSystem] Hit %s for %.1f damage" % [target.name, damage])

func on_hit() -> void:
	## 受击时重置连击
	_reset_combo()

func _reset_combo() -> void:
	if combo_count > 0:
		combo_broken.emit()
		print("[CombatSystem] Combo broken")
	combo_count = 0
	combo_timer = 0.0

func _get_animation_controller() -> AnimationController:
	if parent_character and parent_character.has_node("AnimationController"):
		return parent_character.get_node("AnimationController") as AnimationController
	return null

## 获取当前伤害（包含连击加成）
func get_current_damage() -> float:
	return base_damage * (1.0 + combo_count * 0.1)
