extends Control
class_name GameOverScreen
## 游戏结算界面
## 显示关卡完成后的评分、统计和选项

signal retry_pressed()
signal next_level_pressed()
signal main_menu_pressed()

@onready var result_label: Label
@onready var rank_label: Label
@onready var stats_container: VBoxContainer
@onready var button_container: HBoxContainer

# 设计系统颜色
const COLOR_PRIMARY = Color("#3B6DFF")
const COLOR_SUCCESS = Color("#6EE7B7")
const COLOR_WARNING = Color("#E9A568")
const COLOR_DANGER = Color("#EF4444")
const COLOR_GOLD = Color("#FFD700")
const COLOR_BG_DARK = Color("#0A0D12")
const COLOR_BG_PANEL = Color("#1E2636")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#9CA3AF")

# 评分等级
enum Rank { S, A, B, C, F }

var current_rank: Rank = Rank.C
var level_stats: Dictionary = {}

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	print("[GameOverScreen] Initialized")

## 设置UI
func _setup_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主面板
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.position = Vector2(-400, -300)
	main_panel.custom_minimum_size = Vector2(800, 600)
	add_child(main_panel)

	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_PANEL
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(1, 1, 1, 0.3)
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 12
	main_panel.add_theme_stylebox_override("panel", panel_style)

	# 内容容器
	var content = VBoxContainer.new()
	content.position = Vector2(40, 40)
	content.custom_minimum_size = Vector2(720, 520)
	content.add_theme_constant_override("separation", 24)
	main_panel.add_child(content)

	# 结果标题
	_create_result_section(content)

	# 评分区域
	_create_rank_section(content)

	# 统计数据
	_create_stats_section(content)

	# 按钮区域
	_create_button_section(content)

## 创建结果标题
func _create_result_section(parent: Control) -> void:
	result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "关卡完成！"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 48)
	result_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	result_label.add_theme_color_override("font_outline_color", Color.BLACK)
	result_label.add_theme_constant_override("outline_size", 4)
	parent.add_child(result_label)

## 创建评分区域
func _create_rank_section(parent: Control) -> void:
	var rank_container = VBoxContainer.new()
	rank_container.add_theme_constant_override("separation", 12)
	parent.add_child(rank_container)

	# 评分标题
	var rank_title = Label.new()
	rank_title.text = "评分"
	rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_title.add_theme_font_size_override("font_size", 24)
	rank_title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	rank_container.add_child(rank_title)

	# 评分显示
	rank_label = Label.new()
	rank_label.name = "RankLabel"
	rank_label.text = "C"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 120)
	rank_label.add_theme_color_override("font_color", COLOR_WARNING)
	rank_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rank_label.add_theme_constant_override("outline_size", 6)
	rank_container.add_child(rank_label)

## 创建统计区域
func _create_stats_section(parent: Control) -> void:
	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(720, 200)
	parent.add_child(stats_panel)

	# 统计面板样式
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = COLOR_BG_DARK
	stats_style.corner_radius_top_left = 12
	stats_style.corner_radius_top_right = 12
	stats_style.corner_radius_bottom_left = 12
	stats_style.corner_radius_bottom_right = 12
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.position = Vector2(24, 24)
	stats_container.custom_minimum_size = Vector2(672, 152)
	stats_container.add_theme_constant_override("separation", 12)
	stats_panel.add_child(stats_container)

## 创建按钮区域
func _create_button_section(parent: Control) -> void:
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 16)
	parent.add_child(button_container)

	# 重试按钮
	var retry_button = _create_styled_button("重试", COLOR_WARNING, Vector2(200, 60))
	retry_button.name = "RetryButton"
	retry_button.pressed.connect(_on_retry_pressed)
	button_container.add_child(retry_button)

	# 下一关按钮
	var next_button = _create_styled_button("下一关", COLOR_SUCCESS, Vector2(200, 60))
	next_button.name = "NextButton"
	next_button.pressed.connect(_on_next_level_pressed)
	button_container.add_child(next_button)

	# 返回主菜单按钮
	var menu_button = _create_styled_button("主菜单", COLOR_PRIMARY, Vector2(200, 60))
	menu_button.name = "MenuButton"
	menu_button.pressed.connect(_on_main_menu_pressed)
	button_container.add_child(menu_button)

## 创建样式化按钮
func _create_styled_button(text: String, color: Color, min_size: Vector2) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size

	# 正常状态
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.content_margin_left = 24
	normal_style.content_margin_right = 24
	normal_style.content_margin_top = 16
	normal_style.content_margin_bottom = 16
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = color.lightened(0.3)
	normal_style.shadow_color = Color(0, 0, 0, 0.4)
	normal_style.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal_style)

	# 悬停状态
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	hover_style.shadow_size = 6
	button.add_theme_stylebox_override("hover", hover_style)

	# 按下状态
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	pressed_style.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed_style)

	# 字体
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", COLOR_TEXT)

	return button

## 连接信号
func _connect_signals() -> void:
	pass

## 显示结算界面
func show_results(stats: Dictionary, victory: bool = true) -> void:
	level_stats = stats

	# 设置结果标题
	if victory:
		result_label.text = "关卡完成！"
		result_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	else:
		result_label.text = "关卡失败"
		result_label.add_theme_color_override("font_color", COLOR_DANGER)

	# 计算评分
	current_rank = _calculate_rank(stats)

	# 显示评分
	_display_rank(current_rank)

	# 显示统计数据
	_display_stats(stats)

	# 播放入场动画
	visible = true
	_play_entrance_animation()

## 计算评分
func _calculate_rank(stats: Dictionary) -> Rank:
	var score = 0

	# 完成时间（越快越好）
	var play_time = stats.get("play_time", 0.0)
	if play_time < 60:
		score += 40
	elif play_time < 120:
		score += 30
	elif play_time < 180:
		score += 20
	else:
		score += 10

	# 击败敌人数
	var enemies_defeated = stats.get("enemies_defeated", 0)
	score += min(enemies_defeated * 5, 30)

	# 收集道具数
	var items_collected = stats.get("items_collected", 0)
	score += min(items_collected * 3, 20)

	# 受伤情况（越少越好）
	var damage_taken = stats.get("damage_taken", 0)
	if damage_taken == 0:
		score += 10
	elif damage_taken < 50:
		score += 5

	# 根据分数评级
	if score >= 90:
		return Rank.S
	elif score >= 75:
		return Rank.A
	elif score >= 60:
		return Rank.B
	elif score >= 40:
		return Rank.C
	else:
		return Rank.F

## 显示评分
func _display_rank(rank: Rank) -> void:
	var rank_text = ""
	var rank_color = COLOR_TEXT

	match rank:
		Rank.S:
			rank_text = "S"
			rank_color = COLOR_GOLD
		Rank.A:
			rank_text = "A"
			rank_color = COLOR_SUCCESS
		Rank.B:
			rank_text = "B"
			rank_color = Color("#38BDF8")
		Rank.C:
			rank_text = "C"
			rank_color = COLOR_WARNING
		Rank.F:
			rank_text = "F"
			rank_color = COLOR_DANGER

	rank_label.text = rank_text
	rank_label.add_theme_color_override("font_color", rank_color)

## 显示统计数据
func _display_stats(stats: Dictionary) -> void:
	# 清空现有统计
	for child in stats_container.get_children():
		child.queue_free()

	# 完成时间
	var play_time = stats.get("play_time", 0.0)
	_add_stat_row("⏱ 完成时间", _format_time(play_time))

	# 击败敌人
	var enemies = stats.get("enemies_defeated", 0)
	_add_stat_row("⚔ 击败敌人", "%d" % enemies)

	# 收集道具
	var items = stats.get("items_collected", 0)
	_add_stat_row("💎 收集道具", "%d" % items)

	# 受到伤害
	var damage = stats.get("damage_taken", 0)
	_add_stat_row("💔 受到伤害", "%d" % int(damage))

	# 使用技能
	var skills = stats.get("skills_used", 0)
	_add_stat_row("✨ 使用技能", "%d" % skills)

## 添加统计行
func _add_stat_row(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	# 标签
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# 数值
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", COLOR_TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	stats_container.add_child(row)

## 格式化时间
func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

## 入场动画
func _play_entrance_animation() -> void:
	# 初始状态
	modulate.a = 0.0
	result_label.position.y = -30
	rank_label.scale = Vector2.ZERO

	# 动画序列
	var tween = create_tween()
	tween.set_parallel(false)

	# 背景淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# 标题下落
	tween.tween_property(result_label, "position:y", 0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 评分弹出
	tween.tween_interval(0.2)
	tween.tween_property(rank_label, "scale", Vector2.ONE * 1.2, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(rank_label, "scale", Vector2.ONE, 0.2)

	# 播放音效
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_confirm")

func _on_retry_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_click")
	retry_pressed.emit()

func _on_next_level_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_confirm")
	next_level_pressed.emit()

func _on_main_menu_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ui_sound("ui_cancel")
	main_menu_pressed.emit()
