# QA Visual Skill

Visual regression testing for Yolk Rush golden scenes.

## Trigger

Use this skill when:
- Running visual regression tests
- Comparing screenshots against baselines
- Validating visual consistency across builds
- Keywords: "qa visual", "screenshot test", "visual regression", "golden scene visual"

## Capabilities

1. **Screenshot Capture**: Multi-angle scene captures (front/back/left/right)
2. **Baseline Comparison**: Pixel-diff comparison with stored baselines
3. **Diff Reporting**: Percentage difference and mismatch visualization

## Usage

```bash
# Run visual tests for a scene
python tools/run_qa_tests.py --scene res://scenes/game/snow_island.tscn

# Or via Godot directly
godot --headless --path . --script scripts/qa/qa_runner.gd
```

## How It Works

1. Loads the target scene in headless mode
2. Waits for scene initialization (3 seconds)
3. Captures screenshots from 4 angles
4. Compares with baselines in `res://qa/baselines/`
5. Reports diff percentage (< 1% = pass)

## Setting Baselines

After confirming a scene looks correct:

```gdscript
var screenshot_rig = ScreenshotRig.new()
screenshot_rig.save_as_baseline(
    "user://screenshots/latest/snow_island_front.png",
    "snow_island_front"
)
```

## Output

- Screenshots: `user://screenshots/latest/`
- Comparison results: JSON with `diff_percentage`, `status`
- Visual test section in `PHASE_1_3_REPORT.md`

## Pass Criteria

- All 4 angles < 1% pixel difference from baseline
- No size mismatches
- No missing baselines (or explicitly marked as "new")
