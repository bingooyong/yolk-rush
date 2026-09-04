## HitBox Component
## 攻击判定区域，用于检测能够被攻击的目标
## 通常附加在武器、拳头、子弹等攻击物体上
class_name HitBox
extends Area3D

## 伤害配置
@export var damage: float = 10.0
@export var knockback_force: float = 5.0
@export var hit_once: bool = true  # 是否只能打击一次
@export var lifetime: float = 0.0  # 生命周期（0 表示永久）

## 所有者
var owner_node: Node = null
var hit_targets: Array[Node] = []

## 信号
signal hit_target(target: Node)

func _ready() -> void:
	## 设置碰撞层
	collision_layer = 0  # HitBox 不被检测
	collision_mask = 4   # 检测 HurtBox (layer 3)

	## 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	## 设置生命周期
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_area_entered(area: Area3D) -> void:
	if not area is HurtBox:
		return

	var hurt_box := area as HurtBox

	## 检查是否是自己的 HurtBox
	if hurt_box.owner_node == owner_node:
		return

	## 检查是否已经击中
	if hit_once and hurt_box.owner_node in hit_targets:
		return

	## 应用伤害
	if hurt_box.apply_damage(damage, owner_node):
		hit_targets.append(hurt_box.owner_node)
		hit_target.emit(hurt_box.owner_node)

		## 应用击退
		if knockback_force > 0.0 and hurt_box.owner_node is CharacterBody3D:
			var direction := (hurt_box.global_position - global_position).normalized()
			hurt_box.owner_node.velocity += direction * knockback_force

		## 一次性打击后销毁
		if hit_once:
			call_deferred("queue_free")

func _on_body_entered(body: Node3D) -> void:
	## 处理直接碰撞到 CharacterBody3D 的情况
	pass

## 设置所有者
func set_owner_node(node: Node) -> void:
	owner_node = node

## 重置击中目标列表
func reset_hit_targets() -> void:
	hit_targets.clear()
