extends Area3D
class_name ItemBase
## 道具基类
## 提供拾取和效果应用功能

signal picked_up(item: ItemBase, picker: Node3D)

## 道具属性
@export var item_type: String = "generic"
@export var auto_pickup: bool = true
@export var pickup_effect_value: int = 0

## 视觉节点
var visual_mesh: MeshInstance3D = null
var is_picked_up: bool = false

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)

	# 添加到道具组
	add_to_group("items")

	# 浮动动画
	_start_floating_animation()

	print("[ItemBase] Initialized: Type=%s, Value=%d" % [item_type, pickup_effect_value])

func _on_body_entered(body: Node3D) -> void:
	## 碰撞拾取
	if is_picked_up:
		return

	if auto_pickup and (body.is_in_group("player") or body.has_method("pickup_item")):
		pickup(body)

func pickup(picker: Node3D) -> void:
	## 拾取道具
	if is_picked_up:
		return

	is_picked_up = true
	print("[ItemBase] Picked up by %s" % picker.name)

	# 应用效果
	apply_effect(picker)

	# 发送信号
	picked_up.emit(self, picker)

	# 拾取动画
	_play_pickup_animation()

func apply_effect(picker: Node3D) -> void:
	## 应用道具效果（子类重写）
	pass

func _play_pickup_animation() -> void:
	## 拾取动画（向上消失）
	if visual_mesh:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(visual_mesh, "position:y", position.y + 2.0, 0.3)
		tween.tween_property(visual_mesh, "scale", Vector3.ZERO, 0.3)
		tween.finished.connect(_on_pickup_animation_finished)

func _on_pickup_animation_finished() -> void:
	queue_free()

func _start_floating_animation() -> void:
	## 浮动动画
	if visual_mesh:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(visual_mesh, "position:y", 0.3, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(visual_mesh, "position:y", -0.3, 1.0).set_trans(Tween.TRANS_SINE)

func _create_placeholder_visual(color: Color, radius: float) -> void:
	## 创建占位符视觉（球体）
	visual_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	visual_mesh.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3  # 发光效果
	visual_mesh.material_override = material

	add_child(visual_mesh)
