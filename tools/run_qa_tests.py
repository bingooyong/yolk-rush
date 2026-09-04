#!/usr/bin/env python3
"""
Phase 3 QA Test Runner
Usage: python tools/run_qa_tests.py [--scene SCENE] [--benchmark BENCHMARK]
"""

import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime

PROJECT_ROOT = Path(__file__).parent.parent
GODOT_BINARY = "/Applications/Godot.app/Contents/MacOS/Godot"

def run_qa_test(scene_path: str, benchmark_name: str) -> dict:
    """Run QA test in Godot headless mode"""

    print(f"[QA] Testing scene: {scene_path}")
    print(f"[QA] Benchmark: {benchmark_name}")

    # Create test script
    test_script = f"""
extends SceneTree

func _init():
    var qa_runner_scene = preload("res://scenes/qa/qa_test_runner.tscn")
    var qa_runner = qa_runner_scene.instantiate()
    root.add_child(qa_runner)

    # Run test
    var result = await qa_runner.run_golden_scene_test(
        "{scene_path}",
        "{benchmark_name}"
    )

    # Export results
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
    var report_path = "user://qa_report_" + timestamp + ".json"
    qa_runner.export_report(report_path)

    # Generate markdown
    var md = qa_runner.generate_markdown_report()
    var md_path = "user://PHASE_1_3_REPORT.md"
    var file = FileAccess.open(md_path, FileAccess.WRITE)
    file.store_string(md)
    file.close()

    print("[QA] Overall status: " + result.overall_status)
    print("[QA] Report saved to: " + report_path)
    print("[QA] Markdown report: " + md_path)

    quit(0 if result.overall_status == "pass" else 1)
"""

    script_path = PROJECT_ROOT / "test_runner_temp.gd"
    script_path.write_text(test_script)

    try:
        # Run Godot with test script
        result = subprocess.run(
            [
                GODOT_BINARY,
                "--headless",
                "--path", str(PROJECT_ROOT),
                "--script", str(script_path)
            ],
            capture_output=True,
            text=True,
            timeout=30
        )

        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr, file=sys.stderr)

        return {
            "success": result.returncode == 0,
            "returncode": result.returncode
        }

    finally:
        script_path.unlink(missing_ok=True)

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Run Phase 3 QA tests")
    parser.add_argument(
        "--scene",
        default="res://scenes/game/snow_island.tscn",
        help="Scene to test"
    )
    parser.add_argument(
        "--benchmark",
        default="golden_scene_snow_island",
        help="Performance benchmark name"
    )

    args = parser.parse_args()

    result = run_qa_test(args.scene, args.benchmark)

    sys.exit(0 if result["success"] else 1)

if __name__ == "__main__":
    main()
