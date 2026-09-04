extends SceneTree
## Headless: godot --headless --path . --script tools/validate_level.gd

const PATH := "res://data/levels/snow_island_01.json"
const LIGHT_PATH := "res://data/contracts/lighting_profile.json"

func _init() -> void:
	var def := LevelDefinition.load_from_path(PATH)
	var errors := def.validate()
	var light := LightingProfile.load_from_path(LIGHT_PATH)
	errors.append_array(light.validate())
	if def.is_valid() and light.is_valid() and def.lighting != light.id:
		errors.append("level.lighting '%s' != profile id '%s'" % [def.lighting, light.id])
	if errors.is_empty():
		print("PASS validate_level: %s (%d segments)" % [def.id, def.segments.size()])
		quit(0)
	else:
		print("FAIL validate_level: %s" % PATH)
		for e in errors:
			print("  - %s" % e)
		quit(1)
