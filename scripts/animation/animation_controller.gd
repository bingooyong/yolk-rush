## Animation Controller
## 管理角色动画状态和过渡
## 集成 AnimationPlayer 和状态机逻辑
class_name AnimationController
extends Node

## 动画状态枚举
enum AnimState {
	IDLE,
	WALK,
	ATTACK,
	HIT,
	DEATH
}

## 组件引用
@onready var animation_player: AnimationPlayer
@onready var character_visual: Node3D

## 当前状态
var current_state: AnimState = AnimState.IDLE
var previous_state: AnimState = AnimState.IDLE

## 状态标志
var is_attacking: bool = false
var is_hit: bool = false
var is_dead: bool = false

## 动画配置
var animation_speed: float = 1.0
var blend_time: float = 0.2

## 信号
signal animation_finished(anim_name: String)
signal attack_frame_hit()  # 攻击动画的打击帧

func _ready() -> void:
	_setup_animation_player()
	_connect_signals()

func _setup_animation_player() -> void:
	## 查找 AnimationPlayer
	animation_player = _find_animation_player(get_parent())

	if not animation_player:
		push_error("AnimationController: AnimationPlayer not found")
		return

	## 设置初始状态
	play_animation("idle")

func _find_animation_player(node: Node) -> AnimationPlayer:
	## 递归查找 AnimationPlayer
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var result = _find_animation_player(child)
		if result:
			return result

	return null

func _connect_signals() -> void:
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

## 更新动画状态（从 MovementController 调用）
func update_animation(velocity: Vector3, is_grounded: bool) -> void:
	if is_dead:
		return

	## 受击状态优先级最高
	if is_hit:
		return

	## 攻击状态优先级第二
	if is_attacking:
		return

	## 根据移动速度决定动画
	var speed := velocity.length()

	if not is_grounded:
		## 空中状态（暂时用 idle）
		change_state(AnimState.IDLE)
	elif speed > 0.1:
		## 行走状态
		change_state(AnimState.WALK)
	else:
		## 待机状态
		change_state(AnimState.IDLE)

## 改变动画状态
func change_state(new_state: AnimState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	match current_state:
		AnimState.IDLE:
			play_animation("idle")
		AnimState.WALK:
			play_animation("walk")
		AnimState.ATTACK:
			play_animation("attack")
		AnimState.HIT:
			play_animation("hit")
		AnimState.DEATH:
			play_animation("death")

## 播放动画
func play_animation(anim_name: String, custom_speed: float = 1.0) -> void:
	if not animation_player:
		return

	if not animation_player.has_animation(anim_name):
		push_warning("Animation '%s' not found" % anim_name)
		return

	animation_player.play(anim_name, blend_time, custom_speed * animation_speed)

## 触发攻击
func trigger_attack() -> void:
	if is_attacking or is_hit or is_dead:
		return

	is_attacking = true
	change_state(AnimState.ATTACK)

## 触发受击
func trigger_hit() -> void:
	if is_dead:
		return

	is_hit = true
	is_attacking = false
	change_state(AnimState.HIT)

## 触发死亡
func trigger_death() -> void:
	is_dead = true
	is_attacking = false
	is_hit = false
	change_state(AnimState.DEATH)

## 动画完成回调
func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)

	match anim_name:
		"attack":
			is_attacking = false
			change_state(AnimState.IDLE)
		"hit":
			is_hit = false
			change_state(AnimState.IDLE)
		"death":
			## 死亡动画播放完毕后保持
			pass

## 获取当前动画进度（用于攻击判定）
func get_animation_progress() -> float:
	if not animation_player or not animation_player.is_playing():
		return 0.0
	return animation_player.current_animation_position / animation_player.current_animation_length

## 检查是否在攻击的打击帧（通常在 40%-60% 之间）
func is_in_hit_frame() -> bool:
	if current_state != AnimState.ATTACK:
		return false

	var progress := get_animation_progress()
	return progress >= 0.4 and progress <= 0.6
