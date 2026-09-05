extends Node
class_name AIManager
## AI管理器 - 统一管理所有AI实体

signal ai_registered(ai_controller)
signal ai_unregistered(ai_controller)

## 配置
@export var max_active_ai: int = 50  # 最大活跃AI数量
@export var update_batch_size: int = 10  # 每帧更新的AI数量

## 状态
var registered_ais: Array = []
var active_ais: Array = []
var current_update_index: int = 0

func _ready() -> void:
	print("[AIManager] Initialized")

func _process(_delta: float) -> void:
	_update_active_ais()

func _update_active_ais() -> void:
	if active_ais.is_empty():
		return

	# 批量更新AI，避免单帧更新过多
	var updates_this_frame = min(update_batch_size, active_ais.size())

	for i in range(updates_this_frame):
		var ai_index = (current_update_index + i) % active_ais.size()
		var ai = active_ais[ai_index]

		if is_instance_valid(ai) and ai.entity:
			# AI已经在自己的 _process 中更新
			pass

	current_update_index = (current_update_index + updates_this_frame) % max(1, active_ais.size())

## 注册AI
func register_ai(ai_controller) -> void:
	if ai_controller in registered_ais:
		return

	registered_ais.append(ai_controller)
	active_ais.append(ai_controller)
	ai_registered.emit(ai_controller)

	print("[AIManager] Registered AI: %s" % ai_controller.get_entity_name())

## 注销AI
func unregister_ai(ai_controller) -> void:
	if ai_controller not in registered_ais:
		return

	registered_ais.erase(ai_controller)
	active_ais.erase(ai_controller)
	ai_unregistered.emit(ai_controller)

	print("[AIManager] Unregistered AI: %s" % ai_controller.get_entity_name())

## 激活AI
func activate_ai(ai_controller) -> void:
	if ai_controller not in registered_ais:
		register_ai(ai_controller)
		return

	if ai_controller not in active_ais:
		active_ais.append(ai_controller)

## 停用AI
func deactivate_ai(ai_controller) -> void:
	active_ais.erase(ai_controller)

## 获取所有AI
func get_all_ais() -> Array:
	return registered_ais

## 获取活跃AI
func get_active_ais() -> Array:
	return active_ais

## 获取指定状态的AI
func get_ais_in_state(state: int) -> Array:
	var result: Array = []

	for ai in registered_ais:
		if is_instance_valid(ai) and ai.current_state == state:
			result.append(ai)

	return result

## 获取正在战斗的AI
func get_combat_ais() -> Array:
	# 使用常量值而不是类型引用
	return get_ais_in_state(3)  # COMBAT = 3

## 清理无效的AI
func cleanup_invalid_ais() -> void:
	var invalid_ais: Array = []

	for ai in registered_ais:
		if not is_instance_valid(ai) or not is_instance_valid(ai.entity):
			invalid_ais.append(ai)

	for ai in invalid_ais:
		unregister_ai(ai)

	if not invalid_ais.is_empty():
		print("[AIManager] Cleaned up %d invalid AIs" % invalid_ais.size())

## 通知所有AI某个事件
func broadcast_event(event_name: String, data: Dictionary = {}) -> void:
	for ai in active_ais:
		if is_instance_valid(ai) and ai.has_method("on_event"):
			ai.on_event(event_name, data)

## 让所有AI进入警戒状态
func alert_all(threat: Node) -> void:
	for ai in active_ais:
		if is_instance_valid(ai):
			# IDLE = 0, PATROL = 1
			if ai.current_state in [0, 1]:
				ai.set_target(threat)
				ai.change_state(4)  # ALERT = 4

## 获取统计信息
func get_stats() -> Dictionary:
	var stats = {
		"total_registered": registered_ais.size(),
		"total_active": active_ais.size(),
		"by_state": {}
	}

	# 手动遍历各个状态值
	for state in [0, 1, 2, 3, 4, 5]:  # IDLE到DEAD
		var state_names = ["IDLE", "PATROL", "CHASE", "COMBAT", "ALERT", "DEAD"]
		var count = get_ais_in_state(state).size()
		stats["by_state"][state_names[state]] = count

	return stats

## 打印统计信息
func print_stats() -> void:
	var stats = get_stats()
	print("[AIManager] Stats:")
	print("  Total Registered: %d" % stats["total_registered"])
	print("  Total Active: %d" % stats["total_active"])
	print("  By State:")
	for state_name in stats["by_state"]:
		print("    %s: %d" % [state_name, stats["by_state"][state_name]])
