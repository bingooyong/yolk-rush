extends Node
## Movement Controller: 处理角色移动逻辑

@export var character_body: CharacterBody3D
@export var move_speed: float = 5.0
@export var jump_velocity: float = 7.5
@export var rotation_speed: float = 10.0

var move_direction: Vector2 = Vector2.ZERO
var camera_basis: Basis = Basis.IDENTITY
var attack_input: bool = false  ## 攻击输入

func _ready() -> void:
	print("[MovementController] Ready - Speed: %.1f, Jump: %.1f" % [move_speed, jump_velocity])

func set_move_input(direction: Vector2) -> void:
	move_direction = direction

func set_camera_basis(basis: Basis) -> void:
	camera_basis = basis

func jump() -> void:
	if character_body and character_body.is_on_floor():
		character_body.velocity.y = jump_velocity

func attack() -> void:
	attack_input = true

func _physics_process(delta: float) -> void:
	if not character_body:
		return

	_apply_movement(delta)
	_apply_rotation(delta)
	_handle_attack()

func _apply_movement(delta: float) -> void:
	# Convert 2D input to 3D movement relative to camera
	var forward := -camera_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right := camera_basis.x
	right.y = 0
	right = right.normalized()

	var move_3d := (forward * -move_direction.y + right * move_direction.x).normalized()

	if move_3d.length() > 0.01:
		character_body.velocity.x = move_3d.x * move_speed
		character_body.velocity.z = move_3d.z * move_speed
	else:
		# Deceleration
		character_body.velocity.x = lerp(character_body.velocity.x, 0.0, delta * 8.0)
		character_body.velocity.z = lerp(character_body.velocity.z, 0.0, delta * 8.0)

func _apply_rotation(delta: float) -> void:
	var velocity_2d := Vector2(character_body.velocity.x, character_body.velocity.z)
	if velocity_2d.length() > 0.5:
		var target_rotation := atan2(velocity_2d.x, velocity_2d.y)
		var current_rotation := character_body.rotation.y

		# Smooth rotation
		var angle_diff := wrapf(target_rotation - current_rotation, -PI, PI)
		character_body.rotation.y += angle_diff * rotation_speed * delta

func _handle_attack() -> void:
	if attack_input:
		attack_input = false
		if character_body.has_method("attack"):
			character_body.attack()
