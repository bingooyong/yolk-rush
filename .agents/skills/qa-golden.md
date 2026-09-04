# QA Golden Scene Skill

Golden Scene validation framework for Yolk Rush.

## Trigger

Use this skill when:
- Validating a complete game scene (visual + performance + functionality)
- Running full Phase 1-3 QA suite
- Creating new golden scene baselines
- Keywords: "qa golden", "golden scene", "full qa", "validate scene"

## Capabilities

1. **Comprehensive Testing**: Visual + Performance + Integration
2. **Multi-angle Validation**: 4-way screenshot capture
3. **Benchmark Enforcement**: Automated pass/fail criteria
4. **Report Generation**: Markdown + JSON outputs

## What is a Golden Scene?

A **Golden Scene** is a reference implementation that:
- ✅ Passes all visual regression tests
- ✅ Meets performance benchmarks
- ✅ Demonstrates correct architecture (Gameplay/Visual separation)
- ✅ Serves as a template for future scenes

## Current Golden Scenes

### Snow Island (Phase 2)
- **Path**: `res://scenes/game/snow_island.tscn`
- **Benchmark**: `golden_scene_snow_island`
- **Features**: Character movement, third-person camera, terrain generation
- **Targets**: 60 FPS, < 100 draw calls, < 128 MB memory

## Usage

### Full Golden Scene Test

```bash
python tools/run_qa_tests.py \
  --scene res://scenes/game/snow_island.tscn \
  --benchmark golden_scene_snow_island
```

### Manual Testing

```gdscript
var qa_runner = preload("res://scripts/qa/qa_runner.gd").new()
add_child(qa_runner)

var result = await qa_runner.run_golden_scene_test(
    "res://scenes/game/snow_island.tscn",
    "golden_scene_snow_island"
)

print("Overall: ", result.overall_status)
```

## Test Flow

1. **Scene Load**: Instantiate target scene
2. **Initialization Wait**: 3 seconds for systems to stabilize
3. **Visual Tests**: 4-angle screenshot capture + baseline comparison
4. **Performance Tests**: 2-second metrics collection + benchmark validation
5. **Report Generation**: JSON + Markdown outputs
6. **Cleanup**: Scene teardown

## Creating a New Golden Scene

1. **Build the scene** following architecture principles
2. **Run QA test** to capture initial metrics
3. **Review screenshots** and save as baselines if correct:
   ```gdscript
   screenshot_rig.save_as_baseline(path, "scene_name_angle")
   ```
4. **Set benchmark** in `performance_benchmarks.json`:
   ```json
   "golden_scene_my_scene": {
     "fps": 60,
     "draw_calls": 100,
     ...
   }
   ```
5. **Document** in this skill file

## Pass Criteria

**Overall Status = PASS** requires:
- ✅ Visual tests: All angles < 1% diff from baseline
- ✅ Performance tests: All metrics meet benchmark
- ✅ No runtime errors during 5-second test window

## Output Files

- `user://qa_report_{timestamp}.json` - Full test results
- `user://PHASE_1_3_REPORT.md` - Human-readable summary
- `user://screenshots/latest/*.png` - Scene captures

## Integration with CI

```yaml
# .github/workflows/qa.yml
- name: Run Golden Scene Tests
  run: python tools/run_qa_tests.py
- name: Upload Report
  uses: actions/upload-artifact@v3
  with:
    name: qa-report
    path: ~/.local/share/godot/app_userdata/Yolk Rush/PHASE_1_3_REPORT.md
```

## Troubleshooting

**Scene won't load**
- Check scene path is correct
- Verify all dependencies exist
- Run `godot --check-only` first

**Visual tests fail**
- Baselines may be outdated → Review screenshots manually
- Platform differences (macOS vs Linux rendering)
- Resolution/viewport size mismatch

**Performance tests fail**
- Run in release mode: `godot --export-release`
- Close background apps
- Check if target hardware matches benchmark
