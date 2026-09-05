extends GutTest
## LevelSystem 单元测试

var level_system: LevelSystem

func before_each():
	level_system = LevelSystem.new()
	add_child_autofree(level_system)
	level_system._ready()

func after_each():
	level_system = null

## 测试初始化
func test_initialization():
	assert_eq(level_system.player_level, 1, "Initial level should be 1")
	assert_eq(level_system.current_exp, 0, "Initial exp should be 0")
	assert_eq(level_system.MAX_LEVEL, 50, "Max level should be 50")

## 测试经验曲线加载
func test_exp_curve_loading():
	assert_true(level_system.exp_curve.size() > 0, "Exp curve should be loaded")
	assert_true(level_system.exp_curve.has("1"), "Should have level 1 data")
	assert_eq(level_system.exp_curve["1"]["required_exp"], 100, "Level 1 should require 100 exp")

## 测试获取所需经验
func test_get_required_exp():
	var req_exp = level_system.get_required_exp(1)
	assert_eq(req_exp, 100, "Level 1 should require 100 exp")

	var req_exp_10 = level_system.get_required_exp(10)
	assert_eq(req_exp_10, 3162, "Level 10 should require 3162 exp")

## 测试添加经验值（不升级）
func test_add_exp_no_level_up():
	level_system.add_exp(50)
	assert_eq(level_system.current_exp, 50, "Should have 50 exp")
	assert_eq(level_system.player_level, 1, "Should still be level 1")

## 测试单次升级
func test_single_level_up():
	watch_signals(level_system)

	level_system.add_exp(100)

	assert_signal_emitted(level_system, "level_up", "Should emit level_up signal")
	assert_eq(level_system.player_level, 2, "Should be level 2")
	assert_eq(level_system.current_exp, 0, "Exp should reset to 0")

## 测试连续升级
func test_multiple_level_ups():
	watch_signals(level_system)

	# 给足够升到 Level 3 的经验 (100 + 282 = 382)
	level_system.add_exp(382)

	assert_signal_emit_count(level_system, "level_up", 2, "Should level up twice")
	assert_eq(level_system.player_level, 3, "Should be level 3")
	assert_eq(level_system.current_exp, 0, "Exp should be exactly 0")

## 测试经验溢出
func test_exp_overflow():
	level_system.add_exp(150)  # 100 to level up, 50 overflow

	assert_eq(level_system.player_level, 2, "Should be level 2")
	assert_eq(level_system.current_exp, 50, "Should have 50 overflow exp")

## 测试达到最大等级
func test_max_level():
	level_system._debug_set_level(50)

	level_system.add_exp(10000)

	assert_eq(level_system.player_level, 50, "Should stay at max level")

## 测试经验进度百分比
func test_exp_progress():
	level_system.current_exp = 50
	var progress = level_system.get_exp_progress()

	assert_almost_eq(progress, 0.5, 0.01, "Progress should be 50%")

## 测试满级进度
func test_max_level_progress():
	level_system._debug_set_level(50)
	var progress = level_system.get_exp_progress()

	assert_eq(progress, 1.0, "Max level progress should be 100%")

## 测试获取等级信息
func test_get_level_info():
	level_system.current_exp = 50
	var info = level_system.get_level_info()

	assert_eq(info["level"], 1, "Level should be 1")
	assert_eq(info["current_exp"], 50, "Current exp should be 50")
	assert_eq(info["required_exp"], 100, "Required exp should be 100")
	assert_false(info["is_max_level"], "Should not be max level")

## 测试存档功能
func test_save_and_load():
	level_system.add_exp(150)
	assert_eq(level_system.player_level, 2, "Should be level 2 before save")

	var save_data = level_system.get_save_data()

	assert_eq(save_data["level"], 2, "Saved level should be 2")
	assert_eq(save_data["exp"], 50, "Saved exp should be 50")

	# 重置并加载
	level_system.player_level = 1
	level_system.current_exp = 0

	level_system.load_save_data(save_data)

	assert_eq(level_system.player_level, 2, "Loaded level should be 2")
	assert_eq(level_system.current_exp, 50, "Loaded exp should be 50")

## 测试存档数据钳制
func test_save_data_clamping():
	var invalid_data = {
		"level": 100,  # 超过最大等级
		"exp": -50     # 负数经验
	}

	level_system.load_save_data(invalid_data)

	assert_eq(level_system.player_level, 50, "Level should be clamped to 50")
	assert_eq(level_system.current_exp, 0, "Exp should be clamped to 0")

## 测试信号发射
func test_exp_gained_signal():
	watch_signals(level_system)

	level_system.add_exp(50)

	assert_signal_emitted_with_parameters(
		level_system,
		"exp_gained",
		[50, 50, 100],
		"Should emit exp_gained with correct parameters"
	)

## 测试调试功能
func test_debug_set_level():
	level_system._debug_set_level(25)

	assert_eq(level_system.player_level, 25, "Debug level should be 25")
	assert_eq(level_system.current_exp, 0, "Debug exp should be 0")

## 测试无效调试等级
func test_debug_invalid_level():
	level_system._debug_set_level(100)

	assert_eq(level_system.player_level, 50, "Should clamp to max level")
