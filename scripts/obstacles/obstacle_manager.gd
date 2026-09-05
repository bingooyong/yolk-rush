extends Node
class_name ObstacleManager
## 障碍管理器 - 统一管理关卡中的所有障碍

signal obstacle_triggered(obstacle: ObstacleBase, player: Node)
signal all_obstacles_cleared()

## 障碍注册表
var active_obstacles: Array[ObstacleBase] = []
var obstacle_groups: Dictionary = {}  # 按类型分组

## 统计数据
var total_triggers: int = 0
var players_affected: Dictionary = {}

func _ready() -> void:
	print("[ObstacleManager] Initialized")

## 注册障碍
func register_obstacle(obstacle: ObstacleBase, group_name: String = "default") -> void:
	if obstacle in active_obstacles:
		return

	active_obstacles.append(obstacle)

	# 按组分类
	if not obstacle_groups.has(group_name):
		obstacle_groups[group_name] = []
	obstacle_groups[group_name].append(obstacle)

	# 连接信号
	obstacle.obstacle_triggered.connect(_on_obstacle_triggered.bind(obstacle))

	print("[ObstacleManager] Registered: %s in group '%s'" % [obstacle.obstacle_name, group_name])

## 注销障碍
func unregister_obstacle(obstacle: ObstacleBase) -> void:
	if obstacle not in active_obstacles:
		return

	active_obstacles.erase(obstacle)

	# 从所有组中移除
	for group in obstacle_groups.values():
		if obstacle in group:
			group.erase(obstacle)

	# 断开信号
	if obstacle.obstacle_triggered.is_connected(_on_obstacle_triggered):
		obstacle.obstacle_triggered.disconnect(_on_obstacle_triggered)

	print("[ObstacleManager] Unregistered: %s" % obstacle.obstacle_name)

## 自动发现并注册场景中的所有障碍
func discover_obstacles() -> void:
	var root = get_tree().root
	_discover_recursive(root)
	print("[ObstacleManager] Discovered %d obstacles" % active_obstacles.size())

func _discover_recursive(node: Node) -> void:
	if node is ObstacleBase:
		register_obstacle(node)

	for child in node.get_children():
		_discover_recursive(child)

## 障碍触发回调
func _on_obstacle_triggered(player: Node, obstacle: ObstacleBase) -> void:
	total_triggers += 1

	# 统计玩家
	if player not in players_affected:
		players_affected[player] = 0
	players_affected[player] += 1

	# 发送信号
	obstacle_triggered.emit(obstacle, player)

	print("[ObstacleManager] Obstacle '%s' triggered by '%s' (Total: %d)" %
		[obstacle.obstacle_name, player.name, total_triggers])

## 激活指定组的障碍
func activate_group(group_name: String) -> void:
	if not obstacle_groups.has(group_name):
		return

	for obstacle in obstacle_groups[group_name]:
		obstacle.activate()

	print("[ObstacleManager] Activated group: %s (%d obstacles)" %
		[group_name, obstacle_groups[group_name].size()])

## 禁用指定组的障碍
func deactivate_group(group_name: String) -> void:
	if not obstacle_groups.has(group_name):
		return

	for obstacle in obstacle_groups[group_name]:
		obstacle.deactivate()

	print("[ObstacleManager] Deactivated group: %s" % group_name)

## 激活所有障碍
func activate_all() -> void:
	for obstacle in active_obstacles:
		obstacle.activate()
	print("[ObstacleManager] Activated all obstacles")

## 禁用所有障碍
func deactivate_all() -> void:
	for obstacle in active_obstacles:
		obstacle.deactivate()
	print("[ObstacleManager] Deactivated all obstacles")

## 重置所有障碍
func reset_all() -> void:
	for obstacle in active_obstacles:
		obstacle.reset_obstacle()
	total_triggers = 0
	players_affected.clear()
	print("[ObstacleManager] Reset all obstacles")

## 重置指定组
func reset_group(group_name: String) -> void:
	if not obstacle_groups.has(group_name):
		return

	for obstacle in obstacle_groups[group_name]:
		obstacle.reset_obstacle()

	print("[ObstacleManager] Reset group: %s" % group_name)

## 获取指定类型的障碍
func get_obstacles_by_type(type: String) -> Array[ObstacleBase]:
	var result: Array[ObstacleBase] = []

	for obstacle in active_obstacles:
		if obstacle.get_class() == type:
			result.append(obstacle)

	return result

## 获取指定组的障碍
func get_obstacles_in_group(group_name: String) -> Array:
	if obstacle_groups.has(group_name):
		return obstacle_groups[group_name].duplicate()
	return []

## 获取所有激活的障碍
func get_active_obstacles() -> Array[ObstacleBase]:
	var result: Array[ObstacleBase] = []

	for obstacle in active_obstacles:
		if obstacle.is_active:
			result.append(obstacle)

	return result

## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"total_obstacles": active_obstacles.size(),
		"active_obstacles": get_active_obstacles().size(),
		"total_triggers": total_triggers,
		"players_affected": players_affected.size(),
		"groups": obstacle_groups.keys()
	}

## 打印统计信息
func print_stats() -> void:
	var stats = get_stats()
	print("\n[ObstacleManager] Statistics:")
	print("  Total Obstacles: %d" % stats.total_obstacles)
	print("  Active Obstacles: %d" % stats.active_obstacles)
	print("  Total Triggers: %d" % stats.total_triggers)
	print("  Players Affected: %d" % stats.players_affected)
	print("  Groups: %s" % str(stats.groups))

## 清除所有障碍
func clear_all() -> void:
	for obstacle in active_obstacles.duplicate():
		unregister_obstacle(obstacle)

	obstacle_groups.clear()
	total_triggers = 0
	players_affected.clear()

	print("[ObstacleManager] Cleared all obstacles")

## 序列化障碍状态（用于保存/网络同步）
func serialize_state() -> Dictionary:
	var state = {}

	for i in range(active_obstacles.size()):
		var obstacle = active_obstacles[i]
		state[i] = {
			"name": obstacle.obstacle_name,
			"position": obstacle.global_position,
			"is_active": obstacle.is_active,
			"current_state": obstacle.current_state
		}

	return state

## 反序列化障碍状态
func deserialize_state(state: Dictionary) -> void:
	for i in state.keys():
		if i < active_obstacles.size():
			var obstacle = active_obstacles[i]
			var obstacle_state = state[i]

			obstacle.global_position = obstacle_state.position
			obstacle.is_active = obstacle_state.is_active
			obstacle.set_state(obstacle_state.current_state)
