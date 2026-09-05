class_name PlayerInput
extends Node
## Unified yaw-throttle input. Keyboard WASD+Space and touch stick share the same axes.
## A => yaw_input +1 (CCW / positive rotate_y). D => -1. W => throttle +1.

var throttle: float = 0.0
var yaw_input: float = 0.0
var jump: bool = false

var _touch_yaw: float = 0.0
var _touch_throttle: float = 0.0
var _touch_jump: bool = false

func _process(_delta: float) -> void:
	var k_throttle := 0.0
	var k_yaw := 0.0
	var k_jump := false

	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		k_throttle += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		k_throttle -= 1.0
	# A = counterclockwise (+yaw); D = clockwise (-yaw)
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		k_yaw += 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		k_yaw -= 1.0
	if Input.is_physical_key_pressed(KEY_SPACE):
		k_jump = true

	throttle = clampf(k_throttle + _touch_throttle, -1.0, 1.0)
	yaw_input = clampf(k_yaw + _touch_yaw, -1.0, 1.0)
	jump = k_jump or _touch_jump
	# Touch jump is a one-shot pulse from the HUD button.
	_touch_jump = false


func set_touch_stick(x: float, y: float) -> void:
	## Stick: x = yaw, y = throttle (same contract as keyboard).
	_touch_yaw = clampf(x, -1.0, 1.0)
	_touch_throttle = clampf(y, -1.0, 1.0)


func clear_touch_stick() -> void:
	_touch_yaw = 0.0
	_touch_throttle = 0.0


func pulse_jump() -> void:
	_touch_jump = true
