extends Control
class_name CombatLog
## 战斗日志组件 - 显示战斗消息

@export var max_messages: int = 50
@export var auto_scroll: bool = true
@export var message_fade_time: float = 0.3

var scroll_container: ScrollContainer
var message_list: VBoxContainer
var messages: Array[Dictionary] = []

# 消息类型颜色
const COLOR_DAMAGE = Color(1.0, 0.5, 0.5)
const COLOR_CRITICAL = Color(1.0, 0.2, 0.2)
const COLOR_HEAL = Color(0.5, 1.0, 0.5)
const COLOR_DEATH = Color(0.8, 0.2, 0.2)
const COLOR_INFO = Color(0.8, 0.8, 0.8)
const COLOR_SYSTEM = Color(0.5, 0.8, 1.0)

func _ready() -> void:
	custom_minimum_size = Vector2(300, 200)
	_setup_ui()

func _setup_ui() -> void:
	# 创建背景
	var bg_panel = Panel.new()
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	add_child(bg_panel)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bg_panel.add_theme_stylebox_override("panel", bg_style)

	# 标题
	var title = Label.new()
	title.text = "Combat Log"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.position = Vector2(10, 5)
	bg_panel.add_child(title)

	# 滚动容器
	scroll_container = ScrollContainer.new()
	scroll_container.anchor_left = 0.0
	scroll_container.anchor_right = 1.0
	scroll_container.anchor_top = 0.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_left = 5
	scroll_container.offset_right = -5
	scroll_container.offset_top = 30
	scroll_container.offset_bottom = -5
	scroll_container.follow_focus = true
	bg_panel.add_child(scroll_container)

	# 消息列表容器
	message_list = VBoxContainer.new()
	message_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_list.add_theme_constant_override("separation", 2)
	scroll_container.add_child(message_list)

func add_message(text: String, color: Color = COLOR_INFO) -> void:
	var message_data = {
		"text": text,
		"color": color,
		"timestamp": Time.get_ticks_msec()
	}

	messages.append(message_data)

	# 限制消息数量
	if messages.size() > max_messages:
		_remove_oldest_message()

	_create_message_label(message_data)

	# 自动滚动到底部
	if auto_scroll:
		await get_tree().process_frame
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

func _create_message_label(message_data: Dictionary) -> void:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(0, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 格式化消息
	var formatted_text = "[color=#%s]%s[/color]" % [message_data.color.to_html(false), message_data.text]
	label.text = formatted_text

	# 淡入动画
	label.modulate.a = 0.0
	message_list.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, message_fade_time)

func _remove_oldest_message() -> void:
	if message_list.get_child_count() > 0:
		var oldest = message_list.get_child(0)
		oldest.queue_free()

	if messages.size() > 0:
		messages.remove_at(0)

func clear_log() -> void:
	for child in message_list.get_children():
		child.queue_free()
	messages.clear()

## 便捷方法 - 添加不同类型的消息

func log_damage(attacker: String, target: String, damage: float) -> void:
	add_message("%s dealt %d damage to %s" % [attacker, int(damage), target], COLOR_DAMAGE)

func log_critical(attacker: String, target: String, damage: float) -> void:
	add_message("%s CRITICALLY hit %s for %d damage!" % [attacker, target, int(damage)], COLOR_CRITICAL)

func log_heal(healer: String, target: String, amount: float) -> void:
	add_message("%s healed %s for %d HP" % [healer, target, int(amount)], COLOR_HEAL)

func log_death(entity: String) -> void:
	add_message("%s has been defeated!" % entity, COLOR_DEATH)

func log_miss(attacker: String, target: String) -> void:
	add_message("%s's attack missed %s" % [attacker, target], COLOR_INFO)

func log_system(text: String) -> void:
	add_message("[System] %s" % text, COLOR_SYSTEM)

func log_info(text: String) -> void:
	add_message(text, COLOR_INFO)
