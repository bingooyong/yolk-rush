extends Node
class_name GameStateManager
## 游戏状态管理器
## 管理整个游戏的状态流转和场景切换

## 游戏状态枚举
enum GameState {
	BOOT,           ## 启动
	MAIN_MENU,      ## 主菜单
	LEVEL_SELECT,   ## 关卡选择
	LOADING,        ## 加载中
	PLAYING,        ## 游戏进行中
	PAUSED,         ## 暂停
	VICTORY,        ## 胜利
	DEFEAT,         ## 失败
	TRANSITION      ## 过渡状态
}

## 信号
signal state_changed(from_state: GameState, to_state: GameState)
signal level_started(level_id: int)
signal level_completed(level_id: int, stats: Dictionary)
signal level_failed(level_id: int)
signal game_paused()
signal game_resumed()

## 当前状态
var current_state: GameState = GameState.BOOT

## 上一个状态（用于暂停恢复）
var previous_state: GameState = GameState.BOOT

## 当前关卡ID
var current_level_id: int = -1

## 游戏统计
var session_stats: Dictionary = {
	"levels_completed": 0,
	"total_enemies_defeated": 0,
	"total_items_collected": 0,
	"total_play_time": 0.0,
	"deaths": 0
}

## 关卡统计
var level_stats: Dictionary = {
	"start_time": 0.0,
	"play_time": 0.0,
	"enemies_defeated": 0,
	"items_collected": 0,
	"damage_taken": 0,
	"skills_used": 0
}

## 场景引用
var game_manager: Node = null
var level_manager: Node = null
var ui_manager: Node = null

func _ready() -> void:
	print("[GameStateManager] Initializing...")

	# 等待其他管理器初始化
	await get_tree().process_frame

	# 查找管理器
	_find_managers()

	# 初始化完成，进入主菜单
	change_state(GameState.MAIN_MENU)

	print("[GameStateManager] Initialized")

## 查找管理器引用
func _find_managers() -> void:
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

	if has_node("/root/LevelManager"):
		level_manager = get_node("/root/LevelManager")

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state

	# 退出旧状态
	_exit_state(old_state)

	# 更新状态
	previous_state = old_state
	current_state = new_state

	# 进入新状态
	_enter_state(new_state)

	# 发送信号
	state_changed.emit(old_state, new_state)

	print("[GameStateManager] State changed: %s -> %s" % [
		_state_to_string(old_state),
		_state_to_string(new_state)
	])

## 退出状态
func _exit_state(state: GameState) -> void:
	match state:
		GameState.PLAYING:
			_exit_playing_state()
		GameState.PAUSED:
			_exit_paused_state()

## 进入状态
func _enter_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			_enter_main_menu_state()
		GameState.LEVEL_SELECT:
			_enter_level_select_state()
		GameState.LOADING:
			_enter_loading_state()
		GameState.PLAYING:
			_enter_playing_state()
		GameState.PAUSED:
			_enter_paused_state()
		GameState.VICTORY:
			_enter_victory_state()
		GameState.DEFEAT:
			_enter_defeat_state()

## 进入主菜单状态
func _enter_main_menu_state() -> void:
	if game_manager:
		game_manager.change_state(game_manager.GameState.MAIN_MENU)

## 进入关卡选择状态
func _enter_level_select_state() -> void:
	# TODO: 显示关卡选择UI
	pass

## 进入加载状态
func _enter_loading_state() -> void:
	# TODO: 显示加载界面
	pass

## 进入游戏状态
func _enter_playing_state() -> void:
	# 重置关卡统计
	level_stats = {
		"start_time": Time.get_ticks_msec() / 1000.0,
		"play_time": 0.0,
		"enemies_defeated": 0,
		"items_collected": 0,
		"damage_taken": 0,
		"skills_used": 0
	}

	if game_manager:
		game_manager.change_state(game_manager.GameState.PLAYING)

	level_started.emit(current_level_id)

## 退出游戏状态
func _exit_playing_state() -> void:
	# 更新关卡统计
	level_stats.play_time = Time.get_ticks_msec() / 1000.0 - level_stats.start_time

## 进入暂停状态
func _enter_paused_state() -> void:
	get_tree().paused = true

	if game_manager and game_manager.pause_menu:
		game_manager.pause_menu.show_menu()

	game_paused.emit()

## 退出暂停状态
func _exit_paused_state() -> void:
	get_tree().paused = false

	if game_manager and game_manager.pause_menu:
		game_manager.pause_menu.hide_menu()

	game_resumed.emit()

## 进入胜利状态
func _enter_victory_state() -> void:
	# 更新统计
	session_stats.levels_completed += 1
	session_stats.total_enemies_defeated += level_stats.enemies_defeated
	session_stats.total_items_collected += level_stats.items_collected
	session_stats.total_play_time += level_stats.play_time

	# 发送关卡完成信号
	level_completed.emit(current_level_id, level_stats)

	# TODO: 显示胜利UI

## 进入失败状态
func _enter_defeat_state() -> void:
	# 更新统计
	session_stats.deaths += 1

	# 发送关卡失败信号
	level_failed.emit(current_level_id)

	# TODO: 显示失败UI

## 开始关卡
func start_level(level_id: int) -> void:
	current_level_id = level_id
	change_state(GameState.LOADING)

	# 等待加载
	await get_tree().create_timer(0.5).timeout

	# 开始游戏
	change_state(GameState.PLAYING)

## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

## 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(previous_state)

## 关卡胜利
func level_victory() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.VICTORY)

## 关卡失败
func level_defeat() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.DEFEAT)

## 重新开始当前关卡
func restart_level() -> void:
	if current_level_id >= 0:
		start_level(current_level_id)

## 返回主菜单
func return_to_menu() -> void:
	current_level_id = -1
	change_state(GameState.MAIN_MENU)

## 下一关
func next_level() -> void:
	if current_level_id >= 0:
		start_level(current_level_id + 1)

## 记录敌人击败
func record_enemy_defeated() -> void:
	level_stats.enemies_defeated += 1

## 记录道具拾取
func record_item_collected() -> void:
	level_stats.items_collected += 1

## 记录伤害
func record_damage_taken(amount: float) -> void:
	level_stats.damage_taken += amount

## 记录技能使用
func record_skill_used() -> void:
	level_stats.skills_used += 1

## 获取当前状态字符串
func get_current_state_string() -> String:
	return _state_to_string(current_state)

## 状态转字符串
func _state_to_string(state: GameState) -> String:
	match state:
		GameState.BOOT: return "BOOT"
		GameState.MAIN_MENU: return "MAIN_MENU"
		GameState.LEVEL_SELECT: return "LEVEL_SELECT"
		GameState.LOADING: return "LOADING"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.VICTORY: return "VICTORY"
		GameState.DEFEAT: return "DEFEAT"
		GameState.TRANSITION: return "TRANSITION"
		_: return "UNKNOWN"

## 是否在游戏中
func is_playing() -> bool:
	return current_state == GameState.PLAYING

## 是否暂停
func is_paused() -> bool:
	return current_state == GameState.PAUSED

## 获取会话统计
func get_session_stats() -> Dictionary:
	return session_stats.duplicate()

## 获取关卡统计
func get_level_stats() -> Dictionary:
	return level_stats.duplicate()
