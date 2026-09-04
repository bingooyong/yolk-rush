class_name SkillSystem
extends Node

## 技能系统 - 管理角色技能的释放、冷却和效果
## Phase 5: Combat System - Skill Management

signal skill_cast(skill_id: String)
signal skill_cooldown_started(skill_id: String, duration: float)
signal skill_ready(skill_id: String)

@export var skill_definitions_path: String = "res://data/skills/skill_definitions.json"

var skills: Dictionary = {}  ## skill_id -> SkillData
var cooldowns: Dictionary =   ## skill_id -> remaining_time
var keybindings: Dictionary = {}  ## key -> skill_id
var owner_character: CharacterBody3D

func _ready() -> void:
	owner_character = get_parent() as CharacterBody3D
	_load_skill_definitions()

func _process(delta: float) -> void:
	_update_cooldowns(delta)

## 加载技能定义
func _load_skill_definitions() -> void:
	var file := FileAccess.open(skill_definitions_path, FileAccess.READ)
	if not file:
		push_error("无法加载技能定义: " + skill_definitions_path)
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("技能定义 JSON 解析失败")
		return

	var data: Dictionary = json.data

	# 加载技能
	for skill_dict in data.get("skills", []):
		var skill_data := SkillData.new()
		skill_data.id = skill_dict.get("id", "")
		skill_data.name = skill_dict.get("name", "")
		skill_data.type = skill_dict.get("type", "attack")
		skill_data.cooldown = skill_dict.get("cooldown", 1.0)
		skill_data.damage = skill_dict.get("damage", 0.0)
		skill_data.range = skill_dict.get("range", 1.0)
		skill_data.aoe_radius = skill_dict.get("aoe_radius", 0.0)
		skill_data.cast_time = skill_dict.get("cast_time", 0.0)
		skill_data.animation = skill_dict.get("animation", "")
		skill_data.vfx_scene = skill_dict.get("vfx_scene", "")
		skill_data.description = skill_dict.get("description", "")

		# 特殊属性
		if skill_dict.has("invincibility_duration"):
			skill_data.invincibility_duration = skill_dict.get("invincibility_duration")
		if skill_dict.has("shield_amount"):
			skill_data.shield_amount = skill_dict.get("shield_amount")
		if skill_dict.has("shield_duration"):
			skill_data.shield_duration = skill_dict.get("shield_duration")
		if skill_dict.has("requires_energy"):
			skill_data.requires_energy = skill_dict.get("requires_energy")

		skills[skill_data.id] = skill_data
		cooldowns[skill_data.id] = 0.0

	# 加载按键绑定
	keybindings = data.get("keybindings", {})

	print("✓ 加载了 %d 个技能" % skills.size())

## 释放技能
func cast_skill(skill_key: String) -> bool:
	var skill_id: String = keybindings.get(skill_key, "")
	if skill_id.is_empty():
		return false

	if not skills.has(skill_id):
		return false

	# 检查冷却
	if cooldowns[skill_id] > 0.0:
		print("技能冷却中: %s (%.1fs)" % [skill_id, cooldowns[skill_id]])
		return false

	var skill: SkillData = skills[skill_id]

	# 释放技能
	_execute_skill(skill)

	# 开始冷却
	cooldowns[skill_id] = skill.cooldown
	skill_cooldown_started.emit(skill_id, skill.cooldown)

	return true

## 执行技能效果
func _execute_skill(skill: SkillData) -> void:
	print("释放技能: %s" % skill.name)

	# 播放动画
	if owner_character.has_node("AnimationController"):
		var anim_ctrl = owner_character.get_node("AnimationController")
		# TODO: 添加技能动画支持

	# 生成 VFX
	if not skill.vfx_scene.is_empty() and ResourceLoader.exists(skill.vfx_scene):
		var vfx_inst = load(skill.vfx_scene).instantiate()
		owner_character.add_child(vfx_inst)

	# 根据技能类型执行效果
	match skill.type:
		"attack":
			_execute_attack_skill(skill)
		"mobility":
			_execute_mobility_skill(skill)
		"defense":
			_execute_defense_skill(skill)
		"ultimate":
			_execute_ultimate_skill(skill)

	skill_cast.emit(skill.id)

## 攻击型技能
func _execute_attack_skill(skill: SkillData) -> void:
	if skill.aoe_radius > 0.0:
		# AOE 伤害
		var enemies := _get_enemies_in_radius(skill.aoe_radius)
		for enemy in enemies:
			_deal_damage_to(enemy, skill.damage)
	else:
		# 单体伤害
		var target := _get_closest_enemy_in_range(skill.range)
		if target:
			_deal_damage_to(target, skill.damage)

## 位移型技能
func _execute_mobility_skill(skill: SkillData) -> void:
	# 冲刺
	if owner_character.has_node("MovementController"):
		var move_ctrl = owner_character.get_node("MovementController")
		var dash_direction := -owner_character.global_transform.basis.z
		owner_character.velocity += dash_direction * skill.range * 3.0

	# 无敌帧
	if skill.has("invincibility_duration") and skill.invincibility_duration > 0.0:
		_apply_invincibility(skill.invincibility_duration)

## 防御型技能
func _execute_defense_skill(skill: SkillData) -> void:
	if skill.has("shield_amount"):
		if owner_character.has_node("CombatSystem"):
			var combat = owner_character.get_node("CombatSystem")
			# TODO: 添加护盾系统
			print("生成护盾: %.0f HP" % skill.shield_amount)

## 终结技
func _execute_ultimate_skill(skill: SkillData) -> void:
	# 大范围 AOE
	var enemies := _get_enemies_in_radius(skill.aoe_radius)
	for enemy in enemies:
		_deal_damage_to(enemy, skill.damage)

	# 屏幕震动
	if owner_character.has_node("../CameraRig"):
		var camera_rig = owner_character.get_node("../CameraRig")
		# TODO: 添加相机震动

## 更新冷却
func _update_cooldowns(delta: float) -> void:
	for skill_id in cooldowns.keys():
		if cooldowns[skill_id] > 0.0:
			cooldowns[skill_id] -= delta
			if cooldowns[skill_id] <= 0.0:
				cooldowns[skill_id] = 0.0
				skill_ready.emit(skill_id)

## 获取范围内的敌人
func _get_enemies_in_radius(radius: float) -> Array:
	var result: Array = []
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is CharacterBody3D:
			var distance := owner_character.global_position.distance_to(enemy.global_position)
			if distance <= radius:
				result.append(enemy)
	return result

## 获取范围内最近的敌人
func _get_closest_enemy_in_range(max_range: float) -> CharacterBody3D:
	var closest: CharacterBody3D = null
	var closest_dist := max_range

	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is CharacterBody3D:
			var distance := owner_character.global_position.distance_to(enemy.global_position)
			if distance < closest_dist:
				closest = enemy
				closest_dist = distance

	return closest

## 对目标造成伤害
func _deal_damage_to(target: CharacterBody3D, amount: float) -> void:
	if target.has_node("CombatSystem"):
		var combat = target.get_node("CombatSystem")
		combat.take_damage(amount)

## 应用无敌帧
func _apply_invincibility(duration: float) -> void:
	if owner_character.has_node("CombatSystem"):
		var combat = owner_character.get_node("CombatSystem")
		# TODO: 添加无敌状态
		print("无敌帧: %.1fs" % duration)

## 获取技能冷却剩余时间
func get_cooldown_remaining(skill_key: String) -> float:
	var skill_id: String = keybindings.get(skill_key, "")
	if skill_id.is_empty():
		return 0.0
	return cooldowns.get(skill_id, 0.0)

## 获取技能数据
func get_skill_by_key(skill_key: String) -> SkillData:
	var skill_id: String = keybindings.get(skill_key, "")
	if skill_id.is_empty():
		return null
	return skills.get(skill_id)

## 技能数据类
class SkillData:
	var id: String
	var name: String
	var type: String
	var cooldown: float
	var damage: float
	var range: float
	var aoe_radius: float
	var cast_time: float
	var animation: String
	var vfx_scene: String
	var description: String

	# 特殊属性
	var invincibility_duration: float = 0.0
	var shield_amount: float = 0.0
	var shield_duration: float = 0.0
	var requires_energy: float = 0.0

	func has(property: String) -> bool:
		return get(property) != null
