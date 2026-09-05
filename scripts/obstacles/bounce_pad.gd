extends ObstacleBase
class_name BouncePad
## 弹跳板 - 将玩家弹向空中

@export var bounce_force: float = 15.0  # 弹跳力度
@export var bounce_direction: Vector3 = Vector3.UP  # 弹跳方向
@export var bounce_angle: float = 90.0  # 弹跳角度（度）
@export var pad_size: Vector3 = Vector3(2.0, 0.3, 2.0)  # 弹跳板尺寸
@export var cooldown_time: float = 0.5  # 冷却时间

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0

var pad_mesh: MeshInstance3D
var arrow_indicator: MeshInstance3D
var animation_tween: Tween

func _initialize_obstacle() -> void:
	obstacle_name = "Bounce Pad"
	damage_type = DamageType.NONE  # 弹跳板不造成伤害
	damage_amount = 0.0
	knockback_force = 0.0  # 使用专门的弹跳力

	_create_bounce_pad()

func _create_bounce_pad() -> void:
	# 创建弹跳板平台
	pad_mesh = MeshInstance3D.new()
	pad_mesh.name = "PadMesh"

	var mesh = BoxMesh.new()
	mesh.size = pad_size
	pad_mesh.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.3)  # 绿色
	material.emission_enabled = true
	material.emission = Color(0.1, 0.4, 0.15)
	material.metallic = 0.3
	material.roughness = 0.6
	pad_mesh.material_override = material

	add_child(pad_mesh)

	# 创建方向指示箭头
	_create_arrow_indicator()

	# 设置碰撞
	var shape = BoxShape3D.new()
	shape.size = pad_size

	collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	collision_area.add_child(collision_shape)

func _create_arrow_indicator() -> void:
	arrow_indicator = MeshInstance3D.new()
	arrow_indicator.name = "ArrowIndicator"

	# 创建箭头形状（简单的圆锥）
	var arrow_mesh = CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.3
	arrow_mesh.height = 0.8
	arrow_indicator.mesh = arrow_mesh

	var arrow_material = StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1.0, 1.0, 0.3)  # 黄色
	arrow_material.emission_enabled = true
	arrow_material.emission = Color(0.5, 0.5, 0.15)
	arrow_indicator.material_override = arrow_material

	# 根据弹跳方向旋转箭头
	arrow_indicator.position = Vector3(0, pad_size.y / 2 + 0.5, 0)
	arrow_indicator.look_at(global_position + bounce_direction, Vector3.UP)
	arrow_indicator.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))

	add_child(arrow_indicator)

	# 添加悬浮动画
	_start_arrow_animation()

func _start_arrow_animation() -> void:
	animation_tween = create_tween()
	animation_tween.set_loops()
	animation_tween.tween_property(arrow_indicator, "position:y", pad_size.y / 2 + 0.7, 0.8)
	animation_tween.tween_property(arrow_indicator, "position:y", pad_size.y / 2 + 0.5, 0.8)

func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			_reset_visual()

func _apply_effect(player: Node3D) -> void:
	if is_on_cooldown:
		return

	# 应用弹跳力
	_apply_bounce(player)

	# 触发冷却
	is_on_cooldown = true
	cooldown_timer = cooldown_time

	# 视觉反馈
	_play_bounce_effect()

	# 触发信号
	obstacle_triggered.emit(player)
	_on_triggered(player)

func _apply_bounce(player: Node) -> void:
	if not player is CharacterBody3D:
		return

	# 计算弹跳速度
	var bounce_velocity = bounce_direction.normalized() * bounce_force

	# 应用到玩家
	if player.has_method("apply_bounce"):
		player.apply_bounce(bounce_velocity)
	elif player.has_method("set_velocity"):
		# 保留水平速度，只改变垂直方向
		var current_velocity = player.velocity
		if bounce_direction.y > 0.5:  # 主要是向上弹
			player.velocity = Vector3(current_velocity.x, bounce_velocity.y, current_velocity.z)
		else:
			player.velocity = bounce_velocity

	print("[BouncePad] Bounced player: %s with force %.1f" % [player.name, bounce_force])

func _play_bounce_effect() -> void:
	# 压缩弹跳板
	var compress_tween = create_tween()
	compress_tween.set_parallel(true)
	compress_tween.tween_property(pad_mesh, "scale:y", 0.5, 0.1)
	compress_tween.tween_property(pad_mesh, "scale:y", 1.0, 0.3).set_delay(0.1)

	# 发光效果
	var material = pad_mesh.material_override as StandardMaterial3D
	if material:
		compress_tween.tween_property(material, "emission_energy", 2.0, 0.1)
		compress_tween.tween_property(material, "emission_energy", 1.0, 0.3).set_delay(0.1)

func _reset_visual() -> void:
	pad_mesh.scale = Vector3.ONE

func _on_triggered(player: Node) -> void:
	print("[BouncePad] Triggered by: %s" % player.name)

## 设置弹跳力度
func set_bounce_force(force: float) -> void:
	bounce_force = force

## 设置弹跳方向
func set_bounce_direction(direction: Vector3) -> void:
	bounce_direction = direction.normalized()
	# 更新箭头方向
	if arrow_indicator:
		arrow_indicator.look_at(global_position + bounce_direction, Vector3.UP)
		arrow_indicator.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))

## 设置弹跳角度（相对于地面）
func set_bounce_angle(angle_degrees: float) -> void:
	bounce_angle = angle_degrees
	var angle_rad = deg_to_rad(angle_degrees)
	bounce_direction = Vector3(0, sin(angle_rad), cos(angle_rad))
	set_bounce_direction(bounce_direction)

func _on_reset() -> void:
	is_on_cooldown = false
	cooldown_timer = 0.0
	_reset_visual()
