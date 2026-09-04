extends CharacterBody3D
## Gameplay layer: collision, physics, state. No visual.

const GRAVITY: float = 9.8

@export var character_id: String = "yolk_hero"

var character_data: Dictionary = {}
var collision_profile: Dictionary = {}

func _ready() -> void:
	if not character_id.is_empty():
		_load_character_data()
	_setup_collision()

func _load_character_data() -> void:
	var data_path := "res://data/characters/%s.json" % character_id
	if not FileAccess.file_exists(data_path):
		push_error("[CharacterGameplay] Character data not found: %s" % data_path)
		return

	var file := FileAccess.open(data_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[CharacterGameplay] Failed to parse JSON: %s" % data_path)
		return

	character_data = json.data
	collision_profile = character_data.get("collision_profile", {})

func _setup_collision() -> void:
	if collision_profile.is_empty():
		# Use default values from yolk_hero.json spec
		collision_profile = {
			"height": 1.48,
			"radius": 0.34,
			"offset_y": 0.74
		}

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = collision_profile.get("height", 1.48)
	capsule.radius = collision_profile.get("radius", 0.34)
	shape.shape = capsule
	shape.position.y = collision_profile.get("offset_y", 0.74)
	add_child(shape)
	shape.owner = self

func load_character(data: Dictionary) -> void:
	character_data = data
	collision_profile = data.get("collision_profile", {})
	_setup_collision()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()
