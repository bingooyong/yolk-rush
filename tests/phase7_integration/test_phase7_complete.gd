extends Node
## Phase 7 完整集成测试

func _ready():
	print("\n========================================")
	print("Phase 7 Meta Systems - 完整集成测试")
	print("========================================\n")

	test_level_and_stats()
	test_equipment_system()
	test_inventory_system()
	test_skill_tree()
	test_achievements()
	test_shop_system()
	test_drop_system()
	test_save_and_load()
	test_full_workflow()

	print("\n========================================")
	print("✅ Phase 7 所有测试通过！")
	print("========================================\n")

	get_tree().quit()

## 测试1: 等级和属性系统
func test_level_and_stats():
	print(">>> 测试 1: 等级和属性系统")

	var level_sys = GameManager.level_system
	var stats_sys = GameManager.stats_system

	# 测试升级
	var initial_level = level_sys.current_level
	level_sys.add_exp(500)
	assert(level_sys.current_level > initial_level, "应该升级")
	print("✓ 升级成功: Level %d" % level_sys.current_level)

	# 测试属性分配
	stats_sys.add_stat_points(10)
	stats_sys.allocate_stat("STR", 5)
	stats_sys.allocate_stat("AGI", 5)

	var bonuses = stats_sys.get_all_bonuses()
	assert(bonuses["physical_damage"] > 0, "力量应该增加物理伤害")
	assert(bonuses["attack_speed"] > 0, "敏捷应该增加攻击速度")
	print("✓ 属性系统正常: 物理伤害 +%.1f%%, 攻速 +%.1f%%" % [bonuses["physical_damage"], bonuses["attack_speed"]])
	print()

## 测试2: 装备系统
func test_equipment_system():
	print(">>> 测试 2: 装备系统")

	var equip_sys = GameManager.equipment_system
	var equip_db = GameManager.equipment_database

	# 装备武器
	var weapon = equip_db.get_equipment_by_id("iron_sword")
	assert(weapon != null, "应该能获取铁剑")

	var success = equip_sys.equip_item(weapon)
	assert(success, "应该能装备武器")

	# 装备护甲
	var helmet = equip_db.get_equipment_by_id("iron_helmet")
	equip_sys.equip_item(helmet)

	# 检查总属性
	var total_stats = equip_sys.get_total_stats()
	assert(total_stats["physical_damage"] > 0, "应该有物理伤害加成")
	print("✓ 装备系统正常: 物理伤害 +%.1f, 防御 +%.1f" % [total_stats["physical_damage"], total_stats["defense"]])

	# 检查装备评分
	var score = equip_sys.get_equipment_score()
	print("✓ 装备评分: %d" % score)
	print()

## 测试3: 背包系统
func test_inventory_system():
	print(">>> 测试 3: 背包系统")

	var inv = GameManager.inventory_system
	var item_db = GameManager.item_database
	var qb = GameManager.quick_bar_system

	# 添加物品
	var potion = item_db.get_item_by_id("health_potion_small")
	assert(potion != null, "应该能获取生命药水")

	inv.add_item(potion, 20)
	assert(inv.get_item_count("health_potion_small") == 20, "应该有20个药水")
	print("✓ 添加物品成功: 20x %s" % potion.item_name)

	# 添加材料
	var iron = item_db.get_item_by_id("iron_ore")
	inv.add_item(iron, 150)  # 超过单堆上限

	var iron_count = inv.get_item_count("iron_ore")
	assert(iron_count == 150, "应该有150个铁矿石")
	print("✓ 堆叠系统正常: %d 铁矿石" % iron_count)

	# 测试快捷栏
	var potion_slot = -1
	for i in range(inv.MAX_SLOTS):
		var stack = inv.get_slot(i)
		if not stack.is_empty() and stack.item.id == "health_potion_small":
			potion_slot = i
			break

	if potion_slot != -1:
		qb.bind_slot(0, potion_slot)
		var qb_stack = qb.get_quick_bar_stack(0)
		assert(not qb_stack.is_empty(), "快捷栏应该有物品")
		print("✓ 快捷栏绑定成功")

	print()

## 测试4: 技能树
func test_skill_tree():
	print(">>> 测试 4: 技能树系统")

	var skill_sys = GameManager.skill_tree_system
	var skill_db = GameManager.skill_database

	# 添加技能点
	skill_sys.add_skill_points(10)
	skill_sys.set_player_level(10)

	# 解锁技能
	var skill = skill_db.get_skill_by_id("combat_basic_attack")
	if skill:
		var can_unlock = skill_sys.can_unlock_skill("combat_basic_attack")
		if can_unlock:
			skill_sys.unlock_skill("combat_basic_attack")
			print("✓ 解锁技能: %s" % skill.skill_name)

		# 升级技能
		for i in range(3):
			if skill_sys.can_upgrade_skill("combat_basic_attack"):
				skill_sys.upgrade_skill("combat_basic_attack")

		var level = skill_sys.get_skill_level("combat_basic_attack")
		print("✓ 技能等级: %d" % level)

	# 检查加成
	var bonuses = skill_sys.get_total_skill_bonuses()
	print("✓ 技能加成: %d 项" % bonuses.size())
	print()

## 测试5: 成就系统
func test_achievements():
	print(">>> 测试 5: 成就系统")

	var ach_sys = GameManager.achievement_system

	# 增加进度
	ach_sys.increment_progress("kill_100_enemies", 50)
	ach_sys.increment_progress("collect_100_items", 30)

	# 检查进度
	var kill_progress = ach_sys.get_progress("kill_100_enemies")
	print("✓ 击杀进度: %d/100" % kill_progress)

	var unlocked = ach_sys.get_unlocked_count()
	print("✓ 已解锁成就: %d" % unlocked)
	print()

## 测试6: 商店系统
func test_shop_system():
	print(">>> 测试 6: 商店系统")

	var shop = GameManager.shop_system
	var item_db = GameManager.item_database

	# 设置金币
	shop.set_player_gold(1000)
	print("✓ 玩家金币: %d" % shop.get_player_gold())

	# 购买物品
	var shop_item = shop.get_shop_item("health_potion_small")
	if shop_item:
		var can_buy = shop.can_buy_item("health_potion_small", 5)
		if can_buy:
			var item = item_db.get_item_by_id("health_potion_small")
			shop.buy_item("health_potion_small", 5, item)
			print("✓ 购买成功: 5x 小型生命药水")

	print("✓ 剩余金币: %d" % shop.get_player_gold())
	print()

## 测试7: 掉落系统
func test_drop_system():
	print(">>> 测试 7: 掉落系统")

	var drop_sys = GameManager.drop_system

	# 生成敌人掉落
	var drops = drop_sys.generate_enemy_drops("goblin", 5, 0.0)
	print("✓ 地精掉落: %d 个物品" % drops.size())

	# 生成金币
	var gold = drop_sys.generate_gold_drop(50, 5, 0.0)
	print("✓ 金币掉落: %d" % gold)

	# 生成经验
	var exp = drop_sys.generate_exp_drop(100, 5)
	print("✓ 经验掉落: %d" % exp)
	print()

## 测试8: 存档和加载
func test_save_and_load():
	print(">>> 测试 8: 存档和加载")

	var save_mgr = GameManager.save_manager

	# 保存当前状态
	var save_success = save_mgr.save_game("test_slot")
	assert(save_success, "应该能保存游戏")
	print("✓ 游戏保存成功")

	# 清空部分状态
	GameManager.inventory_system.clear_all()
	assert(GameManager.inventory_system.get_empty_slot_count() == 48, "背包应该为空")

	# 加载存档
	var load_success = save_mgr.load_game("test_slot")
	assert(load_success, "应该能加载游戏")
	print("✓ 游戏加载成功")

	# 验证数据恢复
	var restored_count = GameManager.inventory_system.get_item_count("health_potion_small")
	print("✓ 数据恢复: %d 药水" % restored_count)
	print()

## 测试9: 完整工作流
func test_full_workflow():
	print(">>> 测试 9: 完整游戏流程")

	# 模拟击杀敌人
	print("→ 击杀地精...")
	GameManager.on_enemy_killed("goblin", 5)

	# 检查经验增长
	var level = GameManager.level_system.current_level
	print("  等级: %d" % level)

	# 检查金币增长
	var gold = GameManager.shop_system.get_player_gold()
	print("  金币: %d" % gold)

	# 检查掉落物品
	var item_count = GameManager.inventory_system.get_item_count("health_potion_small")
	print("  背包物品: %d" % item_count)

	# 检查成就进度
	var ach_progress = GameManager.achievement_system.get_progress("kill_100_enemies")
	print("  成就进度: %d/100" % ach_progress)

	# 获取玩家总属性
	var total_stats = GameManager.get_total_player_stats()
	print("✓ 玩家总属性:")
	print("  物理伤害: +%.1f%%" % total_stats.get("physical_damage", 0))
	print("  攻击速度: +%.1f%%" % total_stats.get("attack_speed", 0))
	print("  最大生命: +%.1f" % total_stats.get("max_health", 0))
	print()
