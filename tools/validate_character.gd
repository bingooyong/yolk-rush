extends SceneTree
## Headless: godot --headless --path . --script tools/validate_character.gd

const PATH := "res://data/characters/yolk_hero.json"

func _init() -> void:
	var def := CharacterDefinition.load_from_path(PATH)
	var errors := def.validate()
	if errors.is_empty():
		print("PASS validate_character: %s" % def.id)
		quit(0)
	else:
		print("FAIL validate_character: %s" % PATH)
		for e in errors:
			print("  - %s" % e)
		quit(1)
