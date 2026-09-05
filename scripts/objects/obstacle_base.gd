extends Area3D
class_name ObstacleBase
## 障碍物基类
## 提供基础的伤害功能

signal player_hit(damage: int)

## 障碍物属性
@export var damage: int = 10
@export var damage_cooldown: float = 1.0
@export var obstacle_type: String = "generic"

## 内部状态
var last_damage_time: Dictionary = {}  # 记录每个实体的上次受伤时间

## 视觉节点
var visual_mesh: MeshInstance3D = null

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)

	print("[ObstacleBase] Initialized: Type=%s, Damage=%d" % [obstacle_type, damage])

func _on_body_entered(body: Node3D) -> void:
	## 碰撞检测
	if body.has_method("take_damage"):
		# 检查冷却时间
		var current_time = Time.get_ticks_msec() / 1000.0
		var body_id = body.get_instance_id()

		if body_id in last_damage_time:
			var elapsed = current_time - last_damage_time[body_id]
			if elapsed < damage_cooldown:
				return  # 还在冷却中

		# 造成伤害
		body.take_damage(damage)
		last_damage_time[body_id] = current_time

		# 发送信号
		if body.is_in_group("player"):
			player_hit.emit(damage)

		print("[ObstacleBase] Hit %s for %d damage" % [body.name, damage])

## 创建占位符视觉
func _create_placeholder_visual(color: Color, size: Vector3) -> void:
	visual_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	visual_mesh.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	visual_mesh.material_override = material

	add_child(visual_mesh)
