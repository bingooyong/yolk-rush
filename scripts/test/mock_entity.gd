extends Node2D
## 模拟实体 - 用于测试

var health: float = 100.0
var max_health: float = 100.0
var mana: float = 100.0
var max_mana: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0

# 属性
var strength: float = 20.0
var intelligence: float = 25.0
var agility: float = 15.0
var defense: float = 10.0

signal damage_taken(amount: float, is_crit: bool)
signal healed(amount: float)
signal died()

func _ready() -> void:
	print("[MockEntity] %s initialized" % name)

## 获取属性
func get_stat(stat_name: String) -> float:
	match stat_name:
		"strength":
			return strength
		"intelligence":
			return intelligence
		"agility":
			return agility
		"defense":
			return defense
		_:
			return 0.0

## 生命值相关
func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func take_damage(amount: float) -> void:
	health -= amount
	health = max(0, health)
	print("[MockEntity] %s took %.1f damage (%.1f/%.1f HP)" % [name, amount, health, max_health])
	damage_taken.emit(amount, false)

	if health <= 0:
		died.emit()

func heal(amount: float) -> void:
	var old_health = health
	health += amount
	health = min(health, max_health)
	var actual_heal = health - old_health
	print("[MockEntity] %s healed %.1f HP (%.1f/%.1f HP)" % [name, actual_heal, health, max_health])
	healed.emit(actual_heal)

func add_health(amount: float) -> void:
	heal(amount)

## 法力值相关
func get_mana() -> float:
	return mana

func get_max_mana() -> float:
	return max_mana

func consume_mana(amount: float) -> bool:
	if mana >= amount:
		mana -= amount
		print("[MockEntity] %s consumed %.1f mana (%.1f/%.1f)" % [name, amount, mana, max_mana])
		return true
	return false

## 耐力相关
func get_stamina() -> float:
	return stamina

func get_max_stamina() -> float:
	return max_stamina

func consume_stamina(amount: float) -> bool:
	if stamina >= amount:
		stamina -= amount
		print("[MockEntity] %s consumed %.1f stamina (%.1f/%.1f)" % [name, amount, stamina, max_stamina])
		return true
	return false

## 暴击相关
func get_crit_chance() -> float:
	return 0.15  # 15% 暴击率

func get_crit_multiplier() -> float:
	return 2.0  # 2倍暴击伤害

## 显示名称
func get_display_name() -> String:
	return name
