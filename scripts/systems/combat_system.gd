extends Node
class_name CombatSystem
## 战斗系统
## 处理伤害计算、攻击判定和战斗逻辑

signal damage_dealt(attacker: Node, target: Node, damage: int)
signal entity_died(entity: Node)

## 伤害计算
static func calculate_damage(base_damage: int, attacker: Node = null, target: Node = null) -> int:
	var final_damage = base_damage

	# 可以在这里添加更多计算逻辑
	# 例如：防御力、伤害加成、暴击等

	return max(1, final_damage)  # 至少造成1点伤害

## 应用伤害
static func apply_damage(target: Node, damage: int, attacker: Node = null) -> bool:
	if not target.has_method("take_damage"):
		push_error("[CombatSystem] Target %s has no take_damage method" % target.name)
		return false

	var final_damage = calculate_damage(damage, attacker, target)
	target.take_damage(final_damage)

	print("[CombatSystem] %s dealt %d damage to %s" % [
		attacker.name if attacker else "Unknown",
		final_damage,
		target.name
	])

	return true

## 范围伤害
static func apply_area_damage(center: Vector3, radius: float, damage: int, attacker: Node = null, exclude: Array = []) -> Array:
	var damaged_entities: Array = []

	# 获取所有可能的目标
	var tree = attacker.get_tree() if attacker else null
	if not tree:
		return damaged_entities

	var potential_targets: Array = []
	potential_targets.append_array(tree.get_nodes_in_group("enemies"))
	potential_targets.append_array(tree.get_nodes_in_group("player"))

	for target in potential_targets:
		if target in exclude:
			continue

		if target == attacker:
			continue

		if not target.has_method("take_damage"):
			continue

		# 检查距离
		var distance = (target.global_position - center).length()
		if distance <= radius:
			if apply_damage(target, damage, attacker):
				damaged_entities.append(target)

	return damaged_entities

## 检测攻击命中
static func check_attack_hit(attacker_pos: Vector3, attacker_forward: Vector3, target_pos: Vector3, attack_range: float, attack_angle: float = 60.0) -> bool:
	var to_target = target_pos - attacker_pos
	var distance = to_target.length()

	# 距离检查
	if distance > attack_range:
		return false

	# 角度检查
	var forward_2d = Vector2(attacker_forward.x, attacker_forward.z).normalized()
	var to_target_2d = Vector2(to_target.x, to_target.z).normalized()

	var angle = rad_to_deg(forward_2d.angle_to(to_target_2d))

	return abs(angle) <= attack_angle / 2.0

## 执行近战攻击
static func perform_melee_attack(attacker: Node3D, damage: int, attack_range: float, attack_angle: float = 60.0) -> Array:
	var hit_targets: Array = []

	if not attacker:
		return hit_targets

	var tree = attacker.get_tree()
	if not tree:
		return hit_targets

	# 确定攻击者的朝向
	var forward = -attacker.global_transform.basis.z

	# 获取所有可能的目标
	var potential_targets: Array = []
	if attacker.is_in_group("player"):
		potential_targets = tree.get_nodes_in_group("enemies")
	else:
		potential_targets = tree.get_nodes_in_group("player")

	for target in potential_targets:
		if not is_instance_valid(target):
			continue

		if check_attack_hit(attacker.global_position, forward, target.global_position, attack_range, attack_angle):
			if apply_damage(target, damage, attacker):
				hit_targets.append(target)

	return hit_targets
