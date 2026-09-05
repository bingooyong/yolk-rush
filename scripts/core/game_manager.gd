extends Node
class_name GameManager
## 游戏管理器 - 协调UI、关卡、状态管理

# 预加载所有依赖类
const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const GameHUDScript = preload("res://scenes/ui/game_hud.gd")
const PauseMenuScript = preload("res://scenes/ui/pause_menu.gd")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const LevelSelectMenuScript = preload("res://scenes/ui/level_select_menu.gd")
const GameOverUIScript = preload("res://scenes/ui/game_over_ui.gd")
const LevelManagerScript = preload("res://scripts/map/level_manager.gd")

enum GameState {
	MAIN_MENU,
	LEVEL_SELECT,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

signal state_changed(old_state: GameState, new_state: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over()

# UI 组件
var main_menu
var game_hud
var pause_menu
var settings_menu
var level_select_menu
var game_over_ui

# 系统组件
var level_manager

# 状态
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# 玩家引用
var player: Node3D = null

func _ready() -> void:
	_setup_ui()
	_setup_systems()
	print("[GameManager] Initialized")

	# 默认显示主菜单
	change_state(GameState.MAIN_MENU)

func _setup_ui() -> void:
	# 创建主菜单
	main_menu = MainMenuScript.new()
	main_menu.name = "MainMenu"
	main_menu.start_game_pressed.connect(_on_start_game)
	main_menu.settings_pressed.connect(_on_show_settings)
	main_menu.quit_pressed.connect(_on_quit_game)
	add_child(main_menu)

	# 创建关卡选择菜单
	level_select_menu = LevelSelectMenuScript.new()
	level_select_menu.name = "LevelSelectMenu"
	level_select_menu.level_selected.connect(_on_level_selected)
	level_select_menu.back_pressed.connect(_on_level_select_back)
	level_select_menu.hide_menu()
	add_child(level_select_menu)

	# 创建游戏 HUD
	game_hud = GameHUDScript.new()
	game_hud.name = "GameHUD"
	game_hud.skill_activated.connect(_on_skill_activated)
	game_hud.pause_requested.connect(_on_pause_game)
	game_hud.hide_hud()
	add_child(game_hud)

	# 创建暂停菜单
	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.resume_pressed.connect(_on_resume_game)
	pause_menu.settings_pressed.connect(_on_show_settings)
	pause_menu.main_menu_pressed.connect(_on_return_to_main_menu)
	add_child(pause_menu)

	# 创建游戏结算UI
	game_over_ui = GameOverUIScript.new()
	game_over_ui.name = "GameOverUI"
	game_over_ui.retry_pressed.connect(_on_retry_game)
	game_over_ui.next_level_pressed.connect(_on_next_level)
	game_over_ui.main_menu_pressed.connect(_on_return_to_main_menu)
	game_over_ui.hide_ui()
	add_child(game_over_ui)

	# 创建设置菜单
	settings_menu = SettingsMenuScript.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.settings_changed.connect(_on_settings_changed)
	settings_menu.back_pressed.connect(_on_settings_back)
	settings_menu.hide_menu()
	add_child(settings_menu)

func _setup_systems() -> void:
	# 创建关卡管理器
	level_manager = LevelManagerScript.new()
	level_manager.name = "LevelManager"
	level_manager.level_loaded.connect(_on_level_loaded)
	level_manager.level_unloaded.connect(_on_level_unloaded)
	add_child(level_manager)

func _input(event: InputEvent) -> void:
	# ESC 键处理
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.PLAYING:
				_on_pause_game()
			GameState.PAUSED:
				if settings_menu.visible:
					_on_settings_back()
				else:
					_on_resume_game()

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	var old_state = current_state
	previous_state = old_state
	current_state = new_state

	print("[GameManager] State: %s -> %s" % [
		GameState.keys()[old_state],
		GameState.keys()[new_state]
	])

	# 执行状态转换
	_exit_state(old_state)
	_enter_state(new_state)

	state_changed.emit(old_state, new_state)

func _exit_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			main_menu.hide_menu()

		GameState.LEVEL_SELECT:
			level_select_menu.hide_menu()

		GameState.PLAYING:
			game_hud.hide_hud()

		GameState.PAUSED:
			pause_menu.hide_menu()

		GameState.GAME_OVER, GameState.VICTORY:
			game_over_ui.hide_ui()

func _enter_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			main_menu.show_menu()
			game_hud.hide_hud()
			pause_menu.hide_menu()
			level_select_menu.hide_menu()
			game_over_ui.hide_ui()

		GameState.LEVEL_SELECT:
			main_menu.hide_menu()
			level_select_menu.show_menu()
			game_hud.hide_hud()

		GameState.LOADING:
			# 显示加载界面（如果有）
			pass

		GameState.PLAYING:
			main_menu.hide_menu()
			level_select_menu.hide_menu()
			game_hud.show_hud()
			pause_menu.hide_menu()
			game_over_ui.hide_ui()

		GameState.PAUSED:
			pause_menu.show_menu()

		GameState.GAME_OVER:
			game_hud.hide_hud()
			_show_game_over(false)

		GameState.VICTORY:
			game_hud.hide_hud()
			_show_game_over(true)

## === 信号处理 ===

func _on_start_game() -> void:
	print("[GameManager] Opening level select...")
	change_state(GameState.LEVEL_SELECT)

func _on_level_selected(level_id: int) -> void:
	print("[GameManager] Starting level %d..." % level_id)
	change_state(GameState.LOADING)

	# 生成随机地图
	var map_config = {
		"seed": randi(),
		"map_size": Vector2i(3, 3),
		"chunk_size": 16,
		"tile_size": 2.0,
		"enemy_spawn_count": 5,
		"objective_count": 2
	}

	# 加载关卡
	var success = level_manager.load_level(map_config)

	if success:
		game_started.emit()
		change_state(GameState.PLAYING)

		# 更新 HUD
		game_hud.update_player_health(100, 100)
		game_hud.update_player_energy(100, 100)
		game_hud.update_player_level(1, 0, 100)
		game_hud.add_objective("探索地图")
		game_hud.add_objective("击败所有敌人")
	else:
		push_error("[GameManager] Failed to load level")
		change_state(GameState.LEVEL_SELECT)

func _on_level_select_back() -> void:
	change_state(GameState.MAIN_MENU)

func _on_pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		game_paused.emit()

func _on_resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		game_resumed.emit()

func _on_show_settings() -> void:
	settings_menu.show_menu()

func _on_settings_back() -> void:
	settings_menu.hide_menu()

func _on_settings_changed(settings: Dictionary) -> void:
	print("[GameManager] Settings changed: %s" % settings)

func _on_return_to_main_menu() -> void:
	print("[GameManager] Returning to main menu...")

	# 卸载关卡
	if level_manager.is_level_loaded():
		level_manager.unload_level()

	change_state(GameState.MAIN_MENU)

func _on_quit_game() -> void:
	print("[GameManager] Quitting game...")
	get_tree().quit()

func _on_skill_activated(slot: int) -> void:
	print("[GameManager] Skill %d activated" % slot)
	# TODO: 通知玩家/技能系统

	# 模拟冷却
	game_hud.set_skill_cooldown(slot, 5.0)

func _on_retry_game() -> void:
	print("[GameManager] Retrying level...")
	change_state(GameState.LOADING)
	# 重新加载当前关卡
	await get_tree().create_timer(0.5).timeout
	change_state(GameState.PLAYING)

func _on_next_level() -> void:
	print("[GameManager] Loading next level...")
	change_state(GameState.LOADING)
	# 加载下一关
	await get_tree().create_timer(0.5).timeout
	change_state(GameState.PLAYING)

## 显示游戏结算界面
func _show_game_over(victory: bool) -> void:
	# 获取关卡统计数据
	var game_state_manager = _find_game_state_manager()
	var stats = {}

	if game_state_manager:
		stats = game_state_manager.get_level_stats()
	else:
		# 默认统计
		stats = {
			"play_time": 120.0,
			"enemies_defeated": 5,
			"items_collected": 3,
			"damage_taken": 25,
			"skills_used": 8,
			"completed": victory
		}

	var result_type = GameOverUIScript.ResultType.VICTORY if victory else GameOverUIScript.ResultType.DEFEAT
	game_over_ui.show_result(result_type, stats)

## 查找GameStateManager
func _find_game_state_manager() -> Node:
	if has_node("/root/GameStateManager"):
		return get_node("/root/GameStateManager")
	return null

func _on_level_loaded(map_data) -> void:
	print("[GameManager] Level loaded successfully")
	print("[GameManager] Chunks: %d" % map_data.chunks.size())
	print("[GameManager] Waypoints: %d" % map_data.waypoints.size())

	# 获取玩家生成点
	var spawn_pos = level_manager.get_player_spawn_position()
	print("[GameManager] Player spawn: %s" % spawn_pos)

	# TODO: 生成玩家
	# TODO: 生成敌人

func _on_level_unloaded() -> void:
	print("[GameManager] Level unloaded")

## === 玩家相关 ===

func set_player(p: Node3D) -> void:
	player = p
	print("[GameManager] Player set: %s" % player.name)

	# 连接玩家信号（如果有）
	# player.health_changed.connect(_on_player_health_changed)
	# player.energy_changed.connect(_on_player_energy_changed)

func _on_player_health_changed(current: float, maximum: float) -> void:
	game_hud.update_player_health(current, maximum)

func _on_player_energy_changed(current: float, maximum: float) -> void:
	game_hud.update_player_energy(current, maximum)

func _on_player_died() -> void:
	print("[GameManager] Player died")
	change_state(GameState.GAME_OVER)
	game_over.emit()

## === 实用方法 ===

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func get_current_map():
	return level_manager.get_current_map()
