extends Node3D
class_name PowerUpBase
## 道具基类 - 所有道具的通用行为

signal power_up_collected(player: Node)
signal power_up_activated(player: Node)
signal power_up_expired(player: Node)

enum PowerUpType {
	SPEED_BOOST,     # 加速
	INVINCIBILITY,   # 无敌
	SHIELD,          # 护盾
	DOUBLE_JUMP,     # 双倍跳跃
	MAGNET,          # 磁铁（吸引道具）
	TELEPORT,        # 传送
	SLOW_TIME,       # 时间减缓
	GIANT_SIZE       # 巨大化
}

enum PowerUpRarity {
	COMMON,    # 常见
	UNCOMMON,  # 不常见
	RARE,      # 稀有
	EPIC,      # 史诗
	LEGENDARY  # 传说
}

## 道具属性
@export var power_up_name: String = "PowerUp"
@export var power_up_type: PowerUpType = PowerUpType.SPEED_BOOST
@export var rarity: PowerUpRarity = PowerUpRarity.COMMON
@export var duration: float = 5.0  # 持续时间（秒）
@export var effect_value: float = 1.0  # 效果值
@export var auto_activate: bool = true  # 拾取后自动激活
@export var can_stack: bool = false  # 是否可叠加

## 视觉属性
@export var rotate_speed: float = 90.0  # 旋转速度
@export var float_amplitude: float = 0.3  # 悬浮幅度
@export var float_speed: float = 2.0  # 悬浮速度

## 状态
var is_collected: bool = false
var is_active: bool = false
var current_holder: Node = null
var time_remaining: float = 0.0

## 组件
var mesh_instance: MeshInstance3D
var collision_area: Area3D
var collision_shape: CollisionShape3D
var particle_effect: Node3D

## 动画
var float_offset: float = 0.0
var original_y: float = 0.0

func _ready() -> void:
	original_y = global_position.y
	_setup_visual()
	_setup_collision()
	_initialize_power_up()
	print("[%s] Spawned at %s" % [power_up_name, global_position])

## 设置视觉
func _setup_visual() -> void:
	# 创建道具模型
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	add_child(mesh_instance)

	# 默认使用球体
	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	mesh_instance.mesh = mesh

	# 设置材质
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_rarity_color()
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.5
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.material_override = material

## 设置碰撞
func _setup_collision() -> void:
	collision_area = Area3D.new()
	collision_area.name = "CollisionArea"
	collision_area.collision_layer = 16  # 道具层
	collision_area.collision_mask = 1    # 玩家层
	add_child(collision_area)

	collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision_shape.shape = shape
	collision_area.add_child(collision_shape)

	collision_area.body_entered.connect(_on_body_entered)

## 初始化道具（子类重写）
func _initialize_power_up() -> void:
	pass

## 获取稀有度颜色
func _get_rarity_color() -> Color:
	match rarity:
		PowerUpRarity.COMMON:
			return Color(0.8, 0.8, 0.8)  # 灰色
		PowerUpRarity.UNCOMMON:
			return Color(0.3, 0.8, 0.3)  # 绿色
		PowerUpRarity.RARE:
			return Color(0.3, 0.5, 1.0)  # 蓝色
		PowerUpRarity.EPIC:
			return Color(0.8, 0.3, 0.9)  # 紫色
		PowerUpRarity.LEGENDARY:
			return Color(1.0, 0.6, 0.0)  # 橙色
	return Color.WHITE

func _process(delta: float) -> void:
	if not is_collected:
		_animate_idle(delta)
	elif is_active:
		_update_active_effect(delta)

## 待机动画
func _animate_idle(delta: float) -> void:
	# 旋转
	rotate_y(deg_to_rad(rotate_speed * delta))

	# 悬浮
	float_offset += float_speed * delta
	var float_y = sin(float_offset) * float_amplitude
	global_position.y = original_y + float_y

## 更新激活效果
func _update_active_effect(delta: float) -> void:
	if time_remaining > 0:
		time_remaining -= delta

		if time_remaining <= 0:
			_deactivate()

## 碰撞检测
func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	if _is_player(body):
		_collect(body)

## 判断是否为玩家
func _is_player(body: Node) -> bool:
	return body.is_in_group("player")

## 收集道具
func _collect(player: Node) -> void:
	if is_collected:
		return

	is_collected = true
	current_holder = player

	# 隐藏道具
	visible = false
	collision_area.monitoring = false

	# 触发收集信号
	power_up_collected.emit(player)

	print("[%s] Collected by: %s" % [power_up_name, player.name])

	# 播放收集音效
	_play_collect_sound()

	if auto_activate:
		activate(player)
	else:
		# 添加到玩家背包
		if player.has_method("add_power_up"):
			player.add_power_up(self)

## 激活道具
func activate(player: Node) -> void:
	if is_active:
		if can_stack:
			time_remaining += duration
			print("[%s] Stacked! New duration: %.1fs" % [power_up_name, time_remaining])
		return

	is_active = true
	current_holder = player
	time_remaining = duration

	# 应用效果
	_apply_effect(player)

	# 触发激活信号
	power_up_activated.emit(player)

	print("[%s] Activated for %.1fs" % [power_up_name, duration])

## 应用效果（子类重写）
func _apply_effect(player: Node) -> void:
	pass

## 取消激活
func _deactivate() -> void:
	if not is_active:
		return

	is_active = false

	# 移除效果
	if current_holder:
		_remove_effect(current_holder)

	# 触发过期信号
	power_up_expired.emit(current_holder)

	print("[%s] Expired" % power_up_name)

	# 销毁道具
	queue_free()

## 移除效果（子类重写）
func _remove_effect(player: Node) -> void:
	pass

## 播放收集音效
func _play_collect_sound() -> void:
	# TODO: 集成音效系统
	pass

## 获取剩余时间百分比
func get_time_percentage() -> float:
	if duration <= 0:
		return 0.0
	return time_remaining / duration

## 强制结束
func force_expire() -> void:
	time_remaining = 0.0
	_deactivate()

## 延长持续时间
func extend_duration(extra_time: float) -> void:
	time_remaining += extra_time
	print("[%s] Duration extended by %.1fs" % [power_up_name, extra_time])
