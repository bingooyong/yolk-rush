class_name HeroActor
extends Node3D
## Assembles Gameplay (capsule) + Visual (placeholder/GLB later). Siblings, not fused.

var gameplay: CharacterGameplay
var visual: CharacterVisual
var definition: CharacterDefinition

func setup_from_definition(def: CharacterDefinition) -> void:
	definition = def
	for c in get_children():
		c.queue_free()

	gameplay = CharacterGameplay.new()
	gameplay.name = "Gameplay"
	add_child(gameplay)
	gameplay.apply_definition(def)

	visual = CharacterVisual.new()
	visual.name = "Visual"
	add_child(visual)
	visual.apply_definition(def)

func _physics_process(_delta: float) -> void:
	if gameplay == null or visual == null:
		return
	# Keep presentation glued to the gameplay body without parenting (siblings).
	visual.global_transform = gameplay.global_transform
	_update_pose_from_gameplay()

func apply_input(input: PlayerInput, delta: float) -> void:
	if gameplay != null:
		gameplay.apply_input(input, delta)

func set_visual_visible(v: bool) -> void:
	if visual != null:
		visual.visible = v

func is_visual_visible() -> bool:
	return visual != null and visual.visible

func set_pose(pose: CharacterVisual.Pose) -> void:
	if visual != null:
		visual.set_pose(pose)

func seed_spawn(pos: Vector3, yaw: float) -> void:
	if gameplay == null:
		return
	gameplay.global_position = pos
	gameplay.rotation.y = yaw
	gameplay.seed_safe_checkpoint(pos, yaw)
	if visual != null:
		visual.global_transform = gameplay.global_transform

func _update_pose_from_gameplay() -> void:
	if gameplay == null or visual == null:
		return
	var on_floor := gameplay.is_on_floor()
	var horiz := Vector3(gameplay.velocity.x, 0.0, gameplay.velocity.z).length()
	if not on_floor:
		if gameplay.velocity.y > 0.4:
			visual.set_pose(CharacterVisual.Pose.JUMP_START)
		elif gameplay.velocity.y < -0.4:
			visual.set_pose(CharacterVisual.Pose.FALL)
		else:
			visual.set_pose(CharacterVisual.Pose.AIRBORNE)
	elif horiz > 0.35:
		visual.set_pose(CharacterVisual.Pose.RUN)
	else:
		visual.set_pose(CharacterVisual.Pose.IDLE)
