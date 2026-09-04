extends Node3D
## Level Builder: 从 JSON 构建关卡几何和灯光

signal level_loaded(level_id: String)

var current_level_id: String = ""
var segments: Array = []
var spawn_point: Vector3 = Vector3.ZERO

func load_level(level_id: String) -> bool:
	var level_path := "res://data/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		push_error("[LevelBuilder] Level not found: %s" % level_path)
		return false

	var file := FileAccess.open(level_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[LevelBuilder] Failed to parse level JSON: %s" % level_path)
		return false

	var level_data: Dictionary = json.data
	current_level_id = level_id

	_build_segments(level_data.get("segments", []))

	# Load lighting profile from contract
	var lighting_id = level_data.get("lighting", "")
	var lighting_data: Dictionary = {}
	if lighting_id is String and not lighting_id.is_empty():
		lighting_data = _load_lighting_profile(lighting_id)

	_setup_lighting(lighting_data)
	_set_spawn_point(level_data.get("spawn", {}))

	level_loaded.emit(level_id)
	print("[LevelBuilder] Level loaded: %s" % level_id)
	return true

func _build_segments(segments_data: Array) -> void:
	segments.clear()

	for seg_data in segments_data:
		var segment := _create_segment(seg_data)
		segments.append(segment)
		add_child(segment)

func _load_lighting_profile(lighting_id: String) -> Dictionary:
	var lighting_path := "res://data/contracts/lighting_profiles.json"
	if not FileAccess.file_exists(lighting_path):
		push_warning("[LevelBuilder] Lighting profiles not found: %s" % lighting_path)
		return {}

	var file := FileAccess.open(lighting_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_warning("[LevelBuilder] Failed to parse lighting profiles")
		return {}

	var profiles: Dictionary = json.data
	return profiles.get(lighting_id, {})

func _create_segment(data: Dictionary) -> Node3D:
	var segment := Node3D.new()
	segment.name = data.get("id", "segment")

	var pos: Dictionary = data.get("position", {})
	segment.position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))

	var size: Dictionary = data.get("size", {"w": 10, "d": 10})
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.get("w", 10), 1.0, size.get("d", 10))
	mesh_inst.mesh = box
	mesh_inst.position.y = -0.5

	# Snow material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 1.0)
	mat.roughness = 0.85
	mat.metallic = 0.0
	mesh_inst.material_override = mat

	segment.add_child(mesh_inst)

	# Collision
	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(size.get("w", 10), 1.0, size.get("d", 10))
	collision.shape = collision_box
	collision.position.y = -0.5
	static_body.add_child(collision)
	segment.add_child(static_body)

	return segment

func _setup_lighting(lighting_data: Dictionary) -> void:
	if lighting_data.is_empty():
		push_warning("[LevelBuilder] No lighting profile")
		return

	# Directional light (sun)
	var dir_light := DirectionalLight3D.new()
	var dir: Dictionary = lighting_data.get("directional", {})
	dir_light.light_color = Color(
		dir.get("color_r", 1.0),
		dir.get("color_g", 0.95),
		dir.get("color_b", 0.9)
	)
	dir_light.light_energy = dir.get("energy", 0.8)

	var rot: Dictionary = dir.get("rotation", {})
	dir_light.rotation_degrees = Vector3(
		rot.get("x", -45),
		rot.get("y", 30),
		rot.get("z", 0)
	)

	dir_light.shadow_enabled = true
	add_child(dir_light)

	# Ambient light via environment
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.7, 0.8, 0.9)

	var ambient: Dictionary = lighting_data.get("ambient", {})
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(
		ambient.get("color_r", 0.8),
		ambient.get("color_g", 0.85),
		ambient.get("color_b", 1.0)
	)
	env.ambient_light_energy = ambient.get("energy", 0.4)

	world_env.environment = env
	add_child(world_env)

func _set_spawn_point(spawn_data: Dictionary) -> void:
	spawn_point = Vector3(
		spawn_data.get("x", 0),
		spawn_data.get("y", 2),
		spawn_data.get("z", 0)
	)

func get_spawn_point() -> Vector3:
	return spawn_point
