extends Node3D
## Visual layer: mesh, materials, animations. No gameplay logic.

@export var character_id: String = ""

var visual_model_path: String = ""
var skeleton_name: String = ""
var materials_config: Array = []

func _ready() -> void:
	if not character_id.is_empty():
		_load_character_visual(character_id)

func _load_character_visual(char_id: String) -> void:
	var data_path := "res://data/characters/%s.json" % char_id
	if not FileAccess.file_exists(data_path):
		push_error("[CharacterVisual] Character data not found: %s" % data_path)
		return

	var file := FileAccess.open(data_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[CharacterVisual] Failed to parse JSON: %s" % data_path)
		return

	var data: Dictionary = json.data
	visual_model_path = data.get("visual_model", "")
	skeleton_name = data.get("skeleton", "")
	materials_config = data.get("materials", [])

	# Try to load GLB model first, fallback to placeholder
	if not visual_model_path.is_empty() and FileAccess.file_exists(visual_model_path):
		load_visual_model()
	else:
		_spawn_placeholder()

func _spawn_placeholder() -> void:
	# Phase 4: Procedural CSG character
	print("[CharacterVisual] Creating procedural CSG character")

	var VisualCharacter := load("res://scripts/visual/visual_character.gd")
	var visual_char := Node3D.new()
	visual_char.set_script(VisualCharacter)
	visual_char.name = "VisualCharacter"
	add_child(visual_char)

	print("[CharacterVisual] ✅ Procedural character spawned for: %s" % character_id)

func load_visual_model() -> void:
	# Phase 1+: load actual GLB model
	if visual_model_path.is_empty():
		push_warning("[CharacterVisual] No visual model path set")
		return

	# Check if GLB file exists
	if not FileAccess.file_exists(visual_model_path):
		push_warning("[CharacterVisual] GLB model not found: %s" % visual_model_path)
		return

	# Load GLB scene
	var gltf_document := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var error := gltf_document.append_from_file(visual_model_path, gltf_state)

	if error != OK:
		push_error("[CharacterVisual] Failed to load GLB: %s (error code: %d)" % [visual_model_path, error])
		return

	var model_scene := gltf_document.generate_scene(gltf_state)

	if model_scene == null:
		push_error("[CharacterVisual] Failed to generate scene from GLB")
		return

	# Clear placeholder geometry
	for child in get_children():
		child.queue_free()

	# Add GLB model
	add_child(model_scene)
	model_scene.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Apply materials config if present
	if materials_config.size() > 0:
		_apply_materials(model_scene)

	print("[CharacterVisual] GLB model loaded: %s" % visual_model_path)

func _apply_materials(model: Node) -> void:
	# Apply custom materials from materials_config
	for mat_config in materials_config:
		var target_name: String = mat_config.get("mesh", "")
		var albedo_color := Color.WHITE

		# Parse color if present
		if mat_config.has("albedo_color"):
			var color_array: Array = mat_config["albedo_color"]
			if color_array.size() >= 3:
				albedo_color = Color(color_array[0], color_array[1], color_array[2])

		# Find mesh and apply material
		var mesh_instance := _find_mesh_by_name(model, target_name)
		if mesh_instance:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = albedo_color
			mat.roughness = mat_config.get("roughness", 0.5)
			mat.metallic = mat_config.get("metallic", 0.0)
			mesh_instance.material_override = mat
			print("[CharacterVisual] Applied material to: %s" % target_name)

func _find_mesh_by_name(node: Node, mesh_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == mesh_name:
		return node

	for child in node.get_children():
		var result := _find_mesh_by_name(child, mesh_name)
		if result:
			return result

	return null
