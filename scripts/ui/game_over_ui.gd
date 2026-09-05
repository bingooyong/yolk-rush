extends CanvasLayer
class_name GameOverUI
## 游戏结束界面
## 显示胜利/失败结果和统计信息

signal restart_requested()
signal next_level_requested()
signal return_to_menu_requested()

## 节点引用
@onready var victory_panel: Panel = $VictoryPanel
@onready var defeat_panel: Panel = $DefeatPanel
@onready var stats_container: VBoxContainer = $VictoryPanel/StatsContainer
@onready var score_label: Label = $VictoryPanel/ScoreLabel
@onready var time_label: Label = $VictoryPanel/TimeLabel
@onready var restart_button: Button = $VictoryPanel/ButtonContainer/RestartButton
@onready var next_button: Button = $VictoryPanel/ButtonContainer/NextButton
@onready var menu_button: Button = $VictoryPanel/ButtonContainer/MenuButton

## 当前状态
var is_victory: bool = false
var level_stats: Dictionary = {}
var reward_data: Dictionary = {}

func _ready() -> void:
	# 初始隐藏
	hide_all()

	# 连接信号
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

## 显示胜利界面
func show_victory(stats: Dictionary, reward: Dictionary) -> void:
	is_victory = true
	level_stats = stats
	reward_data = reward

	hide_all()

	if victory_panel:
		victory_panel.visible = true
		_update_victory_ui()

	print("[GameOverUI] Showing victory screen")

## 显示失败界面
func show_defeat(stats: Dictionary) -> void:
	is_victory = false
	level_stats = stats

	hide_all()

	if defeat_panel:
		defeat_panel.visible = true
		_update_defeat_ui()

	print("[GameOverUI] Showing defeat screen")

## 隐藏所有面板
func hide_all() -> void:
	if victory_panel:
		victory_panel.visible = false
	if defeat_panel:
		defeat_panel.visible = false

## 更新胜利界面
func _update_victory_ui() -> void:
	# 更新分数（带动画）
	if score_label:
		var total_score = reward_data.get("total_score", 0)
		score_label.text = "总分: 0"
		_animate_number(score_label, "text", 0, total_score, 1.0, "总分: %d")

	# 更新时间
	if time_label:
		var play_time = level_stats.get("play_time", 0.0)
		time_label.text = "用时: %s" % _format_time(play_time)

		# 根据时间显示星级
		_update_star_rating(play_time)

	# 更新统计信息（延迟显示，逐行动画）
	if stats_container:
		_clear_stats_container()
		await get_tree().create_timer(0.3).timeout

		_add_stat_line_animated("击败敌人: %d" % level_stats.get("enemies_defeated", 0), 0.1)
		await get_tree().create_timer(0.2).timeout

		_add_stat_line_animated("收集道具: %d" % level_stats.get("items_collected", 0), 0.1)
		await get_tree().create_timer(0.2).timeout

		_add_stat_line_animated("承受伤害: %.0f" % level_stats.get("damage_taken", 0), 0.1)
		await get_tree().create_timer(0.2).timeout

		_add_stat_line_animated("使用技能: %d" % level_stats.get("skills_used", 0), 0.1)
		await get_tree().create_timer(0.3).timeout

		# 奖励明细（带动画）
		var breakdown = reward_data.get("breakdown", {})
		if breakdown.size() > 0:
			_add_stat_line("--- 奖励明细 ---")
			await get_tree().create_timer(0.2).timeout

			for key in breakdown:
				_add_stat_line_animated("%s: +%d" % [_translate_reward_key(key), breakdown[key]], 0.1)
				await get_tree().create_timer(0.15).timeout

## 更新失败界面
func _update_defeat_ui() -> void:
	# TODO: 实现失败界面更新
	pass

## 清空统计容器
func _clear_stats_container() -> void:
	if not stats_container:
		return

	for child in stats_container.get_children():
		child.queue_free()

## 添加统计行
func _add_stat_line(text: String) -> void:
	if not stats_container:
		return

	var label = Label.new()
	label.text = text
	stats_container.add_child(label)

## 添加带动画的统计行
func _add_stat_line_animated(text: String, fade_duration: float) -> void:
	if not stats_container:
		return

	var label = Label.new()
	label.text = text
	label.modulate.a = 0.0
	stats_container.add_child(label)

	# 淡入动画
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)

## 数字动画
func _animate_number(label: Label, property: String, from: int, to: int, duration: float, format: String) -> void:
	var tween = create_tween()
	tween.tween_method(func(value: int): label.text = format % value, from, to, duration)

## 更新星级评价
func _update_star_rating(play_time: float) -> void:
	# TODO: 根据时间显示星级（1-3星）
	# 这里需要与UI节点集成
	pass

## 格式化时间
func _format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

## 翻译奖励键
func _translate_reward_key(key: String) -> String:
	match key:
		"completion": return "完成奖励"
		"speed_bonus": return "速度奖励"
		"no_damage": return "无伤奖励"
		"enemies": return "敌人奖励"
		"items": return "道具奖励"
		_: return key

## 按钮回调
func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_next_pressed() -> void:
	next_level_requested.emit()

func _on_menu_pressed() -> void:
	return_to_menu_requested.emit()
