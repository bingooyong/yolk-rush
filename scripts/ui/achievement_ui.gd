extends Control
class_name AchievementUI
## 成就展示UI
## 显示成就列表、进度和解锁动画

## 信号
signal achievement_selected(achievement_id: String)
signal ui_closed()

## 节点引用
@onready var achievement_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/AchievementList
@onready var progress_label: Label = $Panel/MarginContainer/VBox/Header/ProgressLabel
@onready var points_label: Label = $Panel/MarginContainer/VBox/Header/PointsLabel
@onready var filter_all: Button = $Panel/MarginContainer/VBox/FilterBar/AllButton
@onready var filter_unlocked: Button = $Panel/MarginContainer/VBox/FilterBar/UnlockedButton
@onready var filter_locked: Button = $Panel/MarginContainer/VBox/FilterBar/LockedButton
@onready var close_button: Button = $Panel/MarginContainer/VBox/Header/CloseButton

## 成就管理器引用
var achievement_manager: Node = null

## 当前过滤器
enum Filter { ALL, UNLOCKED, LOCKED }
var current_filter: Filter = Filter.ALL

## 成就卡片场景
var achievement_card_scene = null  # 动态加载或创建

func _ready() -> void:
	# 查找成就管理器
	achievement_manager = _find_achievement_manager()

	if not achievement_manager:
		push_warning("[AchievementUI] AchievementManager not found")
		return

	# 连接信号
	if filter_all:
		filter_all.pressed.connect(_on_filter_all)
	if filter_unlocked:
		filter_unlocked.pressed.connect(_on_filter_unlocked)
	if filter_locked:
		filter_locked.pressed.connect(_on_filter_locked)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# 监听成就解锁
	achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

	# 初始化UI
	refresh_ui()

## 查找成就管理器
func _find_achievement_manager() -> Node:
	if has_node("/root/AchievementManager"):
		return get_node("/root/AchievementManager")

	var tree = get_tree()
	if tree and tree.root:
		return tree.root.find_child("AchievementManager", true, false)

	return null

## 刷新UI
func refresh_ui() -> void:
	if not achievement_manager:
		return

	# 更新头部信息
	_update_header()

	# 更新成就列表
	_update_achievement_list()

## 更新头部信息
func _update_header() -> void:
	var completion = achievement_manager.get_completion_percentage()
	var points = achievement_manager.get_total_points()

	if progress_label:
		progress_label.text = "完成度: %.1f%%" % completion

	if points_label:
		points_label.text = "总点数: %d" % points

## 更新成就列表
func _update_achievement_list() -> void:
	if not achievement_list:
		return

	# 清空现有列表
	for child in achievement_list.get_children():
		child.queue_free()

	# 获取成就
	var achievements = achievement_manager.get_all_achievements()

	# 过滤
	var filtered_achievements: Array = []
	for achievement in achievements:
		match current_filter:
			Filter.ALL:
				filtered_achievements.append(achievement)
			Filter.UNLOCKED:
				if achievement.unlocked:
					filtered_achievements.append(achievement)
			Filter.LOCKED:
				if not achievement.unlocked:
					filtered_achievements.append(achievement)

	# 排序：已解锁在前
	filtered_achievements.sort_custom(func(a, b): return a.unlocked and not b.unlocked)

	# 创建卡片
	for achievement in filtered_achievements:
		var card = _create_achievement_card(achievement)
		if card:
			achievement_list.add_child(card)

## 创建成就卡片
func _create_achievement_card(achievement: Dictionary) -> Control:
	# 创建卡片实例
	var card = AchievementCard.new()
	card.set_achievement_data(achievement)
	return card

## 过滤：全部
func _on_filter_all() -> void:
	current_filter = Filter.ALL
	_update_filter_buttons()
	_update_achievement_list()

## 过滤：已解锁
func _on_filter_unlocked() -> void:
	current_filter = Filter.UNLOCKED
	_update_filter_buttons()
	_update_achievement_list()

## 过滤：未解锁
func _on_filter_locked() -> void:
	current_filter = Filter.LOCKED
	_update_filter_buttons()
	_update_achievement_list()

## 更新过滤按钮状态
func _update_filter_buttons() -> void:
	if filter_all:
		filter_all.disabled = (current_filter == Filter.ALL)
	if filter_unlocked:
		filter_unlocked.disabled = (current_filter == Filter.UNLOCKED)
	if filter_locked:
		filter_locked.disabled = (current_filter == Filter.LOCKED)

## 成就解锁回调
func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	# 播放解锁动画
	_play_unlock_animation(achievement_data)

	# 刷新列表
	refresh_ui()

## 播放解锁动画
func _play_unlock_animation(achievement_data: Dictionary) -> void:
	# 创建通知弹窗
	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(400, 150)
	popup.position = Vector2(
		(get_viewport_rect().size.x - 400) / 2,
		50
	)
	add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	popup.add_child(vbox)

	var title = Label.new()
	title.text = "🎉 成就解锁！"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var icon_name = HBoxContainer.new()
	vbox.add_child(icon_name)

	var icon = Label.new()
	icon.text = achievement_data.get("icon", "🏆")
	icon.add_theme_font_size_override("font_size", 32)
	icon_name.add_child(icon)

	var name = Label.new()
	name.text = achievement_data.name
	name.add_theme_font_size_override("font_size", 20)
	icon_name.add_child(name)

	var desc = Label.new()
	desc.text = achievement_data.description
	vbox.add_child(desc)

	var points = Label.new()
	points.text = "+%d 点" % achievement_data.get("points", 0)
	points.modulate = Color.GOLD
	vbox.add_child(points)

	# 3秒后自动消失
	await get_tree().create_timer(3.0).timeout
	popup.queue_free()

## 关闭按钮
func _on_close_pressed() -> void:
	ui_closed.emit()
	hide()

## 显示UI
func show_ui() -> void:
	show()
	refresh_ui()

## 隐藏UI
func hide_ui() -> void:
	hide()
