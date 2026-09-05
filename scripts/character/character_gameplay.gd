class_name CharacterGameplay
extends CharacterBody3D
## Gameplay body. Collision comes ONLY from CharacterDefinition.collision_profile.

const COLLISION_NODE := "Collision"
const SHAPE_NODE := "CollisionShape"

const MOVE_SPEED := 5.5
const JUMP_VELOCITY := 7.0
const GRAVITY := 24.0
const YAW_RATE_BASE := 3.6
const ICE_BLEND := 4.0
const GROUND_BLEND := 18.0

signal fell_in_recovery

var definition: CharacterDefinition
var _on_ice: bool = false
var _safe_position: Vector3 = Vector3.ZERO
var _safe_yaw: float = 0.0
var _has_safe: bool = false
var _was_on_floor: bool = true

func apply_definition(def: CharacterDefinition) -> void:
	definition = def
	floor_snap_length = 0.15
	floor_max_angle = deg_to_rad(50.0)
	_ensure_collision_from_profile()

func _ensure_collision_from_profile() -> void:
	if definition == null or not definition.is_valid():
		push_error("CharacterGameplay: refuse to build collision without valid definition")
		return
	var col := get_node_or_null(COLLISION_NODE) as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		col.name = COLLISION_NODE
		add_child(col)
	var capsule := CapsuleShape3D.new()
	capsule.height = definition.capsule_height()
	capsule.radius = definition.capsule_radius()
	col.shape = capsule
	col.position = Vector3(0.0, definition.capsule_offset_y(), 0.0)
	# Never import mesh collision; visual is a sibling concern.

func apply_input(input: PlayerInput, delta: float) -> void:
	if input == null:
		return

	var throttle := input.throttle
	var yaw_in := input.yaw_input
	var yaw_rate := YAW_RATE_BASE * (0.35 + 0.65 * absf(throttle))
	rotate_y(yaw_in * yaw_rate * delta)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	var desired := forward * MOVE_SPEED * throttle

	_on_ice = _detect_ice()
	var blend := ICE_BLEND if _on_ice else GROUND_BLEND
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	horiz = horiz.lerp(desired, 1.0 - exp(-blend * delta))
	velocity.x = horiz.x
	velocity.z = horiz.z

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif input.jump:
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if _detect_recovery():
		fell_in_recovery.emit()
		respawn_to_safe()
		return

	if is_on_floor() and not _detect_recovery():
		_safe_position = global_position
		_safe_yaw = rotation.y
		_has_safe = true

	_was_on_floor = is_on_floor()

func respawn_to_safe() -> void:
	if _has_safe:
		global_position = _safe_position + Vector3(0.0, 0.15, 0.0)
	else:
		global_position = Vector3(0.0, 0.5, 0.0)
	rotation.y = _safe_yaw
	velocity = Vector3.ZERO

func seed_safe_checkpoint(pos: Vector3, yaw: float) -> void:
	_safe_position = pos
	_safe_yaw = yaw
	_has_safe = true

func is_on_ice() -> bool:
	return _on_ice

func _detect_ice() -> bool:
	if not is_on_floor():
		return false
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider() as Node
		if collider != null and (collider.is_in_group("ice") or bool(collider.get_meta("ice", false))):
			return true
	return false

func _detect_recovery() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider() as Node
		if collider != null and (collider.is_in_group("recovery") or bool(collider.get_meta("recovery", false))):
			return true
	# Also treat deep falls as recovery if we somehow miss the platform.
	if global_position.y < -8.0:
		return true
	return false
