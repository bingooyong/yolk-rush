class_name LightingProfile
extends RefCounted
## Presentation lighting numbers from data/contracts/lighting_profile.json.

var path: String = ""
var id: String = ""
var key: Dictionary = {}
var fill: Dictionary = {}
var rim: Dictionary = {}
var ambient_energy: float = 0.0
var raw: Dictionary = {}

static func load_from_path(json_path: String) -> LightingProfile:
	var p := LightingProfile.new()
	p.path = json_path
	p.raw = JsonData.read_dict(json_path)
	if p.raw.is_empty():
		return p
	p.id = str(p.raw.get("id", ""))
	p.key = p.raw.get("key", {}) as Dictionary
	p.fill = p.raw.get("fill", {}) as Dictionary
	p.rim = p.raw.get("rim", {}) as Dictionary
	p.ambient_energy = float(p.raw.get("ambient_energy", 0.0))
	return p

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if raw.is_empty():
		errors.append("empty lighting profile: %s" % path)
		return errors
	if id.is_empty():
		errors.append("lighting profile missing id")
	if key.is_empty():
		errors.append("lighting profile missing key")
	return errors

func is_valid() -> bool:
	return validate().is_empty()
