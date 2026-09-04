# QA Performance Skill

Performance benchmarking and monitoring for Yolk Rush.

## Trigger

Use this skill when:
- Running performance tests
- Validating FPS/frame time targets
- Checking memory usage
- Monitoring draw calls and rendering metrics
- Keywords: "qa perf", "performance test", "fps check", "benchmark"

## Capabilities

1. **Real-time Metrics**: FPS, frame time, draw calls, memory usage
2. **Benchmark Validation**: Compare against target thresholds
3. **Trend Analysis**: Min/max/avg FPS over time window
4. **Mobile Optimization**: iOS/Android specific targets

## Usage

```bash
# Run performance tests
python tools/run_qa_tests.py --benchmark golden_scene_snow_island

# Or add PerfCounters to any scene
var perf = preload("res://scripts/qa/perf_counters.gd").new()
add_child(perf)
perf.enable_logging = true
```

## Tracked Metrics

### Rendering
- **FPS**: Target 60, minimum 30 (mobile) / 45 (desktop)
- **Frame Time**: Target < 16.67ms
- **Draw Calls**: < 500 (mobile) / < 1000 (desktop)
- **Vertices**: < 100k (mobile) / < 500k (desktop)

### Memory
- **Static Memory**: < 256 MB (mobile) / < 512 MB (desktop)
- **Video Memory**: < 512 MB (mobile) / < 1 GB (desktop)

### Physics
- **Active Objects**: Count of physics bodies
- **Collision Pairs**: Active collision checks

## Benchmarks

Defined in `data/contracts/performance_benchmarks.json`:

- `mobile_target`: iOS/Android targets
- `desktop_target`: PC/Mac targets
- `golden_scene_snow_island`: Phase 2 baseline

## Output

- Real-time console logs every 2 seconds
- JSON export: `user://perf_metrics_{timestamp}.json`
- Performance section in `PHASE_1_3_REPORT.md`

## Pass Criteria

All metrics must meet or exceed benchmark thresholds:
- FPS ≥ target
- Frame time ≤ target
- Memory usage ≤ target
- Draw calls ≤ target

## Profiling

For deep analysis, use Godot's built-in profiler:

```bash
godot --path . --debug-collisions --verbose
```

Or export metrics for external analysis:

```gdscript
perf_counters.export_metrics("user://metrics.json")
```
