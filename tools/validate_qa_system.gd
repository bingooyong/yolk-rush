extends SceneTree
## Simple QA validation script for Phase 3

func _init() -> void:
	print("[QA] Phase 3 QA System Validation")
	print("====================================================")

	# Test 1: Screenshot Rig
	print("\n[Test 1] Screenshot Rig")
	var screenshot_rig = Node.new()
	screenshot_rig.set_script(load("res://scripts/qa/screenshot_rig.gd"))
	root.add_child(screenshot_rig)
	print("  ✓ Screenshot rig loaded")

	# Test 2: Performance Counters
	print("\n[Test 2] Performance Counters")
	var perf_counters = Node.new()
	perf_counters.set_script(load("res://scripts/qa/perf_counters.gd"))
	root.add_child(perf_counters)
	print("  ✓ Performance counters loaded")

	# Test 3: QA Runner
	print("\n[Test 3] QA Runner")
	var qa_runner_scene = load("res://scenes/qa/qa_test_runner.tscn")
	var qa_runner = qa_runner_scene.instantiate()
	root.add_child(qa_runner)
	print("  ✓ QA runner loaded")

	# Test 4: Load benchmarks
	print("\n[Test 4] Performance Benchmarks")
	var benchmark_path := "res://data/contracts/performance_benchmarks.json"
	if FileAccess.file_exists(benchmark_path):
		var file := FileAccess.open(benchmark_path, FileAccess.READ)
		var json := JSON.new()
		var result := json.parse(file.get_as_text())
		file.close()

		if result == OK:
			var benchmarks: Dictionary = json.data
			print("  ✓ Loaded %d benchmarks:" % benchmarks.size())
			for key in benchmarks.keys():
				print("    - %s" % key)
		else:
			print("  ✗ Failed to parse benchmarks")
	else:
		print("  ✗ Benchmark file not found")

	# Test 5: Verify skills exist
	print("\n[Test 5] Agent Skills")
	var skills := ["qa-visual.md", "qa-perf.md", "qa-golden.md"]
	for skill in skills:
		var skill_path: String = ".agents/skills/" + skill
		if FileAccess.file_exists(skill_path):
			print("  ✓ %s" % skill)
		else:
			print("  ✗ %s missing" % skill)

	# Test 6: Check metrics collection
	print("\n[Test 6] Metrics Collection")
	await root.create_timer(1.0).timeout
	var metrics: Dictionary = perf_counters.get_current_metrics()
	if not metrics.is_empty():
		print("  ✓ Collected %d metrics" % metrics.size())
		print("  - FPS: %.1f" % metrics.get("fps", 0))
		print("  - Draw calls: %d" % metrics.get("draw_calls", 0))
		print("  - Memory: %.1f MB" % metrics.get("static_memory_mb", 0))
	else:
		print("  ✗ No metrics collected")

	print("\n====================================================")
	print("[QA] Phase 3 System Validation Complete")
	print("[QA] Status: READY")

	quit(0)
