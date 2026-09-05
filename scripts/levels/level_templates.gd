extends Node
class_name LevelTemplates
## 关卡模板库
## 存储所有预定义关卡的配置

const LevelConfigScript = preload("res://scripts/levels/level_config.gd")

## 获取所有关卡模板
func get_all_levels() -> Array:
	var levels: Array = []

	levels.append(create_level_1())
	levels.append(create_level_2())
	levels.append(create_level_3())
	levels.append(create_level_4())
	levels.append(create_level_5())  # Mini Boss
	levels.append(create_level_6())
	levels.append(create_level_7())
	levels.append(create_level_8())
	levels.append(create_level_9())
	levels.append(create_level_10())  # Final Boss

	return levels

## 根据ID获取关卡
func get_level(level_id: int) -> LevelConfigScript:
	var levels = get_all_levels()
	for level in levels:
		if level.level_id == level_id:
			return level
	return null

## 关卡1 - 草原初章（教学关卡）
func create_level_1() -> LevelConfigScript:
	var config = LevelConfigScript.new()

	config.level_id = 0
	config.level_name = "草原初章"
	config.theme = "grassland"
	config.description = "欢迎来到蛋黄冒险的世界！击败所有敌人通关。"
	config.difficulty = 1
	config.time_limit = 180.0
	config.player_lives = 3

	# 目标
	config.objectives = [
		{
			"type": "defeat_all",
			"description": "击败所有敌人",
			"target": 2
		}
	]

	# 2个基础敌人
	config.enemies = [
		{"type": "basic", "position": Vector3(10, 0, 10), "level": 1},
		{"type": "basic", "position": Vector3(-10, 0, 10), "level": 1}
	]

	# 简单障碍
	config.obstacles = [
		{"type": "spike", "position": Vector3(5, 0, 5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(-5, 0, 5), "rotation": Vector3.ZERO}
	]

	# 道具
	config.items = [
		{"type": "health_potion", "position": Vector3(0, 0, 8)},
		{"type": "coin", "position": Vector3(3, 0, 3)},
		{"type": "coin", "position": Vector3(-3, 0, 3)}
	]

	config.spawn_point = Vector3(0, 0, -15)
	config.exit_point = Vector3(0, 0, 20)
	config.required_level = -1  # 默认解锁

	config.bgm = "grassland_theme"

	return config

## 关卡2 - 草原试炼
func create_level_2() -> LevelConfigScript:
	var config = LevelConfigScript.new()

	config.level_id = 1
	config.level_name = "草原试炼"
	config.theme = "grassland"
	config.description = "更多的敌人，更大的挑战！"
	config.difficulty = 2
	config.time_limit = 150.0
	config.player_lives = 3

	config.objectives = [
		{
			"type": "defeat_all",
			"description": "击败所有敌人",
			"target": 4
		},
		{
			"type": "collect",
			"description": "收集所有金币",
			"target": 5
		}
	]

	# 4个敌人
	config.enemies = [
		{"type": "basic", "position": Vector3(8, 0, 8), "level": 1},
		{"type": "basic", "position": Vector3(-8, 0, 8), "level": 1},
		{"type": "basic", "position": Vector3(8, 0, -8), "level": 2},
		{"type": "basic", "position": Vector3(-8, 0, -8), "level": 2}
	]

	config.obstacles = [
		{"type": "spike", "position": Vector3(0, 0, 5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(5, 0, 0), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(-5, 0, 0), "rotation": Vector3.ZERO}
	]

	config.items = [
		{"type": "coin", "position": Vector3(10, 0, 0)},
		{"type": "coin", "position": Vector3(-10, 0, 0)},
		{"type": "coin", "position": Vector3(0, 0, 10)},
		{"type": "coin", "position": Vector3(5, 0, 5)},
		{"type": "coin", "position": Vector3(-5, 0, 5)},
		{"type": "health_potion", "position": Vector3(0, 0, -5)}
	]

	config.spawn_point = Vector3(0, 0, -15)
	config.exit_point = Vector3(0, 0, 20)
	config.required_level = 0

	config.bgm = "grassland_theme"

	return config

## 关卡3 - 森林入口
func create_level_3() -> LevelConfigScript:
	var config = LevelConfigScript.new()

	config.level_id = 2
	config.level_name = "森林入口"
	config.theme = "forest"
	config.description = "进入神秘的森林，小心空中的敌人！"
	config.difficulty = 3
	config.time_limit = 140.0
	config.player_lives = 3

	config.objectives = [
		{
			"type": "defeat_all",
			"description": "击败所有敌人",
			"target": 5
		}
	]

	# 引入飞行敌人（暂时用basic代替）
	config.enemies = [
		{"type": "basic", "position": Vector3(0, 0, 10), "level": 2},
		{"type": "basic", "position": Vector3(10, 0, 5), "level": 2},
		{"type": "basic", "position": Vector3(-10, 0, 5), "level": 2},
		{"type": "basic", "position": Vector3(5, 0, -5), "level": 3},
		{"type": "basic", "position": Vector3(-5, 0, -5), "level": 3}
	]

	config.obstacles = [
		{"type": "spike", "position": Vector3(0, 0, 0), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(7, 0, 7), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(-7, 0, 7), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(7, 0, -7), "rotation": Vector3.ZERO}
	]

	config.items = [
		{"type": "health_potion", "position": Vector3(12, 0, 0)},
		{"type": "coin", "position": Vector3(0, 0, 12)},
		{"type": "coin", "position": Vector3(8, 0, 0)},
		{"type": "coin", "position": Vector3(-8, 0, 0)}
	]

	config.spawn_point = Vector3(0, 0, -18)
	config.exit_point = Vector3(0, 0, 22)
	config.required_level = 1

	config.bgm = "forest_theme"
	config.ambient_color = Color(0.8, 0.9, 0.8, 1.0)

	return config

## 关卡4 - 森林深处
func create_level_4() -> LevelConfigScript:
	var config = LevelConfigScript.new()

	config.level_id = 3
	config.level_name = "森林深处"
	config.theme = "forest"
	config.description = "敌人越来越多，保持警惕！"
	config.difficulty = 4
	config.time_limit = 130.0
	config.player_lives = 3

	config.objectives = [
		{
			"type": "defeat_all",
			"description": "击败所有敌人",
			"target": 7
		}
	]

	# 7个敌人，多种组合
	config.enemies = [
		{"type": "basic", "position": Vector3(0, 0, 15), "level": 3},
		{"type": "basic", "position": Vector3(10, 0, 10), "level": 3},
		{"type": "basic", "position": Vector3(-10, 0, 10), "level": 3},
		{"type": "basic", "position": Vector3(15, 0, 0), "level": 4},
		{"type": "basic", "position": Vector3(-15, 0, 0), "level": 4},
		{"type": "basic", "position": Vector3(8, 0, -8), "level": 4},
		{"type": "basic", "position": Vector3(-8, 0, -8), "level": 4}
	]

	config.obstacles = [
		{"type": "spike", "position": Vector3(0, 0, 5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(5, 0, 5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(-5, 0, 5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(10, 0, -5), "rotation": Vector3.ZERO},
		{"type": "spike", "position": Vector3(-10, 0, -5), "rotation": Vector3.ZERO}
	]

	config.items = [
		{"type": "health_potion", "position": Vector3(0, 0, -10)},
		{"type": "health_potion", "position": Vector3(12, 0, 5)},
		{"type": "coin", "position": Vector3(0, 0, 0)},
		{"type": "coin", "position": Vector3(7, 0, 0)},
		{"type": "coin", "position": Vector3(-7, 0, 0)}
	]

	config.spawn_point = Vector3(0, 0, -20)
	config.exit_point = Vector3(0, 0, 25)
	config.required_level = 2

	config.bgm = "forest_theme"
	config.ambient_color = Color(0.7, 0.85, 0.7, 1.0)

	return config

## 关卡5 - 森林守卫 (Mini Boss)
func create_level_5() -> LevelConfigScript:
	var config = LevelConfigScript.new()

	config.level_id = 4
	config.level_name = "森林守卫"
	config.theme = "forest"
	config.description = "森林的守护者挡住了你的去路！这是你的第一场Boss战！"
	config.difficulty = 5
	config.time_limit = 180.0
	config.player_lives = 3

	config.objectives = [
		{
			"type": "defeat_boss",
			"description": "击败森林守卫",
			"target": 1
		}
	]

	# Boss战 - 暂时用强化的basic敌人代替
	config.enemies = [
		{"type": "basic", "position": Vector3(0, 0, 10), "level": 10}  # Boss
	]

	config.obstacles = []  # Boss战少障碍

	config.items = [
		{"type": "health_potion", "position": Vector3(15, 0, 0)},
		{"type": "health_potion", "position": Vector3(-15, 0, 0)},
		{"type": "health_potion", "position": Vector3(0, 0, -15)}
	]

	config.spawn_point = Vector3(0, 0, -20)
	config.exit_point = Vector3(0, 0, 30)
	config.required_level = 3
	config.required_grade = "C"  # 至少C级才能挑战

	config.is_boss_level = true
	config.boss_type = "forest_guardian"

	config.bgm = "boss_theme"
	config.ambient_color = Color(0.6, 0.8, 0.6, 1.0)

	return config

## 关卡6-10后续添加...
func create_level_6() -> LevelConfigScript:
	var config = LevelConfigScript.new()
	config.level_id = 5
	config.level_name = "山洞探索"
	config.theme = "cave"
	config.description = "进入黑暗的山洞，小心看不见的危险！"
	config.difficulty = 6
	config.time_limit = 120.0
	config.required_level = 4
	# TODO: 完整配置
	return config

func create_level_7() -> LevelConfigScript:
	var config = LevelConfigScript.new()
	config.level_id = 6
	config.level_name = "山洞险境"
	config.theme = "cave"
	config.difficulty = 7
	config.required_level = 5
	# TODO: 完整配置
	return config

func create_level_8() -> LevelConfigScript:
	var config = LevelConfigScript.new()
	config.level_id = 7
	config.level_name = "火山前哨"
	config.theme = "volcano"
	config.difficulty = 8
	config.required_level = 6
	# TODO: 完整配置
	return config

func create_level_9() -> LevelConfigScript:
	var config = LevelConfigScript.new()
	config.level_id = 8
	config.level_name = "火山核心"
	config.theme = "volcano"
	config.difficulty = 9
	config.required_level = 7
	# TODO: 完整配置
	return config

func create_level_10() -> LevelConfigScript:
	var config = LevelConfigScript.new()
	config.level_id = 9
	config.level_name = "火焰领主"
	config.theme = "castle"
	config.description = "最终的挑战！击败火焰领主！"
	config.difficulty = 10
	config.required_level = 8
	config.required_grade = "B"
	config.is_boss_level = true
	config.boss_type = "flame_lord"
	# TODO: 完整配置
	return config
