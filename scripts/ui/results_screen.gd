extends Control
class_name ResultsScreen
## 结算界面

signal restart_pressed()
signal next_level_pressed()
signal return_to_menu_pressed()

## UI 组件
@onready var result_title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var score_label: Label = $Panel/MarginContainer/VBoxContainer/Stats/Score
@onready var time_label: Label = $Panel/MarginContainer/VBoxContainer/Stats/Time
@onready var rating_label: Label = $Panel/MarginContainer/VBoxContainer/Rating
@onready var stars_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/Stars
@onready var stats_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/DetailedStats
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/RestartButton
@onready var next_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/NextButton
@onready var menu_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/MenuButton

## 结果数据
var results: Dictionary = {}
var is_victory: bool = false

func _ready() -> void:
	# 连接按钮信号
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	# 从 GameFlowManager 获取结果
	_load_results()

## 加载结果
func _load_results() -> void:
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if not flow_manager or not flow_manager.current_session:
		return

	var session = flow_manager.current_session
	results = session.get_session_stats()
	is_victory = session.is_completed and not session.fail_reason

	results["is_victory"] = is_victory
	results["play_time"] = session.elapsed_time
	results["rating"] = session.get_rating()
	results["stars"] = session.get_stars()
	results["fail_reason"] = session.fail_reason

	_display_results()

## 显示结果
func _display_results() -> void:
	# 标题
	if result_title:
		if is_victory:
			result_title.text = "🎉 VICTORY! 🎉"
			result_title.modulate = Color.GREEN
		else:
			result_title.text = "💀 GAME OVER 💀"
			result_title.modulate = Color.RED

	# 分数
	if score_label:
		var score = results.get("score", 0)
		score_label.text = "Score: %d" % score

	# 时间
	if time_label:
		var time = results.get("play_time", 0.0)
		time_label.text = "Time: %.1fs" % time

	# 评级
	if rating_label:
		var rating = results.get("rating", "D")
		rating_label.text = "Rating: %s" % rating

		# 颜色
		match rating:
			"S":
				rating_label.modulate = Color.GOLD
			"A":
				rating_label.modulate = Color.GREEN
			"B":
				rating_label.modulate = Color.CYAN
			"C":
				rating_label.modulate = Color.YELLOW
			_:
				rating_label.modulate = Color.GRAY

	# 星级
	if stars_container:
		for child in stars_container.get_children():
			child.queue_free()

		var stars = results.get("stars", 0)
		for i in range(3):
			var star_label = Label.new()
			star_label.add_theme_font_size_override("font_size", 32)
			if i < stars:
				star_label.text = "⭐"
			else:
				star_label.text = "☆"
			stars_container.add_child(star_label)

	# 详细统计
	if stats_container:
		_display_detailed_stats()

	# 按钮状态
	_update_buttons()

## 显示详细统计
func _display_detailed_stats() -> void:
	if not stats_container:
		return

	# 清空现有统计
	for child in stats_container.get_children():
		if child.name.begins_with("Stat"):
			child.queue_free()

	# 添加统计项
	_add_stat("Obstacles Hit", str(results.get("obstacles_hit", 0)))
	_add_stat("Power-ups Collected", str(results.get("powerups_collected", 0)))
	_add_stat("Distance Traveled", "%.1fm" % results.get("distance_traveled", 0.0))
	_add_stat("Max Combo", str(results.get("max_combo", 0)))
	_add_stat("Checkpoints", str(results.get("checkpoints_reached", 0)))

	# 失败原因
	if not is_victory:
		var fail_reason = results.get("fail_reason", "Unknown")
		_add_stat("Failed", fail_reason, Color.RED)

## 添加统计项
func _add_stat(label_text: String, value_text: String, color: Color = Color.WHITE) -> void:
	var hbox = HBoxContainer.new()
	hbox.name = "Stat_" + label_text.replace(" ", "_")

	var label = Label.new()
	label.text = label_text + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.modulate = color
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value)

	stats_container.add_child(hbox)

## 更新按钮状态
func _update_buttons() -> void:
	# 下一关按钮
	if next_button:
		# 只有胜利才能进入下一关
		next_button.visible = is_victory
		next_button.disabled = not _has_next_level()

## 是否有下一关
func _has_next_level() -> bool:
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if not flow_manager:
		return false

	var current_id = flow_manager.current_level_id
	if current_id.is_empty():
		return false

	# 检查下一关是否存在
	if current_id.begins_with("level_"):
		var num = current_id.substr(6).to_int()
		var next_id = "level_%d" % (num + 1)

		# 检查是否解锁
		if flow_manager.save_system:
			return flow_manager.save_system.is_level_unlocked(next_id)

	return false

## === 信号回调 ===

func _on_restart_pressed() -> void:
	restart_pressed.emit()

	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager:
		flow_manager.restart_level()

func _on_next_pressed() -> void:
	next_level_pressed.emit()

	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager:
		flow_manager.next_level()

func _on_menu_pressed() -> void:
	return_to_menu_pressed.emit()

	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager:
		flow_manager.return_to_main_menu()

## === 动画效果 ===

func _process(delta: float) -> void:
	# 标题闪烁动画
	if result_title and is_victory:
		var time = Time.get_ticks_msec() / 1000.0
		var alpha = 0.7 + sin(time * 3.0) * 0.3
		result_title.modulate.a = alpha

## 显示结果动画
func show_results_animated() -> void:
	# 淡入动画
	modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# 星星依次显示
	if stars_container:
		var stars = results.get("stars", 0)
		for i in range(stars):
			await get_tree().create_timer(0.3).timeout
			# 播放星星特效
