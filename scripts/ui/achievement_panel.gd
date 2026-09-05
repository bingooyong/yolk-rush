extends Panel
class_name AchievementPanel
## 成就面板 UI

const AchievementClass = preload("res://scripts/achievement/achievement.gd")

# UI 节点
@onready var achievement_list: VBoxContainer = $VBox/ScrollContainer/AchievementList
@onready var filter_tabs: TabBar = $VBox/TopBar/FilterTabs
@onready var progress_label: Label = $VBox/TopBar/ProgressLabel
@onready var close_button: Button = $VBox/TopBar/CloseButton

# GameManager 引用
var game_manager = null

# 当前过滤器
var current_filter: int = -1  # -1 = 全部

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	if filter_tabs:
		filter_tabs.tab_changed.connect(_on_filter_changed)
		_setup_filter_tabs()

	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_initialize()
		else:
			game_manager.game_initialized.connect(_initialize)

func _initialize() -> void:
	# 连接成就系统信号
	game_manager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
	game_manager.achievement_system.progress_updated.connect(_on_progress_updated)

	# 初始刷新
	refresh()

## 设置过滤标签
func _setup_filter_tabs() -> void:
	filter_tabs.clear_tabs()
	filter_tabs.add_tab("全部")
	filter_tabs.add_tab("击杀")
	filter_tabs.add_tab("收集")
	filter_tabs.add_tab("等级")
	filter_tabs.add_tab("战斗")
	filter_tabs.add_tab("探索")
	filter_tabs.add_tab("社交")

## 刷新显示
func refresh() -> void:
	if not game_manager or not game_manager.is_initialized:
		return

	# 更新进度标签
	_update_progress_label()

	# 重新创建成就列表
	_create_achievement_list()

## 更新进度标签
func _update_progress_label() -> void:
	if progress_label:
		var unlocked = game_manager.achievement_system.get_unlocked_count()
		var total = game_manager.achievement_system.get_total_count()
		var percentage = (float(unlocked) / float(total)) * 100.0 if total > 0 else 0.0
		progress_label.text = "成就进度: %d/%d (%.1f%%)" % [unlocked, total, percentage]

## 创建成就列表
func _create_achievement_list() -> void:
	if not achievement_list:
		return

	# 清空现有列表
	for child in achievement_list.get_children():
		child.queue_free()

	# 获取所有成就
	var achievements = game_manager.achievement_system.get_all_achievements()

	# 按类型过滤
	if current_filter >= 0:
		achievements = achievements.filter(func(ach):
			return ach.achievement_type == current_filter
		)

	# 排序：未解锁的在前，已解锁的在后
	achievements.sort_custom(func(a, b):
		if a.is_unlocked != b.is_unlocked:
			return not a.is_unlocked  # 未解锁的在前
		return a.title < b.title  # 同样状态按名称排序
	)

	# 创建成就项
	for achievement in achievements:
		var item = _create_achievement_item(achievement)
		achievement_list.add_child(item)

## 创建单个成就项
func _create_achievement_item(achievement) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 图标占位
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.color = _get_rarity_color(achievement.rarity)
	hbox.add_child(icon)

	# 信息区域
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# 标题
	var title_label = Label.new()
	title_label.text = achievement.title
	title_label.add_theme_font_size_override("font_size", 14)
	if achievement.is_unlocked:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(title_label)

	# 描述
	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc_label)

	# 进度条（如果需要）
	if achievement.target_value > 1:
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = achievement.target_value
		progress_bar.value = achievement.current_progress
		progress_bar.show_percentage = true
		vbox.add_child(progress_bar)

		var progress_text = Label.new()
		progress_text.text = "%d / %d" % [achievement.current_progress, achievement.target_value]
		progress_text.add_theme_font_size_override("font_size", 9)
		vbox.add_child(progress_text)

	# 状态标记
	var status_label = Label.new()
	if achievement.is_unlocked:
		status_label.text = "✓ 已解锁"
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		status_label.text = "未解锁"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	status_label.add_theme_font_size_override("font_size", 10)
	hbox.add_child(status_label)

	# 奖励信息
	if achievement.reward_gold > 0 or achievement.reward_exp > 0:
		var reward_label = Label.new()
		var rewards = []
		if achievement.reward_gold > 0:
			rewards.append("%d金币" % achievement.reward_gold)
		if achievement.reward_exp > 0:
			rewards.append("%d经验" % achievement.reward_exp)
		reward_label.text = "奖励: " + ", ".join(rewards)
		reward_label.add_theme_font_size_override("font_size", 9)
		reward_label.modulate = Color(1.0, 0.9, 0.5)
		vbox.add_child(reward_label)

	return panel

## 获取稀有度颜色
func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(0.8, 0.8, 0.8)  # COMMON
		1: return Color(0.3, 1.0, 0.3)  # UNCOMMON
		2: return Color(0.3, 0.5, 1.0)  # RARE
		3: return Color(0.8, 0.3, 1.0)  # EPIC
		4: return Color(1.0, 0.6, 0.0)  # LEGENDARY
		_: return Color.WHITE

## 过滤器改变
func _on_filter_changed(tab: int) -> void:
	current_filter = tab - 1  # -1 = 全部
	refresh()

## 关闭按钮
func _on_close_button_pressed() -> void:
	visible = false

## 信号处理
func _on_achievement_unlocked(achievement_id: String) -> void:
	refresh()
	# 显示解锁通知
	var achievement = game_manager.achievement_system.get_achievement_info(achievement_id)
	if achievement:
		print("[AchievementPanel] Achievement unlocked: %s" % achievement.title)

func _on_progress_updated(achievement_id: String, current: int, target: int) -> void:
	# 只刷新特定成就项而不是整个列表（优化）
	refresh()

## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
