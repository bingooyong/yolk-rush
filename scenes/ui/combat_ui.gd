extends CanvasLayer
class_name CombatUI
## 战斗UI管理器 - 统一管理战斗界面元素

signal combat_started()
signal combat_ended()

@export var player_health_bar: Node
@export var enemy_health_bar: Node
@export var combat_log: Node

var damage_number_container: Node2D
var active_health_bars: Dictionary = {}

# 预加载脚本
const HealthBarScript = preload("res://scenes/ui/health_bar.gd")
const DamageNumberScript = preload("res://scenes/ui/damage_number.gd")
const CombatLogScript = preload("res://scenes/ui/combat_log.gd")

func _ready() -> void:
	_setup_containers()
	_setup_default_ui()
	print("[CombatUI] Initialized")

func _setup_containers() -> void:
	# 创建伤害数字容器（2D空间）
	damage_number_container = Node2D.new()
	damage_number_container.name = "DamageNumberContainer"
	add_child(damage_number_container)

func _setup_default_ui() -> void:
	# 主容器
	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)

	# 玩家血条（左上角）
	if not player_health_bar:
		player_health_bar = HealthBarScript.new()
		player_health_bar.name = "PlayerHealthBar"
		player_health_bar.position = Vector2(20, 20)
		player_health_bar.custom_minimum_size = Vector2(250, 30)
		main_container.add_child(player_health_bar)

	# 战斗日志（右下角）
	if not combat_log:
		combat_log = CombatLogScript.new()
		combat_log.name = "CombatLog"
		combat_log.anchor_left = 1.0
		combat_log.anchor_top = 1.0
		combat_log.anchor_right = 1.0
		combat_log.anchor_bottom = 1.0
		combat_log.offset_left = -320
		combat_log.offset_top = -250
		combat_log.offset_right = -20
		combat_log.offset_bottom = -20
		combat_log.custom_minimum_size = Vector2(300, 230)
		main_container.add_child(combat_log)

	# 敌人血条（顶部居中，默认隐藏）
	if not enemy_health_bar:
		enemy_health_bar = HealthBarScript.new()
		enemy_health_bar.name = "EnemyHealthBar"
		enemy_health_bar.anchor_left = 0.5
		enemy_health_bar.anchor_right = 0.5
		enemy_health_bar.offset_left = -125
		enemy_health_bar.offset_right = 125
		enemy_health_bar.position = Vector2(0, 20)
		enemy_health_bar.custom_minimum_size = Vector2(250, 25)
		enemy_health_bar.visible = false
		main_container.add_child(enemy_health_bar)

## 更新玩家血条
func update_player_health(current: float, maximum: float) -> void:
	if player_health_bar:
		player_health_bar.set_health(current, maximum)

## 更新敌人血条
func update_enemy_health(current: float, maximum: float) -> void:
	if enemy_health_bar:
		enemy_health_bar.visible = true
		enemy_health_bar.set_health(current, maximum)

## 隐藏敌人血条
func hide_enemy_health() -> void:
	if enemy_health_bar:
		enemy_health_bar.visible = false

## 显示伤害数字
func show_damage(amount: float, world_position: Vector2, is_critical: bool = false) -> void:
	var damage_type = DamageNumberScript.DamageType.CRITICAL if is_critical else DamageNumberScript.DamageType.NORMAL
	_create_damage_number(amount, damage_type, world_position)

## 显示治疗数字
func show_heal(amount: float, world_position: Vector2) -> void:
	_create_damage_number(amount, DamageNumberScript.DamageType.HEAL, world_position)

## 显示未命中
func show_miss(world_position: Vector2) -> void:
	_create_damage_number(0, DamageNumberScript.DamageType.MISS, world_position)

func _create_damage_number(value: float, type: int, world_position: Vector2) -> void:
	var damage_num = DamageNumberScript.new()
	damage_num.setup(value, type)

	# 转换世界坐标到画布坐标
	# 如果有相机，需要考虑相机偏移
	var canvas_position = world_position
	damage_num.position = canvas_position

	damage_number_container.add_child(damage_num)

## 战斗日志便捷方法
func log_damage(attacker: String, target: String, damage: float) -> void:
	if combat_log:
		combat_log.log_damage(attacker, target, damage)

func log_critical(attacker: String, target: String, damage: float) -> void:
	if combat_log:
		combat_log.log_critical(attacker, target, damage)

func log_heal(healer: String, target: String, amount: float) -> void:
	if combat_log:
		combat_log.log_heal(healer, target, amount)

func log_death(entity: String) -> void:
	if combat_log:
		combat_log.log_death(entity)

func log_miss(attacker: String, target: String) -> void:
	if combat_log:
		combat_log.log_miss(attacker, target)

func log_system(text: String) -> void:
	if combat_log:
		combat_log.log_system(text)

func log_info(text: String) -> void:
	if combat_log:
		combat_log.log_info(text)

## 开始战斗
func start_combat() -> void:
	log_system("Combat started!")
	combat_started.emit()

## 结束战斗
func end_combat(victory: bool = true) -> void:
	if victory:
		log_system("Victory!")
	else:
		log_system("Defeat...")

	hide_enemy_health()
	combat_ended.emit()

## 清空战斗日志
func clear_log() -> void:
	if combat_log:
		combat_log.clear_log()

## 创建实体专属血条（用于场景中的多个敌人）
func create_entity_health_bar(entity: Node, offset: Vector2 = Vector2(0, -50)) -> Node:
	var health_bar = HealthBarScript.new()
	health_bar.name = "HealthBar_%s" % entity.name
	health_bar.custom_minimum_size = Vector2(80, 12)
	health_bar.show_text = false
	health_bar.bar_height = 12

	# 添加到容器并跟踪
	var main_container = get_node_or_null("MainContainer")
	if main_container:
		main_container.add_child(health_bar)

	active_health_bars[entity] = {
		"bar": health_bar,
		"offset": offset
	}

	return health_bar

## 更新实体血条位置（在_process中调用）
func update_entity_health_bar_positions() -> void:
	for entity in active_health_bars.keys():
		if not is_instance_valid(entity):
			remove_entity_health_bar(entity)
			continue

		var data = active_health_bars[entity]
		var health_bar = data["bar"]
		var offset = data["offset"]

		if entity is Node2D:
			health_bar.global_position = entity.global_position + offset
		elif entity is Node3D:
			# 3D转2D坐标（如果需要）
			pass

## 移除实体血条
func remove_entity_health_bar(entity: Node) -> void:
	if entity in active_health_bars:
		var health_bar = active_health_bars[entity]["bar"]
		if is_instance_valid(health_bar):
			health_bar.queue_free()
		active_health_bars.erase(entity)

func _process(_delta: float) -> void:
	update_entity_health_bar_positions()
