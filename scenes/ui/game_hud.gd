extends CanvasLayer
## GameHUD - 游戏主界面
## Phase 6: 完整数据绑定 + 动画效果

@onready var health_progress: ProgressBar = %HealthProgress
@onready var shield_progress: ProgressBar = %ShieldProgress
@onready var health_text: Label = %HealthText
@onready var combo_label: Label = %ComboLabel
@onready var combo_timer: Timer = %ComboTimer

@onready var skill_q: ColorRect = %SkillQ
@onready var skill_e: ColorRect = %SkillE
@onready var skill_r: ColorRect = %SkillR
@onready var skill_f: ColorRect = %SkillF

var skill_ui_map: Dictionary = {
	"q": {"ui": null, "cooldown_overlay": null, "label": null},
	"e": {"ui": null, "cooldown_overlay": null, "label": null},
	"r": {"ui": null, "cooldown_overlay": null, "label": null},
	"f": {"ui": null, "cooldown_overlay": null, "label": null}
}

var current_combo: int = 0
var combo_fade_tween: Tween

func _ready() -> void:
	print("[GameHUD] Initializing with data binding")

	# 初始化技能UI映射
	skill_ui_map["q"]["ui"] = skill_q
	skill_ui_map["e"]["ui"] = skill_e
	skill_ui_map["r"]["ui"] = skill_r
	skill_ui_map["f"]["ui"] = skill_f

	# 为每个技能创建冷却遮罩和标签
	for key in skill_ui_map.keys():
		_setup_skill_ui(key)

	# 连接 combo 定时器
	combo_timer.timeout.connect(_on_combo_timeout)

	# 初始化显示
	_reset_ui()

func _setup_skill_ui(key: String) -> void:
	var skill_data = skill_ui_map[key]
	var ui: ColorRect = skill_data["ui"]

	# 创建冷却遮罩（半透明黑色）
	var overlay := ColorRect.new()
	overlay.name = "CooldownOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	ui.add_child(overlay)
	skill_data["cooldown_overlay"] = overlay

	# 创建冷却时间标签
	var label := Label.new()
	label.name = "CooldownLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	ui.add_child(label)
	skill_data["label"] = label

func _reset_ui() -> void:
	health_progress.value = 100
	health_progress.max_value = 100
	shield_progress.value = 0
	shield_progress.max_value = 100
	health_text.text = "100 / 100"
	combo_label.text = ""
	combo_label.modulate.a = 0.0
	current_combo = 0

## 更新血条 - 从 HealthComponent 调用
func update_health(current: float, max_hp: float) -> void:
	var target_value := current

	# 平滑动画
	var tween := create_tween()
	tween.tween_property(health_progress, "value", target_value, 0.3).set_trans(Tween.TRANS_CUBIC)

	# 更新最大值和文本
	health_progress.max_value = max_hp
	health_text.text = "%d / %d" % [int(current), int(max_hp)]

	# 低血量警告（红色闪烁）
	if current / max_hp < 0.3:
		_flash_low_health()

func _flash_low_health() -> void:
	var tween := create_tween()
	tween.set_loops(2)
	tween.tween_property(health_progress, "modulate", Color(1, 0.5, 0.5), 0.2)
	tween.tween_property(health_progress, "modulate", Color.WHITE, 0.2)

## 更新护盾条 - 从 ShieldComponent 调用
func update_shield(current: float, max_shield: float) -> void:
	var target_value := current

	# 平滑动画
	var tween := create_tween()
	tween.tween_property(shield_progress, "value", target_value, 0.2).set_trans(Tween.TRANS_QUAD)

	shield_progress.max_value = max_shield
	shield_progress.visible = current > 0

## 更新技能冷却 - 从 SkillSystem 调用
func update_skill_cooldown(skill_key: String, remaining: float, total: float) -> void:
	if not skill_ui_map.has(skill_key):
		return

	var skill_data = skill_ui_map[skill_key]
	var overlay: ColorRect = skill_data["cooldown_overlay"]
	var label: Label = skill_data["label"]

	if remaining > 0:
		# 显示冷却
		overlay.visible = true
		label.visible = true
		label.text = "%.1f" % remaining

		# 冷却进度（从下到上消失）
		var ratio := remaining / total
		overlay.anchor_top = 1.0 - ratio
	else:
		# 冷却完成
		overlay.visible = false
		label.visible = false
		_flash_skill_ready(skill_key)

func _flash_skill_ready(skill_key: String) -> void:
	## 技能就绪闪光效果
	if not skill_ui_map.has(skill_key):
		return

	var ui: ColorRect = skill_ui_map[skill_key]["ui"]
	var original_color := ui.color

	var tween := create_tween()
	tween.tween_property(ui, "color", Color(1, 1, 0.5), 0.15)  # 黄色闪光
	tween.tween_property(ui, "color", original_color, 0.15)

## 更新 Combo - 从 CombatComponent 调用
func update_combo(combo_count: int) -> void:
	current_combo = combo_count

	if current_combo > 0:
		combo_label.text = "COMBO x%d" % current_combo

		# 淡入 + 放大动画
		if combo_fade_tween:
			combo_fade_tween.kill()

		combo_fade_tween = create_tween()
		combo_fade_tween.set_parallel(true)
		combo_fade_tween.tween_property(combo_label, "modulate:a", 1.0, 0.1)
		combo_fade_tween.tween_property(combo_label, "scale", Vector2.ONE * 1.2, 0.1)
		combo_fade_tween.chain().tween_property(combo_label, "scale", Vector2.ONE, 0.1)

		# 重置定时器
		combo_timer.start(2.0)

		# 高连击特殊颜色
		if current_combo >= 10:
			combo_label.add_theme_color_override("font_color", Color(1, 0.5, 0))  # 橙色
		elif current_combo >= 5:
			combo_label.add_theme_color_override("font_color", Color(1, 1, 0))  # 黄色
		else:
			combo_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		_hide_combo()

func _on_combo_timeout() -> void:
	_hide_combo()

func _hide_combo() -> void:
	if combo_fade_tween:
		combo_fade_tween.kill()

	combo_fade_tween = create_tween()
	combo_fade_tween.tween_property(combo_label, "modulate:a", 0.0, 0.3)
	current_combo = 0

## 显示伤害飘字 - 从 GameManager 调用
func show_damage_number(amount: float, position: Vector3, is_critical: bool = false) -> void:
	# 伤害飘字在 3D 空间，由 GameManager 生成 Label3D
	pass  # 实际实现在 GameManager 中
