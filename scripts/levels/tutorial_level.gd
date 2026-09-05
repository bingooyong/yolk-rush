extends Node3D
class_name TutorialLevel
## 关卡 0: 新手训练场
## 教学关卡，引导玩家学习基本操作

## 关卡配置
const LEVEL_ID = 0
const LEVEL_NAME = "新手训练场"
const TIME_LIMIT = 180.0

## 节点引用
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var obstacles_container: Node3D = $Obstacles
@onready var enemies_container: Node3D = $Enemies
@onready var items_container: Node3D = $Items
@onready var finish_trigger: Area3D = $FinishTrigger

## 管理器引用
var game_state_manager: Node = null
var level_flow_controller: Node = null

## 教学提示序列
var tutorial_prompts: Array[Dictionary] = [
	{
		"id": "move",
		"position": Vector3(0, 2, 5),
		"text": "使用 WASD 移动",
		"trigger_distance": 3.0,
		"shown": false
	},
	{
		"id": "jump",
		"position": Vector3(0, 2, 15),
		"text": "按 Space 跳跃",
		"trigger_distance": 3.0,
		"shown": false
	},
	{
		"id": "dash",
		"position": Vector3(0, 2, 25),
		"text": "按 Shift 冲刺",
		"trigger_distance": 3.0,
		"shown": false
	},
	{
		"id": "combat",
		"position": Vector3(0, 2, 35),
		"text": "点击鼠标攻击敌人",
		"trigger_distance": 5.0,
		"shown": false
	},
	{
		"id": "skill",
		"position": Vector3(0, 2, 45),
		"text": "按 Q 释放技能",
		"trigger_distance": 3.0,
		"shown": false
	},
	{
		"id": "pickup",
		"position": Vector3(0, 2, 55),
		"text": "靠近道具自动拾取",
		"trigger_distance": 3.0,
		"shown": false
	}
]

## 玩家引用
var player: Node3D = null

func _ready() -> void:
	print("[TutorialLevel] Initializing...")

	# 查找管理器
	_find_managers()

	# 生成关卡内容
	_spawn_obstacles()
	_spawn_enemies()
	_spawn_items()

	# 等待玩家
	await get_tree().create_timer(0.5).timeout
	_find_player()

	print("[TutorialLevel] Initialized")

func _process(delta: float) -> void:
	if player:
		_check_tutorial_prompts()

## 查找管理器
func _find_managers() -> void:
	if has_node("/root/GameStateManager"):
		game_state_manager = get_node("/root/GameStateManager")

	# 查找场景中的LevelFlowController
	var root = get_tree().root
	if root:
		level_flow_controller = root.find_child("LevelFlowController", true, false)

## 查找玩家
func _find_player() -> void:
	player = get_tree().root.find_child("Player", true, false)
	if player:
		print("[TutorialLevel] Player found")

## 生成障碍物
func _spawn_obstacles() -> void:
	# 第一段: 3个低墙（跳跃练习）
	_create_wall(Vector3(0, 0.5, 10), Vector3(2, 1, 0.5))
	_create_wall(Vector3(0, 0.5, 15), Vector3(2, 1, 0.5))
	_create_wall(Vector3(0, 0.5, 20), Vector3(2, 1, 0.5))

	# 第二段: 2个缓慢移动平台
	_create_moving_platform(Vector3(-3, 1, 30), Vector3(3, 1, 30), 3.0)
	_create_moving_platform(Vector3(3, 1, 35), Vector3(-3, 1, 35), 3.0)

	# 第三段: 1个旋转障碍
	_create_rotating_obstacle(Vector3(0, 1, 45), 2.0)

	print("[TutorialLevel] Spawned obstacles")

## 创建墙体
func _create_wall(pos: Vector3, size: Vector3) -> void:
	var wall = CSGBox3D.new()
	wall.position = pos
	wall.size = size

	# 添加碰撞
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape

	static_body.add_child(collision)
	wall.add_child(static_body)
	obstacles_container.add_child(wall)

## 创建移动平台
func _create_moving_platform(start_pos: Vector3, end_pos: Vector3, duration: float) -> void:
	var platform = CSGBox3D.new()
	platform.size = Vector3(2, 0.5, 2)
	platform.position = start_pos

	# 添加碰撞
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 0.5, 2)
	collision.shape = shape

	static_body.add_child(collision)
	platform.add_child(static_body)
	obstacles_container.add_child(platform)

	# 添加移动动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(platform, "position", end_pos, duration)
	tween.tween_property(platform, "position", start_pos, duration)

## 创建旋转障碍
func _create_rotating_obstacle(pos: Vector3, radius: float) -> void:
	var pivot = Node3D.new()
	pivot.position = pos
	obstacles_container.add_child(pivot)

	# 创建旋转臂
	var arm = CSGBox3D.new()
	arm.size = Vector3(radius * 2, 0.3, 0.3)
	arm.position = Vector3(0, 0, 0)

	# 添加碰撞
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(radius * 2, 0.3, 0.3)
	collision.shape = shape

	static_body.add_child(collision)
	arm.add_child(static_body)
	pivot.add_child(arm)

	# 添加旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(pivot, "rotation:y", TAU, 4.0)

## 生成敌人
func _spawn_enemies() -> void:
	# 3个基础敌人，固定生成点
	_create_enemy_spawn_point(Vector3(-2, 0, 40))
	_create_enemy_spawn_point(Vector3(0, 0, 42))
	_create_enemy_spawn_point(Vector3(2, 0, 44))

	print("[TutorialLevel] Enemy spawn points created")

## 创建敌人生成点
func _create_enemy_spawn_point(pos: Vector3) -> void:
	var marker = Marker3D.new()
	marker.position = pos
	marker.set_meta("enemy_type", "basic")
	marker.set_meta("enemy_health", 30.0)
	marker.set_meta("enemy_damage", 5.0)
	marker.set_meta("enemy_speed", 2.0)
	enemies_container.add_child(marker)

## 生成道具
func _spawn_items() -> void:
	# 5个金币（目标物品）
	for i in range(5):
		_create_coin(Vector3(
			randf_range(-3, 3),
			1,
			50 + i * 3
		))

	# 2个生命包
	_create_health_pack(Vector3(-2, 1, 25))
	_create_health_pack(Vector3(2, 1, 40))

	# 1个加速道具
	_create_speed_boost(Vector3(0, 1, 55))

	print("[TutorialLevel] Spawned items")

## 创建金币
func _create_coin(pos: Vector3) -> void:
	var coin = CSGSphere3D.new()
	coin.radius = 0.3
	coin.position = pos
	coin.set_meta("item_type", "coin")
	coin.set_meta("item_value", 10)

	# 添加触发区域
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape

	area.add_child(collision)
	coin.add_child(area)
	items_container.add_child(coin)

	# 旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(coin, "rotation:y", TAU, 2.0)

## 创建生命包
func _create_health_pack(pos: Vector3) -> void:
	var health_pack = CSGBox3D.new()
	health_pack.size = Vector3(0.5, 0.5, 0.5)
	health_pack.position = pos
	health_pack.set_meta("item_type", "health")
	health_pack.set_meta("heal_amount", 25.0)

	# 添加触发区域
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.8, 0.8)
	collision.shape = shape

	area.add_child(collision)
	health_pack.add_child(area)
	items_container.add_child(health_pack)

## 创建加速道具
func _create_speed_boost(pos: Vector3) -> void:
	var boost = CSGCylinder3D.new()
	boost.radius = 0.3
	boost.height = 0.6
	boost.position = pos
	boost.set_meta("item_type", "speed_boost")
	boost.set_meta("boost_multiplier", 1.5)
	boost.set_meta("boost_duration", 5.0)

	# 添加触发区域
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 0.8
	collision.shape = shape

	area.add_child(collision)
	boost.add_child(area)
	items_container.add_child(boost)

## 检查教学提示
func _check_tutorial_prompts() -> void:
	for prompt in tutorial_prompts:
		if prompt.shown:
			continue

		var distance = player.global_position.distance_to(prompt.position)
		if distance <= prompt.trigger_distance:
			_show_tutorial_prompt(prompt)

## 显示教学提示
func _show_tutorial_prompt(prompt: Dictionary) -> void:
	prompt.shown = true
	print("[TutorialLevel] Tutorial: %s" % prompt.text)

	# TODO: 显示UI提示
	# 这里需要与UI系统集成

## 获取关卡配置
func get_level_config() -> Dictionary:
	return {
		"id": LEVEL_ID,
		"name": LEVEL_NAME,
		"time_limit": TIME_LIMIT,
		"spawn_point": spawn_point.global_position if spawn_point else Vector3.ZERO
	}
