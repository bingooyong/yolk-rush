extends Node
## 技能树系统集成测试（简化版）

const SkillDatabaseClass = preload("res://scripts/skill_tree/skill_database.gd")
const SkillTreeSystemClass = preload("res://scripts/skill_tree/skill_tree_system.gd")

var skill_database
var skill_tree

func _ready():
	print("\n=== 技能树系统集成测试 ===\n")

	# 延迟启动以等待数据库加载
	await get_tree().create_timer(0.5).timeout

	setup_systems()
	run_tests()

	print("\n=== 所有测试完成 ===\n")
	get_tree().quit()

func setup_systems():
	print(">>> 初始化系统")

	skill_database = SkillDatabaseClass.new()
	add_child(skill_database)

	# 等待数据库加载
	await get_tree().create_timer(0.2).timeout

	skill_tree = SkillTreeSystemClass.new()
	add_child(skill_tree)
	skill_tree.set_database(skill_database)
	skill_tree.set_player_level(30)
	skill_tree.add_skill_points(50)

	print("✓ 系统初始化完成\n")

func run_tests():
	test_basic_unlock()
	test_prerequisites()
	test_skill_upgrade()
	test_skill_bonuses()
	test_tree_operations()
	test_save_load()

func test_basic_unlock():
	print(">>> 测试基础技能解锁")

	var can_unlock = skill_tree.can_unlock_skill("power_strike")
	check_assert(can_unlock, "应该可以解锁强力打击")

	var success = skill_tree.unlock_skill("power_strike")
	check_assert(success, "应该成功解锁技能")

	var is_unlocked = skill_tree.is_skill_unlocked("power_strike")
	check_assert(is_unlocked, "技能应该已解锁")

	var level = skill_tree.get_skill_level("power_strike")
	check_assert(level == 1, "技能等级应该是1")

	print("✓ 基础技能解锁测试通过\n")

func test_prerequisites():
	print(">>> 测试前置条件验证")

	var can_unlock_crit = skill_tree.can_unlock_skill("critical_strike")
	check_assert(can_unlock_crit, "已有前置技能，应该可以解锁致命一击")

	skill_tree.unlock_skill("critical_strike")

	skill_tree.unlock_skill("attack_speed")
	var can_unlock_berserker = skill_tree.can_unlock_skill("berserker")
	check_assert(can_unlock_berserker, "已有所有前置技能，应该可以解锁狂暴")

	print("✓ 前置条件验证测试通过\n")

func test_skill_upgrade():
	print(">>> 测试技能升级")

	var initial_level = skill_tree.get_skill_level("power_strike")

	var can_upgrade = skill_tree.can_upgrade_skill("power_strike")
	check_assert(can_upgrade, "应该可以升级技能")

	skill_tree.upgrade_skill("power_strike")
	var new_level = skill_tree.get_skill_level("power_strike")
	check_assert(new_level == initial_level + 1, "技能等级应该增加1")

	for i in range(3):
		skill_tree.upgrade_skill("power_strike")

	var max_level = skill_tree.get_skill_level("power_strike")
	check_assert(max_level == 5, "技能应该达到最大等级5")

	var cannot_upgrade = not skill_tree.can_upgrade_skill("power_strike")
	check_assert(cannot_upgrade, "已满级技能不能继续升级")

	print("✓ 技能升级测试通过\n")

func test_skill_bonuses():
	print(">>> 测试技能加成计算")

	var bonuses = skill_tree.get_total_skill_bonuses()
	check_assert(bonuses.has("physical_damage_bonus"), "应该有物理伤害加成")

	var damage_bonus = bonuses["physical_damage_bonus"]
	check_assert(damage_bonus > 0, "物理伤害加成应该大于0")

	var combat_bonuses = skill_tree.get_tree_bonuses("combat")
	check_assert(combat_bonuses.size() > 0, "战斗树应该有加成")

	print("✓ 技能加成计算测试通过\n")

func test_tree_operations():
	print(">>> 测试技能树操作")

	var unlocked_count = skill_tree.get_unlocked_skill_count()
	check_assert(unlocked_count > 0, "应该有已解锁的技能")

	var combat_count = skill_tree.get_tree_unlocked_count("combat")
	check_assert(combat_count > 0, "战斗树应该有已解锁的技能")

	var spent_points = skill_tree.get_spent_skill_points()
	check_assert(spent_points > 0, "应该有已投入的技能点")

	var initial_points = skill_tree.available_skill_points
	var refunded = skill_tree.reset_skills()
	check_assert(refunded == spent_points, "退还的点数应该等于已投入的点数")

	var new_points = skill_tree.available_skill_points
	check_assert(new_points == initial_points + refunded, "技能点应该增加")

	var after_reset_count = skill_tree.get_unlocked_skill_count()
	check_assert(after_reset_count == 0, "重置后应该没有已解锁的技能")

	print("✓ 技能树操作测试通过\n")

func test_save_load():
	print(">>> 测试存档系统")

	skill_tree.unlock_skill("power_strike")
	skill_tree.unlock_skill("iron_wall")
	skill_tree.upgrade_skill("power_strike")

	var save_data = skill_tree.get_save_data()
	check_assert(save_data != null, "应该能生成存档数据")

	var original_skills = skill_tree.get_all_unlocked_skills()
	var original_points = skill_tree.available_skill_points

	skill_tree.reset_skills()
	check_assert(skill_tree.get_unlocked_skill_count() == 0, "重置后应该为空")

	skill_tree.load_save_data(save_data)
	var loaded_skills = skill_tree.get_all_unlocked_skills()
	var loaded_points = skill_tree.available_skill_points

	check_assert(loaded_skills.size() == original_skills.size(), "加载后技能数量应该一致")
	check_assert(loaded_points == original_points, "加载后技能点应该一致")

	print("✓ 存档系统测试通过\n")

func check_assert(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		print("✗ 6/6 测试通过")
		get_tree().quit(1)
