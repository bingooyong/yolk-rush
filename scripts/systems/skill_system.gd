extends Node
class_name SkillSystem
## 技能系统：管理角色技能的释放、冷却、消耗

signal skill_cast(skill_id: String)
signal skill_cooldown_started(skill_id: String, duration: float)
signal skill_failed(skill_id: String, reason: String)

var skills: Dictionary = {}  # skill_id -> skill_data
var cooldowns: Dictionary = {}  # skill_id -> remaining_time
var character: CharacterBody3D
var health_component: Node
var input_enabled: bool = true

func _ready() -> void:
	load_skills()

func load_skills() -> void:
	var data_path := "res://data/skills/skill_definitions.json"
	if not FileAccess.file_exists(data_path):
		push_error("[SkillSystem] Skill definitions not found: %s" % data_path)
		return

	var file := FileAccess.open(data_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[SkillSystem] Failed to parse skill definitions")
		return

	var data: Dictionary = json.data
	skills = data.get("skills", {})

	# 初始化所有技能冷却为0
	for skill_id in skills.keys():
		cooldowns[skill_id] = 0.0

	print("[SkillSystem] ✅ Loaded %d skills" % skills.size())

func _process(delta: float) -> void:
	# 更新冷却时间
	for skill_id in cooldowns.keys():
		if cooldowns[skill_id] > 0.0:
			cooldowns[skill_id] -= delta
			if cooldowns[skill_id] <= 0.0:
				cooldowns[skill_id] = 0.0

func set_character(char: CharacterBody3D) -> void:
	character = char
	if character and character.has_node("HealthComponent"):
		health_component = character.get_node("HealthComponent")

func try_cast_skill(skill_id: String) -> bool:
	if not input_enabled:
		return false

	if not skills.has(skill_id):
		push_warning("[SkillSystem] Skill not found: %s" % skill_id)
		return false

	var skill: Dictionary = skills[skill_id]

	# 检查冷却
	if is_on_cooldown(skill_id):
		skill_failed.emit(skill_id, "on_cooldown")
		return false

	# 检查消耗
	if not can_afford_cost(skill):
		skill_failed.emit(skill_id, "insufficient_resource")
		return false

	# 消耗资源
	consume_cost(skill)

	# 开始冷却
	var cooldown: float = skill.get("cooldown", 0.0)
	cooldowns[skill_id] = cooldown
	skill_cooldown_started.emit(skill_id, cooldown)

	# 执行技能
	_execute_skill(skill)

	skill_cast.emit(skill_id)
	print("[SkillSystem] Cast skill: %s" % skill.get("name", skill_id))

	return true

func _execute_skill(skill: Dictionary) -> void:
	var skill_type: String = skill.get("type", "attack")

	match skill_type:
		"attack":
			_execute_attack_skill(skill)
		"mobility":
			_execute_mobility_skill(skill)
		"defense":
			_execute_defense_skill(skill)
		"ultimate":
			_execute_ultimate_skill(skill)

func _execute_attack_skill(skill: Dictionary) -> void:
	if not character:
		return

	# 施放动画
	var cast_time: float = skill.get("cast_time", 0.0)
	if cast_time > 0.0:
		input_enabled = false
		await get_tree().create_timer(cast_time).timeout
		input_enabled = true

	# 获取伤害数据
	var damage_data: Dictionary = skill.get("damage", {})
	var base_damage: float = damage_data.get("base", 0.0)

	# 获取AOE数据
	var aoe: Dictionary = skill.get("aoe", {})
	var range_radius: float = aoe.get("radius", 3.0)

	# 查找范围内的敌人
	var targets := _find_enemies_in_range(character.global_position, range_radius)

	# 对每个目标造成伤害
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(base_damage, character)

		# 应用击退效果
		var effects: Array = skill.get("effects", [])
		for effect in effects:
			if effect.get("type") == "knockback":
				_apply_knockback(target, effect.get("strength", 2.0))

	# 播放VFX
	_spawn_skill_vfx(skill)

	print("[SkillSystem] Attack skill hit %d targets" % targets.size())

func _execute_mobility_skill(skill: Dictionary) -> void:
	if not character:
		return

	var dash_data: Dictionary = skill.get("dash", {})
	var distance: float = dash_data.get("distance", 5.0)
	var duration: float = dash_data.get("duration", 0.3)
	var invulnerable: bool = dash_data.get("invulnerable", false)

	# 计算冲刺方向
	var direction := Vector3.ZERO
	if character.velocity.length() > 0.1:
		direction = character.velocity.normalized()
	else:
		direction = -character.transform.basis.z  # 面朝方向

	# 执行冲刺
	var start_pos := character.global_position
	var end_pos := start_pos + direction * distance

	input_enabled = false

	# 无敌帧
	if invulnerable and character.has_method("set_invulnerable"):
		character.set_invulnerable(true)

	# Tween动画
	var tween := create_tween()
	tween.tween_property(character, "global_position", end_pos, duration)
	await tween.finished

	if invulnerable and character.has_method("set_invulnerable"):
		character.set_invulnerable(false)

	input_enabled = true

	_spawn_skill_vfx(skill)
	print("[SkillSystem] Dash skill executed")

func _execute_defense_skill(skill: Dictionary) -> void:
	if not character:
		return

	var shield_data: Dictionary = skill.get("shield", {})
	var shield_amount: float = shield_data.get("amount", 100.0)
	var shield_duration: float = shield_data.get("duration", 5.0)

	# 添加护盾到HealthComponent
	if health_component and health_component.has_method("add_shield"):
		health_component.add_shield(shield_amount, shield_duration)

	_spawn_skill_vfx(skill)
	print("[SkillSystem] Shield skill activated: %.0f for %.1fs" % [shield_amount, shield_duration])

func _execute_ultimate_skill(skill: Dictionary) -> void:
	if not character:
		return

	var cast_time: float = skill.get("cast_time", 1.5)

	# 蓄力阶段
	input_enabled = false
	_spawn_channel_vfx(skill)
	await get_tree().create_timer(cast_time).timeout

	# 释放大招
	var damage_data: Dictionary = skill.get("damage", {})
	var base_damage: float = damage_data.get("base", 200.0)

	var aoe: Dictionary = skill.get("aoe", {})
	var range_radius: float = aoe.get("radius", 8.0)

	var targets := _find_enemies_in_range(character.global_position, range_radius)

	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(base_damage, character)

		# 应用效果
		var effects: Array = skill.get("effects", [])
		for effect in effects:
			match effect.get("type"):
				"stun":
					_apply_stun(target, effect.get("duration", 2.0))
				"knockback":
					_apply_knockback(target, effect.get("strength", 5.0))

	_spawn_skill_vfx(skill)
	_camera_shake(skill)

	input_enabled = true
	print("[SkillSystem] Ultimate skill hit %d targets" % targets.size())

func _find_enemies_in_range(center: Vector3, radius: float) -> Array:
	var enemies: Array = []
	var space_state := character.get_world_3d().direct_space_state

	# 使用物理查询找到范围内的所有碰撞体
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform.origin = center
	query.collision_mask = 2  # 敌人层

	var results := space_state.intersect_shape(query)

	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider != character:
			enemies.append(collider)

	return enemies

func _apply_knockback(target: Node, strength: float) -> void:
	if not target is CharacterBody3D:
		return

	var direction := (target.global_position - character.global_position).normalized()
	target.velocity += direction * strength

func _apply_stun(target: Node, duration: float) -> void:
	if target.has_method("apply_stun"):
		target.apply_stun(duration)

func _spawn_skill_vfx(skill: Dictionary) -> void:
	if not character:
		return

	var skill_id: String = skill.get("id", "")
	var vfx_id: String = skill.get("vfx", {}).get("id", skill_id)

	# 使用 VFXManager 生成特效
	var VFXManager := preload("res://scripts/visual/vfx_manager.gd")
	var root := get_tree().root
	VFXManager.play_skill_vfx(vfx_id, character.global_position, root)

	print("[SkillSystem] Spawned VFX for skill: %s" % skill_id)

func _spawn_channel_vfx(skill: Dictionary) -> void:
	if not character:
		return

	# 蓄力特效（简单光效）
	var light := OmniLight3D.new()
	light.name = "ChannelLight"
	light.light_color = Color(1.0, 0.8, 0.0)
	light.light_energy = 2.0
	light.omni_range = 5.0
	character.add_child(light)

	# 脉冲动画
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(light, "light_energy", 3.0, 0.5)
	tween.tween_property(light, "light_energy", 1.0, 0.5)

	# 技能施放后清理
	await get_tree().create_timer(skill.get("cast_time", 1.5)).timeout
	light.queue_free()

func _camera_shake(skill: Dictionary) -> void:
	var shake_data: Dictionary = skill.get("camera_shake", {})
	var intensity: float = shake_data.get("intensity", 0.5)
	var duration: float = shake_data.get("duration", 0.3)

	# TODO: 实际触发相机抖动（需要相机控制器支持）
	print("[SkillSystem] Camera shake: intensity=%.1f, duration=%.1f" % [intensity, duration])

func can_afford_cost(skill: Dictionary) -> bool:
	var cost: Dictionary = skill.get("cost", {})
	var cost_type: String = cost.get("type", "stamina")
	var cost_amount: float = cost.get("amount", 0.0)

	# TODO: 检查实际资源
	# 暂时总是返回true
	return true

func consume_cost(skill: Dictionary) -> void:
	var cost: Dictionary = skill.get("cost", {})
	var cost_type: String = cost.get("type", "stamina")
	var cost_amount: float = cost.get("amount", 0.0)

	# TODO: 实际消耗资源
	print("[SkillSystem] Consumed %s: %.0f" % [cost_type, cost_amount])

func is_on_cooldown(skill_id: String) -> bool:
	return cooldowns.get(skill_id, 0.0) > 0.0

func get_cooldown_remaining(skill_id: String) -> float:
	return cooldowns.get(skill_id, 0.0)

func get_cooldown_percent(skill_id: String) -> float:
	if not skills.has(skill_id):
		return 0.0

	var max_cooldown: float = skills[skill_id].get("cooldown", 1.0)
	var remaining: float = cooldowns.get(skill_id, 0.0)

	if max_cooldown <= 0.0:
		return 0.0

	return remaining / max_cooldown
