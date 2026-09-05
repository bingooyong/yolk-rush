extends Node
## Bootstrap. Phase 2 routes to match after Domain validation. Studio remains via App.go_hero_studio().

const MATCH_SCENE := "res://scenes/match/match.tscn"

func _ready() -> void:
	print("[Boot] Phase 2 — validate Domain data, then Match.")
	var ok := _boot_domain_loaders()
	if not ok:
		push_error("[Boot] Domain validation FAILED — staying on boot.")
		return
	print("[Boot] Domain OK → %s" % MATCH_SCENE)
	get_tree().change_scene_to_file(MATCH_SCENE)

func _boot_domain_loaders() -> bool:
	var all_ok := true
	var hero: CharacterDefinition = App.load_default_character()
	var hero_errs := hero.validate()
	if hero_errs.is_empty():
		print("[Boot] character ok id=%s" % hero.id)
	else:
		all_ok = false
		for e in hero_errs:
			push_error("[Boot] character: %s" % e)

	var level: LevelDefinition = App.load_default_level()
	var level_errs := level.validate()
	if level_errs.is_empty():
		print("[Boot] level ok id=%s" % level.id)
	else:
		all_ok = false
		for e in level_errs:
			push_error("[Boot] level: %s" % e)

	var light: LightingProfile = App.load_default_lighting()
	var light_errs := light.validate()
	if light_errs.is_empty():
		print("[Boot] lighting ok id=%s" % light.id)
	else:
		all_ok = false
		for e in light_errs:
			push_error("[Boot] lighting: %s" % e)

	if level.is_valid() and light.is_valid() and level.lighting != light.id:
		all_ok = false
		push_error("[Boot] level.lighting mismatch")
	return all_ok
