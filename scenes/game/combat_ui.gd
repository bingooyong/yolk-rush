extends Control
## 战斗原型 UI：显示玩家状态和调试信息

@onready var health_label: Label = $Panel/VBox/HealthLabel
@onready var combo_label: Label = $Panel/VBox/ComboLabel
@onready var state_label: Label = $Panel/VBox/StateLabel
@onready var debug_label: Label = $Panel/VBox/DebugLabel

var player: CharacterBody3D

func _ready() -> void:
	# 创建 UI 元素
	_create_ui()

func _create_ui() -> void:
	# 主面板
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(10, 10)
	panel.size = Vector2(300, 150)
	add_child(panel)

	# 垂直布局
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.position = Vector2(10, 10)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# 生命值标签
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: 100 / 100"
	vbox.add_child(health_label)

	# 连击标签
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = "Combo: x0"
	vbox.add_child(combo_label)

	# 状态标签
	state_label = Label.new()
	state_label.name = "StateLabel"
	state_label.text = "State: IDLE"
	vbox.add_child(state_label)

	# 调试标签
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "Press J/K to attack"
	debug_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(debug_label)

func set_player(p: CharacterBody3D) -> void:
	player = p

	# 连接战斗系统信号
	if player and player.has_node("CombatSystem"):
		var combat_system = player.get_node("CombatSystem")
		combat_system.combo_increased.connect(_on_combo_increased)
		combat_system.combo_broken.connect(_on_combo_broken)
		combat_system.attack_hit.connect(_on_attack_hit)

	# 连接动画控制器信号
	if player and player.has_node("AnimationController"):
		var anim_controller = player.get_node("AnimationController")
		anim_controller.animation_changed.connect(_on_animation_changed)

func _process(_delta: float) -> void:
	if not player:
		return

	# 更新生命值
	if player.has_method("get_health"):
		var current_hp := player.get_health()
		var max_hp := 100.0
		health_label.text = "HP: %.0f / %.0f" % [current_hp, max_hp]

		# 生命值颜色
		var hp_percent := current_hp / max_hp
		if hp_percent > 0.5:
			health_label.modulate = Color.WHITE
		elif hp_percent > 0.25:
			health_label.modulate = Color.YELLOW
		else:
			health_label.modulate = Color.RED

	# 更新状态
	if player.has_node("AnimationController"):
		var anim_controller = player.get_node("AnimationController")
		if anim_controller.has_method("get_state_name"):
			state_label.text = "State: %s" % anim_controller.get_state_name()

func _on_combo_increased(combo_count: int) -> void:
	combo_label.text = "Combo: x%d" % combo_count
	combo_label.modulate = Color.YELLOW

	# 闪烁效果
	var tween := create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.1)

func _on_combo_broken() -> void:
	combo_label.text = "Combo: x0"
	combo_label.modulate = Color.WHITE

func _on_attack_hit(target: Node, damage: float) -> void:
	debug_label.text = "Hit %s for %.0f damage!" % [target.name, damage]
	debug_label.modulate = Color.GREEN

	await get_tree().create_timer(1.0).timeout
	debug_label.text = "Press J/K to attack"
	debug_label.modulate = Color(0.7, 0.7, 0.7)

func _on_animation_changed(from_state: int, to_state: int) -> void:
	# 状态变化的视觉反馈
	var tween := create_tween()
	tween.tween_property(state_label, "modulate", Color.CYAN, 0.1)
	tween.tween_property(state_label, "modulate", Color.WHITE, 0.2)
