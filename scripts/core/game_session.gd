extends Node
class_name GameSession
## 游戏会话 - 管理单次游戏过程

signal game_completed()
signal game_failed(reason: String)
signal score_changed(new_score: int)
signal checkpoint_reached(checkpoint_id: String)

## 会话数据
var level_id: String = ""
var level_data: Dictionary = {}

## 玩家引用
var player: Node = null

## 游戏状态
var is_active: bool = false
var is_completed: bool = false
var fail_reason: String = ""

## 统计数据
var session_stats: Dictionary = {
	"score": 0,
	"obstacles_hit": 0,
	"powerups_collected": 0,
	"deaths": 0,
	"checkpoints_reached": 0,
	"distance_traveled": 0.0,
	"max_combo": 0,
	"current_combo": 0
}

## 目标
var target_score: int = 0
var time_limit: float = 0.0
var elapsed_time: float = 0.0

## 检查点
var checkpoints: Array[String] = []
var reached_checkpoints: Array[String] = []

## 管理器引用
var obstacle_manager: Node = null
var powerup_manager: Node = null

func _ready() -> void:
	# 从关卡数据读取目标
	target_score = level_data.get("target_score", 1000)
	time_limit = level_data.get("time_limit", 0.0)  # 0 = 无限时

	print("[GameSession] Created for level: %s" % level_id)

func _process(delta: float) -> void:
	if not is_active:
		return

	# 更新时间
	elapsed_time += delta

	# 检查时间限制
	if time_limit > 0 and elapsed_time >= time_limit:
		fail_game("Time's up!")
		return

	# 检查胜利条件
	_check_victory_conditions()

## 开始游戏
func start_game() -> void:
	is_active = true
	elapsed_time = 0.0

	# 查找玩家
	player = _find_player()

	if player:
		# 连接玩家信号
		_connect_player_signals()
		print("[GameSession] Game started with player: %s" % player.name)
	else:
		push_warning("[GameSession] No player found!")

	# 查找管理器
	_find_managers()

## 结束游戏
func end_game() -> void:
	is_active = false
	is_completed = true

	# 断开信号
	if player:
		_disconnect_player_signals()

## 完成游戏
func complete_game() -> void:
	if is_completed:
		return

	end_game()
	game_completed.emit()

	print("[GameSession] Game completed!")
	print("  Score: %d / %d" % [session_stats.score, target_score])
	print("  Time: %.1fs" % elapsed_time)

## 失败游戏
func fail_game(reason: String) -> void:
	if is_completed:
		return

	fail_reason = reason
	end_game()

	session_stats.deaths += 1
	game_failed.emit(reason)

	print("[GameSession] Game failed: %s" % reason)

## 查找玩家
func _find_player() -> Node:
	# 在场景树中查找玩家
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		return players[0]

	return null

## 查找管理器
func _find_managers() -> void:
	# 查找障碍管理器
	var obstacles = get_tree().get_nodes_in_group("obstacle_manager")
	if obstacles.size() > 0:
		obstacle_manager = obstacles[0]

	# 查找道具管理器
	var powerups = get_tree().get_nodes_in_group("powerup_manager")
	if powerups.size() > 0:
		powerup_manager = powerups[0]

## 连接玩家信号
func _connect_player_signals() -> void:
	if not player:
		return

	# 连接死亡信号
	if player.has_signal("died"):
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)

	# 连接受伤信号
	if player.has_signal("health_changed"):
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)

## 断开玩家信号
func _disconnect_player_signals() -> void:
	if not player:
		return

	if player.has_signal("died"):
		if player.died.is_connected(_on_player_died):
			player.died.disconnect(_on_player_died)

	if player.has_signal("health_changed"):
		if player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.disconnect(_on_player_health_changed)

## 检查胜利条件
func _check_victory_conditions() -> void:
	# 达到目标分数
	if session_stats.score >= target_score:
		complete_game()
		return

	# 到达终点检查点
	if not checkpoints.is_empty():
		var final_checkpoint = checkpoints[-1]
		if final_checkpoint in reached_checkpoints:
			complete_game()
			return

## === 统计更新 ===

## 增加分数
func add_score(amount: int) -> void:
	session_stats.score += amount
	score_changed.emit(session_stats.score)

	print("[GameSession] Score: %d (+%d)" % [session_stats.score, amount])

## 记录障碍碰撞
func record_obstacle_hit() -> void:
	session_stats.obstacles_hit += 1
	session_stats.current_combo = 0

## 记录道具收集
func record_powerup_collected() -> void:
	session_stats.powerups_collected += 1
	add_score(10)  # 道具基础分数

## 到达检查点
func reach_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id in reached_checkpoints:
		return

	reached_checkpoints.append(checkpoint_id)
	session_stats.checkpoints_reached += 1

	checkpoint_reached.emit(checkpoint_id)

	print("[GameSession] Checkpoint reached: %s (%d/%d)" %
		[checkpoint_id, reached_checkpoints.size(), checkpoints.size()])

	# 检查点奖励分数
	add_score(50)

## 更新连击
func update_combo(combo: int) -> void:
	session_stats.current_combo = combo

	if combo > session_stats.max_combo:
		session_stats.max_combo = combo

## 更新移动距离
func update_distance(distance: float) -> void:
	session_stats.distance_traveled = distance

## === 信号回调 ===

func _on_player_died() -> void:
	fail_game("Player died")

func _on_player_health_changed(old_health: float, new_health: float) -> void:
	# 血量降到0失败
	if new_health <= 0:
		fail_game("Health depleted")

## === 查询接口 ===

## 获取会话统计
func get_session_stats() -> Dictionary:
	return session_stats.duplicate()

## 获取剩余时间
func get_remaining_time() -> float:
	if time_limit <= 0:
		return -1.0  # 无限时

	return max(0.0, time_limit - elapsed_time)

## 获取进度百分比
func get_progress() -> float:
	if target_score <= 0:
		return 0.0

	return min(1.0, float(session_stats.score) / float(target_score))

## 是否有时间限制
func has_time_limit() -> bool:
	return time_limit > 0

## 获取评级
func get_rating() -> String:
	var progress = get_progress()

	if progress >= 1.5:
		return "S"
	elif progress >= 1.2:
		return "A"
	elif progress >= 1.0:
		return "B"
	elif progress >= 0.8:
		return "C"
	else:
		return "D"

## 获取星级（1-3）
func get_stars() -> int:
	var progress = get_progress()

	if progress >= 1.5:
		return 3
	elif progress >= 1.2:
		return 2
	elif progress >= 1.0:
		return 1
	else:
		return 0

## 获取完成时间评级
func get_time_rating() -> String:
	if not has_time_limit():
		return "N/A"

	var time_ratio = elapsed_time / time_limit

	if time_ratio <= 0.5:
		return "Fast"
	elif time_ratio <= 0.75:
		return "Good"
	else:
		return "Slow"
