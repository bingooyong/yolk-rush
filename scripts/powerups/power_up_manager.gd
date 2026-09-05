extends Node
class_name PowerUpManager
## 道具管理器 - 统一管理关卡中的所有道具

signal power_up_collected(power_up: PowerUpBase, player: Node)
signal power_up_activated(power_up: PowerUpBase, player: Node)
signal power_up_expired(power_up: PowerUpBase, player: Node)

## 预加载道具类型
const SpeedBoostScript = preload("res://scripts/powerups/speed_boost_power_up.gd")
const InvincibilityScript = preload("res://scripts/powerups/invincibility_power_up.gd")
const ShieldScript = preload("res://scripts/powerups/shield_power_up.gd")
const MagnetScript = preload("res://scripts/powerups/magnet_power_up.gd")

## 道具注册表
var active_power_ups: Array[PowerUpBase] = []
var spawned_power_ups: Array[PowerUpBase] = []

## 生成配置
@export var auto_spawn: bool = false
@export var spawn_interval: float = 5.0
@export var max_power_ups: int = 10

## 稀有度权重
var rarity_weights: Dictionary = {
	PowerUpBase.PowerUpRarity.COMMON: 50,
	PowerUpBase.PowerUpRarity.UNCOMMON: 30,
	PowerUpBase.PowerUpRarity.RARE: 15,
	PowerUpBase.PowerUpRarity.EPIC: 4,
	PowerUpBase.PowerUpRarity.LEGENDARY: 1
}

## 统计
var total_collected: int = 0
var total_spawned: int = 0
var collection_stats: Dictionary = {}

var spawn_timer: float = 0.0
var spawn_points: Array[Vector3] = []

func _ready() -> void:
	print("[PowerUpManager] Initialized")

func _process(delta: float) -> void:
	if auto_spawn:
		_handle_auto_spawn(delta)

## 自动生成道具
func _handle_auto_spawn(delta: float) -> void:
	if spawned_power_ups.size() >= max_power_ups:
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		spawn_random_power_up()

## 注册道具
func register_power_up(power_up: PowerUpBase) -> void:
	if power_up in active_power_ups:
		return

	active_power_ups.append(power_up)
	spawned_power_ups.append(power_up)
	total_spawned += 1

	# 连接信号
	power_up.power_up_collected.connect(_on_power_up_collected.bind(power_up))
	power_up.power_up_activated.connect(_on_power_up_activated.bind(power_up))
	power_up.power_up_expired.connect(_on_power_up_expired.bind(power_up))

	print("[PowerUpManager] Registered: %s" % power_up.power_up_name)

## 注销道具
func unregister_power_up(power_up: PowerUpBase) -> void:
	if power_up not in active_power_ups:
		return

	active_power_ups.erase(power_up)
	spawned_power_ups.erase(power_up)

	# 断开信号
	if power_up.power_up_collected.is_connected(_on_power_up_collected):
		power_up.power_up_collected.disconnect(_on_power_up_collected)
	if power_up.power_up_activated.is_connected(_on_power_up_activated):
		power_up.power_up_activated.disconnect(_on_power_up_activated)
	if power_up.power_up_expired.is_connected(_on_power_up_expired):
		power_up.power_up_expired.disconnect(_on_power_up_expired)

## 生成随机道具
func spawn_random_power_up(position: Vector3 = Vector3.ZERO) -> PowerUpBase:
	# 随机选择位置
	if position == Vector3.ZERO:
		if spawn_points.is_empty():
			position = Vector3(randf_range(-20, 20), 2, randf_range(-20, 20))
		else:
			position = spawn_points[randi() % spawn_points.size()]

	# 随机选择稀有度
	var rarity = _roll_rarity()

	# 随机选择类型
	var power_up = _create_random_power_up(rarity)
	power_up.global_position = position

	# 添加到场景
	get_tree().root.add_child(power_up)

	# 注册
	register_power_up(power_up)

	print("[PowerUpManager] Spawned %s at %s" % [power_up.power_up_name, position])
	return power_up

## 生成指定类型道具
func spawn_power_up(type: PowerUpBase.PowerUpType, position: Vector3) -> PowerUpBase:
	var power_up: PowerUpBase

	match type:
		PowerUpBase.PowerUpType.SPEED_BOOST:
			power_up = SpeedBoostScript.new()
		PowerUpBase.PowerUpType.INVINCIBILITY:
			power_up = InvincibilityScript.new()
		PowerUpBase.PowerUpType.SHIELD:
			power_up = ShieldScript.new()
		PowerUpBase.PowerUpType.MAGNET:
			power_up = MagnetScript.new()
		_:
			power_up = SpeedBoostScript.new()

	power_up.global_position = position
	get_tree().root.add_child(power_up)
	register_power_up(power_up)

	return power_up

## 创建随机道具
func _create_random_power_up(rarity: PowerUpBase.PowerUpRarity) -> PowerUpBase:
	var types = [
		PowerUpBase.PowerUpType.SPEED_BOOST,
		PowerUpBase.PowerUpType.INVINCIBILITY,
		PowerUpBase.PowerUpType.SHIELD,
		PowerUpBase.PowerUpType.MAGNET
	]

	var type = types[randi() % types.size()]
	var power_up: PowerUpBase

	match type:
		PowerUpBase.PowerUpType.SPEED_BOOST:
			power_up = SpeedBoostScript.new()
		PowerUpBase.PowerUpType.INVINCIBILITY:
			power_up = InvincibilityScript.new()
		PowerUpBase.PowerUpType.SHIELD:
			power_up = ShieldScript.new()
		PowerUpBase.PowerUpType.MAGNET:
			power_up = MagnetScript.new()

	power_up.rarity = rarity
	return power_up

## 随机稀有度
func _roll_rarity() -> PowerUpBase.PowerUpRarity:
	var total_weight = 0
	for weight in rarity_weights.values():
		total_weight += weight

	var roll = randf() * total_weight
	var current_weight = 0

	for rarity in rarity_weights.keys():
		current_weight += rarity_weights[rarity]
		if roll <= current_weight:
			return rarity

	return PowerUpBase.PowerUpRarity.COMMON

## 信号回调
func _on_power_up_collected(player: Node, power_up: PowerUpBase) -> void:
	total_collected += 1

	# 统计
	var type_name = PowerUpBase.PowerUpType.keys()[power_up.power_up_type]
	if not collection_stats.has(type_name):
		collection_stats[type_name] = 0
	collection_stats[type_name] += 1

	power_up_collected.emit(power_up, player)
	print("[PowerUpManager] Collected: %s by %s (Total: %d)" %
		[power_up.power_up_name, player.name, total_collected])

func _on_power_up_activated(player: Node, power_up: PowerUpBase) -> void:
	power_up_activated.emit(power_up, player)
	print("[PowerUpManager] Activated: %s for %s" %
		[power_up.power_up_name, player.name])

func _on_power_up_expired(player: Node, power_up: PowerUpBase) -> void:
	power_up_expired.emit(power_up, player)
	unregister_power_up(power_up)
	print("[PowerUpManager] Expired: %s" % power_up.power_up_name)

## 添加生成点
func add_spawn_point(position: Vector3) -> void:
	spawn_points.append(position)

## 批量添加生成点
func add_spawn_points(positions: Array) -> void:
	for pos in positions:
		if pos is Vector3:
			spawn_points.append(pos)

## 清除所有生成点
func clear_spawn_points() -> void:
	spawn_points.clear()

## 清除所有道具
func clear_all_power_ups() -> void:
	for power_up in spawned_power_ups.duplicate():
		if is_instance_valid(power_up):
			power_up.queue_free()
		unregister_power_up(power_up)

	spawned_power_ups.clear()
	active_power_ups.clear()

## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"total_spawned": total_spawned,
		"total_collected": total_collected,
		"active_count": spawned_power_ups.size(),
		"collection_by_type": collection_stats
	}

## 打印统计
func print_stats() -> void:
	var stats = get_stats()
	print("\n[PowerUpManager] Statistics:")
	print("  Total Spawned: %d" % stats.total_spawned)
	print("  Total Collected: %d" % stats.total_collected)
	print("  Currently Active: %d" % stats.active_count)
	print("  Collection by Type:")
	for type in stats.collection_by_type:
		print("    %s: %d" % [type, stats.collection_by_type[type]])

## 设置稀有度权重
func set_rarity_weight(rarity: PowerUpBase.PowerUpRarity, weight: int) -> void:
	rarity_weights[rarity] = weight

## 启用/禁用自动生成
func set_auto_spawn(enabled: bool) -> void:
	auto_spawn = enabled
	if enabled:
		spawn_timer = spawn_interval

## 设置生成间隔
func set_spawn_interval(interval: float) -> void:
	spawn_interval = interval

## 设置最大道具数量
func set_max_power_ups(max: int) -> void:
	max_power_ups = max
