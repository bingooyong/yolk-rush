class_name PlaceholderYolk
extends Node3D
## Procedural stand-in until a contract-passing GLB exists. Same CharacterVisual interface.

const BODY_COLOR := Color("F2C14E")
const SCARF_COLOR := Color("C45C26")
const BOOT_COLOR := Color("3D2A1A")

var body: MeshInstance3D
var scarf: MeshInstance3D
var boot_l: MeshInstance3D
var boot_r: MeshInstance3D
var _body_base_y := 0.95
var _breath_t := 0.0

func build_from_definition(def: CharacterDefinition) -> void:
	_clear()
	var body_rough := 0.42
	var scarf_rough := 0.86
	var boot_rough := 0.7
	if def != null:
		for m in def.materials:
			if typeof(m) != TYPE_DICTIONARY:
				continue
			var slot := str(m.get("slot", ""))
			var r := float(m.get("roughness", 0.5))
			match slot:
				"body":
					body_rough = r
				"scarf":
					scarf_rough = r
				"boots":
					boot_rough = r

	body = _mesh_instance("Body", _sphere(0.42), BODY_COLOR, body_rough)
	body.position = Vector3(0.0, _body_base_y, 0.0)
	add_child(body)

	scarf = _mesh_instance("Scarf", _torus(0.22, 0.06), SCARF_COLOR, scarf_rough)
	scarf.position = Vector3(0.0, 1.18, 0.05)
	scarf.rotation_degrees = Vector3(70.0, 0.0, 0.0)
	add_child(scarf)

	boot_l = _mesh_instance("BootL", _capsule(0.22, 0.09), BOOT_COLOR, boot_rough)
	boot_l.position = Vector3(-0.14, 0.14, 0.02)
	add_child(boot_l)

	boot_r = _mesh_instance("BootR", _capsule(0.22, 0.09), BOOT_COLOR, boot_rough)
	boot_r.position = Vector3(0.14, 0.14, 0.02)
	add_child(boot_r)

func set_pose_visual(pose_name: String, delta: float) -> void:
	if body == null:
		return
	_breath_t += delta
	match pose_name:
		"idle":
			body.position.y = _body_base_y + sin(_breath_t * 2.0) * 0.02
			body.scale = Vector3.ONE * (1.0 + sin(_breath_t * 2.0) * 0.015)
		"run":
			body.position.y = _body_base_y + abs(sin(_breath_t * 10.0)) * 0.04
			body.rotation_degrees.x = sin(_breath_t * 10.0) * 6.0
		"jump_start", "airborne":
			body.position.y = _body_base_y + 0.12
			body.scale = Vector3(0.95, 1.08, 0.95)
		"fall":
			body.position.y = _body_base_y + 0.08
			body.rotation_degrees.x = 12.0
		"land":
			body.position.y = _body_base_y - 0.04
			body.scale = Vector3(1.08, 0.9, 1.08)
		"hit":
			body.rotation_degrees.z = 18.0
		"fail":
			body.rotation_degrees.x = 55.0
			body.position.y = _body_base_y - 0.2
		_:
			body.position.y = _body_base_y
			body.rotation_degrees = Vector3.ZERO
			body.scale = Vector3.ONE

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	body = null
	scarf = null
	boot_l = null
	boot_r = null

func _mesh_instance(node_name: String, mesh: Mesh, albedo: Color, roughness: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = 0.0
	mi.material_override = mat
	return mi

func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 24
	m.rings = 12
	return m

func _torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 16
	m.ring_segments = 24
	return m

func _capsule(height: float, radius: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.height = height
	m.radius = radius
	m.radial_segments = 12
	m.rings = 4
	return m
