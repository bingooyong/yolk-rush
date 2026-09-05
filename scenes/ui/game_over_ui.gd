extends Control
class_name GameOverUI
## 游戏结算界面
## 显示胜利/失败、统计数据、评分

signal retry_pressed()
signal next_level_pressed()
signal main_menu_pressed()

enum ResultType {
	VICTORY,
	DEFEAT
}

## 当前结果类型
var result_type: ResultType = ResultType.VICTORY

## 统计数据
var stats: Dictionary = {}

## 评分等级
var grade: String = "C"

func _ready() -> void:
	await get_tree().process_frame
	_create_ui()
	hide_ui()

## 创建UI
func _create_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 半透明背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(-350, -300)
	main_container.custom_minimum_size = Vector2(700, 600)
	main_container.add_theme_constant_override("separation", 30)
	add_child(main_container)

	# 结果标题
	var title = Label.new()
	title.name = "Title"
	title.text = "胜利！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	main_container.add_child(title)

	# 评分显示
	var grade_label = Label.new()
	grade_label.name = "GradeLabel"
	grade_label.text = "评分: S"
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_label.add_theme_font_size_override("font_size", 48)
	grade_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	main_container.add_child(grade_label)

	# 统计面板
	var stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.custom_minimum_size = Vector2(700, 250)
	main_container.add_child(stats_panel)

	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 15)
	stats_panel.add_child(stats_container)

	# 统计项（将在show_result中填充）
	for i in range(5):
		var stat_label = Label.new()
		stat_label.name = "StatLabel%d" % i
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.add_theme_font_size_override("font_size", 24)
		stats_container.add_child(stat_label)

	# 按钮容器
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	main_container.add_child(button_container)

	# 重试按钮
	var retry_btn = Button.new()
	retry_btn.name = "RetryButton"
	retry_btn.text = "重试"
	retry_btn.custom_minimum_size = Vector2(150, 50)
	retry_btn.pressed.connect(_on_retry_pressed)
	button_container.add_child(retry_btn)

	# 下一关按钮
	var next_btn = Button.new()
	next_btn.name = "NextButton"
	next_btn.text = "下一关"
	next_btn.custom_minimum_size = Vector2(150, 50)
	next_btn.pressed.connect(_on_next_level_pressed)
	button_container.add_child(next_btn)

	# 主菜单按钮
	var menu_btn = Button.new()
	menu_btn.name = "MenuButton"
	menu_btn.text = "主菜单"
	menu_btn.custom_minimum_size = Vector2(150, 50)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	button_container.add_child(menu_btn)

## 显示结算结果
func show_result(type: ResultType, level_stats: Dictionary) -> void:
	result_type = type
	stats = level_stats

	# 计算评分
	grade = _calculate_grade(level_stats)

	# 更新标题
	var title = get_node_or_null("MainContainer/Title")
	if title:
		if type == ResultType.VICTORY:
			title.text = "胜利！"
			title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			title.text = "失败"
			title.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# 更新评分
	var grade_label = get_node_or_null("MainContainer/GradeLabel")
	if grade_label:
		grade_label.text = "评分: " + grade
		grade_label.add_theme_color_override("font_color", _get_grade_color(grade))

	# 更新统计
	_update_stats_display()

	# 更新按钮可见性
	var next_btn = get_node_or_null("MainContainer/ButtonContainer/NextButton")
	if next_btn:
		next_btn.visible = (type == ResultType.VICTORY)

	show_ui()

## 计算评分
func _calculate_grade(level_stats: Dictionary) -> String:
	var score = 0.0

	# 完成基础分 (30%)
	if level_stats.get("completed", false):
		score += 30.0

	# 时间分 (30%) - 60秒以内满分，之后递减
	var time = level_stats.get("play_time", 0.0)
	if time > 0:
		if time <= 60:
			score += 30.0
		else:
			var time_score = max(0, 30.0 - (time - 60) * 0.5)  # 超过60秒每秒-0.5分
			score += time_score

	# 无伤分 (20%)
	var damage_taken = level_stats.get("damage_taken", 0)
	if damage_taken == 0:
		score += 20.0
	elif damage_taken < 30:
		score += 15.0
	elif damage_taken < 60:
		score += 10.0

	# 击败敌人分 (10%)
	var enemies = level_stats.get("enemies_defeated", 0)
	score += min(10.0, enemies * 1.0)

	# 收集道具分 (10%)
	var items = level_stats.get("items_collected", 0)
	score += min(10.0, items * 1.0)

	# 根据分数返回等级
	if score >= 90:
		return "S"
	elif score >= 80:
		return "A"
	elif score >= 70:
		return "B"
	elif score >= 60:
		return "C"
	else:
		return "F"

## 获取评分颜色
func _get_grade_color(g: String) -> Color:
	match g:
		"S": return Color(1, 0.84, 0)      # 金色
		"A": return Color(0.4, 0.9, 0.4)   # 绿色
		"B": return Color(0.22, 0.75, 0.97) # 蓝色
		"C": return Color(0.9, 0.6, 0.2)   # 橙色
		"F": return Color(0.9, 0.4, 0.4)   # 红色
		_: return Color.WHITE

## 更新统计显示
func _update_stats_display() -> void:
	var stat_texts = [
		"游戏时间: %.1f 秒" % stats.get("play_time", 0.0),
		"击败敌人: %d" % stats.get("enemies_defeated", 0),
		"收集道具: %d" % stats.get("items_collected", 0),
		"受到伤害: %d" % stats.get("damage_taken", 0),
		"使用技能: %d 次" % stats.get("skills_used", 0)
	]

	for i in range(stat_texts.size()):
		var label = get_node_or_null("MainContainer/StatsPanel/StatsContainer/StatLabel%d" % i)
		if label:
			label.text = stat_texts[i]

## 按钮回调
func _on_retry_pressed() -> void:
	retry_pressed.emit()
	hide_ui()

func _on_next_level_pressed() -> void:
	next_level_pressed.emit()
	hide_ui()

func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()
	hide_ui()

## 显示/隐藏UI
func show_ui() -> void:
	visible = true

func hide_ui() -> void:
	visible = false
