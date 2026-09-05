class_name LevelBuilder
extends RefCounted
## Builds StaticBody / Area geometry from LevelDefinition. No mesh-derived collision.

const THICKNESS := 1.0
const ICE_FRICTION := 0.04
const DEFAULT_FRICTION := 0.8

func build(def: LevelDefinition) -> Node3D:
	var root := Node3D.new()
	root.name = "World"
	if def == null or not def.is_valid():
		push_error("LevelBuilder: refuse to build without valid LevelDefinition")
		return root

	var spawn_z := float(def.spawn.get("z", 0.0))
	# Small rear pad so spawn sits on start_hall, not on the +Z lip.
	var cursor_z := spawn_z + 2.0
	var course_z_max := spawn_z
	var course_z_min := spawn_z
	var course_half_w := 0.0
	var recovery_segs: Array = []

	for i in def.segments.size():
		var raw: Variant = def.segments[i]
		if typeof(raw) != TYPE_DICTIONARY:
			push_error("LevelBuilder: segments[%d] not object" % i)
			continue
		var seg: Dictionary = raw
		var role := str(seg.get("role", ""))
		if not LevelDefinition.ALLOWED_ROLES.has(role):
			push_error("LevelBuilder: unknown role '%s' at segments[%d] — fail" % [role, i])
			return root

		if role == "recovery":
			recovery_segs.append(seg)
			continue

		var width := float(seg.get("width", 1.0))
		var length := float(seg.get("length", 1.0))
		var y_top := float(seg.get("y", 0.0))
		var ice := bool(seg.get("ice", false))
		var sid := str(seg.get("id", "seg_%d" % i))

		# Lay along -Z from spawn so start_hall begins under spawn.
		var center_z := cursor_z - length * 0.5
		var center := Vector3(0.0, y_top - THICKNESS * 0.5, center_z)

		if role == "shortcut":
			_add_shortcut(root, sid, width, length, y_top, ice, cursor_z)
		else:
			_add_box(root, sid, role, Vector3(width, THICKNESS, length), center, ice)

		if role == "finish_hall":
			_add_finish_area(root, sid, width, length, y_top, center_z)

		cursor_z -= length
		course_z_max = maxf(course_z_max, center_z + length * 0.5)
		course_z_min = minf(course_z_min, center_z - length * 0.5)
		course_half_w = maxf(course_half_w, width * 0.5)

	for rec in recovery_segs:
		_add_recovery(root, rec, course_z_min, course_z_max, course_half_w)

	return root


func _add_box(
	parent: Node3D,
	sid: String,
	role: String,
	size: Vector3,
	center: Vector3,
	ice: bool
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Seg_%s" % sid
	body.position = center
	body.set_meta("role", role)
	body.set_meta("segment_id", sid)
	if ice:
		body.add_to_group("ice")
		body.set_meta("ice", true)
		var pmat := PhysicsMaterial.new()
		pmat.friction = ICE_FRICTION
		body.physics_material_override = pmat
	else:
		var pmat2 := PhysicsMaterial.new()
		pmat2.friction = DEFAULT_FRICTION
		body.physics_material_override = pmat2

	var col := CollisionShape3D.new()
	col.name = "Collision"
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	body.add_child(col)

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	if ice:
		mat.albedo_color = Color(0.72, 0.88, 0.98)
		mat.roughness = 0.15
		mat.metallic = 0.05
	elif role == "finish_hall":
		mat.albedo_color = Color(0.55, 0.85, 0.55)
	elif role == "start_hall":
		mat.albedo_color = Color(0.9, 0.9, 0.95)
	else:
		mat.albedo_color = Color(0.86, 0.9, 0.94)
	mi.material_override = mat
	body.add_child(mi)

	parent.add_child(body)
	return body


func _add_shortcut(
	parent: Node3D,
	sid: String,
	width: float,
	length: float,
	y_top: float,
	ice: bool,
	cursor_z: float
) -> void:
	# Stepped / tilted boxes — no CSG.
	var steps := 4
	var step_len := length / float(steps)
	# Approximate rise from previous top (~0) toward y_top across the run.
	var y_start := maxf(0.0, y_top - 1.2)
	for s in steps:
		var t0 := float(s) / float(steps)
		var t1 := float(s + 1) / float(steps)
		var y0 := lerpf(y_start, y_top, t0)
		var y1 := lerpf(y_start, y_top, t1)
		var y_mid := (y0 + y1) * 0.5
		var rise := absf(y1 - y0)
		var thick := maxf(THICKNESS, rise + 0.35)
		var z_edge := cursor_z - float(s) * step_len
		var center_z := z_edge - step_len * 0.5
		var center := Vector3(0.0, y_mid - thick * 0.5 + rise * 0.5, center_z)
		# Slight pitch so the top faces along the slope (rotate around X).
		var body := _add_box(
			parent,
			"%s_step%d" % [sid, s],
			"shortcut",
			Vector3(width, thick, step_len * 1.02),
			center,
			ice
		)
		var pitch := -atan2(y1 - y0, step_len)
		body.rotation.x = pitch * 0.85


func _add_finish_area(
	parent: Node3D,
	sid: String,
	width: float,
	length: float,
	y_top: float,
	center_z: float
) -> void:
	var area := Area3D.new()
	area.name = "Finish_%s" % sid
	area.add_to_group("finish")
	area.monitoring = true
	area.monitorable = true
	area.position = Vector3(0.0, y_top + 1.2, center_z)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width * 0.9, 2.4, length * 0.85)
	col.shape = box
	area.add_child(col)
	parent.add_child(area)


func _add_recovery(
	parent: Node3D,
	seg: Dictionary,
	course_z_min: float,
	course_z_max: float,
	course_half_w: float
) -> void:
	var sid := str(seg.get("id", "recovery"))
	var width := float(seg.get("width", 30.0))
	var length := float(seg.get("length", 48.0))
	var y_top := float(seg.get("y", -3.4))
	# Cover the built course; prefer JSON size, expand if course is longer.
	var course_len := maxf(course_z_max - course_z_min, 1.0)
	length = maxf(length, course_len + 8.0)
	width = maxf(width, course_half_w * 2.0 + 8.0)
	var center_z := (course_z_min + course_z_max) * 0.5
	var center := Vector3(0.0, y_top - THICKNESS * 0.5, center_z)
	var body := _add_box(parent, sid, "recovery", Vector3(width, THICKNESS, length), center, false)
	body.add_to_group("recovery")
	body.set_meta("recovery", true)
	var mi := body.get_node_or_null("Mesh") as MeshInstance3D
	if mi != null and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).albedo_color = Color(0.35, 0.42, 0.55)
