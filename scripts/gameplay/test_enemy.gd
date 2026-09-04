extends CharacterBody3D
## 简单的测试敌人，用于验证战斗系统

@export var health: float = 50.0
@export var patrol_speed: float = 2.0
@export var patrol_distance: float = 5.0

var start_position: Vector3
var patrol_direction: float = 1.0
var health_component: Node
var animation_controller: Node

func _ready() -> void:
	start_position = global_position
	collision_layer = 2  ## Layer 2 = 敌人
	collision_mask = 1   ## Mask 1 = 玩家和环境

	_setup_components()
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
	_create_visual()

func _create_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.9

	## 红色材质
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2)
	mesh_instance.set_surface_override_material(0, material)

	add_child(mesh_instance)

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

	## 受击反馈：变白一帧
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var material := mesh.get_surface_override_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			material.albedo_color = Color(1.0, 0.2, 0.2)

func _on_died() -> void:
	print("[TestEnemy] Died")

	## 死亡动画：缩小并消失
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)
