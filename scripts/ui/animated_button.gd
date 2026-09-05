extends Button
class_name AnimatedButton
## 增强的动画按钮组件
## 提供悬停、点击、禁用等状态的平滑动画效果

## 动画配置
@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95
@export var animation_duration: float = 0.15

## 音效配置
@export var hover_sound: String = "ui_hover"
@export var click_sound: String = "ui_click"

## 状态标记
var is_hovered: bool = false
var is_pressed_down: bool = false
var tween: Tween = null

func _ready() -> void:
	# 连接信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)

	# 初始化缩放
	pivot_offset = size / 2.0

func _on_mouse_entered() -> void:
	if disabled:
		return

	is_hovered = true
	_animate_hover()

	# 播放悬停音效
	_play_sound(hover_sound)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_pressed_down:
		_animate_normal()

func _on_button_down() -> void:
	if disabled:
		return

	is_pressed_down = true
	_animate_press()

func _on_button_up() -> void:
	is_pressed_down = false
	if is_hovered:
		_animate_hover()
	else:
		_animate_normal()

func _on_pressed() -> void:
	# 播放点击音效
	_play_sound(click_sound)

	# 点击反馈动画
	_animate_click_feedback()

## 悬停动画
func _animate_hover() -> void:
	_stop_tween()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale), animation_duration)

## 正常状态动画
func _animate_normal() -> void:
	_stop_tween()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), animation_duration)

## 按下动画
func _animate_press() -> void:
	_stop_tween()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(press_scale, press_scale), animation_duration * 0.5)

## 点击反馈动画
func _animate_click_feedback() -> void:
	# 轻微的弹跳效果
	_stop_tween()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(press_scale, press_scale), animation_duration * 0.3)
	tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale), animation_duration * 0.7)

## 停止当前动画
func _stop_tween() -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = null

## 播放音效
func _play_sound(sound_name: String) -> void:
	if sound_name.is_empty():
		return

	# 查找AudioManager
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

## 设置禁用状态（带动画）
func set_disabled_animated(value: bool) -> void:
	disabled = value

	var target_modulate = Color.WHITE if not value else Color(0.5, 0.5, 0.5)

	_stop_tween()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", target_modulate, animation_duration)

	if value:
		_animate_normal()
