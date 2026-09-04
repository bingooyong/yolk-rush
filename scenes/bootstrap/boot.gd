extends Node
## Bootstrap entry. Routes into Domain loaders; no shop, no gacha, no full match yet.

func _ready() -> void:
	print("[Boot] Phase 2 path — Snow Island golden data. No shop, no gacha.")
	var ok := _boot_domain_loaders()
	if ok:
		print("[Boot] Domain loaders OK (character + level + lighting).")
	else:
		push_error("[Boot] Domain loader validation FAILED — see errors above.")

func _boot_domain_loaders() -> bool:
	var all_ok := true
	var hero: CharacterDefinition = App.load_default_character()
	var hero_errs := hero.validate()
	if hero_errs.is_empty():
		print("[Boot] character ok id=%s height_m=%s capsule h=%.2f r=%.2f" % [
			hero.id,
			hero.contract.get("height_m"),
			hero.capsule_height(),
			hero.capsule_radius(),
		])
	else:
		all_ok = false
		for e in hero_errs:
			push_error("[Boot] character: %s" % e)

	var level: LevelDefinition = App.load_default_level()
	var level_errs := level.validate()
	if level_errs.is_empty():
		print("[Boot] level ok id=%s segments=%d lighting=%s" % [
			level.id,
			level.segments.size(),
			level.lighting,
		])
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

	# Ensure lighting id referenced by level exists when both valid.
	if level.is_valid() and light.is_valid() and level.lighting != light.id:
		all_ok = false
		push_error("[Boot] level.lighting '%s' != lighting profile id '%s'" % [level.lighting, light.id])

	return all_ok
