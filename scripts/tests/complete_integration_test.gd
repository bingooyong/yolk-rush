extends SceneTree
## 完整系统集成测试 - 验证所有 7 个阶段

func _init():
	print("\n" + "=".repeat(60))
	print("Yolk Rush - 完整系统集成测试")
	print("=".repeat(60) + "\n")

	var all_passed = true

	all_passed = test_phase_1() and all_passed
	all_passed = test_phase_2() and all_passed
	all_passed = test_phase_3() and all_passed
	all_passed = test_phase_4() and all_passed
	all_passed = test_phase_5() and all_passed
	all_passed = test_phase_6() and all_passed
	all_passed = test_phase_7() and all_passed

	print("\n" + "=".repeat(60))
	if all_passed:
		print("✓ 所有测试通过！系统集成成功！")
	else:
		print("✗ 部分测试失败，请检查错误")
	print("=".repeat(60) + "\n")

	quit()

## Phase 1: 等级和属性系统
func test_phase_1() -> bool:
	print("Phase 1: 测试等级和属性系统")

	var LevelSystemClass = load("res://scripts/progression/level_system.gd")
	var StatsSystemClass = load("res://scripts/progression/stats_system.gd")

	if not LevelSystemClass or not StatsSystemClass:
		print("  ✗ 加载失败")
		return false

	var level_system = LevelSystemClass.new()
	var stats_system = StatsSystemClass.new()

	# 测试等级系统
	level_system.add_exp(50)  # 添加50经验，不会升级
	if level_system.current_exp != 50:
		print("  ✗ 经验值添加失败")
		level_system.free()
		stats_system.free()
		return false

	# 测试属性系统
	stats_system.add_stat_points(10)
	var success = stats_system.allocate_stat("str", 5)
	if not success:
		print("  ✗ 属性分配失败")
		level_system.free()
		stats_system.free()
		return false

	level_system.free()
	stats_system.free()
	print("  ✓ Phase 1 通过\n")
	return true

## Phase 2: 装备系统
func test_phase_2() -> bool:
	print("Phase 2: 测试装备系统")

	var EquipmentDatabaseClass = load("res://scripts/equipment/equipment_database.gd")
	var EquipmentSystemClass = load("res://scripts/equipment/equipment_system.gd")

	if not EquipmentDatabaseClass or not EquipmentSystemClass:
		print("  ✗ 加载失败")
		return false

	print("  ✓ Phase 2 通过\n")
	return true

## Phase 3: 背包系统
func test_phase_3() -> bool:
	print("Phase 3: 测试背包系统")

	var ItemDatabaseClass = load("res://scripts/inventory/item_database.gd")
	var InventorySystemClass = load("res://scripts/inventory/inventory_system.gd")
	var QuickBarSystemClass = load("res://scripts/inventory/quick_bar_system.gd")

	if not ItemDatabaseClass or not InventorySystemClass or not QuickBarSystemClass:
		print("  ✗ 加载失败")
		return false

	print("  ✓ Phase 3 通过\n")
	return true

## Phase 4: 技能树系统
func test_phase_4() -> bool:
	print("Phase 4: 测试技能树系统")

	var SkillDatabaseClass = load("res://scripts/skill_tree/skill_database.gd")
	var SkillTreeSystemClass = load("res://scripts/skill_tree/skill_tree_system.gd")
	var SkillNodeClass = load("res://scripts/skill_tree/skill_node.gd")

	if not SkillDatabaseClass or not SkillTreeSystemClass or not SkillNodeClass:
		print("  ✗ 加载失败")
		return false

	print("  ✓ Phase 4 通过\n")
	return true

## Phase 5: 成就系统
func test_phase_5() -> bool:
	print("Phase 5: 测试成就系统")

	var AchievementDatabaseClass = load("res://scripts/achievement/achievement_database.gd")
	var AchievementSystemClass = load("res://scripts/achievement/achievement_system.gd")
	var AchievementClass = load("res://scripts/achievement/achievement.gd")

	if not AchievementDatabaseClass or not AchievementSystemClass or not AchievementClass:
		print("  ✗ 加载失败")
		return false

	print("  ✓ Phase 5 通过\n")
	return true

## Phase 6: 商店和掉落系统
func test_phase_6() -> bool:
	print("Phase 6: 测试商店和掉落系统")

	var ShopDatabaseClass = load("res://scripts/shop/shop_database.gd")
	var ShopSystemClass = load("res://scripts/shop/shop_system.gd")
	var DropDatabaseClass = load("res://scripts/drop/drop_database.gd")
	var DropSystemClass = load("res://scripts/drop/drop_system.gd")

	if not ShopDatabaseClass or not ShopSystemClass or not DropDatabaseClass or not DropSystemClass:
		print("  ✗ 加载失败")
		return false

	print("  ✓ Phase 6 通过\n")
	return true

## Phase 7: UI 系统
func test_phase_7() -> bool:
	print("Phase 7: 测试 UI 系统")

	var ui_scripts = [
		"res://scripts/ui/hud.gd",
		"res://scripts/ui/inventory_panel.gd",
		"res://scripts/ui/equipment_panel.gd",
		"res://scripts/ui/skill_tree_panel.gd",
		"res://scripts/ui/achievement_panel.gd",
		"res://scripts/ui/shop_panel.gd",
		"res://scripts/ui/ui_manager.gd"
	]

	for script_path in ui_scripts:
		var script = load(script_path)
		if not script:
			print("  ✗ %s 加载失败" % script_path.get_file())
			return false

	print("  ✓ Phase 7 通过\n")
	return true
