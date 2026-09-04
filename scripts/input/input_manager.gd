extends Node
## Input Manager: 统一输入处理，支持触摸和键鼠

signal move_input(direction: Vector2)
signal jump_pressed()
signal action_pressed()
signal attack_pressed()  ## 攻击输入信号
signal skill_pressed(skill_key: String)  ## 技能输入信号 (Q/E/R/F)

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
			KEY_J, KEY_K:  ## J/K 键攻击
				attack_pressed.emit()

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

	## 技能输入检测 (Q/E/R/F) - 使用 is_action_just_pressed 避免连续触发
	if Input.is_action_just_pressed("skill_1") or (Input.is_key_pressed(KEY_Q) and not _skill_held.get("Q", false)):
		skill_pressed.emit("skill_1")
		_skill_held["Q"] = true
	elif not Input.is_key_pressed(KEY_Q):
		_skill_held["Q"] = false

	if Input.is_action_just_pressed("skill_2") or (Input.is_key_pressed(KEY_E) and not _skill_held.get("E", false)):
		skill_pressed.emit("skill_2")
		_skill_held["E"] = true
	elif not Input.is_key_pressed(KEY_E):
		_skill_held["E"] = false

	if Input.is_action_just_pressed("skill_3") or (Input.is_key_pressed(KEY_R) and not _skill_held.get("R", false)):
		skill_pressed.emit("skill_3")
		_skill_held["R"] = true
	elif not Input.is_key_pressed(KEY_R):
		_skill_held["R"] = false

	if Input.is_action_just_pressed("skill_ultimate") or (Input.is_key_pressed(KEY_F) and not _skill_held.get("F", false)):
		skill_pressed.emit("skill_ultimate")
		_skill_held["F"] = true
	elif not Input.is_key_pressed(KEY_F):
		_skill_held["F"] = false

var _skill_held: Dictionary = {}  ## 防止技能按键连续触发
