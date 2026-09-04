extends Node
class_name HealthComponent
## 生命值组件：管理角色血量和受伤逻辑

signal health_changed(current: float, max: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float)
signal died()

@export var max_health: float = 100.0
@export var invulnerable_duration: float = 0.5  ## 受伤后的无敌时间

var current_health: float
var is_dead: bool = false
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	print("[HealthComponent] Ready - Max Health: %.0f" % max_health)

func _physics_process(delta: float) -> void:
	if is_invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false

func take_damage(amount: float, source: Node = null) -> bool:
	if is_dead or is_invulnerable or amount <= 0.0:
		return false

	current_health -= amount
	current_health = max(0.0, current_health)

	damage_taken.emit(amount, source)
	health_changed.emit(current_health, max_health)

	## 触发无敌帧
	is_invulnerable = true
	invulnerable_timer = invulnerable_duration

	print("[HealthComponent] Took %.1f damage, remaining: %.1f/%.1f" % [amount, current_health, max_health])

	if current_health <= 0.0:
		_die()
		return true

	return true

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	var old_health := current_health
	current_health = min(current_health + amount, max_health)

	if current_health > old_health:
		healed.emit(amount)
		health_changed.emit(current_health, max_health)
		print("[HealthComponent] Healed %.1f, current: %.1f/%.1f" % [amount, current_health, max_health])

func set_max_health(new_max: float) -> void:
	max_health = max(1.0, new_max)
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health

func reset() -> void:
	current_health = max_health
	is_dead = false
	is_invulnerable = false
	invulnerable_timer = 0.0
	health_changed.emit(current_health, max_health)

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()
	print("[HealthComponent] Died")
