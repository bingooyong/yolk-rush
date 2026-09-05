extends Node
class_name LevelSystem
## 等级系统 - 管理经验值和升级

signal level_up(new_level: int)
signal exp_gained(amount: int, current_exp: int, required_exp: int)

const MAX_LEVEL := 50
var exp_curve: Dictionary = {}

var current_level: int = 1
var current_exp: int = 0

@onready var player_ref: Node3D = null

func _ready() -> void:
	_load_exp_curve()
	print("[LevelSystem] Initialized - Level %d" % current_level)

func _load_exp_curve() -> void:
	var file_path := "res://data/progression/level_curve.json"
	if not FileAccess.file_exists(file_path):
		push_error("[LevelSystem] level_curve.json not found!")
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			exp_curve = json.data
			print("[LevelSystem] Loaded exp curve: %d levels" % exp_curve.size())
		else:
			push_error("[LevelSystem] Failed to parse JSON: %s" % json.get_error_message())
		file.close()
	else:
		push_error("[LevelSystem] Failed to open level_curve.json")

## 设置玩家引用
func set_player(player: Node3D) -> void:
	player_ref = player
	print("[LevelSystem] Player reference set")

## 获取升级所需经验
func get_required_exp(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0

	if exp_curve.has(str(level)):
		return exp_curve[str(level)]["required_exp"]

	# 默认公式: 100 * (level ^ 1.5)
	return int(100.0 * pow(level, 1.5))

## 增加经验值
func add_exp(amount: int) -> void:
	if current_level >= MAX_LEVEL:
		print("[LevelSystem] Already at max level")
		return

	current_exp += amount
	var required := get_required_exp(current_level)

	print("[LevelSystem] +%d EXP (%d/%d)" % [amount, current_exp, required])
	exp_gained.emit(amount, current_exp, required)

	# 检查升级（支持连续升级）
	while current_exp >= get_required_exp(current_level) and current_level < MAX_LEVEL:
		_level_up()

## 升级处理
func _level_up() -> void:
	var required := get_required_exp(current_level)
	current_exp -= required
	current_level += 1

	print("[LevelSystem] ✨ LEVEL UP to %d! ✨" % current_level)

	# 发放升级奖励
	_grant_level_rewards()

	# 发射信号
	level_up.emit(current_level)

	# 播放升级特效
	_play_level_up_effects()

## 发放升级奖励
func _grant_level_rewards() -> void:
	var level_data: Dictionary = exp_curve.get(str(current_level - 1), {})
	var stat_points: int = level_data.get("stat_points", 5)
	var skill_points: int = level_data.get("skill_points", 1)

	# 属性点 +5
	# if StatsSystem:
	# 	StatsSystem.add_stat_points(stat_points)
	print("[LevelSystem] Granted %d stat points" % stat_points)

	# 技能点 +1
	# if SkillTreeSystem:
	# 	SkillTreeSystem.add_skill_points(skill_points)
	print("[LevelSystem] Granted %d skill points" % skill_points)

	# 恢复满血满蓝
	if player_ref and player_ref.has_node("HealthComponent"):
		var health = player_ref.get_node("HealthComponent")
		health.heal(health.max_health)
		print("[LevelSystem] Health restored to full")

## 播放升级特效
func _play_level_up_effects() -> void:
	# 金色闪光特效
	# if player_ref and VFXManager:
	# 	VFXManager.play_vfx("level_up", player_ref.global_position)

	# 音效
	# if AudioManager:
	# 	AudioManager.play_sfx("level_up")
	pass

	# UI 提示 (暂时禁用，因为GameManager可能没有这个方法)
	# if has_node("/root/GameManager"):
	# 	var game_manager = get_node("/root/GameManager")
	# 	if game_manager.has_method("show_notification"):
	# 		game_manager.show_notification("LEVEL UP!\nLevel %d" % current_level, Color.GOLD)

## 获取当前进度百分比
func get_exp_progress() -> float:
	if current_level >= MAX_LEVEL:
		return 1.0
	var required := get_required_exp(current_level)
	if required == 0:
		return 1.0
	return clampf(float(current_exp) / float(required), 0.0, 1.0)

## 获取等级信息（用于 UI）
func get_level_info() -> Dictionary:
	return {
		"level": current_level,
		"current_exp": current_exp,
		"required_exp": get_required_exp(current_level),
		"progress": get_exp_progress(),
		"is_max_level": current_level >= MAX_LEVEL
	}

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"level": current_level,
		"exp": current_exp
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	current_level = data.get("level", 1)
	current_exp = data.get("exp", 0)

	# 钳制到有效范围
	current_level = clampi(current_level, 1, MAX_LEVEL)
	current_exp = maxi(current_exp, 0)

	print("[LevelSystem] Loaded save - Level %d, EXP %d" % [current_level, current_exp])

	# 发射信号更新 UI
	var required := get_required_exp(current_level)
	exp_gained.emit(0, current_exp, required)

## 调试：设置等级
func _debug_set_level(level: int) -> void:
	if level < 1 or level > MAX_LEVEL:
		push_warning("[LevelSystem] Invalid debug level: %d" % level)
		return

	current_level = clampi(level, 1, MAX_LEVEL)
	current_exp = 0
	print("[LevelSystem] DEBUG: Set to level %d" % current_level)

	var required := get_required_exp(current_level)
	exp_gained.emit(0, current_exp, required)

## 调试：添加大量经验
func _debug_add_exp(amount: int) -> void:
	add_exp(amount)
