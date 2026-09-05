extends Node
## Autoload. Routes only. No gameplay rules.

const CHAR_PATH := "res://data/characters/yolk_hero.json"
const LEVEL_PATH := "res://data/levels/snow_island_01.json"
const LIGHT_PATH := "res://data/contracts/lighting_profile.json"
const STUDIO_SCENE := "res://scenes/studio/hero_studio.tscn"

func _ready() -> void:
	print("[App] Yolk Rush 4.7.2 factory boot")

func load_default_character() -> CharacterDefinition:
	return CharacterDefinition.load_from_path(CHAR_PATH)

func load_default_level() -> LevelDefinition:
	return LevelDefinition.load_from_path(LEVEL_PATH)

func load_default_lighting() -> LightingProfile:
	return LightingProfile.load_from_path(LIGHT_PATH)

func go_hero_studio() -> void:
	get_tree().change_scene_to_file(STUDIO_SCENE)
