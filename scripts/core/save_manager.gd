extends Node
class_name SaveManager
## 统一存档管理器 - 管理所有系统的存档和加载

signal save_completed(slot_index)
signal load_completed(slot_index)
signal save_failed(slot_index, error)
signal load_failed(slot_index, error)

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_"
const SAVE_FILE_EXT = ".json"
const MAX_SAVE_SLOTS = 10

var registered_systems = {}  # system_name -> system_node

func _ready() -> void:
	_ensure_save_directory()
	print("[SaveManager] Initialized")

## 确保存档目录存在
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

## 注册需要存档的系统
func register_system(system_name: String, system_node: Node) -> void:
	if not system_node.has_method("get_save_data") or not system_node.has_method("load_save_data"):
		push_error("[SaveManager] System '%s' missing save methods" % system_name)
		return

	registered_systems[system_name] = system_node
	print("[SaveManager] Registered system: %s" % system_name)

## 注销系统
func unregister_system(system_name: String) -> void:
	registered_systems.erase(system_name)

## 保存游戏到指定槽位
func save_game(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot index: %d" % slot_index)
		save_failed.emit(slot_index, "Invalid slot")
		return false

	var save_data = {
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"systems": {}
	}

	# 收集所有系统的存档数据
	for system_name in registered_systems.keys():
		var system = registered_systems[system_name]
		if system and is_instance_valid(system):
			save_data["systems"][system_name] = system.get_save_data()

	# 写入文件
	var file_path = _get_save_file_path(slot_index)
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		push_error("[SaveManager] Failed to open file for writing: %s" % file_path)
		save_failed.emit(slot_index, "File write error")
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveManager] Game saved to slot %d (%d systems)" % [slot_index, registered_systems.size()])
	save_completed.emit(slot_index)

	return true

## 从指定槽位加载游戏
func load_game(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot index: %d" % slot_index)
		load_failed.emit(slot_index, "Invalid slot")
		return false

	var file_path = _get_save_file_path(slot_index)

	if not FileAccess.file_exists(file_path):
		push_error("[SaveManager] Save file not found: %s" % file_path)
		load_failed.emit(slot_index, "File not found")
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open file for reading: %s" % file_path)
		load_failed.emit(slot_index, "File read error")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("[SaveManager] JSON parse error: %s" % json.get_error_message())
		load_failed.emit(slot_index, "Parse error")
		return false

	var save_data = json.data

	if not save_data is Dictionary or not save_data.has("systems"):
		push_error("[SaveManager] Invalid save data format")
		load_failed.emit(slot_index, "Invalid format")
		return false

	# 加载所有系统的数据
	var systems_data = save_data["systems"]
	for system_name in registered_systems.keys():
		var system = registered_systems[system_name]
		if system and is_instance_valid(system) and systems_data.has(system_name):
			system.load_save_data(systems_data[system_name])

	print("[SaveManager] Game loaded from slot %d" % slot_index)
	load_completed.emit(slot_index)

	return true

## 删除存档槽位
func delete_save(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return false

	var file_path = _get_save_file_path(slot_index)

	if not FileAccess.file_exists(file_path):
		return false

	DirAccess.remove_absolute(file_path)
	print("[SaveManager] Deleted save slot %d" % slot_index)

	return true

## 检查槽位是否有存档
func has_save(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return false

	return FileAccess.file_exists(_get_save_file_path(slot_index))

## 获取存档信息
func get_save_info(slot_index: int) -> Dictionary:
	if not has_save(slot_index):
		return {}

	var file_path = _get_save_file_path(slot_index)
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		return {}

	var save_data = json.data

	if not save_data is Dictionary:
		return {}

	return {
		"slot_index": slot_index,
		"timestamp": save_data.get("timestamp", 0),
		"version": save_data.get("version", "unknown"),
		"date": _format_timestamp(save_data.get("timestamp", 0))
	}

## 获取所有存档槽位信息
func get_all_save_slots() -> Array:
	var slots = []

	for i in range(MAX_SAVE_SLOTS):
		if has_save(i):
			slots.append(get_save_info(i))
		else:
			slots.append({
				"slot_index": i,
				"empty": true
			})

	return slots

## 快速存档（槽位0）
func quick_save() -> bool:
	return save_game(0)

## 快速加载（槽位0）
func quick_load() -> bool:
	return load_game(0)

## 自动存档
func auto_save() -> bool:
	return save_game(MAX_SAVE_SLOTS - 1)

## 获取存档文件路径
func _get_save_file_path(slot_index: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot_index) + SAVE_FILE_EXT

## 格式化时间戳
func _format_timestamp(timestamp: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute
	]
