extends Node
class_name SaveSystem
## 存档系统 - 管理游戏进度和数据持久化

signal save_completed()
signal load_completed()
signal save_failed(error: String)

const SAVE_FILE_PATH = "user://yolk_rush_save.json"
const SAVE_VERSION = 1

## 游戏数据
var game_data: Dictionary = {
	"version": SAVE_VERSION,
	"player_profile": {
		"name": "Player",
		"total_play_time": 0.0,
		"games_played": 0,
		"games_won": 0,
		"created_at": 0
	},
	"levels": {},  # level_id -> level_progress
	"unlocked_levels": ["level_1"],  # 默认解锁第一关
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"difficulty": 1
	},
	"statistics": {
		"total_score": 0,
		"total_obstacles_hit": 0,
		"total_powerups_collected": 0,
		"total_distance": 0.0,
		"best_combo": 0
	}
}

## 是否已加载
var is_loaded: bool = false

func _ready() -> void:
	print("[SaveSystem] Initialized")

## 保存游戏
func save_game() -> bool:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)

	if not file:
		var error = FileAccess.get_open_error()
		push_error("[SaveSystem] Failed to open save file: %s" % error)
		save_failed.emit("Failed to open save file")
		return false

	# 更新时间戳
	game_data.player_profile.last_save = Time.get_unix_time_from_system()

	# 转换为 JSON
	var json_string = JSON.stringify(game_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveSystem] Game saved to: %s" % SAVE_FILE_PATH)
	save_completed.emit()
	return true

## 加载游戏
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveSystem] No save file found, using default data")
		_initialize_default_data()
		is_loaded = true
		load_completed.emit()
		return true

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)

	if not file:
		push_error("[SaveSystem] Failed to open save file for reading")
		_initialize_default_data()
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[SaveSystem] Failed to parse save file: %s" % json.get_error_message())
		_initialize_default_data()
		return false

	var loaded_data = json.data

	# 版本检查
	if loaded_data.get("version", 0) != SAVE_VERSION:
		print("[SaveSystem] Save version mismatch, migrating...")
		loaded_data = _migrate_save_data(loaded_data)

	game_data = loaded_data
	is_loaded = true

	print("[SaveSystem] Game loaded from: %s" % SAVE_FILE_PATH)
	load_completed.emit()
	return true

## 初始化默认数据
func _initialize_default_data() -> void:
	game_data.player_profile.created_at = Time.get_unix_time_from_system()
	is_loaded = true
	print("[SaveSystem] Initialized with default data")

## 迁移存档数据
func _migrate_save_data(old_data: Dictionary) -> Dictionary:
	# 合并旧数据到新结构
	var migrated = game_data.duplicate(true)

	# 保留关卡进度
	if old_data.has("levels"):
		migrated.levels = old_data.levels

	# 保留解锁状态
	if old_data.has("unlocked_levels"):
		migrated.unlocked_levels = old_data.unlocked_levels

	# 保留设置
	if old_data.has("settings"):
		migrated.settings.merge(old_data.settings)

	print("[SaveSystem] Save data migrated to version %d" % SAVE_VERSION)
	return migrated

## === 关卡进度 ===

## 保存关卡结果
func save_level_result(level_id: String, results: Dictionary) -> void:
	if not game_data.levels.has(level_id):
		game_data.levels[level_id] = {
			"best_score": 0,
			"best_time": 0.0,
			"completion_count": 0,
			"best_stars": 0,
			"first_completed_at": 0
		}

	var level_data = game_data.levels[level_id]

	# 更新统计
	level_data.completion_count += 1

	var score = results.get("score", 0)
	var play_time = results.get("play_time", 0.0)
	var stars = results.get("stars", 0)
	var is_victory = results.get("is_victory", false)

	# 更新最佳成绩
	if score > level_data.best_score:
		level_data.best_score = score

	# 更新最佳时间
	if is_victory:
		if level_data.best_time == 0 or play_time < level_data.best_time:
			level_data.best_time = play_time

		# 更新最佳星级
		if stars > level_data.best_stars:
			level_data.best_stars = stars

		# 首次完成
		if level_data.first_completed_at == 0:
			level_data.first_completed_at = Time.get_unix_time_from_system()

	# 更新全局统计
	game_data.statistics.total_score += score
	game_data.statistics.total_obstacles_hit += results.get("obstacles_hit", 0)
	game_data.statistics.total_powerups_collected += results.get("powerups_collected", 0)
	game_data.statistics.total_distance += results.get("distance_traveled", 0.0)

	var max_combo = results.get("max_combo", 0)
	if max_combo > game_data.statistics.best_combo:
		game_data.statistics.best_combo = max_combo

	# 更新玩家资料
	game_data.player_profile.games_played += 1
	if is_victory:
		game_data.player_profile.games_won += 1

	# 解锁下一关
	if is_victory:
		_unlock_next_level(level_id)

	# 自动保存
	save_game()

	print("[SaveSystem] Level result saved: %s" % level_id)

## 解锁下一关
func _unlock_next_level(current_level_id: String) -> void:
	# 简单的线性解锁逻辑
	if current_level_id.begins_with("level_"):
		var num_str = current_level_id.substr(6)
		var num = num_str.to_int()
		var next_level_id = "level_%d" % (num + 1)

		if next_level_id not in game_data.unlocked_levels:
			game_data.unlocked_levels.append(next_level_id)
			print("[SaveSystem] Unlocked level: %s" % next_level_id)

## 获取关卡进度
func get_level_progress(level_id: String) -> Dictionary:
	if game_data.levels.has(level_id):
		return game_data.levels[level_id].duplicate()

	return {
		"best_score": 0,
		"best_time": 0.0,
		"completion_count": 0,
		"best_stars": 0,
		"first_completed_at": 0
	}

## 关卡是否解锁
func is_level_unlocked(level_id: String) -> bool:
	return level_id in game_data.unlocked_levels

## 关卡是否完成过
func is_level_completed(level_id: String) -> bool:
	var progress = get_level_progress(level_id)
	return progress.first_completed_at > 0

## === 设置 ===

## 保存设置
func save_setting(key: String, value: Variant) -> void:
	game_data.settings[key] = value
	save_game()

## 获取设置
func get_setting(key: String, default_value: Variant = null) -> Variant:
	return game_data.settings.get(key, default_value)

## === 玩家资料 ===

## 更新玩家资料
func update_player_profile(key: String, value: Variant) -> void:
	game_data.player_profile[key] = value

## 获取玩家资料
func get_player_profile() -> Dictionary:
	return game_data.player_profile.duplicate()

## 增加游戏时长
func add_play_time(seconds: float) -> void:
	game_data.player_profile.total_play_time += seconds

## === 统计 ===

## 获取全局统计
func get_statistics() -> Dictionary:
	return game_data.statistics.duplicate()

## 获取所有解锁关卡
func get_unlocked_levels() -> Array:
	return game_data.unlocked_levels.duplicate()

## 获取完成的关卡数量
func get_completed_level_count() -> int:
	var count = 0
	for level_id in game_data.levels:
		if is_level_completed(level_id):
			count += 1
	return count

## 获取胜率
func get_win_rate() -> float:
	var games_played = game_data.player_profile.games_played
	if games_played == 0:
		return 0.0

	return float(game_data.player_profile.games_won) / float(games_played)

## === 调试 ===

## 重置存档
func reset_save() -> void:
	_initialize_default_data()
	save_game()
	print("[SaveSystem] Save data reset")

## 解锁所有关卡（调试用）
func unlock_all_levels() -> void:
	for i in range(1, 11):  # 解锁 1-10 关
		var level_id = "level_%d" % i
		if level_id not in game_data.unlocked_levels:
			game_data.unlocked_levels.append(level_id)

	save_game()
	print("[SaveSystem] All levels unlocked")

## 打印存档信息
func print_save_info() -> void:
	print("\n[SaveSystem] Save Information:")
	print("  Player: %s" % game_data.player_profile.name)
	print("  Games Played: %d" % game_data.player_profile.games_played)
	print("  Games Won: %d" % game_data.player_profile.games_won)
	print("  Win Rate: %.1f%%" % (get_win_rate() * 100))
	print("  Play Time: %.1f hours" % (game_data.player_profile.total_play_time / 3600))
	print("  Unlocked Levels: %d" % game_data.unlocked_levels.size())
	print("  Completed Levels: %d" % get_completed_level_count())
	print("  Total Score: %d" % game_data.statistics.total_score)
	print("  Best Combo: %d" % game_data.statistics.best_combo)
