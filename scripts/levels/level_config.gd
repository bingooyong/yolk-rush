extends Resource
class_name LevelConfig
## 关卡配置数据类
## 存储单个关卡的所有配置信息

## 基本信息
@export var level_id: int = -1
@export var level_name: String = ""
@export var theme: String = "grassland"  # grassland, forest, cave, volcano, castle
@export var description: String = ""
@export var difficulty: int = 1  # 1-10

## 游戏规则
@export var time_limit: float = 180.0  # 时间限制（秒）
@export var player_lives: int = 3  # 玩家生命数

## 关卡目标
var objectives: Array = []
# 目标格式: {"type": "defeat_all/collect/reach/survive", "description": "...", "target": 5}

## 关卡内容
var enemies: Array = []
# 敌人格式: {"type": "basic/flying/tank", "position": Vector3, "level": 1}

var obstacles: Array = []
# 障碍格式: {"type": "spike/wall/pit", "position": Vector3, "rotation": Vector3}

var items: Array = []
# 道具格式: {"type": "coin/health_potion/power_up", "position": Vector3}

## 位置信息
@export var spawn_point: Vector3 = Vector3.ZERO  # 玩家出生点
@export var exit_point: Vector3 = Vector3(0, 0, 20)  # 终点位置

## 解锁条件
@export var required_level: int = -1  # 需要完成的前置关卡 (-1 = 无需前置)
@export var required_grade: String = ""  # 需要的评分等级 ("S"/"A"/"B"/"C", 空 = 无要求)

## Boss关卡
@export var is_boss_level: bool = false
@export var boss_type: String = ""

## 环境设置
@export var bgm: String = ""  # 背景音乐
@export var ambient_color: Color = Color(1.0, 1.0, 1.0, 1.0)  # 环境光颜色
@export var fog_enabled: bool = false
@export var fog_density: float = 0.01

## 奖励设置
@export var base_reward: int = 100  # 基础奖励
@export var completion_bonus: int = 50  # 完成奖励
@export var time_bonus_multiplier: float = 1.0  # 时间奖励倍率

## 验证配置是否有效
func is_valid() -> bool:
	if level_id < 0:
		push_error("[LevelConfig] Invalid level_id: %d" % level_id)
		return false

	if level_name.is_empty():
		push_error("[LevelConfig] Level name is empty")
		return false

	if objectives.is_empty():
		push_error("[LevelConfig] No objectives defined")
		return false

	if difficulty < 1 or difficulty > 10:
		push_error("[LevelConfig] Invalid difficulty: %d" % difficulty)
		return false

	return true

## 转换为字典（用于保存）
func to_dict() -> Dictionary:
	return {
		"id": level_id,
		"name": level_name,
		"theme": theme,
		"description": description,
		"difficulty": difficulty,
		"time_limit": time_limit,
		"player_lives": player_lives,
		"objectives": objectives.duplicate(true),
		"enemies": enemies.duplicate(true),
		"obstacles": obstacles.duplicate(true),
		"items": items.duplicate(true),
		"spawn_point": {
			"x": spawn_point.x,
			"y": spawn_point.y,
			"z": spawn_point.z
		},
		"exit_point": {
			"x": exit_point.x,
			"y": exit_point.y,
			"z": exit_point.z
		},
		"required_level": required_level,
		"required_grade": required_grade,
		"is_boss_level": is_boss_level,
		"boss_type": boss_type,
		"bgm": bgm,
		"ambient_color": ambient_color.to_html(),
		"fog_enabled": fog_enabled,
		"fog_density": fog_density,
		"base_reward": base_reward,
		"completion_bonus": completion_bonus,
		"time_bonus_multiplier": time_bonus_multiplier
	}

## 从字典加载
func from_dict(data: Dictionary) -> void:
	level_id = data.get("id", -1)
	level_name = data.get("name", "")
	theme = data.get("theme", "grassland")
	description = data.get("description", "")
	difficulty = data.get("difficulty", 1)
	time_limit = data.get("time_limit", 180.0)
	player_lives = data.get("player_lives", 3)

	objectives = data.get("objectives", []).duplicate(true)
	enemies = data.get("enemies", []).duplicate(true)
	obstacles = data.get("obstacles", []).duplicate(true)
	items = data.get("items", []).duplicate(true)

	var spawn = data.get("spawn_point", {"x": 0, "y": 0, "z": 0})
	spawn_point = Vector3(spawn.x, spawn.y, spawn.z)

	var exit = data.get("exit_point", {"x": 0, "y": 0, "z": 20})
	exit_point = Vector3(exit.x, exit.y, exit.z)

	required_level = data.get("required_level", -1)
	required_grade = data.get("required_grade", "")

	is_boss_level = data.get("is_boss_level", false)
	boss_type = data.get("boss_type", "")

	bgm = data.get("bgm", "")
	ambient_color = Color.from_string(data.get("ambient_color", "#FFFFFF"), Color.WHITE)
	fog_enabled = data.get("fog_enabled", false)
	fog_density = data.get("fog_density", 0.01)

	base_reward = data.get("base_reward", 100)
	completion_bonus = data.get("completion_bonus", 50)
	time_bonus_multiplier = data.get("time_bonus_multiplier", 1.0)

## 获取显示信息
func get_display_info() -> String:
	var info = "【%s】\n" % level_name
	info += "难度: %d | 时间: %.0fs | 生命: %d\n" % [difficulty, time_limit, player_lives]
	info += "目标: %d个 | 敌人: %d个\n" % [objectives.size(), enemies.size()]

	if is_boss_level:
		info += "★ Boss关卡 ★\n"

	if not description.is_empty():
		info += description + "\n"

	return info
