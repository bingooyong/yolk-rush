extends Node
## Autoload. Routes only. No gameplay rules.

const CHAR_PATH := "res://data/characters/yolk_hero.json"
const LEVEL_PATH := "res://data/levels/snow_island_01.json"
const LIGHT_PATH := "res://data/contracts/lighting_profile.json"
const STUDIO_SCENE := "res://scenes/studio/hero_studio.tscn"
const MATCH_SCENE := "res://scenes/match/match.tscn"

func _ready() -> void:
	print("[App] Yolk Rush 4.7.2 factory boot")

func load_default_character():
	var script = load("res://scripts/character/character_definition.gd")
	if script == null:
		return null
	var obj = script.new()
	if obj and obj.has_method("load_from_path"):
		return obj.load_from_path(CHAR_PATH)
	return null

func load_default_level():
	var script = load("res://scripts/level/level_definition.gd")
	if script == null:
		return null
	var obj = script.new()
	if obj and obj.has_method("load_from_path"):
		return obj.load_from_path(LEVEL_PATH)
	return null

func load_default_lighting():
	var script = load("res://scripts/core/lighting_profile.gd")
	if script == null:
		return null
	var obj = script.new()
	if obj and obj.has_method("load_from_path"):
		return obj.load_from_path(LIGHT_PATH)
	return null

func go_hero_studio() -> void:
	get_tree().change_scene_to_file(STUDIO_SCENE)

func go_match() -> void:
	get_tree().change_scene_to_file(MATCH_SCENE)
