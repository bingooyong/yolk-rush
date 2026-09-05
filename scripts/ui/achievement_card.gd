extends PanelContainer
class_name AchievementCard
## 成就卡片组件
## 显示单个成就的详细信息

## 信号
signal card_clicked(achievement_id: String)

## 成就数据
var achievement_data: Dictionary = {}

## 颜色映射
const TIER_COLORS = {
	"bronze": Color("#CD7F32"),
	"silver": Color("#C0C0C0"),
	"gold": Color("#FFD700"),
	"platinum": Color("#E5E4E2")
}

## 节点引用
var icon_label: Label
var name_label: Label
var desc_label: Label
var tier_label: Label
var points_label: Label
var status_label: Label
var progress_bar: ProgressBar

func _ready() -> void:
	custom_minimum_size = Vector2(0, 80)

	# 创建UI结构
	_create_ui()

	# 如果已有数据，显示
	if not achievement_data.is_empty():
		_update_display()

## 创建UI结构
func _create_ui() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# 图标
	icon_label = Label.new()
	icon_label.custom_minimum_size = Vector2(48, 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	hbox.add_child(icon_label)

	# 信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	# 名称和等级
	var name_tier_hbox = HBoxContainer.new()
	name_tier_hbox.add_theme_constant_override("separation", 10)
	info_vbox.add_child(name_tier_hbox)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	name_tier_hbox.add_child(name_label)

	tier_label = Label.new()
	tier_label.add_theme_font_size_override("font_size", 12)
	name_tier_hbox.add_child(tier_label)

	# 描述
	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# 进度条（如果适用）
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	progress_bar.visible = false
	info_vbox.add_child(progress_bar)

	# 右侧区域
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(80, 0)
	right_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(right_vbox)

	# 点数
	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 14)
	right_vbox.add_child(points_label)

	# 状态
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	right_vbox.add_child(status_label)

## 设置成就数据
func set_achievement_data(data: Dictionary) -> void:
	achievement_data = data
	if is_node_ready():
		_update_display()

## 更新显示
func _update_display() -> void:
	if achievement_data.is_empty():
		return

	# 图标
	icon_label.text = achievement_data.get("icon", "🏆")

	# 名称
	name_label.text = achievement_data.get("name", "未知成就")

	# 等级
	var tier = achievement_data.get("tier", "bronze")
	var tier_name = _get_tier_name(tier)
	tier_label.text = "[%s]" % tier_name

	if tier in TIER_COLORS:
		tier_label.modulate = TIER_COLORS[tier]

	# 描述
	desc_label.text = achievement_data.get("description", "")

	# 点数
	var points = achievement_data.get("points", 0)
	points_label.text = "%d 点" % points

	# 解锁状态
	var unlocked = achievement_data.get("unlocked", false)
	if unlocked:
		status_label.text = "✓"
		status_label.modulate = Color.GREEN
		name_label.modulate = TIER_COLORS.get(tier, Color.WHITE)

		# 已解锁，隐藏进度条
		progress_bar.visible = false
	else:
		status_label.text = "🔒"
		status_label.modulate = Color.GRAY
		name_label.modulate = Color.DIM_GRAY
		desc_label.modulate = Color.GRAY

		# 显示进度（如果有）
		_update_progress()

## 更新进度
func _update_progress() -> void:
	var progress = achievement_data.get("progress", {})
	if progress.is_empty():
		progress_bar.visible = false
		return

	var current = progress.get("current", 0)
	var required = progress.get("required", 1)

	if required > 1:
		progress_bar.visible = true
		progress_bar.max_value = required
		progress_bar.value = current

		# 添加进度文本
		var progress_text = "%d / %d" % [current, required]
		if not progress_bar.has_node("ProgressLabel"):
			var label = Label.new()
			label.name = "ProgressLabel"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 10)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			progress_bar.add_child(label)

		var label = progress_bar.get_node("ProgressLabel")
		label.text = progress_text
		label.size = progress_bar.size
	else:
		progress_bar.visible = false

## 获取等级名称
func _get_tier_name(tier: String) -> String:
	match tier:
		"bronze": return "青铜"
		"silver": return "白银"
		"gold": return "黄金"
		"platinum": return "铂金"
		_: return "未知"

## 鼠标进入
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(achievement_data.get("id", ""))

			# 点击反馈
			modulate = Color(0.9, 0.9, 0.9)
			await get_tree().create_timer(0.1).timeout
			modulate = Color.WHITE
