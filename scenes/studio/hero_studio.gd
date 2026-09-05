extends Node3D
## Phase 1 review scene. No level, no HUD stick, no shop/gacha.

const LIGHT_PATH := "res://data/contracts/lighting_profile.json"
const CAM_PATH := "res://data/contracts/camera_profiles.json"
const CHAR_PATH := "res://data/characters/yolk_hero.json"

const CAM_ORDER: PackedStringArray = ["three_quarter", "front", "side", "back"]
const POSE_BY_KEY := {
	KEY_1: CharacterVisual.Pose.IDLE,
	KEY_2: CharacterVisual.Pose.RUN,
	KEY_3: CharacterVisual.Pose.JUMP_START,
	KEY_4: CharacterVisual.Pose.AIRBORNE,
	KEY_5: CharacterVisual.Pose.FALL,
	KEY_6: CharacterVisual.Pose.LAND,
	KEY_7: CharacterVisual.Pose.HIT,
	KEY_8: CharacterVisual.Pose.FAIL,
}

var _hero: HeroActor
var _camera: Camera3D
var _cam_profiles: Dictionary = {}
var _cam_index := 0
var _label: Label

func _ready() -> void:
	print("[HeroStudio] Phase 1 — Yolk Hero review. Keys 1-8 pose, Z/X/C/V cameras.")
	_build_world()
	_build_hero()
	_build_hud_hint()
	_apply_camera(CAM_ORDER[_cam_index])

func _build_world() -> void:
	var light := LightingProfile.load_from_path(LIGHT_PATH)
	if not light.is_valid():
		push_error("[HeroStudio] lighting profile invalid")
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.85, 0.9, 1.0)
	environment.ambient_light_energy = light.ambient_energy if light.is_valid() else 0.35
	env.environment = environment
	add_child(env)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	if light.is_valid():
		var elev := deg_to_rad(float(light.key.get("elevation_deg", 35.0)))
		var azim := deg_to_rad(float(light.key.get("azimuth_deg", -40.0)))
		key.rotation = Vector3(-elev, azim, 0.0)
		key.light_energy = float(light.key.get("energy", 1.15))
	else:
		key.rotation_degrees = Vector3(-35.0, -40.0, 0.0)
		key.light_energy = 1.15
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-20.0, 120.0, 0.0)
	fill.light_energy = float(light.fill.get("energy", 0.35)) if light.is_valid() else 0.35
	add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.name = "RimLight"
	rim.rotation_degrees = Vector3(-15.0, 200.0, 0.0)
	rim.light_energy = float(light.rim.get("energy", 0.55)) if light.is_valid() else 0.55
	add_child(rim)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.82, 0.86, 0.9)
	gmat.roughness = 0.9
	ground.material_override = gmat
	add_child(ground)

	_camera = Camera3D.new()
	_camera.name = "ReviewCamera"
	_camera.current = true
	add_child(_camera)

	var cams := JsonData.read_dict(CAM_PATH)
	_cam_profiles = cams.get("hero_lock", {}) as Dictionary

func _build_hero() -> void:
	var def := CharacterDefinition.load_from_path(CHAR_PATH)
	var errs := def.validate()
	if not errs.is_empty():
		for e in errs:
			push_error("[HeroStudio] character: %s" % e)
		return
	_hero = HeroActor.new()
	_hero.name = "Hero"
	add_child(_hero)
	_hero.setup_from_definition(def)
	_hero.set_pose(CharacterVisual.Pose.IDLE)

func _build_hud_hint() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.text = "1-8 pose | Z X C V camera | Gameplay+Visual siblings"
	_label.position = Vector2(16, 12)
	layer.add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event.keycode
		if POSE_BY_KEY.has(key) and _hero != null:
			_hero.set_pose(POSE_BY_KEY[key])
			_refresh_hint()
			get_viewport().set_input_as_handled()
			return
		match key:
			KEY_Z:
				_cam_index = 0
			KEY_X:
				_cam_index = 1
			KEY_C:
				_cam_index = 2
			KEY_V:
				_cam_index = 3
			_:
				return
		_apply_camera(CAM_ORDER[_cam_index])
		_refresh_hint()
		get_viewport().set_input_as_handled()

func _apply_camera(cam_id: String) -> void:
	if _camera == null:
		return
	var cfg: Dictionary = _cam_profiles.get(cam_id, {}) as Dictionary
	if cfg.is_empty():
		_camera.position = Vector3(2.2, 1.55, 2.4)
		_camera.look_at(Vector3(0.0, 0.85, 0.0))
		return
	var p: Dictionary = cfg.get("position", {}) as Dictionary
	var t: Dictionary = cfg.get("look_at", {}) as Dictionary
	_camera.position = Vector3(float(p.get("x", 0.0)), float(p.get("y", 1.0)), float(p.get("z", 3.0)))
	_camera.look_at(Vector3(float(t.get("x", 0.0)), float(t.get("y", 0.85)), float(t.get("z", 0.0))))
	_camera.fov = float(cfg.get("fov", 35.0))

func _refresh_hint() -> void:
	if _label == null or _hero == null or _hero.visual == null:
		return
	_label.text = "pose=%s camera=%s | 1-8 pose, Z/X/C/V cam" % [
		_hero.visual.pose_name(),
		CAM_ORDER[_cam_index],
	]
