extends GutTest
## ProgressionManager 集成测试

var progression_manager: ProgressionManager
var level_system: LevelSystem
var stats_system: StatsSystem

func before_each():
	# 创建系统实例
	level_system = LevelSystem.new()
	stats_system = StatsSystem.new()
	progression_manager = ProgressionManager.new()
	
	# 添加到场景树
	add_child_autofree(level_system)
	add_child_autofree(stats_system)
	add_child_autofree(progression_manager)
	
	# 手动初始化
	level_system._ready()
	stats_system._ready()
	
	# 模拟 Autoload（设置为子节点以便访问）
	progression_manager.level_system = level_system
	progression_manager.stats_system = stats_system

func after_each():
	progression_manager = null
	level_system = null
	stats_system = null

## 测试敌人击杀奖励
func test_enemy_killed_normal():
	progression_manager.on_enemy_killed("normal", 5)
	
	# 普通敌人：5 * 10 * 1.0 = 50 EXP
	assert_eq(level_system.current_exp, 50, "Should grant 50 exp for normal enemy")

func test_enemy_killed_elite():
	progression_manager.on_enemy_killed("elite", 5)
	
	# 精英敌人：5 * 10 * 2.0 = 100 EXP
	assert_eq(level_system.current_exp, 100, "Should grant 100 exp for elite enemy")

func test_enemy_killed_boss():
	progression_manager.on_enemy_killed("boss", 5)
	
	# Boss：5 * 10 * 5.0 = 250 EXP
	assert_eq(level_system.current_exp, 250, "Should grant 250 exp for boss")

## 测试升级并获得属性点
func test_level_up_grants_stat_points():
	watch_signals(level_system)
	watch_signals(stats_system)
	
	# 给足够的经验升级
	progression_manager.on_enemy_killed("normal", 10)  # 100 exp
	
	assert_signal_emitted(level_system, "level_up", "Should level up")
	assert_eq(level_system.player_level, 2, "Should be level 2")
	assert_eq(stats_system.stat_points, 5, "Should have 5 stat points")

## 测试完整存档流程
func test_full_save_load_cycle():
	# 模拟游戏进度
	progression_manager.on_enemy_killed("boss", 10)  # 500 exp
	assert_true(level_system.player_level >= 2, "Should have leveled up")
	
	stats_system.allocate_stat("str", 3)
	stats_system.allocate_stat("agi", 2)
	
	# 保存
	var save_data = progression_manager.get_all_progression_data()
	
	assert_true(save_data.has("level"), "Should have level data")
	assert_true(save_data.has("stats"), "Should have stats data")
	
	# 重置
	progression_manager.reset_all_progression()
	assert_eq(level_system.player_level, 1, "Should be level 1 after reset")
	assert_eq(stats_system.base_stats["str"], 10, "STR should be 10 after reset")
	
	# 加载
	progression_manager.load_all_progression_data(save_data)
	
	assert_true(level_system.player_level >= 2, "Should restore level")
	assert_eq(stats_system.base_stats["str"], 13, "Should restore STR")
	assert_eq(stats_system.base_stats["agi"], 12, "Should restore AGI")

## 测试重置功能
func test_reset_all_progression():
	# 模拟一些进度
	level_system.add_exp(500)
	stats_system.add_stat_points(10)
	stats_system.allocate_stat("str", 10)
	
	# 重置
	progression_manager.reset_all_progression()
	
	assert_eq(level_system.player_level, 1, "Level should be 1")
	assert_eq(level_system.current_exp, 0, "Exp should be 0")
	assert_eq(stats_system.base_stats["str"], 10, "STR should be 10")
	assert_eq(stats_system.stat_points, 0, "Stat points should be 0")
