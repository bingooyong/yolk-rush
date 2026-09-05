extends Node3D
class_name LevelVFXIntegration
## 关卡环境粒子效果集成
## 为关卡添加氛围粒子和事件特效

signal checkpoint_activated(checkpoint_id: int)
signal level_complete()

## 引用
var vfx_emitter: Node3D
var ambient_effects: Array[GPUParticles3D] = []

## 配置
@export var enable_ambient_particles: bool = true
@export var ambient_type: String = "dust"  # "dust", "snow", "rain"
@export var enable_checkpoint_effects: bool = true
@export var enable_level_complete_effects: bool = true

func _ready() -> void:
	# 创建VFXEmitter
	_setup_vfx_emitter()

	# 启动环境粒子
	if enable_ambient_particles:
		_play_ambient_particles()

	print("[LevelVFXIntegration] Initialized - Ambient: %s" % ambient_type)

func _setup_vfx_emitter() -> void:
	var vfx_script = load("res://scripts/vfx/vfx_emitter.gd")
	if not vfx_script:
		push_warning("[LevelVFXIntegration] VFXEmitter script not found")
		return

	vfx_emitter = Node3D.new()
	vfx_emitter.name = "VFXEmitter"
	vfx_emitter.set_script(vfx_script)
	add_child(vfx_emitter)

func _play_ambient_particles() -> void:
	if not vfx_emitter:
		return

	await get_tree().process_frame

	# 根据类型播放不同的环境粒子
	var effect_name = ""
	match ambient_type:
		"dust":
			effect_name = "ambient_dust"
		"snow":
			effect_name = "snow_fall"
		"rain":
			effect_name = "rain_drop"
		_:
			effect_name = "ambient_dust"

	# 启动持续环境效果
	var effect = vfx_emitter.start_continuous_effect(effect_name, Vector3.DOWN, 2.0)
	if effect:
		ambient_effects.append(effect)
		print("[LevelVFX] Ambient particles started: %s" % ambient_type)

## 检查点激活特效
func play_checkpoint_effect(checkpoint_position: Vector3, checkpoint_id: int = 0) -> void:
	if not vfx_emitter or not enable_checkpoint_effects:
		return

	# 在检查点位置播放激活特效
	vfx_emitter.global_position = checkpoint_position
	vfx_emitter.trigger_effect("pickup_flash", Vector3.UP, 1.5)
	vfx_emitter.trigger_effect("pickup_sparkle", Vector3.UP, 1.2)
	vfx_emitter.trigger_effect("impact_wave", Vector3.UP, 1.0)

	checkpoint_activated.emit(checkpoint_id)
	print("[LevelVFX] Checkpoint %d activated at %s" % [checkpoint_id, checkpoint_position])

## 关卡完成特效
func play_level_complete_effect(complete_position: Vector3) -> void:
	if not vfx_emitter or not enable_level_complete_effects:
		return

	# 大型庆祝特效
	vfx_emitter.global_position = complete_position

	# 连续播放多个特效
	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, 2.0)
	await get_tree().create_timer(0.2).timeout

	vfx_emitter.trigger_effect("pickup_flash", Vector3.UP, 2.5)
	await get_tree().create_timer(0.2).timeout

	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, 1.8)

	level_complete.emit()
	print("[LevelVFX] Level complete effect at %s" % complete_position)

## 障碍物碰撞特效
func play_obstacle_collision_effect(collision_position: Vector3, collision_normal: Vector3) -> void:
	if not vfx_emitter:
		return

	vfx_emitter.global_position = collision_position
	vfx_emitter.play_collision_effect(collision_normal)

	print("[LevelVFX] Obstacle collision effect")

## 爆炸特效（用于关卡事件）
func play_explosion_effect(explosion_position: Vector3, scale: float = 1.0) -> void:
	if not vfx_emitter:
		return

	vfx_emitter.global_position = explosion_position
	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, scale)
	vfx_emitter.trigger_effect("collision_debris", Vector3.UP, scale * 0.8)

	print("[LevelVFX] Explosion effect at %s (scale: %.1f)" % [explosion_position, scale])

## 传送门特效
func play_portal_effect(portal_position: Vector3) -> GPUParticles3D:
	if not vfx_emitter:
		return null

	vfx_emitter.global_position = portal_position
	var effect = vfx_emitter.start_continuous_effect("skill_charge", Vector3.UP, 1.5)

	if effect:
		ambient_effects.append(effect)
		print("[LevelVFX] Portal effect started")

	return effect

## 停止传送门特效
func stop_portal_effect(effect: GPUParticles3D) -> void:
	if effect and vfx_emitter:
		vfx_emitter.stop_continuous_effect(effect)
		ambient_effects.erase(effect)
		print("[LevelVFX] Portal effect stopped")

## 切换环境粒子类型
func change_ambient_type(new_type: String) -> void:
	# 停止当前环境粒子
	_stop_ambient_particles()

	# 切换类型
	ambient_type = new_type

	# 启动新的环境粒子
	if enable_ambient_particles:
		_play_ambient_particles()

	print("[LevelVFX] Ambient changed to: %s" % new_type)

## 停止环境粒子
func _stop_ambient_particles() -> void:
	if not vfx_emitter:
		return

	for effect in ambient_effects:
		vfx_emitter.stop_continuous_effect(effect)

	ambient_effects.clear()

## 清理
func _exit_tree() -> void:
	_stop_ambient_particles()

	if vfx_emitter and vfx_emitter.has_method("stop_all_continuous_effects"):
		vfx_emitter.stop_all_continuous_effects()
