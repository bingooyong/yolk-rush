extends Node
class_name PlayerVFXIntegration
## 玩家粒子效果集成
## 为玩家动作添加视觉反馈

signal vfx_triggered(effect_name: String)

## 引用
var player: CharacterBody3D
var vfx_emitter: Node3D  # VFXEmitter

## 状态追踪
var was_on_floor: bool = false
var was_moving: bool = false
var dash_trail_effect: GPUParticles3D = null

## 配置
@export var enable_jump_dust: bool = true
@export var enable_land_impact: bool = true
@export var enable_dash_trail: bool = true
@export var enable_hit_spark: bool = true

func _ready() -> void:
	# 等待父节点初始化
	await get_tree().process_frame

	# 获取玩家引用
	player = get_parent() as CharacterBody3D
	if not player:
		push_error("[PlayerVFXIntegration] Must be child of CharacterBody3D (Player)")
		return

	# 创建VFXEmitter
	_setup_vfx_emitter()

	# 连接玩家信号
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

	print("[PlayerVFXIntegration] Initialized")

func _setup_vfx_emitter() -> void:
	# 加载VFXEmitter脚本
	var vfx_script = load("res://scripts/vfx/vfx_emitter.gd")
	if not vfx_script:
		push_warning("[PlayerVFXIntegration] VFXEmitter script not found")
		return

	# 创建VFXEmitter节点
	vfx_emitter = Node3D.new()
	vfx_emitter.name = "VFXEmitter"
	vfx_emitter.set_script(vfx_script)
	player.add_child(vfx_emitter)

	print("[PlayerVFXIntegration] VFXEmitter created")

func _physics_process(_delta: float) -> void:
	if not player or not vfx_emitter:
		return

	# 检测跳跃（离开地面）
	if enable_jump_dust and was_on_floor and not player.is_on_floor():
		if player.velocity.y > 0:  # 向上运动 = 跳跃
			_play_jump_effect()

	# 检测着陆（回到地面）
	if enable_land_impact and not was_on_floor and player.is_on_floor():
		if player.velocity.y < -2.0:  # 有一定下落速度
			_play_land_effect()

	# 检测移动状态（用于未来的冲刺效果）
	var is_moving = player.velocity.length() > 0.5
	if is_moving != was_moving:
		was_moving = is_moving

	# 更新地面状态
	was_on_floor = player.is_on_floor()

## 跳跃效果
func _play_jump_effect() -> void:
	if not vfx_emitter:
		return

	# 在脚下位置播放灰尘粒子
	var foot_pos = player.global_position
	foot_pos.y -= 0.9  # 脚部偏移

	vfx_emitter.global_position = foot_pos
	vfx_emitter.trigger_effect("ambient_dust", Vector3.UP, 0.8)

	vfx_triggered.emit("jump_dust")
	print("[PlayerVFX] Jump dust")

## 着陆效果
func _play_land_effect() -> void:
	if not vfx_emitter:
		return

	# 在脚下位置播放冲击波
	var foot_pos = player.global_position
	foot_pos.y -= 0.9

	vfx_emitter.global_position = foot_pos
	vfx_emitter.trigger_effect("impact_wave", Vector3.UP, 1.0)
	vfx_emitter.trigger_effect("ambient_dust", Vector3.UP, 1.2)

	vfx_triggered.emit("land_impact")
	print("[PlayerVFX] Land impact")

## 冲刺轨迹（由外部调用，如技能系统）
func play_dash_trail() -> GPUParticles3D:
	if not vfx_emitter or not enable_dash_trail:
		return null

	# 启动持续轨迹效果
	dash_trail_effect = vfx_emitter.play_skill_trail()

	vfx_triggered.emit("dash_trail")
	print("[PlayerVFX] Dash trail started")

	return dash_trail_effect

## 停止冲刺轨迹
func stop_dash_trail() -> void:
	if dash_trail_effect and vfx_emitter:
		vfx_emitter.stop_continuous_effect(dash_trail_effect)
		dash_trail_effect = null
		print("[PlayerVFX] Dash trail stopped")

## 受击火花
func play_hit_effect(hit_direction: Vector3 = Vector3.UP) -> void:
	if not vfx_emitter or not enable_hit_spark:
		return

	# 在玩家中心位置播放火花
	vfx_emitter.global_position = player.global_position
	vfx_emitter.play_collision_effect(hit_direction)

	vfx_triggered.emit("hit_spark")
	print("[PlayerVFX] Hit spark")

## 攻击特效（由玩家攻击时调用）
func play_attack_effect() -> void:
	if not vfx_emitter:
		return

	# 在玩家前方播放攻击特效
	var forward_pos = player.global_position + player.global_transform.basis.z * -1.5
	vfx_emitter.global_position = forward_pos
	vfx_emitter.trigger_effect("skill_explosion", Vector3.UP, 0.8)

	vfx_triggered.emit("attack")
	print("[PlayerVFX] Attack effect")

## 技能充能效果
func play_skill_charge() -> GPUParticles3D:
	if not vfx_emitter:
		return null

	vfx_emitter.global_position = player.global_position
	var effect = vfx_emitter.play_skill_charge()

	vfx_triggered.emit("skill_charge")
	print("[PlayerVFX] Skill charge")

	return effect

## 技能释放效果
func play_skill_release(direction: Vector3 = Vector3.FORWARD) -> void:
	if not vfx_emitter:
		return

	vfx_emitter.global_position = player.global_position
	vfx_emitter.play_skill_release(direction)

	vfx_triggered.emit("skill_release")
	print("[PlayerVFX] Skill release")

## 生命值变化响应
func _on_player_health_changed(current: float, maximum: float) -> void:
	# 如果受伤，播放受击特效
	if current < maximum:
		# 延迟一帧，确保是受伤而不是治疗
		await get_tree().process_frame
		if player and player.health < maximum:
			play_hit_effect()

## 清理
func _exit_tree() -> void:
	stop_dash_trail()

	if vfx_emitter and vfx_emitter.has_method("stop_all_continuous_effects"):
		vfx_emitter.stop_all_continuous_effects()
