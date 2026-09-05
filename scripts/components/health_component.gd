extends Node
class_name HealthComponent
## 生命值组件 - 管理实体的生命值

signal health_changed(current: float, max_value: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float)
signal died()

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var regeneration_rate: float = 0.0  # 每秒回血
@export var is_invulnerable: bool = false

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	print("[HealthComponent] Initialized: %.1f/%.1f HP" % [current_health, max_health])

func _process(delta: float) -> void:
	# 自动回血
	if regeneration_rate > 0 and current_health < max_health and not is_dead:
		heal(regeneration_rate * delta)

## 受到伤害
func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or is_invulnerable:
		return

	var actual_damage = maxf(amount, 0.0)
	current_health = maxf(current_health - actual_damage, 0.0)

	print("[HealthComponent] Took %.1f damage, HP: %.1f/%.1f" % [actual_damage, current_health, max_health])

	damage_taken.emit(actual_damage, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die()

## 治疗
func heal(amount: float) -> void:
	if is_dead:
		return

	var actual_heal = maxf(amount, 0.0)
	var old_health = current_health
	current_health = minf(current_health + actual_heal, max_health)

	var healed_amount = current_health - old_health

	if healed_amount > 0:
		healed.emit(healed_amount)
		health_changed.emit(current_health, max_health)

## 设置最大生命值
func set_max_health(value: float) -> void:
	max_health = maxf(value, 1.0)
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)

## 完全恢复
func restore_full() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

## 获取生命值百分比
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health

## 是否存活
func is_alive() -> bool:
	return not is_dead

## 死亡处理
func _die() -> void:
	if is_dead:
		return

	is_dead = true
	print("[HealthComponent] Entity died")
	died.emit()

## 复活
func revive(health_percentage: float = 1.0) -> void:
	is_dead = false
	current_health = max_health * clampf(health_percentage, 0.0, 1.0)
	health_changed.emit(current_health, max_health)
	print("[HealthComponent] Revived with %.1f HP" % current_health)

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"is_dead": is_dead
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	current_health = data.get("current_health", max_health)
	max_health = data.get("max_health", 100.0)
	is_dead = data.get("is_dead", false)
	health_changed.emit(current_health, max_health)
