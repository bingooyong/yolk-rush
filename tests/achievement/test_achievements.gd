extends Node
## 成就系统集成测试

const AchievementSystemClass = preload("res://scripts/achievement/achievement_system.gd")
const AchievementDatabaseClass = preload("res://scripts/achievement/achievement_database.gd")

var achievement_system
var achievement_database

func _ready():
	print("\n=== 开始成就系统集成测试 ===\n")

	setup_systems()
	test_basic_unlock()
	test_progress_tracking()
	test_event_tracking()
	test_completion_stats()
	test_save_load()

	print("\n=== 所有测试完成 ===\n")
	get_tree().quit()

func setup_systems():
	print(">>> 初始化系统")

	achievement_database = AchievementDatabaseClass.new()
	add_child(achievement_database)
	achievement_database.load_database()

	achievement_system = AchievementSystemClass.new()
	add_child(achievement_system)
	achievement_system.set_database(achievement_database)

	print("✓ 系统初始化完成\n")

func test_basic_unlock():
	print(">>> 测试基础解锁")

	var success = achievement_system.unlock_achievement("first_blood")
	check_assert(success, "应该能解锁初次胜利")
	check_assert(achievement_system.is_unlocked("first_blood"), "成就应该已解锁")

	var duplicate = achievement_system.unlock_achievement("first_blood")
	check_assert(not duplicate, "不应该重复解锁")

	print("✓ 基础解锁测试通过\n")

func test_progress_tracking():
	print(">>> 测试进度追踪")

	# 测试进度累积
	achievement_system.track_event("KILL", 10)
	var progress = achievement_system.get_progress("slayer")
	check_assert(progress == 10, "击杀进度应该是10")

	achievement_system.track_event("KILL", 30)
	progress = achievement_system.get_progress("slayer")
	check_assert(progress == 40, "击杀进度应该累积到40")

	# 测试进度百分比
	var percentage = achievement_system.get_progress_percentage("slayer")
	check_assert(percentage == 40.0, "进度应该是40%")

	print("✓ 进度追踪测试通过\n")

func test_event_tracking():
	print(">>> 测试事件追踪自动解锁")

	var initial_count = achievement_system.get_unlocked_count()

	# 继续追踪击杀，应该自动解锁 slayer (100次)
	achievement_system.track_event("KILL", 60)

	var is_unlocked = achievement_system.is_unlocked("slayer")
	check_assert(is_unlocked, "应该自动解锁杀戮者成就")

	var new_count = achievement_system.get_unlocked_count()
	check_assert(new_count == initial_count + 1, "解锁数量应该增加1")

	print("✓ 事件追踪测试通过\n")

func test_completion_stats():
	print(">>> 测试完成度统计")

	var total = achievement_database.get_achievement_count()
	check_assert(total == 15, "应该有15个成就")

	var unlocked = achievement_system.get_unlocked_count()
	check_assert(unlocked >= 2, "至少应该解锁2个成就")

	var percentage = achievement_system.get_completion_percentage()
	check_assert(percentage > 0 and percentage <= 100, "完成度应该在0-100之间")

	print("  总成就数: %d" % total)
	print("  已解锁: %d" % unlocked)
	print("  完成度: %.1f%%" % percentage)

	# 测试获取已解锁列表
	var unlocked_list = achievement_system.get_unlocked_achievements()
	check_assert(unlocked_list.size() == unlocked, "已解锁列表大小应该匹配")

	print("✓ 完成度统计测试通过\n")

func test_save_load():
	print(">>> 测试存档系统")

	var save_data = achievement_system.get_save_data()
	check_assert(save_data != null, "应该能生成存档")
	check_assert(save_data.has("unlocked"), "存档应该包含解锁数据")
	check_assert(save_data.has("progress"), "存档应该包含进度数据")

	var original_unlocked = achievement_system.get_unlocked_count()
	var original_progress = achievement_system.get_progress("slayer")

	# 模拟新的进度
	achievement_system.track_event("LEVEL", 5)
	achievement_system.track_event("COMBAT", 50)

	# 加载之前的存档
	achievement_system.load_save_data(save_data)

	var loaded_unlocked = achievement_system.get_unlocked_count()
	var loaded_progress = achievement_system.get_progress("slayer")

	check_assert(loaded_unlocked == original_unlocked, "加载后解锁数量应该一致")
	check_assert(loaded_progress == original_progress, "加载后进度应该一致")

	print("✓ 存档系统测试通过\n")

func check_assert(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		get_tree().quit(1)
