## Health Component
## 管理生命值、伤害、死亡逻辑
## 可复用的组件，适用于玩家和敌人
class_name HealthComponent
extends Node

## 生命值配置
@export var max_health: float = 100.0
@export var regeneration_rate: float = 0.0  # 每秒恢复量
@export var invincibility_duration: float = 0.5  # 无敌时间

## 当前状态
var current_health: float
var is_dead: bool = false
var is_invincible: bool = false
var invincibility_timer: float = 0.0

## 信号
signal health_changed(current: float, maximum: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float)
signal died()
signal revived()

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	## 处理无敌时间
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0.0:
			is_invincible = false

	## 处理生命恢复
	if regeneration_rate > 0.0 and not is_dead:
		heal(regeneration_rate * delta)

## 受到伤害
func take_damage(amount: float, source: Node = null) -> bool:
	if is_dead or is_invincible:
		return false

	var actual_damage := max(0.0, amount)
	current_health = max(0.0, current_health - actual_damage)

	health_changed.emit(current_health, max_health)
	damage_taken.emit(actual_damage, source)

	# Phase 4.5: 播放受击特效
	_play_hit_vfx()

	## 触发无敌时间
	if invincibility_duration > 0.0:
		is_invincible = true
		invincibility_timer = invincibility_duration

	## 检查死亡
	if current_health <= 0.0 and not is_dead:
		die()

	return true

## Phase 4.5: 播放受击视觉反馈
func _play_hit_vfx() -> void:
	var character := get_parent()
	if not character:
		return

	var VFXManager := load("res://scripts/visual/vfx_manager.gd")

	# 受击火花
	VFXManager.spawn_hit_vfx(character.global_position + Vector3(0, 1, 0), get_tree().root)

	# 红色闪光
	VFXManager.flash_hit_feedback(character, 0.15)

## 治疗
func heal(amount: float) -> void:
	if is_dead:
		return

	var actual_heal := max(0.0, amount)
	var old_health := current_health
	current_health = min(max_health, current_health + actual_heal)

	if current_health > old_health:
		health_changed.emit(current_health, max_health)
		healed.emit(current_health - old_health)

## 死亡
func die() -> void:
	if is_dead:
		return

	is_dead = true
	current_health = 0.0
	died.emit()

## 复活
func revive(health_percent: float = 1.0) -> void:
	if not is_dead:
		return

	is_dead = false
	current_health = max_health * clamp(health_percent, 0.0, 1.0)
	health_changed.emit(current_health, max_health)
	revived.emit()

## 设置最大生命值
func set_max_health(new_max: float) -> void:
	var health_ratio := current_health / max_health if max_health > 0 else 1.0
	max_health = max(1.0, new_max)
	current_health = max_health * health_ratio
	health_changed.emit(current_health, max_health)

## 获取生命值百分比
func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0

## 是否满血
func is_full_health() -> bool:
	return current_health >= max_health
