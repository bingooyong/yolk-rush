extends CharacterBody3D
## Gameplay layer: collision, physics, state. No visual.

const GRAVITY: float = 9.8

@export var character_id: String = "yolk_hero"

var character_data: Dictionary =
var collision_profile: Dictionary = {}

## 战斗组件
var animation_controller: AnimationController
var health_component: HealthComponent
var combat_system: CombatSystem

## 视觉组件
var visual_character: Node3D
var attack_vfx: CPUParticles3D
var hit_vfx: CPUParticles3D

func _ready() -> void:
	if not character_id.is_empty():
		_load_character_data()
	_setup_collision()
	_setup_combat_components()
	_setup_visual_components()

func _load_character_data() -> void:
	var data_path := "res://data/characters/%s.json" % character_id
	if not FileAccess.file_exists(data_path):
		push_error("[CharacterGameplay] Character data not found: %s" % data_path)
		return

	var file := FileAccess.open(data_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[CharacterGameplay] Failed to parse JSON: %s" % data_path)
		return

	character_data = json.data
	collision_profile = character_data.get("collision_profile", {})

func _setup_collision() -> void:
	if collision_profile.is_empty():
		# Use default values from yolk_hero.json spec
		collision_profile = {
			"height": 1.48,
			"radius": 0.34,
			"offset_y": 0.74
		}

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = collision_profile.get("height", 1.48)
	capsule.radius = collision_profile.get("radius", 0.34)
	shape.shape = capsule
	shape.position.y = collision_profile.get("offset_y", 0.74)
	add_child(shape)
	shape.owner = self

func load_character(data: Dictionary) -> void:
	character_data = data
	collision_profile = data.get("collision_profile", {})
	_setup_collision()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

	## 更新动画
	if animation_controller:
		animation_controller.update_animation(velocity, is_on_floor())

func _setup_combat_components() -> void:
	## 创建 AnimationController
	animation_controller = AnimationController.new()
	animation_controller.name = "AnimationController"
	add_child(animation_controller)

	## 创建 HealthComponent
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	health_component.max_health = 100.0
	add_child(health_component)

	## 创建 CombatSystem
	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	combat_system.base_damage = 15.0
	combat_system.attack_range = 2.0
	add_child(combat_system)

	## 连接信号
	if health_component:
		health_component.damage_taken.connect(_on_damage_taken)
		health_component.died.connect(_on_died)

func _on_damage_taken(amount: float, source: Node) -> void:
	if combat_system:
		combat_system.on_hit()

	# 播放受击特效
	if hit_vfx:
		hit_vfx.play_effect()
	if visual_character and visual_character.has_method("play_hit"):
		visual_character.play_hit()

func _on_died() -> void:
	print("[CharacterGameplay] %s died" % name)

## 攻击接口
func attack() -> bool:
	if combat_system:
		var success := combat_system.try_attack()
		if success:
			# 播放攻击特效
			if attack_vfx:
				attack_vfx.play_effect()
			if visual_character and visual_character.has_method("play_attack"):
				visual_character.play_attack()
		return success
	return false

## 获取生命值
func get_health() -> float:
	if health_component:
		return health_component.current_health
	return 0.0

## 获取生命值百分比
func get_health_percent() -> float:
	if health_component:
		return health_component.get_health_percent()
	return 0.0

## 是否存活
func is_alive() -> bool:
	if health_component:
		return not health_component.is_dead
	return true

func _setup_visual_components() -> void:
	## 创建视觉角色
	var VisualCharacter := load("res://scripts/visual/visual_character.gd")
	visual_character = Node3D.new()
	visual_character.set_script(VisualCharacter)
	visual_character.name = "VisualCharacter"
	add_child(visual_character)

	## 创建攻击特效
	var AttackVFX := load("res://scripts/vfx/attack_vfx.gd")
	attack_vfx = CPUParticles3D.new()
	attack_vfx.set_script(AttackVFX)
	attack_vfx.name = "AttackVFX"
	attack_vfx.position = Vector3(0, 1.0, -0.5)  # 角色前方
	add_child(attack_vfx)

	## 创建受击特效
	var HitVFX := load("res://scripts/vfx/hit_vfx.gd")
	hit_vfx = CPUParticles3D.new()
	hit_vfx.set_script(HitVFX)
	hit_vfx.name = "HitVFX"
	hit_vfx.position = Vector3(0, 1.0, 0)  # 角色中心
	add_child(hit_vfx)
