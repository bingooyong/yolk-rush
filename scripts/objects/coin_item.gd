extends "res://scripts/objects/item_base.gd"
class_name CoinItem
## 金币道具
## 拾取后增加分数

@export var coin_value: int = 10

func _ready() -> void:
	item_type = "coin"
	pickup_effect_value = coin_value

	# 创建金币视觉（黄色球体）
	_create_placeholder_visual(Color(1.0, 0.9, 0.0), 0.3)

	# 配置碰撞
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	add_child(collision)

	super._ready()

func apply_effect(picker: Node3D) -> void:
	## 增加分数
	if picker.has_method("add_score"):
		picker.add_score(coin_value)
		print("[CoinItem] Added %d score to %s" % [coin_value, picker.name])
