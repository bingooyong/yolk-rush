class_name CharacterDefinition
extends RefCounted
## Data-driven character entry. Collision authority is collision_profile, never mesh.

const HEIGHT_MIN := 1.40
const HEIGHT_MAX := 1.70
const REQUIRED_ANIM_KEYS: PackedStringArray = [
	"idle_animation",
	"run_animation",
	"jump_animation",
	"airborne_animation",
	"fall_animation",
	"land_animation",
	"roll_animation",
	"dash_animation",
	"pounce_animation",
	"hit_animation",
	"victory_animation",
	"fail_animation",
]

var path: String = ""
var id: String = ""
var display_name: String = ""
var visual_model: String = ""
var skeleton: String = ""
var scale: float = 1.0
var materials: Array = []
var collision_profile: Dictionary = {}
var contract: Dictionary = {}
var raw: Dictionary = {}

static func load_from_path(json_path: String) -> CharacterDefinition:
	var def := CharacterDefinition.new()
	def.path = json_path
	def.raw = JsonData.read_dict(json_path)
	if def.raw.is_empty():
		return def
	def.id = str(def.raw.get("id", ""))
	def.display_name = str(def.raw.get("display_name", ""))
	def.visual_model = str(def.raw.get("visual_model", ""))
	def.skeleton = str(def.raw.get("skeleton", ""))
	def.scale = float(def.raw.get("scale", 1.0))
	def.materials = def.raw.get("materials", []) as Array
	def.collision_profile = def.raw.get("collision_profile", {}) as Dictionary
	def.contract = def.raw.get("contract", {}) as Dictionary
	return def

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if raw.is_empty():
		errors.append("empty or unreadable JSON: %s" % path)
		return errors
	if id.is_empty():
		errors.append("missing id")
	if visual_model.is_empty():
		errors.append("missing visual_model")
	elif not (visual_model.ends_with(".glb") or visual_model.ends_with(".gltf")):
		errors.append("visual_model must be .glb or .gltf: %s" % visual_model)
	if skeleton.is_empty():
		errors.append("missing skeleton")
	for key in REQUIRED_ANIM_KEYS:
		if str(raw.get(key, "")).is_empty():
			errors.append("missing animation field: %s" % key)
	if materials.is_empty():
		errors.append("materials must be a non-empty array")
	else:
		for i in materials.size():
			var m: Variant = materials[i]
			if typeof(m) != TYPE_DICTIONARY:
				errors.append("materials[%d] must be object" % i)
				continue
			var md: Dictionary = m
			if str(md.get("slot", "")).is_empty() or str(md.get("library", "")).is_empty():
				errors.append("materials[%d] needs slot + library" % i)
	if collision_profile.is_empty():
		errors.append("missing collision_profile")
	else:
		for k in ["height", "radius", "offset_y"]:
			if not collision_profile.has(k):
				errors.append("collision_profile missing %s" % k)
			elif typeof(collision_profile[k]) != TYPE_FLOAT and typeof(collision_profile[k]) != TYPE_INT:
				errors.append("collision_profile.%s must be number" % k)
			elif float(collision_profile[k]) <= 0.0 and k != "offset_y":
				errors.append("collision_profile.%s must be > 0" % k)
			elif k == "offset_y" and float(collision_profile[k]) < 0.0:
				errors.append("collision_profile.offset_y must be >= 0")
	if contract.is_empty():
		errors.append("missing contract")
	else:
		if not contract.has("version"):
			errors.append("contract.version missing")
		var hm := float(contract.get("height_m", -1.0))
		if hm < HEIGHT_MIN or hm > HEIGHT_MAX:
			errors.append("contract.height_m must be in [%.2f, %.2f], got %s" % [HEIGHT_MIN, HEIGHT_MAX, contract.get("height_m")])
		if str(contract.get("facing", "")) != "-Z":
			errors.append("contract.facing must be -Z")
		if str(contract.get("origin", "")) != "feet":
			errors.append("contract.origin must be feet")
	return errors

func is_valid() -> bool:
	return validate().is_empty()

func capsule_height() -> float:
	return float(collision_profile.get("height", 0.0))

func capsule_radius() -> float:
	return float(collision_profile.get("radius", 0.0))

func capsule_offset_y() -> float:
	return float(collision_profile.get("offset_y", 0.0))
