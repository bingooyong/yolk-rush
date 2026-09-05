extends Node
## Bootstrap. Phase 1 routes to hero studio after Domain validation. No shop, no gacha.

const STUDIO_SCENE := "res://scenes/studio/hero_studio.tscn"

func _ready() -> void:
	print("[Boot] Phase 1 — validate Domain data, then Hero Studio.")
	var ok := _boot_domain_loaders()
	if not ok:
		push_error("[Boot] Domain validation FAILED — staying on boot.")
		return
	print("[Boot] Domain OK → %s" % STUDIO_SCENE)
	get_tree().change_scene_to_file(STUDIO_SCENE)

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
		print("[Boot] level ok id=%s (Phase 2 will play it)" % level.id)
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
