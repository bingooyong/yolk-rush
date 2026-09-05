extends RefCounted
class_name SkillEffect
## 技能效果执行器 - 静态方法处理各种技能效果

## 应用技能效果
static func apply_effect(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	var effect_type = effect.get("type", "")

	match effect_type:
		"damage":
			_apply_damage(effect, skill, caster, target)
		"heal":
			_apply_heal(effect, skill, caster, target)
		"buff":
			_apply_buff(effect, skill, caster, target)
		"debuff":
			_apply_debuff(effect, skill, caster, target)
		"teleport":
			_apply_teleport(effect, skill, caster, target)
		_:
			push_warning("[SkillEffect] Unknown effect type: %s" % effect_type)

## 应用伤害效果
static func _apply_damage(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	if target == null:
		return

	# 计算伤害值
	var damage = skill.calculate_effect_value(effect, caster)

	# 检查是否暴击
	var is_crit = false
	if effect.get("can_crit", false):
		is_crit = _roll_critical(caster)
		if is_crit:
			var crit_multiplier = _get_crit_multiplier(caster)
			damage *= crit_multiplier

	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# 触发伤害事件（用于UI显示）
	if target.has_signal("damage_taken"):
		target.emit_signal("damage_taken", damage, is_crit)

	# 通知战斗系统（如果存在）
	var combat_ui = _get_combat_ui()
	if combat_ui:
		var target_pos = _get_world_position(target)
		combat_ui.show_damage(damage, target_pos, is_crit)

		var caster_name = _get_entity_name(caster)
		var target_name = _get_entity_name(target)

		if is_crit:
			combat_ui.log_critical(caster_name, target_name, damage)
		else:
			combat_ui.log_damage(caster_name, target_name, damage)

## 应用治疗效果
static func _apply_heal(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	if target == null:
		return

	# 计算治疗值
	var heal_amount = skill.calculate_effect_value(effect, caster)

	# 应用治疗
	if target.has_method("heal"):
		target.heal(heal_amount)
	elif target.has_method("add_health"):
		target.add_health(heal_amount)

	# 触发治疗事件
	if target.has_signal("healed"):
		target.emit_signal("healed", heal_amount)

	# 通知战斗系统
	var combat_ui = _get_combat_ui()
	if combat_ui:
		var target_pos = _get_world_position(target)
		combat_ui.show_heal(heal_amount, target_pos)

		var caster_name = _get_entity_name(caster)
		var target_name = _get_entity_name(target)
		combat_ui.log_heal(caster_name, target_name, heal_amount)

## 应用增益效果
static func _apply_buff(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	if target == null:
		return

	# 获取状态效果系统（Phase 11 实现）
	# 这里先预留接口
	var buff_type = effect.get("buff_type", "")
	var duration = effect.get("duration", 0.0)

	print("[SkillEffect] Apply buff: %s for %.1fs (not implemented yet)" % [buff_type, duration])

	# TODO: Phase 11 - 集成状态效果系统
	# if target.has_method("add_buff"):
	#     target.add_buff(buff_type, duration, effect)

## 应用减益效果
static func _apply_debuff(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	if target == null:
		return

	var debuff_type = effect.get("debuff_type", "")
	var duration = effect.get("duration", 0.0)

	print("[SkillEffect] Apply debuff: %s for %.1fs (not implemented yet)" % [debuff_type, duration])

	# TODO: Phase 11 - 集成状态效果系统
	# if target.has_method("add_debuff"):
	#     target.add_debuff(debuff_type, duration, effect)

## 应用传送效果
static func _apply_teleport(effect: Dictionary, skill, caster: Node, target: Node) -> void:
	var teleport_target = effect.get("target", "")

	match teleport_target:
		"enemy":
			if target != null and caster is Node3D and target is Node3D:
				# 传送到目标附近
				var offset = Vector3(1.0, 0, 0)  # 目标前方1米
				caster.global_position = target.global_position + offset
			elif target != null and caster is Node2D and target is Node2D:
				var offset = Vector2(50, 0)
				caster.global_position = target.global_position + offset

		"location":
			var location = effect.get("location", Vector3.ZERO)
			if caster is Node3D:
				caster.global_position = location
			elif caster is Node2D:
				caster.global_position = Vector2(location.x, location.y)

## 暴击判定
static func _roll_critical(caster: Node) -> bool:
	var crit_chance = 0.15  # 默认15%暴击率

	if caster.has_method("get_crit_chance"):
		crit_chance = caster.get_crit_chance()
	elif caster.has_node("StatsComponent"):
		var stats = caster.get_node("StatsComponent")
		if stats.has_method("get_crit_chance"):
			crit_chance = stats.get_crit_chance()

	return randf() < crit_chance

## 获取暴击倍率
static func _get_crit_multiplier(caster: Node) -> float:
	var multiplier = 2.0  # 默认2倍

	if caster.has_method("get_crit_multiplier"):
		multiplier = caster.get_crit_multiplier()
	elif caster.has_node("StatsComponent"):
		var stats = caster.get_node("StatsComponent")
		if stats.has_method("get_crit_multiplier"):
			multiplier = stats.get_crit_multiplier()

	return multiplier

## 获取战斗UI
static func _get_combat_ui() -> Node:
	# 尝试从场景树获取CombatUI
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var root = tree.root
		if root:
			# 查找CombatUI节点
			var combat_ui = root.find_child("CombatUI", true, false)
			if combat_ui:
				return combat_ui

	return null

## 获取世界坐标
static func _get_world_position(node: Node) -> Vector2:
	if node is Node3D:
		return Vector2(node.global_position.x, node.global_position.y)
	elif node is Node2D:
		return node.global_position
	return Vector2.ZERO

## 获取实体名称
static func _get_entity_name(node: Node) -> String:
	if node.has_method("get_display_name"):
		return node.get_display_name()
	return node.name
