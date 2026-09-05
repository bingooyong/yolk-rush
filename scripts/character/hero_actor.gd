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

func set_pose(pose: CharacterVisual.Pose) -> void:
	if visual != null:
		visual.set_pose(pose)
