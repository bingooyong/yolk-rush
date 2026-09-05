extends Control
class_name SkillCooldownDisplay
## 技能冷却显示组件
## 显示技能图标、冷却遮罩和倒计时

## 配置
@export var skill_icon: Texture2D = null
@export var cooldown_time: float = 10.0

## 节点引用
@onready var icon_rect: TextureRect = $IconRect
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel
@onready var available_effect: Control = $AvailableEffect

## 状态
var remaining_time: float = 0.0
var is_cooling_down: bool = false

func _ready() -> void:
	# 设置图标
	if skill_icon and icon_rect:
		icon_rect.texture = skill_icon

	# 初始状态：可用
	_set_available()

func _process(delta: float) -> void:
	if not is_cooling_down:
		return

	remaining_time -= delta

	if remaining_time <= 0.0:
		_on_cooldown_complete()
	else:
		_update_cooldown_display()

## 开始冷却
func start_cooldown(duration: float = 0.0) -> void:
	if duration > 0.0:
		cooldown_time = duration

	remaining_time = cooldown_time
	is_cooling_down = true

	# 显示冷却遮罩
	if cooldown_overlay:
		cooldown_overlay.visible = true
		cooldown_overlay.modulate.a = 0.7

	# 显示倒计时
	if cooldown_label:
		cooldown_label.visible = true

	# 隐藏可用特效
	if available_effect:
		available_effect.visible = false

## 更新冷却显示
func _update_cooldown_display() -> void:
	var progress = 1.0 - (remaining_time / cooldown_time)

	# 更新遮罩高度（从下往上消退）
	if cooldown_overlay:
		var overlay_size = cooldown_overlay.size
		cooldown_overlay.size.y = overlay_size.y * (1.0 - progress)
		cooldown_overlay.position.y = overlay_size.y * progress

	# 更新倒计时文字
	if cooldown_label:
		cooldown_label.text = "%.1f" % remaining_time

## 冷却完成
func _on_cooldown_complete() -> void:
	is_cooling_down = false
	remaining_time = 0.0

	_set_available()

	# 播放可用音效
	_play_available_sound()

## 设置为可用状态
func _set_available() -> void:
	# 隐藏冷却遮罩
	if cooldown_overlay:
		cooldown_overlay.visible = false

	# 隐藏倒计时
	if cooldown_label:
		cooldown_label.visible = false

	# 显示可用特效
	if available_effect:
		available_effect.visible = true
		_animate_available_effect()

## 可用特效动画
func _animate_available_effect() -> void:
	if not available_effect:
		return

	# 发光脉冲动画
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(available_effect, "modulate:a", 0.8, 0.8)
	tween.tween_property(available_effect, "modulate:a", 0.3, 0.8)

## 播放可用音效
func _play_available_sound() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound("skill_ready")

## 是否可用
func is_available() -> bool:
	return not is_cooling_down

## 获取冷却进度（0-1）
func get_cooldown_progress() -> float:
	if not is_cooling_down:
		return 1.0
	return 1.0 - (remaining_time / cooldown_time)
