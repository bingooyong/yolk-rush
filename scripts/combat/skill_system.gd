class_name SkillSystem
extends Node

## 技能系统
## 管理角色的技能施放、冷却、资源消耗

## 信号
signal skill_cast(skill_id: String)
signal skill_cooldown_started(skill_id: String, duration: float)
signal skill_cooldown_finished(skill_id: String)
signal skill_failed(skill_id: String, reason: String)

## 技能定义
var skills: Dictionary = {}  ## skill_id -> SkillData
var cooldowns: Dictionary = {}  ## skill_id -> remaining_time
var character: Node3D

## 技能数据结构
class SkillData:
	var id: String
	var name: String
	var type: String  ## "attack", "mobility", "defense", "ultimate"
	var cooldown: float
	var damage: float
	var range: float
	var aoe_radius: float
	var cast_time: float
	var animation: String
	var vfx_scene: String

	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		type = data.get("type", "attack")
		cooldown = data.get("cooldown", 5.0)
		damage = data.get("damage", 20.0)
		range = data.get("range", 3.0)
		aoe_radius = data.get("aoe_radius", 0.0)
		cast_time = data.get("cast_time", 0.3)
		animation = data.get("animation", "attack")
		vfx_scene = data.get("vfx_scene", "")

func _ready() -> void:
	_load_default_skills()

func set_character(char: Node3D) -> void:
	character = char

func _load_default_skills() -> void:
	## 加载默认技能配置
	var default_skills := [
		{
			"id": "skill_1",
			"name": "旋风斩",
			"type": "attack",
			"cooldown": 6.0,
			"damage": 30.0,
			"range": 3.0,
			"aoe_radius": 2.5,
			"cast_time": 0.5,
			"animation": "spin_attack",
			"vfx_scene": "res://vfx/whirlwind.tscn"
		},
		{
			"id": "skill_2",
			"name": "冲刺",
			"type": "mobility",
			"cooldown": 8.0,
			"damage": 15.0,
			"range": 5.0,
			"aoe_radius": 0.0,
			"cast_time": 0.2,
			"animation": "dash",
			"vfx_scene": "res://vfx/dash_trail.tscn"
		},
		{
			"id": "skill_3",
			"name": "护盾",
			"type": "defense",
			"cooldown": 12.0,
			"damage": 0.0,
			"range": 0.0,
			"aoe_radius": 0.0,
			"cast_time": 0.3,
			"animation": "shield",
			"vfx_scene": "res://vfx/shield_bubble.tscn"
		},
		{
			"id": "skill_ultimate",
			"name": "毁灭一击",
			"type": "ultimate",
			"cooldown": 30.0,
			"damage": 100.0,
			"range": 5.0,
			"aoe_radius": 4.0,
			"cast_time": 1.0,
			"animation": "ultimate",
			"vfx_scene": "res://vfx/ultimate_explosion.tscn"
		}
	]

	for skill_data in default_skills:
		var skill := SkillData.new(skill_data)
		skills[skill.id] = skill
		cooldowns[skill.id] = 0.0

func _process(delta: float) -> void:
	## 更新冷却计时器
	for skill_id in cooldowns.keys():
		if cooldowns[skill_id] > 0.0:
			cooldowns[skill_id] -= delta
			if cooldowns[skill_id] <= 0.0:
				cooldowns[skill_id] = 0.0
				skill_cooldown_finished.emit(skill_id)

func can_cast_skill(skill_id: String) -> bool:
	## 检查技能是否可以施放
	if not skills.has(skill_id):
		return false

	if cooldowns[skill_id] > 0.0:
		return false

	return true

func cast_skill(skill_id: String) -> bool:
	## 施放技能
	if not can_cast_skill(skill_id):
		skill_failed.emit(skill_id, "cooldown")
		return false

	var skill: SkillData = skills[skill_id]

	## 开始冷却
	cooldowns[skill_id] = skill.cooldown
	skill_cooldown_started.emit(skill_id, skill.cooldown)

	## 触发技能效果
	_execute_skill_effect(skill)

	## 发出信号
	skill_cast.emit(skill_id)

	return true

func _execute_skill_effect(skill: SkillData) -> void:
	## 执行技能效果
	match skill.type:
		"attack":
			_execute_attack_skill(skill)
		"mobility":
			_execute_mobility_skill(skill)
		"defense":
			_execute_defense_skill(skill)
		"ultimate":
			_execute_ultimate_skill(skill)

func _execute_attack_skill(skill: SkillData) -> void:
	## 执行攻击技能
	print("[SkillSystem] 施放攻击技能: %s (伤害: %.1f, 范围: %.1f)" % [skill.name, skill.damage, skill.aoe_radius])

	## 播放动画
	if character and character.has_node("AnimationController"):
		var anim_ctrl = character.get_node("AnimationController")
		anim_ctrl.request_animation(skill.animation)

	## 生成VFX
	_spawn_vfx(skill.vfx_scene)

	## AOE 伤害检测
	if skill.aoe_radius > 0.0:
		_apply_aoe_damage(skill.damage, skill.aoe_radius)

func _execute_mobility_skill(skill: SkillData) -> void:
	## 执行位移技能
	print("[SkillSystem] 施放位移技能: %s (距离: %.1f)" % [skill.name, skill.range])

	if character:
		## 向前冲刺
		var forward := -character.global_transform.basis.z
		var dash_velocity := forward * skill.range * 3.0

		if character.has_method("apply_impulse"):
			character.apply_impulse(dash_velocity)

	## 播放动画和VFX
	if character and character.has_node("AnimationController"):
		var anim_ctrl = character.get_node("AnimationController")
		anim_ctrl.request_animation(skill.animation)

	_spawn_vfx(skill.vfx_scene)

func _execute_defense_skill(skill: SkillData) -> void:
	## 执行防御技能
	print("[SkillSystem] 施放防御技能: %s" % skill.name)

	## 添加护盾效果
	if character and character.has_node("HealthComponent"):
		var health_comp = character.get_node("HealthComponent")
		# TODO: 实现护盾系统
		print("  [护盾] 吸收 50 点伤害，持续 5 秒")

	## 播放动画和VFX
	if character and character.has_node("AnimationController"):
		var anim_ctrl = character.get_node("AnimationController")
		anim_ctrl.request_animation(skill.animation)

	_spawn_vfx(skill.vfx_scene)

func _execute_ultimate_skill(skill: SkillData) -> void:
	## 执行终结技
	print("[SkillSystem] 施放终结技: %s (伤害: %.1f, 范围: %.1f)" % [skill.name, skill.damage, skill.aoe_radius])

	## 播放动画
	if character and character.has_node("AnimationController"):
		var anim_ctrl = character.get_node("AnimationController")
		anim_ctrl.request_animation(skill.animation)

	## 生成大范围VFX
	_spawn_vfx(skill.vfx_scene)

	## 大范围AOE伤害
	_apply_aoe_damage(skill.damage, skill.aoe_radius)

func _apply_aoe_damage(damage: float, radius: float) -> void:
	## 应用AOE伤害
	if not character:
		return

	## 查找范围内的敌人
	var space_state := character.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform = character.global_transform
	query.collision_mask = 4  ## Enemy layer

	var results := space_state.intersect_shape(query)

	for result in results:
		var enemy = result.collider
		if enemy and enemy.has_node("HealthComponent"):
			var health_comp = enemy.get_node("HealthComponent")
			health_comp.take_damage(damage)
			print("  [AOE] 对 %s 造成 %.1f 伤害" % [enemy.name, damage])

func _spawn_vfx(vfx_path: String) -> void:
	## 生成VFX特效
	if vfx_path.is_empty() or not character:
		return

	# TODO: 加载并实例化VFX场景
	print("  [VFX] 播放特效: %s" % vfx_path)

func get_skill_cooldown(skill_id: String) -> float:
	## 获取技能剩余冷却时间
	return cooldowns.get(skill_id, 0.0)

func get_skill_data(skill_id: String) -> SkillData:
	## 获取技能数据
	return skills.get(skill_id, null)

