class_name TouchHud
extends CanvasLayer
## Minimal touch stick (x=yaw, y=throttle) + jump + hide Visual.

var _match: Node
var _player_input: PlayerInput
var _stick_active: bool = false
var _stick_radius: float = 64.0
var _stick_base: Control
var _stick_knob: Control
var _jump_btn: Button
var _hide_btn: Button
var _hint: Label

func bind_match(m: Node) -> void:
	_match = m
	if m != null and m.has_method("get_player_input"):
		_player_input = m.call("get_player_input") as PlayerInput
	_ensure_ui()

func _ready() -> void:
	_ensure_ui()

func _ensure_ui() -> void:
	if _stick_base != null:
		return
	layer = 10

	_hint = Label.new()
	_hint.text = "W/A/D/Space · stick=yaw/throttle · Jump · Hide Visual"
	_hint.position = Vector2(16, 12)
	add_child(_hint)

	_stick_base = _make_panel(Vector2(120, 120), Color(0.1, 0.1, 0.15, 0.35))
	_stick_base.position = Vector2(48, 520)
	_stick_base.name = "StickBase"
	add_child(_stick_base)

	_stick_knob = _make_panel(Vector2(48, 48), Color(0.95, 0.85, 0.4, 0.75))
	_stick_knob.position = Vector2(36, 36)
	_stick_knob.name = "StickKnob"
	_stick_base.add_child(_stick_knob)

	_jump_btn = Button.new()
	_jump_btn.text = "JUMP"
	_jump_btn.position = Vector2(1080, 560)
	_jump_btn.size = Vector2(140, 80)
	_jump_btn.pressed.connect(_on_jump)
	add_child(_jump_btn)

	_hide_btn = Button.new()
	_hide_btn.text = "Hide Visual"
	_hide_btn.position = Vector2(1080, 40)
	_hide_btn.size = Vector2(160, 48)
	_hide_btn.pressed.connect(_on_hide_visual)
	add_child(_hide_btn)

func _make_panel(sz: Vector2, col: Color) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = sz
	p.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	p.add_theme_stylebox_override("panel", sb)
	return p

func _on_jump() -> void:
	if _player_input != null:
		_player_input.pulse_jump()

func _on_hide_visual() -> void:
	if _match != null and _match.has_method("toggle_visual_visible"):
		_match.call("toggle_visual_visible")
		if _match.has_method("get_hero"):
			var h: HeroActor = _match.call("get_hero")
			if h != null:
				_hide_btn.text = "Show Visual" if not h.is_visual_visible() else "Hide Visual"

func _input(event: InputEvent) -> void:
	if _stick_base == null:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var local := st.position - _stick_base.global_position
		if st.pressed and Rect2(Vector2.ZERO, _stick_base.size).grow(24.0).has_point(local):
			_stick_active = true
			_update_stick(local)
		elif not st.pressed and _stick_active:
			_stick_active = false
			_reset_stick()
	elif event is InputEventScreenDrag and _stick_active:
		var drag := event as InputEventScreenDrag
		_update_stick(drag.position - _stick_base.global_position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var local3 := mb.position - _stick_base.global_position
			if mb.pressed and Rect2(Vector2.ZERO, _stick_base.size).grow(24.0).has_point(local3):
				_stick_active = true
				_update_stick(local3)
			elif not mb.pressed and _stick_active:
				_stick_active = false
				_reset_stick()
	elif event is InputEventMouseMotion and _stick_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mm := event as InputEventMouseMotion
		_update_stick(mm.position - _stick_base.global_position)

func _update_stick(local: Vector2) -> void:
	var center := _stick_base.size * 0.5
	var delta := local - center
	if delta.length() > _stick_radius:
		delta = delta.normalized() * _stick_radius
	_stick_knob.position = center + delta - _stick_knob.size * 0.5
	var nx := clampf(delta.x / _stick_radius, -1.0, 1.0)
	var ny := clampf(-delta.y / _stick_radius, -1.0, 1.0) # up = +throttle
	if _player_input != null:
		_player_input.set_touch_stick(nx, ny)

func _reset_stick() -> void:
	var center := _stick_base.size * 0.5
	_stick_knob.position = center - _stick_knob.size * 0.5
	if _player_input != null:
		_player_input.clear_touch_stick()
