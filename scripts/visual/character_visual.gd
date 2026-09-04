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

	_spawn_placeholder()

func _spawn_placeholder() -> void:
	# Phase 1: placeholder geometry (capsule + sphere)
	var capsule_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.48
	capsule.radius = 0.34
	capsule_mesh.mesh = capsule
	capsule_mesh.position.y = 0.74
	add_child(capsule_mesh)
	capsule_mesh.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	var head_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.24
	head_mesh.mesh = sphere
	head_mesh.position.y = 1.55
	add_child(head_mesh)
	head_mesh.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Apply placeholder material (bright color for visibility)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)  # Yolk yellow
	mat.roughness = 0.42
	capsule_mesh.material_override = mat
	head_mesh.material_override = mat

	print("[CharacterVisual] Placeholder spawned for: %s" % character_id)

func load_visual_model() -> void:
	# Phase 1+: load actual GLB model
	if visual_model_path.is_empty():
		push_warning("[CharacterVisual] No visual model path set")
		return

	# TODO: Load GLB and apply materials_config
	pass
