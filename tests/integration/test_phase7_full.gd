extends Node
## Phase 7 元系统 - 完整集成测试

const GameManagerClass = preload("res://scripts/core/game_manager.gd")

var game_manager

func _ready():
	print("\n============================================================")
	print("Phase 7 元系统 - 最终集成测试")
	print("============================================================\n")

	test_full_game_loop()

	print("\n============================================================")
	print("所有集成测试完成！")
	print("============================================================\n")

	get_tree().quit()

func test_full_game_loop():
	print(">>> 测试完整游戏循环\n")

	# 1. 初始化游戏管理器
	print("【步骤 1】初始化游戏管理器")
	game_manager = GameManagerClass.new()
	add_child(game_manager)
	await get_tree().create_timer(0.5).timeout
	assert_true(game_manager.is_initialized, "游戏管理器应该初始化完成")
	print("✓ 游戏管理器初始化完成\n")

	# 2. 开始新游戏
	print("【步骤 2】开始新游戏")
	game_manager.new_game()
	var summary = game_manager.get_player_summary()
	assert_true(summary.level == 1, "应该从1级开始")
	assert_true(summary.gold == 1000, "应该有1000初始金币")
	print("✓ 新游戏开始: 等级%d, 金币%d\n" % [summary.level, summary.gold])

	# 3. 模拟战斗和成长
	print("【步骤 3】模拟战斗循环")
	for i in range(10):
		game_manager.on_enemy_killed("goblin", 1)

	summary = game_manager.get_player_summary()
	print("✓ 击杀10只哥布林后:")
	print("  - 等级: %d" % summary.level)
	print("  - 经验: %d" % summary.exp)
	print("  - 金币: %d" % summary.gold)
	print("  - 背包物品: %d\n" % game_manager.inventory_system.get_all_items().size())

	# 4. 测试商店购买
	print("【步骤 4】测试商店购买")
	var can_buy = game_manager.shop_system.can_buy("health_potion_small", 5)
	if can_buy:
		game_manager.shop_system.buy_item("health_potion_small", 5)
		print("✓ 成功购买5个生命药水")
		print("  - 剩余金币: %d\n" % game_manager.shop_system.get_player_gold())

	# 5. 测试装备穿戴
	print("【步骤 5】测试装备系统")
	var sword = game_manager.equipment_database.get_equipment_by_id("iron_sword")
	if sword:
		game_manager.equipment_system.equip_item(sword)
		print("✓ 装备铁剑")
		var eq_stats = game_manager.equipment_system.get_total_stats()
		print("  - 装备属性加成: %s\n" % str(eq_stats))

	# 6. 测试属性分配
	print("【步骤 6】测试属性系统")
	game_manager.stats_system.add_stat_points(10)
	game_manager.stats_system.allocate_stat("strength", 5)
	game_manager.stats_system.allocate_stat("agility", 5)
	var bonuses = game_manager.stats_system.get_all_bonuses()
	print("✓ 分配10点属性")
	print("  - 力量加成: +%d%% 物理伤害" % bonuses.get("physical_damage", 0))
	print("  - 敏捷加成: +%d%% 攻速\n" % bonuses.get("attack_speed", 0))

	# 7. 测试技能树
	print("【步骤 7】测试技能树系统")
	game_manager.skill_tree_system.add_skill_points(5)
	var unlocked = game_manager.skill_tree_system.unlock_skill("warrior_str_1")
	if unlocked:
		print("✓ 解锁技能: 战士力量 I")
		var skill_bonuses = game_manager.skill_tree_system.get_total_skill_bonuses()
		print("  - 技能加成: %s\n" % str(skill_bonuses))

	# 8. 测试掉落系统
	print("【步骤 8】测试掉落系统")
	var drops = game_manager.drop_system.generate_drops("chest_common", 0.1)
	print("✓ 开启普通宝箱，获得 %d 件物品:" % drops.size())
	for drop in drops:
		print("  - %s x%d" % [drop.item_id, drop.quantity])
	print()

	# 9. 测试成就系统
	print("【步骤 9】测试成就系统")
	game_manager.achievement_system.check_achievement("first_blood")
	var unlocked_achievements = game_manager.achievement_system.get_unlocked_achievements()
	print("✓ 已解锁成就数: %d\n" % unlocked_achievements.size())

	# 10. 测试存档系统
	print("【步骤 10】测试存档系统")
	var save_success = game_manager.save_manager.save_game(0)
	assert_true(save_success, "存档应该成功")
	print("✓ 游戏已保存到槽位 0")

	var has_save = game_manager.save_manager.has_save(0)
	assert_true(has_save, "应该检测到存档")

	var save_info = game_manager.save_manager.get_save_info(0)
	print("✓ 存档信息:")
	print("  - 时间: %s" % save_info.date)
	print("  - 版本: %s\n" % save_info.version)

	# 11. 测试加载存档
	print("【步骤 11】测试加载存档")
	var original_level = game_manager.level_system.current_level
	var original_gold = game_manager.shop_system.get_player_gold()

	# 修改数据
	game_manager.level_system.current_level = 99
	game_manager.shop_system.set_player_gold(999999)

	# 加载存档
	var load_success = game_manager.save_manager.load_game(0)
	assert_true(load_success, "加载应该成功")

	var loaded_level = game_manager.level_system.current_level
	var loaded_gold = game_manager.shop_system.get_player_gold()

	assert_true(loaded_level == original_level, "等级应该恢复")
	assert_true(loaded_gold == original_gold, "金币应该恢复")
	print("✓ 存档加载成功，数据已恢复\n")

	# 12. 获取最终玩家摘要
	print("【步骤 12】最终玩家状态")
	summary = game_manager.get_player_summary()
	print("========================================")
	print("玩家摘要:")
	print("  等级: %d" % summary.level)
	print("  经验: %d" % summary.exp)
	print("  金币: %d" % summary.gold)
	print("  技能点: %d" % summary.skill_points)
	print("  装备评分: %d" % summary.equipment_score)
	print("  已解锁成就: %d" % summary.achievements_unlocked)
	print("========================================\n")

	print("✓ 完整游戏循环测试通过！\n")

func assert_true(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		print("\n============================================================")
		print("测试失败！")
		print("============================================================")
		get_tree().quit(1)
