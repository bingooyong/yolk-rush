extends Node
class_name LevelFlowController
## 关卡流程控制器
## 管理关卡的初始化、目标、胜利条件和过渡

signal objective_completed(objective_id: String)
signal all_objectives_completed()
signal level_ready()
signal level_cleanup_started()

## 关卡配置
var level_config: Dictionary = {}

## 当前目标
var objectives: Dictionary = {}

## 是否已准备
var is_ready: bool = false

## 是否已完成
var is_completed: bool = false

## 游戏状态管理器引用
var game_state_manager: Node = null

func _ready() -> void:
	# 查找游戏状态管理器
	if has_node("/root/GameStateManager"):
		game_state_manager = get_node("/root/GameStateManager")

## 初始化关卡
func initialize_level(config: Dictionary) -> void:
	print("[LevelFlowController] Initializing level: %s" % config.get("name", "Unknown"))

	level_config = config
	objectives.clear()
	is_ready = false
	is_completed = false

	# 加载目标
	_load_objectives()

	# 等待一帧确保所有节点准备就绪
	await get_tree().process_frame

	is_ready = true
	level_ready.emit()

	print("[LevelFlowController] Level ready: %d objectives" % objectives.size())

## 加载关卡目标
func _load_objectives() -> void:
	var objectives_data = level_config.get("objectives", [])

	for obj_data in objectives_data:
		var obj_id = obj_data.get("id", "")
		if obj_id == "":
			continue

		objectives[obj_id] = {
			"id": obj_id,
			"type": obj_data.get("type", "collect"),
			"description": obj_data.get("description", ""),
			"target": obj_data.get("target", 1),
			"current": 0,
			"completed": false,
			"optional": obj_data.get("optional", false)
		}

	# 如果没有定义目标，创建默认目标（到达终点）
	if objectives.size() == 0:
		objectives["reach_finish"] = {
			"id": "reach_finish",
			"type": "reach",
			"description": "到达终点",
			"target": 1,
			"current": 0,
			"completed": false,
			"optional": false
		}

## 更新目标进度
func update_objective(objective_id: String, progress: int = 1) -> void:
	if not objectives.has(objective_id):
		return

	var obj = objectives[objective_id]

	if obj.completed:
		return

	obj.current += progress

	# 检查是否完成
	if obj.current >= obj.target:
		obj.current = obj.target
		obj.completed = true
		objective_completed.emit(objective_id)

		print("[LevelFlowController] Objective completed: %s" % obj.description)

		# 检查所有目标是否完成
		_check_all_objectives()

## 检查所有目标是否完成
func _check_all_objectives() -> void:
	var required_completed = true

	for obj_id in objectives:
		var obj = objectives[obj_id]
		if not obj.optional and not obj.completed:
			required_completed = false
			break

	if required_completed and not is_completed:
		is_completed = true
		all_objectives_completed.emit()

		print("[LevelFlowController] All objectives completed!")

		# 通知游戏状态管理器
		if game_state_manager:
			game_state_manager.level_victory()

## 关卡失败
func level_failed(reason: String = "") -> void:
	if is_completed:
		return

	print("[LevelFlowController] Level failed: %s" % reason)

	# 通知游戏状态管理器
	if game_state_manager:
		game_state_manager.level_defeat()

## 清理关卡
func cleanup_level() -> void:
	print("[LevelFlowController] Cleaning up level")

	level_cleanup_started.emit()

	objectives.clear()
	level_config.clear()
	is_ready = false
	is_completed = false

## 获取目标列表
func get_objectives() -> Array:
	var result: Array = []
	for obj_id in objectives:
		result.append(objectives[obj_id])
	return result

## 获取目标进度（0.0 - 1.0）
func get_objective_progress(objective_id: String) -> float:
	if not objectives.has(objective_id):
		return 0.0

	var obj = objectives[objective_id]
	if obj.target == 0:
		return 0.0

	return float(obj.current) / float(obj.target)

## 获取总体进度（0.0 - 1.0）
func get_overall_progress() -> float:
	if objectives.size() == 0:
		return 0.0

	var completed_count = 0
	var required_count = 0

	for obj_id in objectives:
		var obj = objectives[obj_id]
		if not obj.optional:
			required_count += 1
			if obj.completed:
				completed_count += 1

	if required_count == 0:
		return 0.0

	return float(completed_count) / float(required_count)

## 是否所有必需目标完成
func are_required_objectives_completed() -> bool:
	for obj_id in objectives:
		var obj = objectives[obj_id]
		if not obj.optional and not obj.completed:
			return false

	return true

## 获取剩余目标数量
func get_remaining_objectives_count() -> int:
	var count = 0
	for obj_id in objectives:
		var obj = objectives[obj_id]
		if not obj.optional and not obj.completed:
			count += 1

	return count
