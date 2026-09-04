class_name CharacterGameplay
extends CharacterBody3D
## Gameplay body. Collision comes ONLY from CharacterDefinition.collision_profile.

const COLLISION_NODE := "Collision"
const SHAPE_NODE := "CollisionShape"

var definition: CharacterDefinition

func apply_definition(def: CharacterDefinition) -> void:
	definition = def
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
