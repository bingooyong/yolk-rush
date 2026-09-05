extends Control
class_name VictoryScreen
## 胜利结算界面
## 显示评分、统计和奖励

const UITheme = preload("res://scripts/ui/ui_theme.gd")

## 信号
signal next_level_pressed()
signal retry_pressed()
signal main_menu_pressed()

## 节点引用
@onready var rank_label: Label = $Panel/VBox/RankLabel
@onready var star_container: HBoxContainer = $Panel/VBox/StarContainer
@onready var time_label: Label = $Panel/VBox/Stats/TimeLabel
@onready var coins_label: Label = $Panel/VBox/Stats/CoinsLabel
@onready var enemies_label: Label = $Panel/VBox/Stats/EnemiesLabel
@onready var next_button: Button = $Panel/VBox/Buttons/NextButton
@onready var retry_button: Button = $Panel/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Panel/VBox/Buttons/MenuButton

## 数据
var level_stats: Dictionary = {}
var rank: String = "C"
var stars: int = 1

func _ready() -> void:
	# 连接按钮信号
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	# 初始隐藏
	visible = false
	modulate.a = 0.0

## 显示结算界面
func show_victory(stats: Dictionary) -> void:
	level_stats = stats

	# 计算评分
	_calculate_rank()

	# 更新UI
	_update_display()

	# 显示动画
	visible = true
	_animate_show()

## 计算评分
func _calculate_rank() -> void:
	var time = level_stats.get("play_time", 0.0)
	var coins_collected = level_stats.get("items_collected", 0)
	var damage_taken = level_stats.get("damage_taken", 0)

	# 评分逻辑
	var score = 0

	# 时间评分（越快越好）
	if time < 60:
		score += 40
	elif time < 120:
		score += 30
	elif time < 180:
		score += 20
	else:
		score += 10

	# 收集评分
	score += coins_collected * 5

	# 生存评分（受伤越少越好）
	if damage_taken == 0:
		score += 40
	elif damage_taken < 30:
		score += 30
	elif damage_taken < 60:
		score += 20
	else:
		score += 10

	# 根据分数确定评级
	if score >= 90:
		rank = "S"
		stars = 3
	elif score >= 75:
		rank = "A"
		stars = 3
	elif score >= 60:
		rank = "B"
		stars = 2
	elif score >= 45:
		rank = "C"
		stars = 2
	else:
		rank = "D"
		stars = 1

## 更新显示
func _update_display() -> void:
	# 评级
	if rank_label:
		rank_label.text = rank
		rank_label.modulate = UITheme.get_rank_color(rank)

	# 星级
	_update_stars()

	# 统计
	if time_label:
		var minutes = int(level_stats.get("play_time", 0.0)) / 60
		var seconds = int(level_stats.get("play_time", 0.0)) % 60
		time_label.text = "时间: %02d:%02d" % [minutes, seconds]

	if coins_label:
		coins_label.text = "金币: %d" % level_stats.get("items_collected", 0)

	if enemies_label:
		enemies_label.text = "击败: %d" % level_stats.get("enemies_defeated", 0)

## 更新星级显示
func _update_stars() -> void:
	if not star_container:
		return

	# 清空现有星星
	for child in star_container.get_children():
		child.queue_free()

	# 创建新星星
	for i in range(3):
		var star = Label.new()
		star.text = "★" if i < stars else "☆"
		star.add_theme_font_size_override("font_size", 48)
		star.modulate = UITheme.Colors.PRIMARY if i < stars else UITheme.Colors.TEXT_DISABLED
		star_container.add_child(star)

## 显示动画
func _animate_show() -> void:
	# 淡入
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# 依次显示元素
	await tween.finished
	_animate_rank()
	await get_tree().create_timer(0.3).timeout
	_animate_stars()
	await get_tree().create_timer(0.5).timeout
	_animate_stats()

## 评级动画
func _animate_rank() -> void:
	if not rank_label:
		return

	rank_label.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(rank_label, "scale", Vector2.ONE, 0.6)

	# 播放音效
	_play_sound("rank_reveal")

## 星级动画
func _animate_stars() -> void:
	if not star_container:
		return

	var star_children = star_container.get_children()
	for i in range(star_children.size()):
		var star = star_children[i]
		star.scale = Vector2.ZERO

		await get_tree().create_timer(0.15).timeout

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(star, "scale", Vector2.ONE, 0.3)

		if i < stars:
			_play_sound("star_appear")

## 统计动画
func _animate_stats() -> void:
	# 数字递增动画
	if time_label:
		_animate_number_count(time_label, 0, level_stats.get("play_time", 0.0))

	if coins_label:
		_animate_number_count(coins_label, 0, level_stats.get("items_collected", 0))

	if enemies_label:
		_animate_number_count(enemies_label, 0, level_stats.get("enemies_defeated", 0))

## 数字递增动画
func _animate_number_count(label: Label, from: float, to: float) -> void:
	var duration = 1.0
	var elapsed = 0.0

	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var progress = min(elapsed / duration, 1.0)
		var current = lerp(from, to, progress)

		# 更新文字（保持前缀）
		var text = label.text
		var prefix = text.split(":")[0] + ": "
		label.text = prefix + str(int(current))

## 按钮回调
func _on_next_pressed() -> void:
	_play_sound("ui_click")
	next_level_pressed.emit()
	_hide_screen()

func _on_retry_pressed() -> void:
	_play_sound("ui_click")
	retry_pressed.emit()
	_hide_screen()

func _on_menu_pressed() -> void:
	_play_sound("ui_click")
	main_menu_pressed.emit()
	_hide_screen()

## 隐藏界面
func _hide_screen() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	visible = false

## 播放音效
func _play_sound(sound_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)
