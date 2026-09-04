extends SceneTree
## Phase 3 Golden Scene QA 测试执行器

func _init() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 3 Golden Scene QA Test")
	print("=".repeat(60) + "\n")

	# Load QA Runner
	var qa_runner_script := load("res://scripts/qa/qa_runner.gd")
	var qa_runner := Node.new()
	qa_runner.set_script(qa_runner_script)
	root.add_child(qa_runner)

	# Wait for initialization
	await create_timer(1.0).timeout

	print("[Phase3QA] Running Snow Island golden scene test...")

	# Run golden scene test
	var results: Dictionary = await qa_runner.run_golden_scene_test(
		"res://scenes/game/snow_island.tscn",
		"golden_scene_snow_island"
	)

	# Print summary
	print("\n" + "-".repeat(60))
	print("Test Results Summary")
	print("-".repeat(60))
	print("Scene: %s" % results.get("scene", "N/A"))
	print("Overall Status: %s" % results.get("overall_status", "unknown").to_upper())

	var visual: Dictionary = results.get("visual_tests", {})
	print("\nVisual Tests: %s" % visual.get("status", "unknown").to_upper())

	var perf: Dictionary = results.get("performance_tests", {})
	print("Performance Tests: %s" % ("PASSED" if perf.get("passed", false) else "FAILED"))

	if perf.has("metrics"):
		var metrics: Dictionary = perf.metrics
		print("\nPerformance Metrics:")
		print("  FPS: %.1f (min: %.1f, max: %.1f)" % [
			metrics.get("fps", 0),
			metrics.get("min_fps", 0),
			metrics.get("max_fps", 0)
		])
		print("  Frame Time: %.2fms" % metrics.get("frame_time_ms", 0))
		print("  Draw Calls: %d" % metrics.get("draw_calls", 0))
		print("  Memory: %.1f MB" % metrics.get("static_memory_mb", 0))

	# Export reports
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var json_path := "user://qa_report_%s.json" % timestamp
	var md_path := "user://qa_report_%s.md" % timestamp

	qa_runner.export_report(json_path)

	var md_content: String = qa_runner.generate_markdown_report()
	var md_file := FileAccess.open(md_path, FileAccess.WRITE)
	if md_file:
		md_file.store_string(md_content)
		md_file.close()
		print("\nMarkdown report: %s" % md_path)

	print("\n" + "=".repeat(60))
	print("Phase 3 QA Test Complete")
	print("=".repeat(60) + "\n")

	quit(0 if results.get("overall_status") == "pass" else 1)
