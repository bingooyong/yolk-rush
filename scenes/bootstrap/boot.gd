extends Node

@export_enum("HeroStudio", "SnowIsland") var launch_mode: String = "SnowIsland"

func _ready() -> void:
	print("[Boot] Phase 1-2 — Hero Studio + Snow Island. No shop, no gacha.")

	match launch_mode:
		"HeroStudio":
			call_deferred("_launch_hero_studio")
		"SnowIsland":
			call_deferred("_launch_snow_island")
		_:
			push_error("[Boot] Unknown launch mode: %s" % launch_mode)

func _launch_hero_studio() -> void:
	var studio_scene := preload("res://scenes/studio/hero_studio.tscn")
	var studio := studio_scene.instantiate()
	get_tree().root.call_deferred("add_child", studio)
	print("[Boot] Hero Studio launched")

func _launch_snow_island() -> void:
	var island_scene := preload("res://scenes/game/snow_island.tscn")
	var island := island_scene.instantiate()
	get_tree().root.call_deferred("add_child", island)
	print("[Boot] Snow Island launched")
