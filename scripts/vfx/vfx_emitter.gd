extends Node3D
class_name VFXEmitter
## VFX发射器 - 附加到游戏对象上自动触发粒子效果

signal effect_triggered(effect_name: String)

## 效果配置
@export var auto_trigger_on_ready: bool = false
@export var default_effect: String = ""
@export var trigger_on_collision: bool = false
@export var trigger_on_pickup: bool = false

## 粒子效果管理器引用
var particle_manager: Node = null

## 当前播放的持续效果
var continuous_effects: Array[GPUParticles3D] = []

func _ready() -> void:
	# 获取粒子管理器
	particle_manager = _find_particle_manager()

	if not particle_manager:
		push_warning("[VFXEmitter] ParticleEffectManager not found")
		return

	# 自动触发
	if auto_trigger_on_ready and default_effect != "":
		trigger_effect(default_effect)

## 查找粒子管理器
func _find_particle_manager() -> Node:
	# 尝试从场景树查找
	var tree = get_tree()
	if tree and tree.root:
		var manager = tree.root.find_child("ParticleEffectManager", true, false)
		if manager:
			return manager

	return null

## 触发粒子效果
func trigger_effect(effect_name: String, direction: Vector3 = Vector3.UP, scale: float = 1.0) -> GPUParticles3D:
	if not particle_manager:
		return null

	var effect = particle_manager.spawn_effect(effect_name, global_position, direction, scale)

	if effect:
		effect_triggered.emit(effect_name)

	return effect

## 触发持续粒子效果（不自动停止）
func start_continuous_effect(effect_name: String, direction: Vector3 = Vector3.UP, scale: float = 1.0) -> GPUParticles3D:
	if not particle_manager:
		return null

	var effect = particle_manager.spawn_effect(effect_name, global_position, direction, scale)

	if effect:
		continuous_effects.append(effect)
		effect_triggered.emit(effect_name)

	return effect

## 停止持续效果
func stop_continuous_effect(effect: GPUParticles3D) -> void:
	if effect and effect in continuous_effects:
		particle_manager.stop_effect(effect)
		continuous_effects.erase(effect)

## 停止所有持续效果
func stop_all_continuous_effects() -> void:
	for effect in continuous_effects:
		particle_manager.stop_effect(effect)
	continuous_effects.clear()

## 便捷方法 - 道具拾取特效
func play_pickup_effect() -> void:
	trigger_effect("pickup_flash")
	trigger_effect("pickup_sparkle")

## 便捷方法 - 碰撞特效
func play_collision_effect(impact_direction: Vector3 = Vector3.UP) -> void:
	trigger_effect("collision_spark", impact_direction)
	trigger_effect("impact_wave")

## 便捷方法 - 技能充能
func play_skill_charge() -> GPUParticles3D:
	return start_continuous_effect("skill_charge")

## 便捷方法 - 技能释放
func play_skill_release(direction: Vector3 = Vector3.FORWARD) -> void:
	stop_all_continuous_effects()
	trigger_effect("skill_explosion")

## 便捷方法 - 技能轨迹
func play_skill_trail() -> GPUParticles3D:
	return start_continuous_effect("skill_trail", Vector3.DOWN)

func _exit_tree() -> void:
	stop_all_continuous_effects()
