extends Node
class_name CombatComponent
## 战斗组件 - 管理实体的战斗属性和伤害计算

signal attack_performed(target: Node, damage: float)
signal critical_hit(target: Node, damage: float)

@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0  # 每秒攻击次数
@export var crit_chance: float = 0.05  # 暴击率 5%
@export var crit_multiplier: float = 2.0  # 暴击倍率
@export var accuracy: float = 0.95  # 命中率

var equipment_damage_bonus: float = 0.0
var skill_damage_multiplier: float = 1.0
var attack_cooldown: float = 0.0

func _ready() -> void:
	print("[CombatComponent] Initialized - Base Damage: %.1f" % base_damage)

func _process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

## 获取总伤害
func get_total_damage() -> float:
	var total = base_damage + equipment_damage_bonus
	total *= skill_damage_multiplier
	return total

## 计算对目标的伤害
func calculate_damage(target: Node) -> float:
	# 检查命中
	if randf() > accuracy:
		print("[CombatComponent] Attack missed!")
		return 0.0

	var damage = get_total_damage()

	# 检查暴击
	var is_crit = randf() < crit_chance
	if is_crit:
		damage *= crit_multiplier
		print("[CombatComponent] Critical hit! Damage: %.1f" % damage)
		critical_hit.emit(target, damage)
	else:
		print("[CombatComponent] Normal hit! Damage: %.1f" % damage)

	# 如果目标有防御，计算减伤
	if target.has_node("CombatComponent"):
		var target_combat = target.get_node("CombatComponent")
		if target_combat.has_method("get_defense"):
			var defense = target_combat.get_defense()
			var reduction = defense / (defense + 100.0)
			damage *= (1.0 - reduction)

	return damage

## 攻击目标
func attack(target: Node) -> bool:
	if attack_cooldown > 0:
		return false

	if not target or not target.has_node("HealthComponent"):
		print("[CombatComponent] Invalid target")
		return false

	var damage = calculate_damage(target)
	var target_health = target.get_node("HealthComponent")
	target_health.take_damage(damage, get_parent())

	attack_performed.emit(target, damage)
	attack_cooldown = 1.0 / attack_speed

	return true

## 是否可以攻击
func can_attack() -> bool:
	return attack_cooldown <= 0

## 设置装备加成
func set_equipment_bonus(bonus: float) -> void:
	equipment_damage_bonus = bonus
	print("[CombatComponent] Equipment bonus: %.1f" % equipment_damage_bonus)

## 设置技能伤害倍率
func set_skill_multiplier(multiplier: float) -> void:
	skill_damage_multiplier = multiplier
	print("[CombatComponent] Skill multiplier: %.2fx" % skill_damage_multiplier)

## 设置攻击速度
func set_equipment_attack_speed(speed_bonus: float) -> void:
	attack_speed = 1.0 + (speed_bonus / 100.0)
	print("[CombatComponent] Attack speed: %.2f" % attack_speed)

## 设置暴击属性
func set_equipment_crit_stats(crit_chance_bonus: float, crit_damage_bonus: float) -> void:
	crit_chance = 0.05 + (crit_chance_bonus / 100.0)
	crit_multiplier = 2.0 + (crit_damage_bonus / 100.0)
	print("[CombatComponent] Crit: %.1f%% chance, %.2fx damage" % [crit_chance * 100, crit_multiplier])

## 获取防御值（用于敌人）
func get_defense() -> float:
	return 0.0  # 基类返回0，子类可以重写

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"base_damage": base_damage,
		"attack_speed": attack_speed,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	base_damage = data.get("base_damage", 10.0)
	attack_speed = data.get("attack_speed", 1.0)
	crit_chance = data.get("crit_chance", 0.05)
	crit_multiplier = data.get("crit_multiplier", 2.0)
