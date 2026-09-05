extends Node
class_name CombatSystem
## 战斗系统 - 处理伤害计算、暴击、战斗事件

signal damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool)
signal combat_started(attacker: Node, target: Node)
signal combat_ended(attacker: Node, target: Node)
signal entity_died(entity: Node, killer: Node)

# 战斗参数
const BASE_CRIT_CHANCE = 5.0  # 基础暴击率 5%
const BASE_CRIT_DAMAGE = 150.0  # 基础暴击伤害 150%
const DODGE_CHANCE_BASE = 5.0  # 基础闪避率 5%

# 伤害类型
enum DamageType {
	PHYSICAL,
	MAGICAL,
	TRUE  # 真实伤害（无视防御）
}

# 活跃战斗
var active_combats: Dictionary = {}  # {attacker_id: {target: Node, time: float}}

func _ready():
	print("[CombatSystem] Initialized")

## 计算伤害
func calculate_damage(
	attacker: Node,
	target: Node,
	base_damage: float,
	damage_type: DamageType = DamageType.PHYSICAL,
	can_crit: bool = true
) -> Dictionary:
	var result = {
		"damage": base_damage,
		"is_crit": false,
		"is_dodged": false,
		"damage_type": damage_type
	}

	# 获取攻击者属性
	var attacker_stats = _get_entity_stats(attacker)

	# 获取目标属性
	var target_stats = _get_entity_stats(target)

	# 检查闪避
	if _check_dodge(attacker_stats, target_stats):
		result.is_dodged = true
		result.damage = 0
		return result

	# 应用属性加成
	match damage_type:
		DamageType.PHYSICAL:
			# 物理伤害 = 基础伤害 + 物理攻击 - 物理防御
			result.damage += attacker_stats.get("physical_damage", 0)
			result.damage -= target_stats.get("physical_defense", 0)
		DamageType.MAGICAL:
			# 魔法伤害 = 基础伤害 + 魔法攻击 - 魔法防御
			result.damage += attacker_stats.get("magical_damage", 0)
			result.damage -= target_stats.get("magical_defense", 0)
		DamageType.TRUE:
			# 真实伤害无视防御
			pass

	# 检查暴击
	if can_crit and _check_crit(attacker_stats):
		result.is_crit = true
		var crit_damage_multiplier = attacker_stats.get("crit_damage", BASE_CRIT_DAMAGE) / 100.0
		result.damage *= crit_damage_multiplier

	# 伤害不能为负
	result.damage = max(1.0, result.damage)

	return result

## 应用伤害
func apply_damage(attacker: Node, target: Node, damage_info: Dictionary):
	if damage_info.is_dodged:
		print("[CombatSystem] %s dodged attack from %s" % [target.name, attacker.name])
		return

	var damage = damage_info.damage
	var is_crit = damage_info.is_crit

	# 对目标造成伤害
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# 发射信号
	damage_dealt.emit(attacker, target, damage, is_crit)

	# 记录战斗
	_register_combat(attacker, target)

	# 打印日志
	var crit_text = " (CRIT!)" if is_crit else ""
	print("[CombatSystem] %s dealt %.1f damage to %s%s" % [attacker.name, damage, target.name, crit_text])

	# 检查目标是否死亡
	if _is_entity_dead(target):
		_on_entity_died(target, attacker)

## 检查暴击
func _check_crit(stats: Dictionary) -> bool:
	var crit_chance = stats.get("crit_chance", BASE_CRIT_CHANCE)
	return randf() * 100.0 < crit_chance

## 检查闪避
func _check_dodge(attacker_stats: Dictionary, target_stats: Dictionary) -> bool:
	var dodge_chance = target_stats.get("dodge_chance", DODGE_CHANCE_BASE)
	var accuracy = attacker_stats.get("accuracy", 100.0)

	# 命中率影响闪避
	var final_dodge = dodge_chance * (100.0 / accuracy)

	return randf() * 100.0 < final_dodge

## 获取实体属性
func _get_entity_stats(entity: Node) -> Dictionary:
	if entity.has_method("get_player_stats"):
		return entity.get_player_stats()
	elif entity.has_method("get_stats"):
		return entity.get_stats()

	# 默认属性
	return {
		"physical_damage": 0,
		"magical_damage": 0,
		"physical_defense": 0,
		"magical_defense": 0,
		"crit_chance": BASE_CRIT_CHANCE,
		"crit_damage": BASE_CRIT_DAMAGE,
		"dodge_chance": DODGE_CHANCE_BASE,
		"accuracy": 100.0
	}

## 检查实体是否死亡
func _is_entity_dead(entity: Node) -> bool:
	if entity.has_method("is_dead"):
		return entity.is_dead()

	# 检查健康值
	if "current_health" in entity:
		return entity.current_health <= 0

	return false

## 注册战斗
func _register_combat(attacker: Node, target: Node):
	var attacker_id = attacker.get_instance_id()

	if not active_combats.has(attacker_id):
		combat_started.emit(attacker, target)

	active_combats[attacker_id] = {
		"target": target,
		"time": Time.get_ticks_msec() / 1000.0
	}

## 实体死亡
func _on_entity_died(entity: Node, killer: Node):
	entity_died.emit(entity, killer)

	# 移除相关战斗记录
	_clear_combat_for_entity(entity)

	print("[CombatSystem] %s was killed by %s" % [entity.name, killer.name])

## 清理实体的战斗记录
func _clear_combat_for_entity(entity: Node):
	var entity_id = entity.get_instance_id()

	# 移除该实体作为攻击者的记录
	if active_combats.has(entity_id):
		var combat = active_combats[entity_id]
		combat_ended.emit(entity, combat.target)
		active_combats.erase(entity_id)

	# 移除该实体作为目标的记录
	for attacker_id in active_combats.keys():
		var combat = active_combats[attacker_id]
		if combat.target == entity:
			var attacker = instance_from_id(attacker_id)
			if attacker:
				combat_ended.emit(attacker, entity)
			active_combats.erase(attacker_id)

## 获取活跃战斗数量
func get_active_combat_count() -> int:
	return active_combats.size()

## 检查是否在战斗中
func is_in_combat(entity: Node) -> bool:
	var entity_id = entity.get_instance_id()

	# 作为攻击者
	if active_combats.has(entity_id):
		return true

	# 作为目标
	for combat in active_combats.values():
		if combat.target == entity:
			return true

	return false

## 清理超时的战斗记录
func _process(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	var timeout = 10.0  # 10秒无交互视为战斗结束

	var to_remove = []

	for attacker_id in active_combats.keys():
		var combat = active_combats[attacker_id]
		if current_time - combat.time > timeout:
			to_remove.append(attacker_id)

	for attacker_id in to_remove:
		var combat = active_combats[attacker_id]
		var attacker = instance_from_id(attacker_id)
		if attacker:
			combat_ended.emit(attacker, combat.target)
		active_combats.erase(attacker_id)
