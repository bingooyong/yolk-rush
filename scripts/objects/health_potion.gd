extends "res://scripts/objects/item_base.gd"
class_name HealthPotion
## 生命药水
## 拾取后恢复生命值

@export var heal_amount: int = 30

func _ready() -> void:
	item_type = "health_potion"
	pickup_effect_value = heal_amount

	# 创建药水视觉（绿色球体）
	_create_placeholder_visual(Color(0.2, 0.8, 0.2), 0.35)

	# 配置碰撞
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	add_child(collision)

	super._ready()

func apply_effect(picker: Node3D) -> void:
	## 恢复生命值
	if picker.has_method("heal"):
		picker.heal(heal_amount)
		print("[HealthPotion] Healed %s for %d HP" % [picker.name, heal_amount])
