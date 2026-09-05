class_name CharacterVisual
extends Node3D
## Presentation only. No Input. No gameplay rules. Pose-driven.

enum Pose {
	IDLE,
	RUN,
	JUMP_START,
	AIRBORNE,
	FALL,
	LAND,
	HIT,
	FAIL,
}

const POSE_NAMES := {
	Pose.IDLE: "idle",
	Pose.RUN: "run",
	Pose.JUMP_START: "jump_start",
	Pose.AIRBORNE: "airborne",
	Pose.FALL: "fall",
	Pose.LAND: "land",
	Pose.HIT: "hit",
	Pose.FAIL: "fail",
}

var definition: CharacterDefinition
var pose: Pose = Pose.IDLE
var _placeholder: PlaceholderYolk

func apply_definition(def: CharacterDefinition) -> void:
	definition = def
	for c in get_children():
		c.queue_free()
	_placeholder = PlaceholderYolk.new()
	_placeholder.name = "PlaceholderYolk"
	add_child(_placeholder)
	_placeholder.build_from_definition(def)
	# Facing contract: character forward is -Z (Godot default forward is -Z for look).
	rotation_degrees = Vector3.ZERO

func set_pose(p: Pose) -> void:
	pose = p

func pose_name() -> String:
	return POSE_NAMES.get(pose, "idle")

func _process(delta: float) -> void:
	if _placeholder != null:
		_placeholder.set_pose_visual(pose_name(), delta)
