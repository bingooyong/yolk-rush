extends CharacterBody3D
## 简单的测试敌人，用于验证战斗系统

@export var health: float = 50.0
@export var patrol_speed: float = 2.0
@export var patrol_distance: float = 5.0

var start_position: Vector3
var patrol_direction: float = 1.0
var health_component: Node
var animation_controller: Node
var visual_node: Node3D
var hit_vfx: CPUParticles3D

func _ready() -> void:
	start_position = global_position
	collision_layer = 2  ## Layer 2 = 敌人
	collision_mask = 1   ## Mask 1 = 玩家和环境

	_setup_components()
	_setup_vfx()
	print("[TestEnemy] Spawned at %s with %.0f HP" % [global_position, health])

func _setup_components() -> void:
	## 创建 HealthComponent
	var HealthComponent := preload("res://scripts/gameplay/health_component.gd")
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	health_component.max_health = health
	add_child(health_component)

	if health_component:
		health_component.damage_taken.connect(_on_damage_taken)
		health_component.died.connect(_on_died)

	## 创建简单的视觉（红色胶囊）
	visual_node = _create_visual()

func _create_visual() -> Node3D:
	var visual := Node3D.new()
	visual.name = "Visual"

	# 身体 - 红色胶囊
	var body := CSGCylinder3D.new()
	body.name = "Body"
	body.radius = 0.4
	body.height = 1.2
	body.sides = 8
	body.material = _create_material(Color(0.8, 0.2, 0.2))
	visual.add_child(body)

	# 头部 - 深红色球体
	var head := CSGSphere3D.new()
	head.name = "Head"
	head.radius = 0.35
	head.radial_segments = 8
	head.rings = 6
	head.material = _create_material(Color(0.6, 0.1, 0.1))
	head.position = Vector3(0, 0.75, 0)
	visual.add_child(head)

	# 眼睛 - 黄色发光
	for i in 2:
		var eye := CSGSphere3D.new()
		eye.name = "Eye%d" % i
		eye.radius = 0.08
		eye.radial_segments = 6
		eye.rings = 4
		var eye_mat := _create_material(Color(1.0, 0.9, 0.2))
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1.0, 0.9, 0.2)
		eye_mat.emission_energy_multiplier = 2.0
		eye.material = eye_mat
		eye.position = Vector3(-0.15 + i * 0.3, 0.85, -0.3)
		visual.add_child(eye)

	visual.position.y = 0.6
	add_child(visual)
	return visual

func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.2
	mat.roughness = 0.8
	return mat

func _setup_vfx() -> void:
	## 创建受击特效
	var HitVFX := load("res://scripts/vfx/hit_vfx.gd")
	hit_vfx = CPUParticles3D.new()
	hit_vfx.set_script(HitVFX)
	hit_vfx.name = "HitVFX"
	hit_vfx.position = Vector3(0, 1.0, 0)
	add_child(hit_vfx)

func _physics_process(delta: float) -> void:
	if health_component and health_component.is_dead:
		return

	## 简单的来回巡逻
	var target_x := start_position.x + patrol_distance * patrol_direction
	var current_x := global_position.x

	if abs(target_x - current_x) < 0.1:
		patrol_direction *= -1.0

	velocity.x = patrol_speed * patrol_direction
	velocity.y -= 9.8 * delta  ## 重力

	move_and_slide()

func take_damage(amount: float, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)

func _on_damage_taken(amount: float, source: Node) -> void:
	print("[TestEnemy] Took %.1f damage from %s" % [amount, source.name if source else "unknown"])

	# 播放受击特效
	if hit_vfx:
		hit_vfx.play_effect()

	# 受击反馈：整个视觉节点闪白
	if visual_node:
		_play_hit_flash()

func _on_died() -> void:
	print("[TestEnemy] Died")

	# 死亡特效：爆炸粒子
	if hit_vfx:
		hit_vfx.amount = 30  # 更多粒子
		hit_vfx.play_effect()

	# 死亡动画：缩小并消失
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)

func _play_hit_flash() -> void:
	# 所有 CSG 节点变白闪烁
	for child in visual_node.get_children():
		if child is CSGPrimitive3D:
			var original_mat := child.material as StandardMaterial3D
			if original_mat:
				var flash_mat := original_mat.duplicate()
				flash_mat.albedo_color = Color.WHITE
				child.material = flash_mat

				# 0.1 秒后恢复
				await get_tree().create_timer(0.1).timeout
				child.material = original_mat
