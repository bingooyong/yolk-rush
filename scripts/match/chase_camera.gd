class_name ChaseCamera
extends Camera3D
## Third-person chase behind hero. Numbers from camera_profiles.json → chase.

const CAM_PATH := "res://data/contracts/camera_profiles.json"

var target: Node3D
var distance: float = 6.5
var height: float = 2.8
var look_height: float = 1.05
var lag: float = 8.0
var _cfg_loaded := false

func apply_profile(cfg: Dictionary = {}) -> void:
	if cfg.is_empty():
		var root := JsonData.read_dict(CAM_PATH)
		cfg = root.get("chase", {}) as Dictionary
	if cfg.is_empty():
		return
	distance = float(cfg.get("distance", distance))
	height = float(cfg.get("height", height))
	look_height = float(cfg.get("look_at_height", look_height))
	lag = float(cfg.get("lag", lag))
	fov = float(cfg.get("fov", 50.0))
	_cfg_loaded = true

func set_target(node: Node3D) -> void:
	target = node

func _ready() -> void:
	if not _cfg_loaded:
		apply_profile()
	current = true

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var follow: Node3D = target
	# Prefer gameplay body if hero exposes it.
	if target is HeroActor and (target as HeroActor).gameplay != null:
		follow = (target as HeroActor).gameplay

	var back := follow.global_transform.basis.z
	back.y = 0.0
	if back.length_squared() < 0.0001:
		back = Vector3(0.0, 0.0, 1.0)
	else:
		back = back.normalized()

	var desired := follow.global_position + back * distance + Vector3(0.0, height, 0.0)
	global_position = global_position.lerp(desired, 1.0 - exp(-lag * delta))
	var look := follow.global_position + Vector3(0.0, look_height, 0.0)
	look_at(look, Vector3.UP)
