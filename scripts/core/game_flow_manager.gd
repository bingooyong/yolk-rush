extends Node
class_name GameFlowManager
## 游戏流程管理器 - 控制整个游戏的状态流转

signal state_changed(old_state: GameState, new_state: GameState)
signal level_started(level_data: Dictionary)
signal level_completed(results: Dictionary)
signal level_failed(reason: String)
signal game_paused()
signal game_resumed()

enum GameState {
	BOOT,              # 启动
	MAIN_MENU,         # 主菜单
	LEVEL_SELECT,      # 关卡选择
	LOADING,           # 加载中
	COUNTDOWN,         # 倒计时
	PLAYING,           # 游戏中
	PAUSED,            # 暂停
	LEVEL_COMPLETE,    # 关卡完成
	LEVEL_FAILED,      # 关卡失败
	RESULTS,           # 结算
	QUIT               # 退出
}

## 当前状态
var current_state: GameState = GameState.BOOT
var previous_state: GameState = GameState.BOOT

## 当前会话
var current_session: GameSession = null
var current_level_id: String = ""
var current_level_data: Dictionary = {}

## 系统引用
var save_system: SaveSystem = null
var scene_manager: Node = null

## 统计
var total_play_time: float = 0.0
var session_start_time: float = 0.0

func _ready() -> void:
	# 初始化存档系统
	save_system = SaveSystem.new()
	add_child(save_system)
	save_system.load_game()

	print("[GameFlowManager] Initialized")
	change_state(GameState.MAIN_MENU)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		total_play_time += delta

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	var old_state = current_state

	# 退出旧状态
	_exit_state(old_state)

	# 更新状态
	previous_state = old_state
	current_state = new_state

	# 进入新状态
	_enter_state(new_state)

	# 触发信号
	state_changed.emit(old_state, new_state)

	print("[GameFlowManager] State: %s -> %s" %
		[GameState.keys()[old_state], GameState.keys()[new_state]])

## 进入状态
func _enter_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			_enter_main_menu()
		GameState.LEVEL_SELECT:
			_enter_level_select()
		GameState.LOADING:
			_enter_loading()
		GameState.COUNTDOWN:
			_enter_countdown()
		GameState.PLAYING:
			_enter_playing()
		GameState.PAUSED:
			_enter_paused()
		GameState.LEVEL_COMPLETE:
			_enter_level_complete()
		GameState.LEVEL_FAILED:
			_enter_level_failed()
		GameState.RESULTS:
			_enter_results()

## 退出状态
func _exit_state(state: GameState) -> void:
	match state:
		GameState.PLAYING:
			_exit_playing()
		GameState.PAUSED:
			_exit_paused()

## === 状态处理 ===

func _enter_main_menu() -> void:
	# 加载主菜单场景
	_load_scene("res://scenes/ui/main_menu.tscn")

func _enter_level_select() -> void:
	# 加载关卡选择场景
	_load_scene("res://scenes/ui/level_select.tscn")

func _enter_loading() -> void:
	# 显示加载界面
	print("[GameFlowManager] Loading level: %s" % current_level_id)

func _enter_countdown() -> void:
	# 开始倒计时
	session_start_time = Time.get_ticks_msec() / 1000.0
	_start_countdown()

func _enter_playing() -> void:
	# 游戏开始
	if current_session:
		current_session.start_game()

	level_started.emit(current_level_data)
	print("[GameFlowManager] Level started")

func _exit_playing() -> void:
	pass

func _enter_paused() -> void:
	get_tree().paused = true
	game_paused.emit()
	print("[GameFlowManager] Game paused")

func _exit_paused() -> void:
	get_tree().paused = false
	game_resumed.emit()
	print("[GameFlowManager] Game resumed")

func _enter_level_complete() -> void:
	# 关卡完成处理
	var results = _collect_results(true)

	# 保存成绩
	save_system.save_level_result(current_level_id, results)

	level_completed.emit(results)

	# 延迟显示结算
	await get_tree().create_timer(1.0).timeout
	change_state(GameState.RESULTS)

func _enter_level_failed() -> void:
	# 关卡失败处理
	var results = _collect_results(false)

	level_failed.emit(results.get("fail_reason", "Unknown"))

	# 延迟显示结算
	await get_tree().create_timer(1.0).timeout
	change_state(GameState.RESULTS)

func _enter_results() -> void:
	# 显示结算界面
	_load_scene("res://scenes/ui/results_screen.tscn")

## === 游戏流程控制 ===

## 开始关卡
func start_level(level_id: String) -> void:
	current_level_id = level_id
	current_level_data = _load_level_data(level_id)

	if current_level_data.is_empty():
		push_error("[GameFlowManager] Failed to load level: %s" % level_id)
		return

	change_state(GameState.LOADING)

	# 加载关卡场景
	var level_scene_path = current_level_data.get("scene_path", "")
	if level_scene_path.is_empty():
		push_error("[GameFlowManager] No scene path for level: %s" % level_id)
		return

	_load_scene(level_scene_path)

	# 创建游戏会话
	current_session = GameSession.new()
	current_session.level_id = level_id
	current_session.level_data = current_level_data
	add_child(current_session)

	# 连接信号
	current_session.game_completed.connect(_on_game_completed)
	current_session.game_failed.connect(_on_game_failed)

	# 进入倒计时
	change_state(GameState.COUNTDOWN)

## 重新开始当前关卡
func restart_level() -> void:
	if current_level_id.is_empty():
		return

	# 清理当前会话
	if current_session:
		current_session.queue_free()
		current_session = null

	# 重新开始
	start_level(current_level_id)

## 下一关
func next_level() -> void:
	var next_id = _get_next_level_id(current_level_id)

	if next_id.is_empty():
		# 没有下一关，返回关卡选择
		return_to_level_select()
	else:
		start_level(next_id)

## 返回主菜单
func return_to_main_menu() -> void:
	# 清理会话
	if current_session:
		current_session.queue_free()
		current_session = null

	current_level_id = ""
	current_level_data = {}

	change_state(GameState.MAIN_MENU)

## 返回关卡选择
func return_to_level_select() -> void:
	# 清理会话
	if current_session:
		current_session.queue_free()
		current_session = null

	current_level_id = ""
	current_level_data = {}

	change_state(GameState.LEVEL_SELECT)

## 暂停/恢复
func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
	elif current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

## 退出游戏
func quit_game() -> void:
	# 保存数据
	save_system.save_game()

	change_state(GameState.QUIT)
	get_tree().quit()

## === 辅助方法 ===

## 加载场景
func _load_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[GameFlowManager] Scene not found: %s" % path)
		return

	get_tree().change_scene_to_file(path)

## 加载关卡数据
func _load_level_data(level_id: String) -> Dictionary:
	# 从关卡配置加载
	var config_path = "res://data/levels/%s.json" % level_id

	if not FileAccess.file_exists(config_path):
		# 使用默认数据
		return {
			"id": level_id,
			"name": "Test Level",
			"scene_path": "res://scenes/levels/test_level.tscn",
			"difficulty": 1,
			"time_limit": 60.0,
			"target_score": 1000
		}

	var file = FileAccess.open(config_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		return json.data
	else:
		push_error("[GameFlowManager] Failed to parse level data: %s" % config_path)
		return {}

## 获取下一关ID
func _get_next_level_id(current_id: String) -> String:
	# 简单的数字递增逻辑
	if current_id.begins_with("level_"):
		var num_str = current_id.substr(6)
		var num = num_str.to_int()
		return "level_%d" % (num + 1)

	return ""

## 开始倒计时
func _start_countdown() -> void:
	# 倒计时 3, 2, 1, GO!
	for i in range(3, 0, -1):
		print("[Countdown] %d" % i)
		await get_tree().create_timer(1.0).timeout

	print("[Countdown] GO!")
	change_state(GameState.PLAYING)

## 收集结果
func _collect_results(is_victory: bool) -> Dictionary:
	var play_time = (Time.get_ticks_msec() / 1000.0) - session_start_time

	var results = {
		"level_id": current_level_id,
		"is_victory": is_victory,
		"play_time": play_time,
		"timestamp": Time.get_unix_time_from_system()
	}

	if current_session:
		results.merge(current_session.get_session_stats())

	return results

## === 信号回调 ===

func _on_game_completed() -> void:
	change_state(GameState.LEVEL_COMPLETE)

func _on_game_failed(reason: String) -> void:
	if current_session:
		current_session.fail_reason = reason
	change_state(GameState.LEVEL_FAILED)

## === 查询接口 ===

## 获取当前状态名
func get_state_name() -> String:
	return GameState.keys()[current_state]

## 是否在游戏中
func is_playing() -> bool:
	return current_state == GameState.PLAYING

## 是否暂停
func is_paused() -> bool:
	return current_state == GameState.PAUSED

## 获取游戏时长
func get_play_time() -> float:
	return total_play_time

## 获取当前关卡信息
func get_current_level_info() -> Dictionary:
	return current_level_data.duplicate()
