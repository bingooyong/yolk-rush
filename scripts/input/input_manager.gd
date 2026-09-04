extends Node
## Input Manager: 统一输入处理，支持触摸和键鼠

signal move_input(direction: Vector2)
signal jump_pressed()
signal action_pressed()

var touch_start: Vector2 = Vector2.ZERO
var is_touching: bool = false

func _ready() -> void:
	print("[InputManager] Ready - Touch + Keyboard/Mouse input")

func _input(event: InputEvent) -> void:
	# Touch input
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

	# Keyboard input
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				jump_pressed.emit()
			KEY_E, KEY_F:
				action_pressed.emit()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_start = event.position
		is_touching = true
	else:
		is_touching = false
		move_input.emit(Vector2.ZERO)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if not is_touching:
		return

	var delta := event.position - touch_start
	var direction := delta.normalized()
	var magnitude := minf(delta.length() / 100.0, 1.0)

	move_input.emit(direction * magnitude)

func _process(_delta: float) -> void:
	# Keyboard WASD/Arrow keys
	var input_dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	if input_dir != Vector2.ZERO:
		move_input.emit(input_dir.normalized())
	elif not is_touching:
		move_input.emit(Vector2.ZERO)
