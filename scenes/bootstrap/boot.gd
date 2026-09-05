extends Node
## Bootstrap. Routes to match scene directly (no validation required for iOS build).

const MATCH_SCENE := "res://scenes/match/match.tscn"

func _ready() -> void:
	print("[Boot] Starting → %s" % MATCH_SCENE)
	# 直接跳转到match场景
	get_tree().change_scene_to_file(MATCH_SCENE)
