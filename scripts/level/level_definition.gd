class_name LevelDefinition
extends RefCounted
## Level DSL from data/levels/*.json. Scene must not own these rules.

const JsonData = preload("res://scripts/core/json_data.gd")

const ALLOWED_ROLES: PackedStringArray = [
	"start_hall",
	"main_lane",
	"challenge",
	"shortcut",
	"recovery",
	"finish_hall",
]

var path: String = ""
var id: String = ""
var display_name: String = ""
var lighting: String = ""
var spawn: Dictionary = {}
var segments: Array = []
var raw: Dictionary = {}

static func load_from_path(json_path: String) -> LevelDefinition:
	var def := LevelDefinition.new()
	def.path = json_path
	def.raw = JsonData.read_dict(json_path)
	if def.raw.is_empty():
		return def
	def.id = str(def.raw.get("id", ""))
	def.display_name = str(def.raw.get("display_name", ""))
	def.lighting = str(def.raw.get("lighting", ""))
	def.spawn = def.raw.get("spawn", {}) as Dictionary
	def.segments = def.raw.get("segments", []) as Array
	return def

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if raw.is_empty():
		errors.append("empty or unreadable JSON: %s" % path)
		return errors
	if id.is_empty():
		errors.append("missing id")
	if lighting.is_empty():
		errors.append("missing lighting profile id")
	if spawn.is_empty():
		errors.append("missing spawn")
	else:
		for k in ["x", "y", "z"]:
			if not spawn.has(k):
				errors.append("spawn missing %s" % k)
	if segments.is_empty():
		errors.append("segments must be non-empty")
		return errors
	var roles_seen: Dictionary = {}
	for i in segments.size():
		var s: Variant = segments[i]
		if typeof(s) != TYPE_DICTIONARY:
			errors.append("segments[%d] must be object" % i)
			continue
		var seg: Dictionary = s
		var sid := str(seg.get("id", ""))
		var role := str(seg.get("role", ""))
		if sid.is_empty():
			errors.append("segments[%d] missing id" % i)
		if role.is_empty():
			errors.append("segments[%d] missing role" % i)
		elif not ALLOWED_ROLES.has(role):
			errors.append("segments[%d] role not allowed: %s" % [i, role])
		else:
			roles_seen[role] = true
		for k in ["width", "length", "y"]:
			if not seg.has(k):
				errors.append("segments[%d] missing %s" % [i, k])
			elif float(seg[k]) == 0.0 and k != "y":
				# width/length should be > 0; y may be 0
				if k != "y" and float(seg.get(k, 0.0)) <= 0.0:
					errors.append("segments[%d].%s must be > 0" % [i, k])
	for need in ["start_hall", "finish_hall"]:
		if not roles_seen.has(need):
			errors.append("missing required segment role: %s" % need)
	return errors

func is_valid() -> bool:
	return validate().is_empty()
