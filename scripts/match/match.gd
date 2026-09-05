extends Node3D
## Phase 2 playable match: Snow Island + Hero + ChaseCamera + Touch HUD.

const LEVEL_PATH := "res://data/levels/snow_island_01.json"
const CHAR_PATH := "res://data/characters/yolk_hero.json"
const LIGHT_PATH := "res://data/contracts/lighting_profile.json"
const CAM_PATH := "res://data/contracts/camera_profiles.json"
const TOUCH_HUD_SCENE := "res://scenes/ui/touch_hud.tscn"

signal match_finished

var _hero: HeroActor
var _player_input: PlayerInput
var _camera: ChaseCamera
var _hud: Node
var _finished: bool = false

func _ready() -> void:
	print("[Match] Phase 2 — Snow Island. W throttle, A/D yaw, Space jump.")
	_build_lighting()
	_build_world()
	_build_hero()
	_build_input_and_camera()
	_build_hud()
	# Seed spawn after nodes are inside the tree.
	call_deferred("_seed_hero_spawn")

func _physics_process(delta: float) -> void:
	if _hero != null and _player_input != null and not _finished:
		_hero.apply_input(_player_input, delta)

func _build_lighting() -> void:
	var light := LightingProfile.load_from_path(LIGHT_PATH)
	if not light.is_valid():
		push_error("[Match] lighting profile invalid")
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.78, 0.92)
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

func _build_world() -> void:
	var def := LevelDefinition.load_from_path(LEVEL_PATH)
	var errs := def.validate()
	if not errs.is_empty():
		for e in errs:
			push_error("[Match] level: %s" % e)
		return
	var builder := LevelBuilder.new()
	var world := builder.build(def)
	world.name = "World"
	add_child(world)
	_connect_finish_areas(world)

func _connect_finish_areas(world: Node) -> void:
	for n in world.get_children():
		if n is Area3D and n.is_in_group("finish"):
			(n as Area3D).body_entered.connect(_on_finish_body_entered)

func _on_finish_body_entered(body: Node) -> void:
	if _finished:
		return
	var ok := body is CharacterGameplay
	if not ok and body.get_parent() is HeroActor:
		ok = true
	if ok:
		_finished = true
		print("[Match] FINISH — match_finished")
		match_finished.emit()

func _build_hero() -> void:
	var def := CharacterDefinition.load_from_path(CHAR_PATH)
	var errs := def.validate()
	if not errs.is_empty():
		for e in errs:
			push_error("[Match] character: %s" % e)
		return
	_hero = HeroActor.new()
	_hero.name = "Hero"
	add_child(_hero)
	_hero.setup_from_definition(def)
	if _hero.gameplay != null:
		_hero.gameplay.fell_in_recovery.connect(_on_fell_in_recovery)

func _seed_hero_spawn() -> void:
	if _hero == null:
		return
	var level := LevelDefinition.load_from_path(LEVEL_PATH)
	var sp: Dictionary = level.spawn
	var pos := Vector3(
		float(sp.get("x", 0.0)),
		float(sp.get("y", 0.0)) + 0.05,
		float(sp.get("z", 0.0))
	)
	var yaw := float(sp.get("yaw", 0.0))
	_hero.seed_spawn(pos, yaw)

func _on_fell_in_recovery() -> void:
	print("[Match] recovery → respawn to safe checkpoint")

func _build_input_and_camera() -> void:
	_player_input = PlayerInput.new()
	_player_input.name = "PlayerInput"
	add_child(_player_input)

	_camera = ChaseCamera.new()
	_camera.name = "ChaseCamera"
	var cams := JsonData.read_dict(CAM_PATH)
	_camera.apply_profile(cams.get("chase", {}) as Dictionary)
	add_child(_camera)
	_camera.set_target(_hero)

func _build_hud() -> void:
	if ResourceLoader.exists(TOUCH_HUD_SCENE):
		var packed := load(TOUCH_HUD_SCENE) as PackedScene
		if packed != null:
			_hud = packed.instantiate()
			add_child(_hud)
			if _hud.has_method("bind_match"):
				_hud.call("bind_match", self)
			return
	var fallback := TouchHud.new()
	fallback.name = "TouchHud"
	add_child(fallback)
	fallback.bind_match(self)

func toggle_visual_visible() -> void:
	if _hero == null:
		return
	_hero.set_visual_visible(not _hero.is_visual_visible())
	print("[Match] Visual visible=%s" % _hero.is_visual_visible())

func get_player_input() -> PlayerInput:
	return _player_input

func get_hero() -> HeroActor:
	return _hero
