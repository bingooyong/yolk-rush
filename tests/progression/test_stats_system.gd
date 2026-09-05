extends GutTest
## StatsSystem 单元测试

var stats_system: StatsSystem

func before_each():
	stats_system = StatsSystem.new()
	add_child_autofree(stats_system)
	stats_system._ready()

func after_each():
	stats_system = null

## 测试初始化
func test_initialization():
	assert_eq(stats_system.base_stats["str"], 10, "Initial STR should be 10")
	assert_eq(stats_system.base_stats["agi"], 10, "Initial AGI should be 10")
	assert_eq(stats_system.base_stats["vit"], 10, "Initial VIT should be 10")
	assert_eq(stats_system.base_stats["int"], 10, "Initial INT should be 10")
	assert_eq(stats_system.base_stats["luk"], 10, "Initial LUK should be 10")
	assert_eq(stats_system.stat_points, 0, "Initial stat points should be 0")

## 测试添加属性点
func test_add_stat_points():
	watch_signals(stats_system)

	stats_system.add_stat_points(5)

	assert_eq(stats_system.stat_points, 5, "Should have 5 stat points")
	assert_signal_emitted(stats_system, "stat_points_changed", "Should emit signal")

## 测试分配属性点
func test_allocate_stat():
	stats_system.add_stat_points(5)
	watch_signals(stats_system)

	var success = stats_system.allocate_stat("str", 3)

	assert_true(success, "Should successfully allocate")
	assert_eq(stats_system.base_stats["str"], 13, "STR should be 13")
	assert_eq(stats_system.stat_points, 2, "Should have 2 points left")
	assert_signal_emitted(stats_system, "stats_changed", "Should emit stats_changed")
	assert_signal_emitted(stats_system, "stat_points_changed", "Should emit stat_points_changed")

## 测试属性点不足
func test_allocate_insufficient_points():
	stats_system.add_stat_points(2)

	var success = stats_system.allocate_stat("str", 5)

	assert_false(success, "Should fail with insufficient points")
	assert_eq(stats_system.base_stats["str"], 10, "STR should remain 10")
	assert_eq(stats_system.stat_points, 2, "Points should remain 2")

## 测试无效属性名
func test_allocate_invalid_stat():
	stats_system.add_stat_points(5)

	var success = stats_system.allocate_stat("invalid", 1)

	assert_false(success, "Should fail with invalid stat name")
	assert_eq(stats_system.stat_points, 5, "Points should remain unchanged")

## 测试力量加成计算
func test_str_bonus():
	stats_system.base_stats["str"] = 20

	var phys_dmg = stats_system.calculate_stat_bonus("str", "physical_damage")

	assert_eq(phys_dmg, 40.0, "20 STR should give +40 physical damage")

## 测试敏捷加成计算
func test_agi_bonus():
	stats_system.base_stats["agi"] = 30

	var atk_speed = stats_system.calculate_stat_bonus("agi", "attack_speed")
	var evasion = stats_system.calculate_stat_bonus("agi", "evasion")

	assert_almost_eq(atk_speed, 0.15, 0.01, "30 AGI should give +15% attack speed")
	assert_almost_eq(evasion, 0.09, 0.01, "30 AGI should give +9% evasion")

## 测试体质加成计算
func test_vit_bonus():
	stats_system.base_stats["vit"] = 25

	var max_hp = stats_system.calculate_stat_bonus("vit", "max_health")

	assert_eq(max_hp, 250.0, "25 VIT should give +250 max health")

## 测试智力加成计算
func test_int_bonus():
	stats_system.base_stats["int"] = 15

	var skill_dmg = stats_system.calculate_stat_bonus("int", "skill_damage_mult")

	assert_almost_eq(skill_dmg, 0.45, 0.01, "15 INT should give +45% skill damage")

## 测试幸运加成计算
func test_luk_bonus():
	stats_system.base_stats["luk"] = 40

	var crit = stats_system.calculate_stat_bonus("luk", "crit_chance")
	var drop_rate = stats_system.calculate_stat_bonus("luk", "drop_rate")

	assert_almost_eq(crit, 0.2, 0.01, "40 LUK should give +20% crit chance")
	assert_almost_eq(drop_rate, 0.08, 0.01, "40 LUK should give +8% drop rate")

## 测试获取所有加成
func test_get_all_bonuses():
	stats_system.base_stats["str"] = 20
	stats_system.base_stats["agi"] = 30
	stats_system.base_stats["vit"] = 25
	stats_system.base_stats["int"] = 15
	stats_system.base_stats["luk"] = 40

	var bonuses = stats_system.get_all_bonuses()

	assert_eq(bonuses["physical_damage"], 40.0, "Physical damage bonus correct")
	assert_almost_eq(bonuses["attack_speed"], 0.15, 0.01, "Attack speed bonus correct")
	assert_eq(bonuses["max_health"], 250.0, "Max health bonus correct")
	assert_almost_eq(bonuses["skill_damage_mult"], 0.45, 0.01, "Skill damage bonus correct")
	assert_almost_eq(bonuses["crit_chance"], 0.2, 0.01, "Crit chance bonus correct")

## 测试重置属性
func test_reset_stats():
	stats_system.add_stat_points(10)
	stats_system.allocate_stat("str", 5)
	stats_system.allocate_stat("agi", 5)

	assert_eq(stats_system.base_stats["str"], 15, "STR should be 15 before reset")
	assert_eq(stats_system.base_stats["agi"], 15, "AGI should be 15 before reset")
	assert_eq(stats_system.stat_points, 0, "Should have 0 points before reset")

	watch_signals(stats_system)
	var success = stats_system.reset_stats(1000)

	assert_true(success, "Reset should succeed")
	assert_eq(stats_system.base_stats["str"], 10, "STR should be 10 after reset")
	assert_eq(stats_system.base_stats["agi"], 10, "AGI should be 10 after reset")
	assert_eq(stats_system.stat_points, 10, "Should have 10 points back")
	assert_signal_emitted(stats_system, "stats_changed", "Should emit stats_changed")

## 测试获取属性详情
func test_get_stat_details():
	stats_system.base_stats["str"] = 20

	var details = stats_system.get_stat_details("str")

	assert_eq(details["name"], "力量", "Display name should be correct")
	assert_eq(details["value"], 20, "Value should be 20")
	assert_eq(details["bonuses"].size(), 1, "Should have 1 bonus")
	assert_eq(details["bonuses"][0]["type"], "物理攻击", "Bonus type should be correct")
	assert_eq(details["bonuses"][0]["value"], 40.0, "Bonus value should be correct")

## 测试获取所有属性详情
func test_get_all_stats_details():
	var all_details = stats_system.get_all_stats_details()

	assert_eq(all_details.size(), 5, "Should have 5 stats")

## 测试存档功能
func test_save_and_load():
	stats_system.add_stat_points(15)
	stats_system.allocate_stat("str", 5)
	stats_system.allocate_stat("agi", 5)

	var save_data = stats_system.get_save_data()

	assert_eq(save_data["stats"]["str"], 15, "Saved STR should be 15")
	assert_eq(save_data["stats"]["agi"], 15, "Saved AGI should be 15")
	assert_eq(save_data["stat_points"], 5, "Saved points should be 5")

	# 重置并加载
	stats_system.base_stats = {
		"str": 10, "agi": 10, "vit": 10, "int": 10, "luk": 10
	}
	stats_system.stat_points = 0

	watch_signals(stats_system)
	stats_system.load_save_data(save_data)

	assert_eq(stats_system.base_stats["str"], 15, "Loaded STR should be 15")
	assert_eq(stats_system.base_stats["agi"], 15, "Loaded AGI should be 15")
	assert_eq(stats_system.stat_points, 5, "Loaded points should be 5")
	assert_signal_emitted(stats_system, "stats_changed", "Should emit stats_changed")

## 测试默认存档数据
func test_load_empty_save():
	stats_system.load_save_data({})

	assert_eq(stats_system.base_stats["str"], 10, "Should load default stats")
	assert_eq(stats_system.stat_points, 0, "Should load default points")

## 测试属性显示名称
func test_stat_display_names():
	assert_eq(stats_system._get_stat_display_name("str"), "力量")
	assert_eq(stats_system._get_stat_display_name("agi"), "敏捷")
	assert_eq(stats_system._get_stat_display_name("vit"), "体质")
	assert_eq(stats_system._get_stat_display_name("int"), "智力")
	assert_eq(stats_system._get_stat_display_name("luk"), "幸运")

## 测试加成显示名称
func test_bonus_display_names():
	assert_eq(stats_system._get_bonus_display_name("physical_damage"), "物理攻击")
	assert_eq(stats_system._get_bonus_display_name("attack_speed"), "攻击速度")
	assert_eq(stats_system._get_bonus_display_name("max_health"), "最大生命值")
	assert_eq(stats_system._get_bonus_display_name("skill_damage_mult"), "技能伤害")
	assert_eq(stats_system._get_bonus_display_name("crit_chance"), "暴击率")

## 测试调试功能
func test_debug_add_stat_points():
	stats_system._debug_add_stat_points(100)

	assert_eq(stats_system.stat_points, 100, "Should have 100 points")
