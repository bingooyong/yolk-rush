extends Node3D
## Visual Enemy: CSG 几何体敌人 - 发光球体 + 尖刺

@export var enemy_color: Color = Color(0.9, 0.2, 0.3)  ## 红色
@export var glow_intensity: float = 2.0

var core: CSGSphere3D
var spikes: Array[CSGCylinder3D] = []
var glow_material: StandardMaterial3D

func _ready() -> void:
	_create_enemy()
	_start_idle_animation()

func _create_enemy() -> void:
	# 核心球体
	core = CSGSphere3D.new()
	core.radius = 0.4
	glow_material = _create_glow_material(enemy_color)
	core.material = glow_material
	add_child(core)

	# 6 个尖刺（上下左右前后）
	var spike_directions := [
		Vector3(1, 0, 0),    # 右
		Vector3(-1, 0, 0),   # 左
		Vector3(0, 1, 0),    # 上
		Vector3(0, -1, 0),   # 下
		Vector3(0, 0, 1),    # 前
		Vector3(0, 0, -1),   # 后
	]

	for dir in spike_directions:
		var spike := CSGCylinder3D.new()
		spike.radius = 0.08
		spike.height = 0.4
		spike.position = dir * 0.5

		# 旋转尖刺指向外侧
		if dir.x != 0:
			spike.rotation_degrees = Vector3(0, 0, 90 if dir.x > 0 else -90)
		elif dir.z != 0:
			spike.rotation_degrees = Vector3(90 if dir.z > 0 else -90, 0, 0)

		spike.material = _create_glow_material(enemy_color.darkened(0.2))
		add_child(spike)
		spikes.append(spike)

func _create_glow_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow_intensity
	mat.metallic = 0.5
	mat.roughness = 0.3
	return mat

func _start_idle_animation() -> void:
	# 缓慢旋转 + 呼吸效果
	var rotate_tween := create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(self, "rotation_degrees:y", 360, 4.0)

	var breath_tween := create_tween()
	breath_tween.set_loops()
	breath_tween.tween_property(core, "scale", Vector3(1.1, 1.1, 1.1), 1.0)
	breath_tween.tween_property(core, "scale", Vector3(1.0, 1.0, 1.0), 1.0)

func play_hit() -> void:
	# 受击 - 闪白 + 震动
	_flash_white()
	_shake()

func play_death() -> void:
	# 死亡 - 爆炸缩小
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0, 0, 0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _flash_white() -> void:
	if not core:
		return

	var original_color := glow_material.albedo_color
	glow_material.albedo_color = Color.WHITE
	glow_material.emission = Color.WHITE

	await get_tree().create_timer(0.1).timeout

	glow_material.albedo_color = original_color
	glow_material.emission = original_color

func _shake() -> void:
	var original_pos := position
	var tween := create_tween()
	for i in 5:
		tween.tween_property(self, "position", original_pos + Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1)), 0.02)
	tween.tween_property(self, "position", original_pos, 0.05)
