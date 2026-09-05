extends Node3D
## 游戏循环测试 - 完整的RPG循环演示

@onready var player = $Player
@onready var level_label = $GameUI/HUD/TopLeft/LevelLabel
@onready var exp_label = $GameUI/HUD/TopLeft/ExpLabel
@onready var health_label = $GameUI/HUD/TopLeft/HealthLabel
@onready var gold_label = $GameUI/HUD/TopLeft/GoldLabel
@onready var stats_label = $GameUI/HUD/TopRight/StatsLabel
@onready var equipment_label = $GameUI/HUD/TopRight/EquipmentLabel
@onready var message_label = $GameUI/HUD/Center/MessageLabel

var spawn_timer: float = 0.0
var enemy_count: int = 0

func _ready() -> void:
	print("\n=== 游戏循环测试开始 ===\n")

	# 等待GameManager初始化
	await get_tree().create_timer(0.5).timeout

	if not has_node("/root/GameManager"):
		push_error("GameManager not found in autoload!")
		return

	var game_manager = get_node("/root/GameManager")
	if not game_manager.is_initialized:
		push_error("GameManager not initialized!")
		return

	# 连接信号
	_connect_signals()

	# 初始化UI
	_update_ui()

	# 显示欢迎消息
	show_message("Welcome to Yolk Rush!\nDefeat enemies to gain XP and loot!", 3.0)

	print("[GameLoop] Ready! Kill enemies to test the full RPG loop")

func _process(delta: float) -> void:
	# 自动生成敌人
	spawn_timer += delta
	if spawn_timer >= 10.0 and enemy_count < 5:
		_spawn_enemy()
		spawn_timer = 0.0

func _connect_signals() -> void:
	var game_manager = get_node("/root/GameManager")

	# 等级系统
	if game_manager.level_system:
		game_manager.level_system.level_up.connect(_on_level_up)
		game_manager.level_system.exp_gained.connect(_on_exp_gained)

	# 装备系统
	if game_manager.equipment_system:
		game_manager.equipment_system.equipment_changed.connect(_on_equipment_changed)

	# 背包系统
	if game_manager.inventory_system:
		game_manager.inventory_system.inventory_changed.connect(_on_inventory_changed)

	# 商店系统
	if game_manager.shop_system:
		game_manager.shop_system.gold_changed.connect(_on_gold_changed)

	# 玩家
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)

	print("[GameLoop] Signals connected")

## 更新UI
func _update_ui() -> void:
	if not has_node("/root/GameManager"):
		return

	var game_manager = get_node("/root/GameManager")

	# 等级和经验
	if game_manager.level_system:
		var level = game_manager.level_system.current_level
		var exp = game_manager.level_system.current_exp
		var required = game_manager.level_system.get_required_exp(level)
		level_label.text = "Level %d" % level
		exp_label.text = "EXP: %d / %d" % [exp, required]

	# 生命值
	if player:
		health_label.text = "HP: %d / %d" % [player.health, player.max_health]

	# 金币
	if game_manager.shop_system:
		var gold = game_manager.shop_system.get_player_gold()
		gold_label.text = "Gold: %d" % gold

	# 属性
	var stats = game_manager.get_total_player_stats()
	var atk = stats.get("physical_damage", 10)
	var def_val = stats.get("physical_defense", 5)
	var spd = stats.get("attack_speed", 1.0)
	stats_label.text = "ATK: %d | DEF: %d | SPD: %.1f" % [atk, def_val, spd]

	# 装备评分
	if game_manager.equipment_system:
		var score = game_manager.equipment_system.get_equipment_score()
		equipment_label.text = "Equipment Score: %d" % score

## 升级时
func _on_level_up(new_level: int) -> void:
	print("[GameLoop] ✨ LEVEL UP to %d! ✨" % new_level)
	show_message("LEVEL UP!\nLevel %d" % new_level, 2.0)
	_update_ui()

## 经验值变化
func _on_exp_gained(amount: int, current: int, required: int) -> void:
	_update_ui()

## 装备变化
func _on_equipment_changed(slot: String, item) -> void:
	print("[GameLoop] Equipment changed in slot: %s" % slot)
	_update_ui()

## 背包变化
func _on_inventory_changed() -> void:
	_update_ui()

## 金币变化
func _on_gold_changed(amount: int) -> void:
	_update_ui()

## 玩家生命值变化
func _on_player_health_changed(current: float, maximum: float) -> void:
	health_label.text = "HP: %d / %d" % [current, maximum]

## 玩家死亡
func _on_player_died() -> void:
	show_message("You Died!\nRespawning...", 2.0)

## 显示消息
func show_message(text: String, duration: float = 2.0) -> void:
	message_label.text = text
	message_label.show()

	# 自动隐藏
	await get_tree().create_timer(duration).timeout
	message_label.hide()

## 生成敌人
func _spawn_enemy() -> void:
	var goblin_scene = preload("res://scenes/enemies/goblin.tscn")
	var goblin = goblin_scene.instantiate()

	# 随机位置
	var angle = randf() * TAU
	var distance = randf_range(8.0, 15.0)
	var pos = Vector3(cos(angle) * distance, 1.0, sin(angle) * distance)

	goblin.global_position = pos
	goblin.enemy_level = GameManager.level_system.current_level

	$Enemies.add_child(goblin)
	enemy_count += 1

	print("[GameLoop] Spawned enemy at %s" % pos)

## 输入处理
func _input(event: InputEvent) -> void:
	# 测试快捷键
	if event.is_action_pressed("ui_text_completion_accept"):  # Tab
		_debug_give_items()

	if event.is_action_pressed("ui_page_up"):
		_debug_level_up()

	if event.is_action_pressed("ui_page_down"):
		_debug_spawn_enemy()

## 调试：给予物品
func _debug_give_items() -> void:
	if not has_node("/root/GameManager"):
		return

	var game_manager = get_node("/root/GameManager")

	# 给予一些物品测试
	var potion = game_manager.item_database.get_item_by_id("health_potion_small")
	if potion:
		game_manager.inventory_system.add_item(potion, 3)
		show_message("Received 3x Health Potion (Small)", 1.5)

	# 给予金币
	var current_gold = game_manager.shop_system.get_player_gold()
	game_manager.shop_system.set_player_gold(current_gold + 50)
	show_message("Received 50 Gold", 1.5)

## 调试：升级
func _debug_level_up() -> void:
	if not has_node("/root/GameManager"):
		return

	var game_manager = get_node("/root/GameManager")
	var required = game_manager.level_system.get_required_exp(game_manager.level_system.current_level)
	game_manager.level_system.add_exp(required)

## 调试：生成敌人
func _debug_spawn_enemy() -> void:
	_spawn_enemy()
