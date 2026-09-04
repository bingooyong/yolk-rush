extends Node
class_name AnimationController
## 动画控制器：管理角色动画状态

enum AnimState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	HIT,
	DEATH
}

signal animation_changed(from_state: AnimState, to_state: AnimState)
signal attack_hit_frame()  ## 攻击命中帧信号

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree

var current_state: AnimState = AnimState.IDLE
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_duration: float = 0.6  ## 攻击动画时长

func _ready() -> void:
	print("[AnimationController] Ready")

func update_animation(velocity: Vector3, on_floor: bool) -> void:
	if is_attacking:
		return  ## 攻击动画优先，不能被打断

	var speed := Vector2(velocity.x, velocity.z).length()

	## 状态机
	var new_state := current_state

	if not on_floor:
		if velocity.y > 0.1:
			new_state = AnimState.JUMP
		else:
			new_state = AnimState.FALL
	elif speed > 0.1:
		if speed > 7.0:
			new_state = AnimState.RUN
		else:
			new_state = AnimState.WALK
	else:
		new_state = AnimState.IDLE

	if new_state != current_state:
		_change_state(new_state)

func play_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	attack_timer = 0.0
	_change_state(AnimState.ATTACK)

	## 0.3秒后发送命中帧信号
	await get_tree().create_timer(0.3).timeout
	attack_hit_frame.emit()

func play_hit() -> void:
	if is_attacking:
		return
	_change_state(AnimState.HIT)

func play_death() -> void:
	_change_state(AnimState.DEATH)

func _physics_process(delta: float) -> void:
	if is_attacking:
		attack_timer += delta
		if attack_timer >= attack_duration:
			is_attacking = false
			_change_state(AnimState.IDLE)

func _change_state(new_state: AnimState) -> void:
	if new_state == current_state:
		return

	var old_state := current_state
	current_state = new_state
	animation_changed.emit(old_state, new_state)

	## 播放动画（目前使用占位符，后续接入 AnimationTree）
	_play_placeholder_animation(new_state)

func _play_placeholder_animation(state: AnimState) -> void:
	match state:
		AnimState.IDLE:
			print("[AnimationController] → IDLE")
		AnimState.WALK:
			print("[AnimationController] → WALK")
		AnimState.RUN:
			print("[AnimationController] → RUN")
		AnimState.JUMP:
			print("[AnimationController] → JUMP")
		AnimState.FALL:
			print("[AnimationController] → FALL")
		AnimState.ATTACK:
			print("[AnimationController] → ATTACK")
		AnimState.HIT:
			print("[AnimationController] → HIT")
		AnimState.DEATH:
			print("[AnimationController] → DEATH")

## 获取当前状态名称
func get_state_name() -> String:
	return AnimState.keys()[current_state]
