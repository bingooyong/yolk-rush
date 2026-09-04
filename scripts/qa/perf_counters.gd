extends Node
## Performance Counters: FPS, draw calls, memory tracking

signal metrics_updated(metrics: Dictionary)

@export var update_interval: float = 1.0
@export var enable_logging: bool = true

var current_metrics: Dictionary = {}
var frame_times: Array = []
var max_samples: int = 60

var update_timer: float = 0.0

func _ready() -> void:
	print("[PerfCounters] Ready - Update interval: %.1fs" % update_interval)

func _process(delta: float) -> void:
	frame_times.append(delta)
	if frame_times.size() > max_samples:
		frame_times.pop_front()

	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_metrics()

func _update_metrics() -> void:
	current_metrics = {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"frame_time_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_time_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,

		# Rendering
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"vertices": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objects_drawn": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),

		# Memory
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0,
		"dynamic_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0,
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0,

		# Physics
		"physics_3d_active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"physics_3d_collision_pairs": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),

		# Average frame time
		"avg_frame_time_ms": _calculate_average_frame_time() * 1000.0,
		"min_fps": _calculate_min_fps(),
		"max_fps": _calculate_max_fps()
	}

	if enable_logging:
		_log_metrics()

	metrics_updated.emit(current_metrics)

func _calculate_average_frame_time() -> float:
	if frame_times.is_empty():
		return 0.0

	var sum: float = 0.0
	for ft in frame_times:
		sum += ft

	return sum / frame_times.size()

func _calculate_min_fps() -> float:
	if frame_times.is_empty():
		return 0.0

	var max_frame_time: float = frame_times.max()
	return 1.0 / max_frame_time if max_frame_time > 0 else 0.0

func _calculate_max_fps() -> float:
	if frame_times.is_empty():
		return 0.0

	var min_frame_time: float = frame_times.min()
	return 1.0 / min_frame_time if min_frame_time > 0 else 0.0

func _log_metrics() -> void:
	print("[PerfCounters] FPS: %.1f (min: %.1f, max: %.1f) | Frame: %.2fms | Draw calls: %d | Memory: %.1f MB" % [
		current_metrics.fps,
		current_metrics.min_fps,
		current_metrics.max_fps,
		current_metrics.frame_time_ms,
		current_metrics.draw_calls,
		current_metrics.static_memory_mb
	])

func get_current_metrics() -> Dictionary:
	return current_metrics.duplicate()

func export_metrics(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[PerfCounters] Failed to open file: %s" % path)
		return

	var json := JSON.stringify(current_metrics, "\t")
	file.store_string(json)
	file.close()

	print("[PerfCounters] Metrics exported to: %s" % path)

func check_against_benchmark(benchmark: Dictionary) -> Dictionary:
	var results := {
		"passed": true,
		"failures": []
	}

	for key in benchmark.keys():
		if not current_metrics.has(key):
			continue

		var threshold = benchmark[key]
		var current = current_metrics[key]

		var passed := false
		if key in ["fps", "min_fps", "max_fps"]:
			passed = current >= threshold
		else:
			passed = current <= threshold

		if not passed:
			results.passed = false
			results.failures.append({
				"metric": key,
				"expected": threshold,
				"actual": current
			})

	return results
