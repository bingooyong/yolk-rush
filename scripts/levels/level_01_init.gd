extends Node3D
## 关卡1 - 草原初章
## 启动脚本，负责初始化关卡

@onready var level_generator: Node = $LevelGenerator
@onready var level_flow: Node = $LevelFlowController
@onready var spawn_point: Marker3D = $SpawnPoint

## 玩家场景
const PLAYER_SCENE = preload("res://scenes/player/player.tscn")

var player: Node3D = null
var level_config = null
var enemies_defeated: int = 0
var total_enemies: int = 0

func _ready() -> void:
	print("[Level01] Starting grassland level...")

	# 加载关卡配置
	var templates = preload("res://scripts/levels/level_templates.gd").new()
	level_config = templates.get_level(0)  # 关卡1

	if not level_config:
		push_error("[Level01] Failed to load level config")
		return

	print("[Level01] Loaded config: %s" % level_config.level_name)

	# 生成玩家
	await _spawn_player()

	# 设置关卡生成器
	level_generator.set_player(player)

	# 生成关卡内容
	await level_generator.generate_level(level_config, self)

	# 获取生成的敌人数量
	total_enemies = level_generator.get_enemies().size()
	print("[Level01] Total enemies: %d" % total_enemies)

	# 连接敌人死亡信号
	_connect_enemy_signals()

	# 连接玩家信号
	_connect_player_signals()

	# 初始化关卡流程控制器
	await _init_level_flow()

	print("[Level01] Level initialization complete!")

func _spawn_player() -> void:
	## 生成玩家
	player = PLAYER_SCENE.instantiate()
	add_child(player)

	# 设置出生点
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.global_position = Vector3(0, 1, -15)

	print("[Level01] Player spawned at %s" % player.global_position)

	await get_tree().process_frame

func _connect_enemy_signals() -> void:
	## 连接所有敌人的死亡信号
	var enemies = level_generator.get_enemies()
	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)

func _connect_player_signals() -> void:
	## 连接玩家信号
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

func _init_level_flow() -> void:
	## 初始化关卡流程控制器
	# 创建配置字典
	var flow_config = {
		"name": level_config.level_name,
		"objectives": [
			{
				"id": "defeat_all_enemies",
				"type": "defeat_all",
				"description": "击败所有敌人",
				"target": total_enemies,
				"optional": false
			}
		]
	}

	# 初始化
	await level_flow.initialize_level(flow_config)

	# 连接信号
	level_flow.all_objectives_completed.connect(_on_level_completed)

	print("[Level01] Level flow initialized")

func _on_enemy_died(enemy: Node) -> void:
	## 敌人死亡回调
	enemies_defeated += 1
	print("[Level01] Enemy defeated: %d/%d" % [enemies_defeated, total_enemies])

	# 更新目标进度
	level_flow.update_objective("defeat_all_enemies", 1)

func _on_player_died() -> void:
	## 玩家死亡回调
	print("[Level01] Player died - Level Failed!")
	level_flow.level_failed("Player died")

func _on_level_completed() -> void:
	## 关卡完成回调
	print("[Level01] Level Complete! Victory!")

	# 显示胜利UI（稍后实现）
	await get_tree().create_timer(2.0).timeout
	print("[Level01] Returning to main menu...")
	# TODO: 返回主菜单或下一关

