## HurtBox Component
## 受击判定区域，用于接收伤害
## 通常附加在角色身体上
class_name HurtBox
extends Area3D

## 所有者（必须有 HealthComponent）
var owner_node: Node = null
var health_component: HealthComponent = null

## 伤害倍率（可用于弱点系统）
@export var damage_multiplier: float = 1.0
@export var is_weak_point: bool = false  # 是否是弱点

## 信号
signal damage_received(amount: float, source: Node)

func _ready() -> void:
	## 设置碰撞层
	collision_layer = 4  # HurtBox 在 layer 3
	collision_mask = 0   # HurtBox 不检测其他物体

	## 自动查找所有者和 HealthComponent
	_find_owner_and_health()

func _find_owner_and_health() -> void:
	## 向上查找拥有 HealthComponent 的节点
	var current := get_parent()
	while current:
		var health := current.find_child("HealthComponent", false, false) as HealthComponent
		if health:
			owner_node = current
			health_component = health
			return
		current = current.get_parent()

	push_warning("HurtBox: No HealthComponent found in parent hierarchy")

## 应用伤害
func apply_damage(amount: float, source: Node = null) -> bool:
	if not health_component:
		return false

	## 计算最终伤害
	var final_damage := amount * damage_multiplier
	if is_weak_point:
		final_damage *= 2.0  # 弱点双倍伤害

	## 应用到 HealthComponent
	var success := health_component.take_damage(final_damage, source)

	if success:
		damage_received.emit(final_damage, source)

	return success

## 设置所有者
func set_owner_node(node: Node) -> void:
	owner_node = node

	## 重新查找 HealthComponent
	if owner_node:
		health_component = owner_node.find_child("HealthComponent", true, false) as HealthComponent
