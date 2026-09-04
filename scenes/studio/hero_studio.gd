extends Node3D
## Hero Studio: 四机位角色展示场景

@onready var cameras := {
	"front": $Cameras/Front,
	"back": $Cameras/Back,
	"left": $Cameras/Left,
	"right": $Cameras/Right
}

@onready var buttons := {
	"front": $UI/CameraSwitch/FrontBtn,
	"back": $UI/CameraSwitch/BackBtn,
	"left": $UI/CameraSwitch/LeftBtn,
	"right": $UI/CameraSwitch/RightBtn
}

var current_camera: String = "front"

func _ready() -> void:
	_connect_buttons()
	_load_camera_profiles()
	print("[HeroStudio] Ready - Press 1/2/3/4 to switch cameras")

func _connect_buttons() -> void:
	for cam_id in buttons.keys():
		buttons[cam_id].pressed.connect(_switch_camera.bind(cam_id))

func _load_camera_profiles() -> void:
	var profile_path := "res://data/contracts/camera_profiles.json"
	if not FileAccess.file_exists(profile_path):
		push_warning("[HeroStudio] Camera profiles not found, using defaults")
		return

	var file := FileAccess.open(profile_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[HeroStudio] Failed to parse camera profiles")
		return

	var data: Dictionary = json.data
	var profiles: Array = data.get("profiles", [])

	for profile in profiles:
		var cam_id: String = profile.get("id", "")
		if not cameras.has(cam_id):
			continue

		var cam: Camera3D = cameras[cam_id]
		var pos: Dictionary = profile.get("position", {})
		var look: Dictionary = profile.get("look_at", {})

		cam.position = Vector3(pos.get("x", 0), pos.get("y", 1.2), pos.get("z", 3.5))
		cam.look_at(Vector3(look.get("x", 0), look.get("y", 1.0), look.get("z", 0)))
		cam.fov = profile.get("fov", 50)

func _switch_camera(cam_id: String) -> void:
	if not cameras.has(cam_id):
		return

	for id in cameras.keys():
		cameras[id].current = (id == cam_id)

	current_camera = cam_id
	print("[HeroStudio] Switched to: %s" % cam_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _switch_camera("front")
			KEY_2: _switch_camera("back")
			KEY_3: _switch_camera("left")
			KEY_4: _switch_camera("right")
