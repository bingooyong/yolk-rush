extends CanvasLayer
class_name GameHUD
## 游戏战斗 HUD
## Phase 6: UI 系统

@onready var health_bar: ProgressBar = %HealthBar
@onready var shield_bar: ProgressBar = %ShieldBar
@onready var health_text: Label = %HealthText

@onready var skill_q: TextureRect = %SkillQ
@onready var skill_e: TextureRect = %SkillE
@onready var skill_r: TextureRect = %SkillR
@onready var skill_f: TextureRect = %SkillF

@onready var combo_label: Label = %ComboLabel
@onready var combo_timer: Timer = %ComboTimer

var current_combo := 0

func _ready() -> void:
	combo_label.visible = false
	combo_timer.timeout.connect(_on_combo_timeout)

## 更新血量显示
func update_health(current: float, max_value: float, shield: float, max_shield: float) -> void:
	if health_bar:
		health_bar.max_value = max_value
		health_bar.value = current

		# 平滑过渡
		var tween := create_tween()
		tween.tween_property(health_bar, "value", current, 0.2)

	if shield_bar:
		shield_bar.max_value = max_shield if max_shield > 0 else 100
		shield_bar.value = shield
		shield_bar.visible = shield > 0

	if health_text:
		health_text.text = "%d / %d" % [int(current), int(max_value)]

## 更新技能冷却
func update_skill_cooldown(skill_key: String, remaining: float, total: float) -> void:
	var skill_ui: TextureRect = null
	match skill_key:
		"Q": skill_ui = skill_q
		"E": skill_ui = skill_e
		"R": skill_ui = skill_r
		"F": skill_ui = skill_f

	if not skill_ui:
		return

	# 冷却遮罩
	var cooldown_overlay := skill_ui.get_node_or_null("CooldownOverlay") as ColorRect
	if not cooldown_overlay:
		cooldown_overlay = ColorRect.new()
		cooldown_overlay.name = "CooldownOverlay"
		cooldown_overlay.color = Color(0, 0, 0, 0.6)
		cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_ui.add_child(cooldown_overlay)
		cooldown_overlay.anchors_preset = Control.PRESET_FULL_RECT

	if remaining > 0:
		var progress := 1.0 - (remaining / total)
		cooldown_overlay.visible = true
		# 从下往上收缩
		cooldown_overlay.anchor_top = progress
	else:
		cooldown_overlay.visible = false

## 增加连击数
func add_combo() -> void:
	current_combo += 1
	combo_label.text = "x%d COMBO!" % current_combo
	combo_label.visible = true

	# 重置计时器
	combo_timer.start(2.0)

	# 动画效果
	var tween := create_tween()
	tween.set_parallel(true)
	combo_label.scale = Vector2.ONE * 1.5
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

	# 颜色变化
	if current_combo >= 10:
		combo_label.add_theme_color_override("font_color", Color.GOLD)
	elif current_combo >= 5:
		combo_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		combo_label.add_theme_color_override("font_color", Color.WHITE)

## 重置连击
func reset_combo() -> void:
	current_combo = 0
	combo_label.visible = false

func _on_combo_timeout() -> void:
	reset_combo()

## 显示伤害飘字
func show_damage_number(amount: float, position: Vector2, is_crit: bool = false) -> void:
	var damage_label := Label.new()
	damage_label.text = "-%d" % int(amount)
	damage_label.add_theme_font_size_override("font_size", 24 if not is_crit else 36)

	if is_crit:
		damage_label.text = "CRIT! " + damage_label.text
		damage_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		damage_label.add_theme_color_override("font_color", Color.RED)

	add_child(damage_label)
	damage_label.global_position = position

	# 飘字动画
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "global_position:y", position.y - 50, 0.8)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	await tween.finished
	damage_label.queue_free()

## 显示治疗飘字
func show_heal_number(amount: float, position: Vector2) -> void:
	var heal_label := Label.new()
	heal_label.text = "+%d" % int(amount)
	heal_label.add_theme_font_size_override("font_size", 24)
	heal_label.add_theme_color_override("font_color", Color.GREEN)

	add_child(heal_label)
	heal_label.global_position = position

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_label, "global_position:y", position.y - 50, 0.8)
	tween.tween_property(heal_label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	await tween.finished
	heal_label.queue_free()
