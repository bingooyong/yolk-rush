extends Node
class_name SaveManager
## 保存管理器
## 管理游戏进度保存和加载

## 信号
signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_failed(slot_id: int, error: String)
signal load_failed(slot_id: int, error: String)

## 保存配置
const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_"
const SAVE_FILE_EXTENSION = ".dat"
const MAX_SAVE_SLOTS = 3
const SAVE_VERSION = 1

## 当前存档槽
var current_slot: int = -1

## 存档数据缓存
var save_data_cache: Dictionary = {}

## GameConfig引用（可选，用于直接访问）
var game_config_override: Node = null

func _ready() -> void:
	print("[SaveManager] Initializing...")

	# 确保保存目录存在
	_ensure_save_directory()

	# 扫描现有存档
	_scan_saves()

	print("[SaveManager] Initialized")

## 确保保存目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")
			print("[SaveManager] Created save directory")

## 扫描现有存档
func _scan_saves() -> void:
	save_data_cache.clear()

	for slot_id in range(MAX_SAVE_SLOTS):
		var save_path = _get_save_path(slot_id)
		if FileAccess.file_exists(save_path):
			var metadata = _load_save_metadata(slot_id)
			if metadata:
				save_data_cache[slot_id] = metadata
				print("[SaveManager] Found save in slot %d" % slot_id)

## 保存游戏
func save_game(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot ID: %d" % slot_id)
		save_failed.emit(slot_id, "Invalid slot ID")
		return false

	print("[SaveManager] Saving game to slot %d..." % slot_id)

	# 收集保存数据
	var save_data = _collect_save_data()

	# 添加元数据
	save_data["metadata"] = {
		"version": SAVE_VERSION,
		"slot_id": slot_id,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": _get_total_play_time(),
		"level_progress": _get_level_progress()
	}

	# 写入文件
	var save_path = _get_save_path(slot_id)
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	if not file:
		push_error("[SaveManager] Failed to open save file: %s" % save_path)
		save_failed.emit(slot_id, "Failed to open file")
		return false

	# 转换为JSON并写入
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	# 更新缓存
	save_data_cache[slot_id] = save_data["metadata"]

	# 设置当前槽
	current_slot = slot_id

	print("[SaveManager] Save completed to slot %d" % slot_id)
	save_completed.emit(slot_id)

	return true

## 加载游戏
func load_game(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot ID: %d" % slot_id)
		load_failed.emit(slot_id, "Invalid slot ID")
		return false

	var save_path = _get_save_path(slot_id)

	if not FileAccess.file_exists(save_path):
		push_error("[SaveManager] Save file not found: %s" % save_path)
		load_failed.emit(slot_id, "Save file not found")
		return false

	print("[SaveManager] Loading game from slot %d..." % slot_id)

	# 读取文件
	var file = FileAccess.open(save_path, FileAccess.READ)

	if not file:
		push_error("[SaveManager] Failed to open save file: %s" % save_path)
		load_failed.emit(slot_id, "Failed to open file")
		return false

	var json_string = file.get_as_text()
	file.close()

	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file")
		load_failed.emit(slot_id, "Failed to parse save data")
		return false

	var save_data = json.data

	# 验证版本
	if not save_data.has("metadata"):
		push_error("[SaveManager] Invalid save data: missing metadata")
		load_failed.emit(slot_id, "Invalid save data")
		return false

	var metadata = save_data["metadata"]
	if metadata.get("version", 0) != SAVE_VERSION:
		push_warning("[SaveManager] Save version mismatch: %d vs %d" % [metadata.get("version"), SAVE_VERSION])
		# 继续加载，但可能需要迁移

	# 应用保存数据
	_apply_save_data(save_data)

	# 设置当前槽
	current_slot = slot_id

	print("[SaveManager] Load completed from slot %d" % slot_id)
	load_completed.emit(slot_id)

	return true

## 删除存档
func delete_save(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot ID: %d" % slot_id)
		return false

	var save_path = _get_save_path(slot_id)

	if not FileAccess.file_exists(save_path):
		print("[SaveManager] Save file not found, nothing to delete")
		return true

	# 删除文件
	var dir = DirAccess.open("user://saves/")
	if dir:
		var error = dir.remove(_get_save_filename(slot_id))
		if error == OK:
			print("[SaveManager] Deleted save in slot %d" % slot_id)
			save_data_cache.erase(slot_id)

			if current_slot == slot_id:
				current_slot = -1

			return true
		else:
			push_error("[SaveManager] Failed to delete save file: %d" % error)
			return false

	return false

## 获取存档元数据
func get_save_metadata(slot_id: int) -> Dictionary:
	if save_data_cache.has(slot_id):
		return save_data_cache[slot_id]

	return {}

## 检查存档是否存在
func has_save(slot_id: int) -> bool:
	return save_data_cache.has(slot_id)

## 获取所有存档信息
func get_all_saves_info() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []

	for slot_id in range(MAX_SAVE_SLOTS):
		var info: Dictionary = {
			"slot_id": slot_id,
			"exists": has_save(slot_id),
			"metadata": get_save_metadata(slot_id)
		}
		saves.append(info)

	return saves

## 自动保存
func auto_save() -> bool:
	if current_slot >= 0:
		print("[SaveManager] Auto-saving to slot %d..." % current_slot)
		return save_game(current_slot)
	else:
		print("[SaveManager] No current slot for auto-save")
		return false

## 收集保存数据
func _collect_save_data() -> Dictionary:
	var data: Dictionary = {}

	# 玩家进度
	data["player"] = _collect_player_data()

	# 关卡进度
	data["levels"] = _collect_level_data()

	# 游戏统计
	data["statistics"] = _collect_statistics_data()

	# 游戏设置
	data["settings"] = _collect_settings_data()

	return data

## 收集玩家数据
func _collect_player_data() -> Dictionary:
	# TODO: 从实际玩家系统收集数据
	return {
		"level": 1,
		"experience": 0,
		"health": 100.0,
		"max_health": 100.0
	}

## 收集关卡数据
func _collect_level_data() -> Dictionary:
	var game_config = _get_game_config()
	if not game_config:
		return {}

	var levels_data: Dictionary = {}
	var level_count = game_config.get_level_count()

	for i in range(level_count):
		levels_data[str(i)] = {
			"unlocked": game_config.is_level_unlocked(i),
			"completed": false,  # TODO: 从实际系统获取
			"best_time": 0.0,
			"best_score": 0
		}

	return levels_data

## 收集统计数据
func _collect_statistics_data() -> Dictionary:
	var game_state_manager = _get_game_state_manager()
	if not game_state_manager:
		return {}

	return game_state_manager.get_session_stats()

## 收集设置数据
func _collect_settings_data() -> Dictionary:
	# TODO: 从实际设置系统收集
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"difficulty": "normal"
	}

## 应用保存数据
func _apply_save_data(save_data: Dictionary) -> void:
	# 应用玩家数据
	if save_data.has("player"):
		_apply_player_data(save_data["player"])

	# 应用关卡进度
	if save_data.has("levels"):
		_apply_level_data(save_data["levels"])

	# 应用统计数据
	if save_data.has("statistics"):
		_apply_statistics_data(save_data["statistics"])

	# 应用设置数据
	if save_data.has("settings"):
		_apply_settings_data(save_data["settings"])

## 应用玩家数据
func _apply_player_data(player_data: Dictionary) -> void:
	# TODO: 应用到实际玩家系统
	print("[SaveManager] Applied player data: level %d" % player_data.get("level", 1))

## 应用关卡数据
func _apply_level_data(levels_data: Dictionary) -> void:
	var game_config = _get_game_config()
	if not game_config:
		print("[SaveManager] GameConfig not found, cannot apply level data")
		return

	# 等待GameConfig初始化完成
	if not game_config.is_node_ready():
		await game_config.ready

	# 解锁关卡
	var unlocked_count = 0
	for level_id_str in levels_data:
		var level_id = int(level_id_str)
		var level_data = levels_data[level_id_str]

		if level_data.get("unlocked", false):
			game_config.unlock_level(level_id)
			unlocked_count += 1

	print("[SaveManager] Applied level data: %d levels unlocked" % unlocked_count)

## 应用统计数据
func _apply_statistics_data(stats_data: Dictionary) -> void:
	# TODO: 应用到游戏状态管理器
	print("[SaveManager] Applied statistics data")

## 应用设置数据
func _apply_settings_data(settings_data: Dictionary) -> void:
	# TODO: 应用到设置系统
	print("[SaveManager] Applied settings data")

## 加载存档元数据（不加载完整数据）
func _load_save_metadata(slot_id: int) -> Dictionary:
	var save_path = _get_save_path(slot_id)

	if not FileAccess.file_exists(save_path):
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		return {}

	var save_data = json.data
	return save_data.get("metadata", {})

## 获取保存路径
func _get_save_path(slot_id: int) -> String:
	return SAVE_DIR + _get_save_filename(slot_id)

## 获取保存文件名
func _get_save_filename(slot_id: int) -> String:
	return SAVE_FILE_PREFIX + str(slot_id) + SAVE_FILE_EXTENSION

## 获取游戏配置
func _get_game_config() -> Node:
	# 优先使用直接引用
	if game_config_override and is_instance_valid(game_config_override):
		return game_config_override

	# 尝试从场景树查找
	var root = get_tree().root
	if root:
		var config = root.find_child("GameConfig", true, false)
		if config:
			return config

	# 尝试从父节点的兄弟节点查找
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "GameConfig":
				return child

	return null

## 获取游戏状态管理器
func _get_game_state_manager() -> Node:
	if has_node("/root/GameStateManager"):
		return get_node("/root/GameStateManager")
	return null

## 获取总游戏时间
func _get_total_play_time() -> float:
	var game_state_manager = _get_game_state_manager()
	if game_state_manager:
		var stats = game_state_manager.get_session_stats()
		return stats.get("total_play_time", 0.0)
	return 0.0

## 获取关卡进度
func _get_level_progress() -> String:
	var game_config = _get_game_config()
	if not game_config:
		return "0/0"

	var level_count = game_config.get_level_count()
	var unlocked_count = game_config.get_unlocked_levels().size()

	return "%d/%d" % [unlocked_count, level_count]
