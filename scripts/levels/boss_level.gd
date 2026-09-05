extends Node3D
class_name BossLevel
## 关卡 2: Boss 战
## 终极挑战，击败 Boss

## 关卡配置
const LEVEL_ID = 2
const LEVEL_NAME = "终极挑战"
const TIME_LIMIT = 300.0

## Boss 配置
const BOSS_HEALTH = 500.0
const BOSS_DAMAGE = 30.0
const BOSS_SPEED = 4.0
const BOSS_PHASES = 3

## 节点引用
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var arena_center: Marker3D = $ArenaCenter
@onready var cover_container: Node3D = $Covers
@onready var item_spawn_points: Node3D = $ItemSpawnPoints
@onready var boss_spawn_point: Marker3D = $BossSpawnPoint

## 管理器引用
var game_state_manager: Node = null
var level_flow_controller: Node = null

## Boss 引用
var boss: Node = null
var boss_current_health: float = BOSS_HEALTH
var boss_current_phase: int = 1

## 玩家引用
var player: Node3D = null

## 小怪生成计时器
var minion_spawn_timer: float = 0.0
var minion_spawn_interval: float = 15.0

func _ready() -> void:
	print("[BossLevel] Initializing...")

	# 查找管理器
	_find_managers()

	# 创建竞技场
	_create_arena()

	# 创建掩体
	_create_covers()

	# 创建道具生成点
	_create_item_spawn_points()

	# 等待玩家和Boss
	await get_tree().create_timer(0.5).timeout
	_find_player()
	_spawn_boss()

	print("[BossLevel] Initialized")

func _process(delta: float) -> void:
	if boss and player:
		_update_boss_phase()
		_update_minion_spawning(delta)

## 查找管理器
func _find_managers() -> void:
	if has_node("/root/GameStateManager"):
		game_state_manager = get_node("/root/GameStateManager")

	var root = get_tree().root
	if root:
		level_flow_controller = root.find_child("LevelFlowController", true, false)

## 查找玩家
func _find_player() -> void:
	player = get_tree().root.find_child("Player", true, false)
	if player:
		print("[BossLevel] Player found")

## 创建竞技场
func _create_arena() -> void:
	# 竞技场地面（圆形）
	var arena_floor = CSGCylinder3D.new()
	arena_floor.radius = 20.0
	arena_floor.height = 0.5
	arena_floor.position = Vector3(0, -0.25, 0)

	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 20.0
	shape.height = 0.5
	collision.shape = shape

	static_body.add_child(collision)
	arena_floor.add_child(static_body)
	add_child(arena_floor)

	# 竞技场边界墙
	var wall_count = 16
	var wall_radius = 20.0
	for i in range(wall_count):
		var angle = (TAU / wall_count) * i
		var wall_pos = Vector3(
			cos(angle) * wall_radius,
			2,
			sin(angle) * wall_radius
		)

		var wall = CSGBox3D.new()
		wall.size = Vector3(0.5, 4, 3)
		wall.position = wall_pos
		wall.rotation.y = angle

		var wall_body = StaticBody3D.new()
		var wall_collision = CollisionShape3D.new()
		var wall_shape = BoxShape3D.new()
		wall_shape.size = Vector3(0.5, 4, 3)
		wall_collision.shape = wall_shape

		wall_body.add_child(wall_collision)
		wall.add_child(wall_body)
		add_child(wall)

	print("[BossLevel] Arena created")

## 创建掩体
func _create_covers() -> void:
	# 3个可破坏掩体（120度分布）
	for i in range(3):
		var angle = (TAU / 3) * i
		var cover_pos = Vector3(
			cos(angle) * 8,
			0.75,
			sin(angle) * 8
		)
		_create_cover(cover_pos)

	print("[BossLevel] Covers created")

## 创建单个掩体
func _create_cover(pos: Vector3) -> void:
	var cover = CSGBox3D.new()
	cover.size = Vector3(2, 1.5, 0.5)
	cover.position = pos
	cover.set_meta("cover_health", 100.0)
	cover.set_meta("is_destructible", true)

	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 1.5, 0.5)
	collision.shape = shape

	static_body.add_child(collision)
	cover.add_child(static_body)
	cover_container.add_child(cover)

## 创建道具生成点
func _create_item_spawn_points() -> void:
	# 4个固定道具生成点（90度分布）
	for i in range(4):
		var angle = (TAU / 4) * i + PI/4
		var spawn_pos = Vector3(
			cos(angle) * 12,
			1,
			sin(angle) * 12
		)

		var marker = Marker3D.new()
		marker.position = spawn_pos
		marker.set_meta("item_type", "random")
		item_spawn_points.add_child(marker)

	print("[BossLevel] Item spawn points created")

## 生成 Boss
func _spawn_boss() -> void:
	# 创建 Boss 占位符（巨大的球体）
	boss = CSGSphere3D.new()
	boss.radius = 2.0
	boss.position = boss_spawn_point.global_position if boss_spawn_point else Vector3(0, 2, 0)
	boss.set_meta("is_boss", true)
	boss.set_meta("health", BOSS_HEALTH)
	boss.set_meta("max_health", BOSS_HEALTH)
	boss.set_meta("damage", BOSS_DAMAGE)
	boss.set_meta("speed", BOSS_SPEED)
	boss.set_meta("phase", 1)

	# 添加碰撞
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 2.0
	collision.shape = shape

	area.add_child(collision)
	boss.add_child(area)
	add_child(boss)

	boss_current_health = BOSS_HEALTH
	boss_current_phase = 1

	print("[BossLevel] Boss spawned")

## 更新 Boss 阶段
func _update_boss_phase() -> void:
	if not boss:
		return

	var health_percent = boss_current_health / BOSS_HEALTH

	var new_phase = 1
	if health_percent <= 0.33:
		new_phase = 3
	elif health_percent <= 0.66:
		new_phase = 2

	if new_phase != boss_current_phase:
		_on_boss_phase_changed(boss_current_phase, new_phase)
		boss_current_phase = new_phase

## Boss 阶段转换
func _on_boss_phase_changed(old_phase: int, new_phase: int) -> void:
	print("[BossLevel] Boss phase changed: %d -> %d" % [old_phase, new_phase])

	# 生成生命包
	_spawn_health_packs_at_item_points()

	# 根据阶段调整行为
	match new_phase:
		2:
			# 阶段2: 增加移速
			boss.set_meta("speed", BOSS_SPEED * 1.3)
			minion_spawn_interval = 12.0
		3:
			# 阶段3: 狂暴模式
			boss.set_meta("speed", BOSS_SPEED * 1.5)
			boss.set_meta("damage", BOSS_DAMAGE * 1.5)
			minion_spawn_interval = 10.0

## 更新小怪生成
func _update_minion_spawning(delta: float) -> void:
	if boss_current_phase == 1:
		return  # 阶段1不生成小怪

	minion_spawn_timer += delta
	if minion_spawn_timer >= minion_spawn_interval:
		minion_spawn_timer = 0.0
		_spawn_minions()

## 生成小怪
func _spawn_minions() -> void:
	var minion_count = 2 if boss_current_phase == 2 else 3

	for i in range(minion_count):
		var angle = randf() * TAU
		var spawn_pos = Vector3(
			cos(angle) * 15,
			0,
			sin(angle) * 15
		)
		_create_minion(spawn_pos)

	print("[BossLevel] Spawned %d minions" % minion_count)

## 创建小怪
func _create_minion(pos: Vector3) -> void:
	var minion = CSGSphere3D.new()
	minion.radius = 0.8
	minion.position = pos

	# 随机类型
	var minion_types = ["basic", "fast", "tank"]
	var type = minion_types[randi() % minion_types.size()]

	match type:
		"basic":
			minion.set_meta("enemy_type", "basic")
			minion.set_meta("health", 70.0)
			minion.set_meta("damage", 15.0)
			minion.set_meta("speed", 3.5)
		"fast":
			minion.set_meta("enemy_type", "fast")
			minion.set_meta("health", 40.0)
			minion.set_meta("damage", 12.0)
			minion.set_meta("speed", 6.0)
		"tank":
			minion.set_meta("enemy_type", "tank")
			minion.set_meta("health", 150.0)
			minion.set_meta("damage", 20.0)
			minion.set_meta("speed", 1.5)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.8
	collision.shape = shape

	area.add_child(collision)
	minion.add_child(area)
	add_child(minion)

## 在道具点生成生命包
func _spawn_health_packs_at_item_points() -> void:
	for spawn_point in item_spawn_points.get_children():
		_spawn_health_pack(spawn_point.global_position)

## 生成生命包
func _spawn_health_pack(pos: Vector3) -> void:
	var health_pack = CSGBox3D.new()
	health_pack.size = Vector3(0.5, 0.5, 0.5)
	health_pack.position = pos
	health_pack.set_meta("item_type", "health")
	health_pack.set_meta("heal_amount", 25.0)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.8, 0.8)
	collision.shape = shape

	area.add_child(collision)
	health_pack.add_child(area)
	add_child(health_pack)

## Boss 受伤
func on_boss_damaged(damage: float) -> void:
	boss_current_health -= damage
	boss_current_health = max(0, boss_current_health)

	if boss.has_meta("health"):
		boss.set_meta("health", boss_current_health)

	print("[BossLevel] Boss health: %.0f / %.0f" % [boss_current_health, BOSS_HEALTH])

	if boss_current_health <= 0:
		_on_boss_defeated()

## Boss 被击败
func _on_boss_defeated() -> void:
	print("[BossLevel] Boss defeated!")

	if boss:
		boss.queue_free()
		boss = null

	# 通知关卡流程控制器
	if level_flow_controller:
		level_flow_controller.update_objective("defeat_boss", 1)

	# 通知游戏状态管理器
	if game_state_manager:
		game_state_manager.record_enemy_defeated()

## 获取关卡配置
func get_level_config() -> Dictionary:
	return {
		"id": LEVEL_ID,
		"name": LEVEL_NAME,
		"time_limit": TIME_LIMIT,
		"spawn_point": spawn_point.global_position if spawn_point else Vector3.ZERO,
		"boss_config": {
			"health": BOSS_HEALTH,
			"damage": BOSS_DAMAGE,
			"speed": BOSS_SPEED,
			"phases": BOSS_PHASES
		}
	}
