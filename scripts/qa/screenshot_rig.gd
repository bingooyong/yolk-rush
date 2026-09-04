extends Node
## Screenshot Rig: 自动截图对比工具

signal screenshot_captured(path: String)
signal comparison_completed(result: Dictionary)

const SCREENSHOT_DIR := "user://screenshots/"
const BASELINE_DIR := "res://qa/baselines/"

var viewport: Viewport
var capture_queue: Array = []

func _ready() -> void:
	viewport = get_viewport()
	_ensure_directories()
	print("[ScreenshotRig] Ready")

func _ensure_directories() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	if not dir.dir_exists("screenshots/latest"):
		dir.make_dir("screenshots/latest")

func capture_scene(scene_name: String, camera_angle: String = "default") -> String:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var filename := "%s_%s_%s.png" % [scene_name, camera_angle, timestamp]
	var save_path := SCREENSHOT_DIR + "latest/" + filename

	# Wait one frame for rendering
	await get_tree().process_frame

	var image := viewport.get_texture().get_image()
	image.save_png(save_path)

	print("[ScreenshotRig] Captured: %s" % filename)
	screenshot_captured.emit(save_path)

	return save_path

func capture_golden_scene(scene_path: String, angles: Array) -> Array:
	var screenshots := []

	for angle in angles:
		var screenshot := await capture_scene(scene_path.get_file().get_basename(), angle)
		screenshots.append(screenshot)
		await get_tree().create_timer(0.5).timeout

	return screenshots

func compare_with_baseline(screenshot_path: String, baseline_name: String) -> Dictionary:
	var baseline_path := BASELINE_DIR + baseline_name + ".png"

	if not FileAccess.file_exists(baseline_path):
		return {
			"status": "no_baseline",
			"message": "Baseline not found: %s" % baseline_name
		}

	var current := Image.load_from_file(screenshot_path)
	var baseline := Image.load_from_file(baseline_path)

	if current.get_size() != baseline.get_size():
		return {
			"status": "size_mismatch",
			"current_size": current.get_size(),
			"baseline_size": baseline.get_size()
		}

	var diff_pixels := _count_different_pixels(current, baseline)
	var total_pixels := current.get_width() * current.get_height()
	var diff_percentage := (float(diff_pixels) / float(total_pixels)) * 100.0

	var result := {
		"status": "match" if diff_percentage < 1.0 else "mismatch",
		"diff_pixels": diff_pixels,
		"total_pixels": total_pixels,
		"diff_percentage": diff_percentage
	}

	comparison_completed.emit(result)
	return result

func _count_different_pixels(img1: Image, img2: Image) -> int:
	var diff_count := 0
	var width := img1.get_width()
	var height := img1.get_height()

	for y in range(height):
		for x in range(width):
			var color1 := img1.get_pixel(x, y)
			var color2 := img2.get_pixel(x, y)

			if not color1.is_equal_approx(color2):
				diff_count += 1

	return diff_count

func save_as_baseline(screenshot_path: String, baseline_name: String) -> void:
	var baseline_path := BASELINE_DIR + baseline_name + ".png"
	var image := Image.load_from_file(screenshot_path)
	image.save_png(baseline_path)
	print("[ScreenshotRig] Baseline saved: %s" % baseline_name)
