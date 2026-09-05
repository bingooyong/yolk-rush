extends Node
class_name CombatVFXIntegration
## 战斗粒子效果集成
## 为战斗系统添加视觉反馈

signal vfx_triggered(effect_name: String, position: Vector3)

## 引用
var vfx_emitter: Node3D
var parent_node: Node3D

## 配置
@export var enable_attack_effects: bool = true
@export var enable_hit_effects: bool = true
@export var enable_death_effects: bool = true
@export var enable_skill_effects: bool = true

func _ready() -> void:
	await get_tree().process_frame

	parent_node = get_parent() as Node3D
	if not parent_node:
		push_error("[CombatVFXIntegration] Must be child of Node3D")
		return

	# 创建VFXEmitter
	_setup_vfx_emitter()

	# 尝试连接战斗信号
	_connect_combat_signals()

	print("[CombatVFXIntegration] Initialized for %s" % parent_node.name)

func _setup_vfx_emitter() -> void:
	var vfx_script = load("res://scripts/vfx/vfx_emitter.gd")
	if not vfx_script:
		push_warning("[CombatVFXIntegration] VFXEmitter script not found")
		return

	vfx_emitter = Node3D.new()
	vfx_emitter.name = "VFXEmitter"
	vfx_emitter.set_script(vfx_script)
	parent_node.add_child(vfx_emitter)

func _connect_combat_signals() -> void:
	# 尝试连接常见的战斗信号
	if parent_node.has_signal("attacked"):
		parent_node.attacked.connect(_on_attacked)

	if parent_node.has_signal("hit_taken"):
		parent_node.hit_taken.connect(_on_hit_taken)

	if parent_node.has_signal("died"):
		parent_node.died.connect(_on_died)

	if parent_node.has_signal("skill_cast"):
		parent_node.skill_cast.connect(_on_skill_cast)

## 攻击特效
func play_attack_effect(target_position: Vector3 = Vector3.ZERO) -> void:
	if not vfx_emitter or not enable_attack_effects:
		return

	# 在攻击方向播放特效
	var attack_pos = parent_node.global_position
	if target_position != Vector3.ZERO:
		var direction = (target_position - attack_pos).normalized()
		attack_pos += direction * 1.0

	vfx_emitter.global_position = attack_pos
	vfx_emitter.trigger_effect("collision_spark", Vector3.UP, 0.8)

	vfx_triggered.emit("attack", attack_pos)
	print("[CombatVFX] Attack effect at %s" % parent_node.name)

## 受击特效
func play_hit_effect(hit_direction: Vector3 = Vector3.UP) -> void:
	if not vfx_emitter or not enable_hit_effects:
		return

	# 在受击位置播放火花
	vfx_emitter.global_position = parent_node.global_position
	vfx_emitter.play_collision_effect(hit_direction)

	vfx_triggered.emit("hit", parent_node.global_position)
	print("[CombatVFX] Hit effect on %s" % parent_node.name)

## 死亡特效
func play_death_effect() -> void:
	if not vfx_emitter or not enable_death_effects:
		return

	# 大爆炸效果
	vfx_emitter.global_position = parent_node.global_position
	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, 1.5)
	vfx_emitter.trigger_effect("collision_debris", Vector3.UP, 1.2)

	vfx_triggered.emit("death", parent_node.global_position)
	print("[CombatVFX] Death effect for %s" % parent_node.name)

## 技能充能特效
func play_skill_charge() -> GPUParticles3D:
	if not vfx_emitter or not enable_skill_effects:
		return null

	vfx_emitter.global_position = parent_node.global_position
	var effect = vfx_emitter.play_skill_charge()

	vfx_triggered.emit("skill_charge", parent_node.global_position)
	print("[CombatVFX] Skill charge on %s" % parent_node.name)

	return effect

## 技能释放特效
func play_skill_release(direction: Vector3 = Vector3.FORWARD) -> void:
	if not vfx_emitter or not enable_skill_effects:
		return

	vfx_emitter.global_position = parent_node.global_position
	vfx_emitter.play_skill_release(direction)

	vfx_triggered.emit("skill_release", parent_node.global_position)
	print("[CombatVFX] Skill release on %s" % parent_node.name)

## 技能命中特效
func play_skill_hit_effect(hit_position: Vector3) -> void:
	if not vfx_emitter or not enable_skill_effects:
		return

	vfx_emitter.global_position = hit_position
	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, 1.0)
	vfx_emitter.trigger_effect("impact_wave", Vector3.UP, 0.8)

	vfx_triggered.emit("skill_hit", hit_position)
	print("[CombatVFX] Skill hit at position")

## 信号回调
func _on_attacked() -> void:
	play_attack_effect()

func _on_hit_taken(_damage: float, _attacker: Node = null) -> void:
	play_hit_effect()

func _on_died() -> void:
	play_death_effect()

func _on_skill_cast(skill_name: String) -> void:
	play_skill_release()

## 清理
func _exit_tree() -> void:
	if vfx_emitter and vfx_emitter.has_method("stop_all_continuous_effects"):
		vfx_emitter.stop_all_continuous_effects()
