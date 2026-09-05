extends CanvasLayer
class_name InGameHUD
## 游戏内HUD界面

## 节点引用
@onready var health_bar: ProgressBar = $TopLeft/HealthBar
@onready var shield_indicator: TextureRect = $TopLeft/ShieldIndicator
@onready var timer_label: Label = $TopRight/TimerLabel
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var skill_container: HBoxContainer = $BottomLeft/SkillContainer
@onready var objective_panel: Panel = $TopCenter/ObjectivePanel
@onready var objective_progress: ProgressBar = $TopCenter/ObjectivePanel/ObjectiveProgress
@onready var objective_label: Label = $TopCenter/ObjectivePanel/ObjectiveLabel

## 管理器引用
var game_state_manager: Node = null
var level_flow_controller: Node = null

## 玩家引用
var player: Node = null

## 当前数据
var current_health: float = 100.0
var max_health: float = 100.0
var current_score: int = 0
var time_remaining: float = 180.0
var has_shield: bool = false

func _ready() -> void:
	print("[InGameHUD] Initializing...")

	# 如果节点不存在，创建它们
	if not has_node("TopLeft"):
		_create_ui()

	# 查找管理器
	_find_managers()

	# 查找玩家
	await get_tree().create_timer(0.5).timeout
	_find_player()

	print("[InGameHUD] Initialized")

func _process(delta: float) -> void:
	_update_timer(delta)
	_update_objectives()

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
		print("[InGameHUD] Player found")

## 创建UI
func _create_ui() -> void:
	# 左上角容器
	var top_left = VBoxContainer.new()
	top_left.name = "TopLeft"
	top_left.offset_left = 20
	top_left.offset_top = 20
	add_child(top_left)

	# 血量条
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(250, 30)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	top_left.add_child(health_bar)

	# 血量文本
	var health_label = Label.new()
	health_label.text = "HP"
	health_label.position = Vector2(10, 5)
	health_label.add_theme_font_size_override("font_size", 18)
	health_bar.add_child(health_label)

	# 护盾指示器
	shield_indicator = TextureRect.new()
	shield_indicator.name = "ShieldIndicator"
	shield_indicator.custom_minimum_size = Vector2(30, 30)
	shield_indicator.visible = false
	top_left.add_child(shield_indicator)

	# 右上角容器
	var top_right = VBoxContainer.new()
	top_right.name = "TopRight"
	top_right.offset_right = -20
	top_right.offset_top = 20
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(top_right)

	# 计时器
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "03:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	top_right.add_child(timer_label)

	# 分数
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "分数: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	top_right.add_child(score_label)

	# 左下角容器（技能）
	var bottom_left = HBoxContainer.new()
	bottom_left.name = "BottomLeft"
	bottom_left.offset_left = 20
	bottom_left.offset_bottom = -20
	bottom_left.anchor_top = 1.0
	bottom_left.anchor_bottom = 1.0
	bottom_left.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(bottom_left)

	# 技能容器
	skill_container = HBoxContainer.new()
	skill_container.name = "SkillContainer"
	skill_container.add_theme_constant_override("separation", 10)
	bottom_left.add_child(skill_container)

	# 创建技能图标（占位符）
	for i in range(4):
		var skill_icon = _create_skill_icon(i)
		skill_container.add_child(skill_icon)

	# 中上方容器（目标）
	var top_center = Control.new()
	top_center.name = "TopCenter"
	top_center.anchor_left = 0.5
	top_center.anchor_right = 0.5
	top_center.offset_left = -200
	top_center.offset_right = 200
	top_center.offset_top = 20
	add_child(top_center)

	# 目标面板
	objective_panel = Panel.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.anchor_right = 1.0
	objective_panel.custom_minimum_size = Vector2(0, 80)
	top_center.add_child(objective_panel)

	# 目标标签
	objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.text = "目标: 完成所有任务"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.position = Vector2(10, 10)
	objective_label.size = Vector2(380, 30)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_panel.add_child(objective_label)

	# 目标进度条
	objective_progress = ProgressBar.new()
	objective_progress.name = "ObjectiveProgress"
	objective_progress.position = Vector2(10, 45)
	objective_progress.size = Vector2(380, 25)
	objective_progress.max_value = 100
	objective_progress.value = 0
	objective_panel.add_child(objective_progress)

## 创建技能图标
func _create_skill_icon(index: int) -> Panel:
	var icon_panel = Panel.new()
	icon_panel.custom_minimum_size = Vector2(60, 60)

	# 技能图标背景
	var icon_bg = ColorRect.new()
	icon_bg.color = Color(0.2, 0.2, 0.3)
	icon_bg.anchor_right = 1.0
	icon_bg.anchor_bottom = 1.0
	icon_panel.add_child(icon_bg)

	# 技能键位提示
	var key_label = Label.new()
	key_label.text = ["Q", "E", "R", "F"][index]
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.anchor_right = 1.0
	key_label.anchor_bottom = 1.0
	key_label.add_theme_font_size_override("font_size", 24)
	icon_panel.add_child(key_label)

	# 冷却遮罩
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.anchor_right = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.visible = false
	icon_panel.add_child(cooldown_overlay)

	return icon_panel

## 更新血量
func update_health(current: float, maximum: float) -> void:
	current_health = current
	max_health = maximum

	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

		# 血量低于30%时变红
		if current / maximum < 0.3:
			health_bar.modulate = Color(1, 0.3, 0.3)
		else:
			health_bar.modulate = Color(1, 1, 1)

## 更新护盾状态
func update_shield(active: bool) -> void:
	has_shield = active

	if shield_indicator:
		shield_indicator.visible = active

## 更新分数
func update_score(score: int) -> void:
	current_score = score

	if score_label:
		score_label.text = "分数: %d" % score

## 更新计时器
func _update_timer(delta: float) -> void:
	if not game_state_manager:
		return

	# 从关卡统计获取已用时间
	var level_stats = game_state_manager.get_level_stats()
	var elapsed = level_stats.get("play_time", 0.0)

	# 计算剩余时间（假设3分钟限制）
	time_remaining = max(0, 180.0 - elapsed)

	if timer_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]

		# 时间低于30秒时变红并闪烁
		if time_remaining < 30:
			timer_label.modulate = Color(1, 0.3, 0.3)
			if int(time_remaining * 2) % 2 == 0:
				timer_label.modulate.a = 1.0
			else:
				timer_label.modulate.a = 0.5
		else:
			timer_label.modulate = Color(1, 1, 1)

## 更新目标
func _update_objectives() -> void:
	if not level_flow_controller:
		return

	# 获取总体进度
	var progress = level_flow_controller.get_overall_progress()

	if objective_progress:
		objective_progress.value = progress * 100

	# 更新目标文本
	var remaining = level_flow_controller.get_remaining_objectives_count()

	if objective_label:
		if remaining == 0:
			objective_label.text = "✓ 所有目标完成！"
			objective_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		else:
			objective_label.text = "剩余目标: %d" % remaining
			objective_label.add_theme_color_override("font_color", Color(1, 1, 1))

## 更新技能冷却
func update_skill_cooldown(skill_index: int, progress: float) -> void:
	if skill_index < 0 or skill_index >= skill_container.get_child_count():
		return

	var icon = skill_container.get_child(skill_index)
	var overlay = icon.get_node_or_null("CooldownOverlay")

	if overlay:
		if progress >= 1.0:
			overlay.visible = false
		else:
			overlay.visible = true
			overlay.anchor_bottom = 1.0 - progress

## 显示提示消息
func show_message(text: String, duration: float = 2.0) -> void:
	# 创建临时消息标签
	var message = Label.new()
	message.text = text
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 28)
	message.add_theme_color_override("font_color", Color(1, 1, 0))
	message.anchor_left = 0.5
	message.anchor_right = 0.5
	message.anchor_top = 0.5
	message.anchor_bottom = 0.5
	message.offset_left = -200
	message.offset_right = 200
	message.offset_top = -50
	message.offset_bottom = 50
	add_child(message)

	# 淡入淡出动画
	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration - 0.6)
	tween.tween_property(message, "modulate:a", 0.0, 0.3)
	tween.tween_callback(message.queue_free)

## 显示/隐藏
func show_hud() -> void:
	visible = true

func hide_hud() -> void:
	visible = false
