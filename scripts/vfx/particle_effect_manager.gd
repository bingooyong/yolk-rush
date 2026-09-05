extends Node
class_name ParticleEffectManager
## 粒子效果管理器 - 统一管理和池化粒子系统

signal effect_spawned(effect: GPUParticles3D)
signal effect_finished(effect: GPUParticles3D)

## 粒子效果池配置
@export var max_pool_size: int = 50
@export var initial_pool_size: int = 10
@export var auto_cleanup_interval: float = 5.0

## 预加载的粒子效果
var effect_templates: Dictionary = {}

## 粒子池（按类型分组）
var particle_pools: Dictionary = {}

## 活跃的粒子效果
var active_effects: Array[GPUParticles3D] = []

## 清理计时器
var cleanup_timer: float = 0.0

func _ready() -> void:
	_load_effect_templates()
	_initialize_pools()
	print("[ParticleEffectManager] Initialized")

func _process(delta: float) -> void:
	_update_active_effects(delta)

	# 定期清理
	cleanup_timer += delta
	if cleanup_timer >= auto_cleanup_interval:
		cleanup_timer = 0.0
		_cleanup_finished_effects()

## 加载粒子效果模板
func _load_effect_templates() -> void:
	# 道具拾取特效
	effect_templates["pickup_sparkle"] = _create_pickup_sparkle_template()
	effect_templates["pickup_flash"] = _create_pickup_flash_template()
	effect_templates["pickup_trail"] = _create_pickup_trail_template()

	# 障碍碰撞特效
	effect_templates["collision_spark"] = _create_collision_spark_template()
	effect_templates["collision_debris"] = _create_collision_debris_template()
	effect_templates["impact_wave"] = _create_impact_wave_template()

	# 技能释放特效
	effect_templates["skill_charge"] = _create_skill_charge_template()
	effect_templates["skill_explosion"] = _create_skill_explosion_template()
	effect_templates["skill_trail"] = _create_skill_trail_template()

	# 环境粒子
	effect_templates["ambient_dust"] = _create_ambient_dust_template()
	effect_templates["snow_fall"] = _create_snow_fall_template()
	effect_templates["rain_drop"] = _create_rain_drop_template()

	print("[ParticleEffectManager] Loaded %d effect templates" % effect_templates.size())

## 初始化粒子池
func _initialize_pools() -> void:
	for effect_name in effect_templates.keys():
		particle_pools[effect_name] = []

		# 预创建初始池
		for i in range(initial_pool_size):
			var particle = _create_particle_instance(effect_name)
			particle.emitting = false
			particle.visible = false
			add_child(particle)
			particle_pools[effect_name].append(particle)

	print("[ParticleEffectManager] Initialized pools with %d particles" % (effect_templates.size() * initial_pool_size))

## 从池中获取粒子效果
func spawn_effect(effect_name: String, position: Vector3, direction: Vector3 = Vector3.UP, scale: float = 1.0) -> GPUParticles3D:
	if not effect_templates.has(effect_name):
		push_warning("[ParticleEffectManager] Unknown effect: %s" % effect_name)
		return null

	var particle = _get_from_pool(effect_name)

	# 设置位置和方向
	particle.global_position = position
	particle.scale = Vector3.ONE * scale

	# 根据方向旋转（可选）
	if direction != Vector3.UP:
		particle.look_at(position + direction, Vector3.UP)

	# 激活粒子
	particle.visible = true
	particle.emitting = true
	particle.restart()

	# 添加到活跃列表
	active_effects.append(particle)

	effect_spawned.emit(particle)

	return particle

## 从池中获取或创建新粒子
func _get_from_pool(effect_name: String) -> GPUParticles3D:
	var pool = particle_pools.get(effect_name, [])

	# 尝试从池中获取未使用的粒子
	for particle in pool:
		if not particle.emitting and not particle.visible:
			return particle

	# 池已满，检查是否可以扩展
	if pool.size() < max_pool_size:
		var new_particle = _create_particle_instance(effect_name)
		new_particle.emitting = false
		new_particle.visible = false
		add_child(new_particle)
		pool.append(new_particle)
		return new_particle

	# 池已达上限，复用最早的粒子
	return pool[0]

## 创建粒子实例
func _create_particle_instance(effect_name: String) -> GPUParticles3D:
	var template = effect_templates[effect_name]
	var particle = GPUParticles3D.new()

	# 复制模板属性
	particle.amount = template.get("amount", 32)
	particle.lifetime = template.get("lifetime", 1.0)
	particle.one_shot = template.get("one_shot", true)
	particle.explosiveness = template.get("explosiveness", 0.0)
	particle.randomness = template.get("randomness", 0.0)
	particle.fixed_fps = template.get("fixed_fps", 30)
	particle.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME

	# 创建粒子材质
	var material = _create_particle_material(template)
	particle.process_material = material

	# 创建网格
	var mesh = _create_particle_mesh(template)
	particle.draw_pass_1 = mesh

	return particle

## 创建粒子材质
func _create_particle_material(template: Dictionary) -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# 发射形状
	var emission_shape = template.get("emission_shape", ParticleProcessMaterial.EMISSION_SHAPE_SPHERE)
	material.emission_shape = emission_shape
	material.emission_sphere_radius = template.get("emission_radius", 0.5)

	# 方向和速度
	material.direction = template.get("direction", Vector3.UP)
	material.spread = template.get("spread", 45.0)
	material.initial_velocity_min = template.get("velocity_min", 1.0)
	material.initial_velocity_max = template.get("velocity_max", 3.0)

	# 重力
	material.gravity = template.get("gravity", Vector3(0, -9.8, 0))

	# 缩放
	material.scale_min = template.get("scale_min", 0.1)
	material.scale_max = template.get("scale_max", 0.3)

	# 颜色
	if template.has("color_ramp"):
		var gradient = Gradient.new()
		var color_data = template["color_ramp"]
		for i in range(color_data.size()):
			var point = color_data[i]
			gradient.add_point(point[0], point[1])
		material.color_ramp = gradient

	# 阻尼
	material.damping_min = template.get("damping_min", 0.0)
	material.damping_max = template.get("damping_max", 1.0)

	return material

## 创建粒子网格
func _create_particle_mesh(template: Dictionary) -> Mesh:
	var mesh_type = template.get("mesh_type", "quad")

	match mesh_type:
		"quad":
			var quad = QuadMesh.new()
			quad.size = Vector2(0.2, 0.2)
			return quad
		"sphere":
			var sphere = SphereMesh.new()
			sphere.radius = 0.1
			sphere.height = 0.2
			return sphere
		"box":
			var box = BoxMesh.new()
			box.size = Vector3(0.1, 0.1, 0.1)
			return box
		_:
			return QuadMesh.new()

## 更新活跃粒子
func _update_active_effects(delta: float) -> void:
	# 这里可以添加自定义更新逻辑
	pass

## 清理已完成的粒子
func _cleanup_finished_effects() -> void:
	var to_remove: Array[GPUParticles3D] = []

	for effect in active_effects:
		if not effect.emitting and effect.one_shot:
			# 检查所有粒子是否已结束
			if not effect.is_emitting():
				effect.visible = false
				to_remove.append(effect)
				effect_finished.emit(effect)

	for effect in to_remove:
		active_effects.erase(effect)

	if to_remove.size() > 0:
		print("[ParticleEffectManager] Cleaned up %d finished effects" % to_remove.size())

## 停止粒子效果
func stop_effect(effect: GPUParticles3D) -> void:
	if effect:
		effect.emitting = false
		if effect in active_effects:
			active_effects.erase(effect)

## 停止所有粒子
func stop_all_effects() -> void:
	for effect in active_effects:
		effect.emitting = false
		effect.visible = false
	active_effects.clear()

## 获取活跃粒子数量
func get_active_count() -> int:
	return active_effects.size()

## 获取池使用情况
func get_pool_stats() -> Dictionary:
	var stats = {}
	for effect_name in particle_pools.keys():
		var pool = particle_pools[effect_name]
		var active = 0
		for particle in pool:
			if particle.emitting or particle.visible:
				active += 1
		stats[effect_name] = {
			"total": pool.size(),
			"active": active,
			"available": pool.size() - active
		}
	return stats

## ========================================
## 粒子效果模板定义
## ========================================

## 道具拾取 - 闪光效果
func _create_pickup_sparkle_template() -> Dictionary:
	return {
		"amount": 20,
		"lifetime": 0.8,
		"one_shot": true,
		"explosiveness": 0.8,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.3,
		"direction": Vector3.UP,
		"spread": 180.0,
		"velocity_min": 2.0,
		"velocity_max": 4.0,
		"gravity": Vector3(0, -2.0, 0),
		"scale_min": 0.05,
		"scale_max": 0.15,
		"color_ramp": [
			[0.0, Color(1.0, 1.0, 0.5, 1.0)],
			[0.5, Color(1.0, 0.8, 0.2, 0.8)],
			[1.0, Color(1.0, 0.5, 0.0, 0.0)]
		],
		"mesh_type": "quad"
	}

## 道具拾取 - 闪光爆发
func _create_pickup_flash_template() -> Dictionary:
	return {
		"amount": 10,
		"lifetime": 0.3,
		"one_shot": true,
		"explosiveness": 1.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.1,
		"direction": Vector3.UP,
		"spread": 180.0,
		"velocity_min": 3.0,
		"velocity_max": 5.0,
		"gravity": Vector3.ZERO,
		"scale_min": 0.2,
		"scale_max": 0.4,
		"color_ramp": [
			[0.0, Color(1.0, 1.0, 1.0, 1.0)],
			[0.3, Color(1.0, 1.0, 0.8, 0.8)],
			[1.0, Color(1.0, 0.8, 0.0, 0.0)]
		],
		"mesh_type": "quad"
	}

## 道具拾取 - 轨迹
func _create_pickup_trail_template() -> Dictionary:
	return {
		"amount": 15,
		"lifetime": 0.5,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
		"direction": Vector3.DOWN,
		"spread": 20.0,
		"velocity_min": 0.5,
		"velocity_max": 1.0,
		"gravity": Vector3(0, -1.0, 0),
		"scale_min": 0.03,
		"scale_max": 0.08,
		"color_ramp": [
			[0.0, Color(1.0, 1.0, 0.5, 0.8)],
			[1.0, Color(1.0, 0.8, 0.2, 0.0)]
		],
		"mesh_type": "quad"
	}

## 障碍碰撞 - 火花
func _create_collision_spark_template() -> Dictionary:
	return {
		"amount": 25,
		"lifetime": 0.6,
		"one_shot": true,
		"explosiveness": 0.9,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.2,
		"direction": Vector3.UP,
		"spread": 120.0,
		"velocity_min": 3.0,
		"velocity_max": 6.0,
		"gravity": Vector3(0, -9.8, 0),
		"scale_min": 0.02,
		"scale_max": 0.05,
		"color_ramp": [
			[0.0, Color(1.0, 0.8, 0.3, 1.0)],
			[0.5, Color(1.0, 0.5, 0.1, 0.8)],
			[1.0, Color(0.5, 0.2, 0.0, 0.0)]
		],
		"mesh_type": "quad"
	}

## 障碍碰撞 - 碎片
func _create_collision_debris_template() -> Dictionary:
	return {
		"amount": 15,
		"lifetime": 1.0,
		"one_shot": true,
		"explosiveness": 0.8,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.3,
		"direction": Vector3.UP,
		"spread": 90.0,
		"velocity_min": 2.0,
		"velocity_max": 4.0,
		"gravity": Vector3(0, -9.8, 0),
		"scale_min": 0.05,
		"scale_max": 0.15,
		"color_ramp": [
			[0.0, Color(0.6, 0.6, 0.6, 1.0)],
			[0.5, Color(0.5, 0.5, 0.5, 0.8)],
			[1.0, Color(0.3, 0.3, 0.3, 0.0)]
		],
		"mesh_type": "box"
	}

## 碰撞冲击波
func _create_impact_wave_template() -> Dictionary:
	return {
		"amount": 8,
		"lifetime": 0.4,
		"one_shot": true,
		"explosiveness": 1.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.1,
		"direction": Vector3.UP,
		"spread": 180.0,
		"velocity_min": 4.0,
		"velocity_max": 6.0,
		"gravity": Vector3.ZERO,
		"scale_min": 0.3,
		"scale_max": 0.6,
		"color_ramp": [
			[0.0, Color(1.0, 1.0, 1.0, 0.8)],
			[0.3, Color(0.8, 0.8, 1.0, 0.5)],
			[1.0, Color(0.5, 0.5, 0.8, 0.0)]
		],
		"mesh_type": "quad"
	}

## 技能充能
func _create_skill_charge_template() -> Dictionary:
	return {
		"amount": 30,
		"lifetime": 1.0,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 1.0,
		"direction": Vector3.ZERO,
		"spread": 180.0,
		"velocity_min": -2.0,
		"velocity_max": -1.0,
		"gravity": Vector3.ZERO,
		"scale_min": 0.05,
		"scale_max": 0.1,
		"color_ramp": [
			[0.0, Color(0.3, 0.5, 1.0, 0.0)],
			[0.5, Color(0.5, 0.7, 1.0, 0.8)],
			[1.0, Color(0.7, 0.9, 1.0, 0.0)]
		],
		"mesh_type": "quad"
	}

## 技能爆炸
func _create_skill_explosion_template() -> Dictionary:
	return {
		"amount": 40,
		"lifetime": 0.8,
		"one_shot": true,
		"explosiveness": 1.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_radius": 0.2,
		"direction": Vector3.UP,
		"spread": 180.0,
		"velocity_min": 4.0,
		"velocity_max": 8.0,
		"gravity": Vector3(0, -2.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.3,
		"color_ramp": [
			[0.0, Color(1.0, 0.8, 0.3, 1.0)],
			[0.5, Color(1.0, 0.5, 0.2, 0.8)],
			[1.0, Color(0.5, 0.2, 0.1, 0.0)]
		],
		"mesh_type": "sphere"
	}

## 技能轨迹
func _create_skill_trail_template() -> Dictionary:
	return {
		"amount": 20,
		"lifetime": 0.6,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
		"direction": Vector3.DOWN,
		"spread": 30.0,
		"velocity_min": 0.5,
		"velocity_max": 1.5,
		"gravity": Vector3.ZERO,
		"scale_min": 0.08,
		"scale_max": 0.15,
		"color_ramp": [
			[0.0, Color(0.5, 0.7, 1.0, 0.8)],
			[1.0, Color(0.3, 0.5, 0.8, 0.0)]
		],
		"mesh_type": "quad"
	}

## 环境 - 灰尘
func _create_ambient_dust_template() -> Dictionary:
	return {
		"amount": 50,
		"lifetime": 3.0,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_radius": 5.0,
		"direction": Vector3.UP,
		"spread": 20.0,
		"velocity_min": 0.2,
		"velocity_max": 0.5,
		"gravity": Vector3.ZERO,
		"scale_min": 0.05,
		"scale_max": 0.15,
		"color_ramp": [
			[0.0, Color(0.8, 0.8, 0.7, 0.0)],
			[0.3, Color(0.7, 0.7, 0.6, 0.3)],
			[0.7, Color(0.6, 0.6, 0.5, 0.3)],
			[1.0, Color(0.5, 0.5, 0.4, 0.0)]
		],
		"mesh_type": "quad"
	}

## 环境 - 雪花
func _create_snow_fall_template() -> Dictionary:
	return {
		"amount": 100,
		"lifetime": 5.0,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_radius": 10.0,
		"direction": Vector3.DOWN,
		"spread": 10.0,
		"velocity_min": 0.5,
		"velocity_max": 1.0,
		"gravity": Vector3(0, -0.5, 0),
		"scale_min": 0.03,
		"scale_max": 0.08,
		"color_ramp": [
			[0.0, Color(1.0, 1.0, 1.0, 0.8)],
			[1.0, Color(0.9, 0.9, 1.0, 0.6)]
		],
		"mesh_type": "quad"
	}

## 环境 - 雨滴
func _create_rain_drop_template() -> Dictionary:
	return {
		"amount": 200,
		"lifetime": 2.0,
		"one_shot": false,
		"explosiveness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_radius": 15.0,
		"direction": Vector3.DOWN,
		"spread": 5.0,
		"velocity_min": 10.0,
		"velocity_max": 15.0,
		"gravity": Vector3(0, -20.0, 0),
		"scale_min": 0.02,
		"scale_max": 0.05,
		"color_ramp": [
			[0.0, Color(0.7, 0.8, 1.0, 0.6)],
			[1.0, Color(0.5, 0.6, 0.8, 0.4)]
		],
		"mesh_type": "quad"
	}
