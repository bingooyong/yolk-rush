extends Control
class_name HUD
## 游戏抬头显示 - 显示玩家基本信息

# UI 节点引用
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var exp_bar: ProgressBar = $TopLeft/ExpBar
@onready var exp_label: Label = $TopLeft/ExpLabel
@onready var gold_label: Label = $TopRight/GoldLabel
@onready var skill_points_label: Label = $TopRight/SkillPointsLabel

# 属性显示
@onready var health_bar: ProgressBar = $BottomLeft/HealthBar
@onready var health_label: Label = $BottomLeft/HealthLabel

# 快捷栏
@onready var quick_bar_container: HBoxContainer = $Bottom/QuickBarContainer

# 通知系统
@onready var notification_label: Label = $Center/NotificationLabel
@onready var level_up_popup: Control = $Center/LevelUpPopup

# GameManager 引用
var game_manager = null

var notification_timer: Timer

func _ready() -> void:
	# 创建通知计时器
	notification_timer = Timer.new()
	notification_timer.one_shot = true
	notification_timer.timeout.connect(_hide_notification)
	add_child(notification_timer)

	# 隐藏通知元素
	if notification_label:
		notification_label.visible = false
	if level_up_popup:
		level_up_popup.visible = false

	# 等待游戏管理器初始化
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_initialize()
		else:
			game_manager.game_initialized.connect(_initialize)

func _initialize() -> void:
	# 连接信号
	game_manager.level_system.level_up.connect(_on_level_up)
	game_manager.level_system.exp_gained.connect(_on_exp_gained)
	game_manager.shop_system.gold_changed.connect(_on_gold_changed)
	game_manager.skill_tree_system.skill_points_changed.connect(_on_skill_points_changed)

	# 初始更新
	update_all()

## 更新所有显示
func update_all() -> void:
	update_level()
	update_exp_bar()
	update_gold()
	update_skill_points()
	update_health()
	update_quick_bar()

## 更新等级显示
func update_level() -> void:
	if level_label:
		var level = game_manager.level_system.current_level
		level_label.text = "等级 %d" % level

## 更新经验条
func update_exp_bar(current: int = -1, required: int = -1) -> void:
	if exp_bar:
		var info = game_manager.level_system.get_level_info()
		exp_bar.value = info.progress * 100

		if exp_label:
			exp_label.text = "%d / %d" % [info.current_exp, info.required_exp]

## 更新金币显示
func update_gold(gold: int = -1) -> void:
	if gold_label:
		var current_gold = gold if gold >= 0 else game_manager.shop_system.get_player_gold()
		gold_label.text = "%d 金币" % current_gold

## 更新技能点显示
func update_skill_points(points: int = -1) -> void:
	if skill_points_label:
		var current_points = points if points >= 0 else game_manager.skill_tree_system.available_skill_points
		skill_points_label.text = "%d 技能点" % current_points

## 更新生命值显示
func update_health() -> void:
	if health_bar and health_label:
		# TODO: 从玩家获取实际生命值
		# 这里使用最大生命值作为示例
		var stats = game_manager.get_total_player_stats()
		var max_health = stats.get("max_health", 100.0)
		var current_health = max_health  # 暂时使用满血

		health_bar.max_value = max_health
		health_bar.value = current_health
		health_label.text = "%.0f / %.0f" % [current_health, max_health]

## 更新快捷栏显示
func update_quick_bar() -> void:
	if not quick_bar_container:
		return

	# 清空现有显示
	for child in quick_bar_container.get_children():
		child.queue_free()

	# 创建快捷栏槽位显示
	for i in range(game_manager.quick_bar_system.QUICK_BAR_SIZE):
		var slot = create_quick_bar_slot(i)
		quick_bar_container.add_child(slot)

## 创建快捷栏槽位
func create_quick_bar_slot(slot_index: int) -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(50, 50)

	var label = Label.new()
	label.text = str(slot_index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(label)

	# TODO: 显示绑定的物品图标和数量

	return slot

## 显示升级弹窗
func show_level_up(new_level: int) -> void:
	if level_up_popup:
		# 更新弹窗文本
		var label = level_up_popup.get_node_or_null("Label")
		if label:
			label.text = "升级到 %d 级！" % new_level

		# 显示弹窗
		level_up_popup.visible = true

		# 3秒后自动隐藏
		await get_tree().create_timer(3.0).timeout
		if level_up_popup:
			level_up_popup.visible = false

	# 更新显示
	update_level()
	update_exp_bar()

## 显示通知
func show_notification(text: String, duration: float = 2.0) -> void:
	if notification_label:
		notification_label.text = text
		notification_label.visible = true
		notification_timer.start(duration)

## 隐藏通知
func _hide_notification() -> void:
	if notification_label:
		notification_label.visible = false

## 信号处理
func _on_level_up(new_level: int) -> void:
	show_level_up(new_level)

func _on_exp_gained(amount: int, current: int, required: int) -> void:
	update_exp_bar(current, required)

func _on_gold_changed(current_gold: int) -> void:
	update_gold(current_gold)

func _on_skill_points_changed(current_points: int) -> void:
	update_skill_points(current_points)

## 处理输入（快捷栏）
func _input(event: InputEvent) -> void:
	# 数字键 1-8 使用快捷栏
	for i in range(8):
		if event.is_action_pressed("quick_bar_%d" % (i + 1)):
			game_manager.quick_bar_system.use_quick_bar_item(i)
			update_quick_bar()
			get_viewport().set_input_as_handled()
			break
