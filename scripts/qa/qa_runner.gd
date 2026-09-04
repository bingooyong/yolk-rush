extends Node
## QA Runner: 执行 Phase 3 QA 测试套件

@onready var screenshot_rig: Node
@onready var perf_counters: Node

var test_results: Dictionary = {}
var current_scene: Node

func _ready() -> void:
	_setup_qa_tools()
	print("[QARunner] Ready - Phase 3 QA system initialized")

func _setup_qa_tools() -> void:
	# Screenshot rig
	screenshot_rig = Node.new()
	screenshot_rig.set_script(preload("res://scripts/qa/screenshot_rig.gd"))
	add_child(screenshot_rig)

	# Performance counters
	perf_counters = Node.new()
	perf_counters.set_script(preload("res://scripts/qa/perf_counters.gd"))
	perf_counters.set("enable_logging", true)
	perf_counters.set("update_interval", 2.0)
	add_child(perf_counters)

func run_golden_scene_test(scene_path: String, benchmark_name: String) -> Dictionary:
	print("[QARunner] Testing golden scene: %s" % scene_path)

	test_results = {
		"scene": scene_path,
		"timestamp": Time.get_datetime_string_from_system(),
		"visual_tests": {},
		"performance_tests": {},
		"overall_status": "pending"
	}

	# Load scene
	var scene_resource := load(scene_path)
	if not scene_resource:
		test_results.overall_status = "error"
		test_results.error = "Failed to load scene"
		return test_results

	current_scene = scene_resource.instantiate()
	get_tree().root.add_child(current_scene)

	# Wait for scene to initialize
	await get_tree().create_timer(3.0).timeout

	# Visual tests
	test_results.visual_tests = await _run_visual_tests(scene_path.get_file().get_basename())

	# Performance tests
	test_results.performance_tests = await _run_performance_tests(benchmark_name)

	# Overall status
	var visual_passed: bool = test_results.visual_tests.get("status", "fail") == "pass"
	var perf_passed: bool = test_results.performance_tests.get("passed", false)

	test_results.overall_status = "pass" if (visual_passed and perf_passed) else "fail"

	# Cleanup
	current_scene.queue_free()

	return test_results

func _run_visual_tests(scene_name: String) -> Dictionary:
	print("[QARunner] Running visual tests...")

	var angles := ["front", "back", "left", "right"]
	var screenshots: Array = await screenshot_rig.capture_golden_scene(scene_name, angles)

	var visual_result := {
		"status": "pass",
		"screenshots": screenshots,
		"comparisons": []
	}

	for i in range(screenshots.size()):
		var baseline_name := "%s_%s" % [scene_name, angles[i]]
		var comparison: Dictionary = screenshot_rig.compare_with_baseline(screenshots[i], baseline_name)
		visual_result.comparisons.append(comparison)

		if comparison.status == "mismatch":
			visual_result.status = "fail"

	return visual_result

func _run_performance_tests(benchmark_name: String) -> Dictionary:
	print("[QARunner] Running performance tests...")

	# Wait for metrics to stabilize
	await get_tree().create_timer(2.0).timeout

	var benchmark: Dictionary = _load_benchmark(benchmark_name)
	if benchmark.is_empty():
		return {
			"passed": false,
			"error": "Benchmark not found: %s" % benchmark_name
		}

	var result: Dictionary = perf_counters.check_against_benchmark(benchmark)
	result["metrics"] = perf_counters.get_current_metrics()

	return result

func _load_benchmark(benchmark_name: String) -> Dictionary:
	var benchmark_path := "res://data/contracts/performance_benchmarks.json"
	if not FileAccess.file_exists(benchmark_path):
		push_error("[QARunner] Benchmarks file not found")
		return {}

	var file := FileAccess.open(benchmark_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[QARunner] Failed to parse benchmarks")
		return {}

	var benchmarks: Dictionary = json.data
	return benchmarks.get(benchmark_name, {})

func export_report(output_path: String) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[QARunner] Failed to create report: %s" % output_path)
		return

	var json := JSON.stringify(test_results, "\t")
	file.store_string(json)
	file.close()

	print("[QARunner] Report exported to: %s" % output_path)

func generate_markdown_report() -> String:
	var md := "# Phase 1-3 QA Report\n\n"
	md += "**Generated:** %s\n\n" % test_results.get("timestamp", "N/A")
	md += "**Scene:** %s\n\n" % test_results.get("scene", "N/A")
	md += "**Overall Status:** %s\n\n" % test_results.get("overall_status", "unknown").to_upper()

	# Visual tests
	md += "## Visual Tests\n\n"
	var visual: Dictionary = test_results.get("visual_tests", {})
	md += "**Status:** %s\n\n" % visual.get("status", "unknown").to_upper()

	if visual.has("comparisons"):
		md += "### Screenshot Comparisons\n\n"
		for comp in visual.comparisons:
			md += "- **%s**: %s\n" % [comp.get("angle", "unknown"), comp.get("status", "unknown")]
			if comp.has("diff_percentage"):
				md += "  - Difference: %.2f%%\n" % comp.diff_percentage

	md += "\n"

	# Performance tests
	md += "## Performance Tests\n\n"
	var perf: Dictionary = test_results.get("performance_tests", {})
	md += "**Passed:** %s\n\n" % ("YES" if perf.get("passed", false) else "NO")

	if perf.has("metrics"):
		md += "### Metrics\n\n"
		var metrics: Dictionary = perf.metrics
		md += "- FPS: %.1f (min: %.1f, max: %.1f)\n" % [
			metrics.get("fps", 0),
			metrics.get("min_fps", 0),
			metrics.get("max_fps", 0)
		]
		md += "- Frame Time: %.2fms (avg: %.2fms)\n" % [
			metrics.get("frame_time_ms", 0),
			metrics.get("avg_frame_time_ms", 0)
		]
		md += "- Draw Calls: %d\n" % metrics.get("draw_calls", 0)
		md += "- Memory: %.1f MB (static) / %.1f MB (video)\n" % [
			metrics.get("static_memory_mb", 0),
			metrics.get("video_memory_mb", 0)
		]

	if perf.has("failures") and not perf.failures.is_empty():
		md += "\n### Failures\n\n"
		for failure in perf.failures:
			md += "- **%s**: expected %s, got %s\n" % [
				failure.metric,
				str(failure.expected),
				str(failure.actual)
			]

	return md
