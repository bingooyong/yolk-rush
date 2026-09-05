extends Node
## UI 系统集成测试

func _ready() -> void:
	print("\n" + "=".repeat(70))
	print("UI 系统集成测试")
	print("=".repeat(70))

	await get_tree().process_frame

	if not GameManager or not GameManager.is_initialized:
		await GameManager.game_initialized

	_run_tests()

func _run_tests() -> void:
	print("\n[测试 1] UI 脚本加载测试")
	test_ui_scripts_loading()

	print("\n[测试 2] UI 管理器初始化")
	test_ui_manager_initialization()

	print("\n[测试 3] HUD 更新测试")
	test_hud_updates()

	print("\n[测试 4] 背包面板测试")
	test_inventory_panel()

	print("\n[测试 5] 装备面板测试")
	test_equipment_panel()

	print("\n[测试 6] 技能树面板测试")
	test_skill_tree_panel()

	print("\n[测试 7] 成就面板测试")
	test_achievement_panel()

	print("\n[测试 8] 商店面板测试")
	test_shop_panel()

	print("\n" + "=".repeat(70))
	print("UI 系统集成测试完成")
	print("=".repeat(70))

	get_tree().quit()

## 测试 1: UI 脚本加载
func test_ui_scripts_loading() -> void:
	var scripts = {
		"UIManager": "res://scripts/ui/ui_manager.gd",
		"HUD": "res://scripts/ui/hud.gd",
		"InventoryPanel": "res://scripts/ui/inventory_panel.gd",
		"EquipmentPanel": "res://scripts/ui/equipment_panel.gd",
		"SkillTreePanel": "res://scripts/ui/skill_tree_panel.gd",
		"AchievementPanel": "res://scripts/ui/achievement_panel.gd",
		"ShopPanel": "res://scripts/ui/shop_panel.gd"
	}

	for script_name in scripts.keys():
		var path = scripts[script_name]
		if ResourceLoader.exists(path):
			var script = load(path)
			if script:
				print("  ✓ %s 加载成功" % script_name)
			else:
				print("  ✗ %s 加载失败" % script_name)
		else:
			print("  ✗ %s 文件不存在: %s" % [script_name, path])

## 测试 2: UIManager 初始化
func test_ui_manager_initialization() -> void:
	var UIManagerClass = load("res://scripts/ui/ui_manager.gd")
	var ui_manager = UIManagerClass.new()
	add_child(ui_manager)

	await get_tree().process_frame

	print("  ✓ UIManager 创建成功")
	print("  - 当前打开的 UI: %s" % ui_manager.current_open_ui)
	print("  - 是否有 UI 打开: %s" % ui_manager.is_any_ui_open)

	ui_manager.queue_free()

## 测试 3: HUD 更新
func test_hud_updates() -> void:
	var HUDClass = load("res://scripts/ui/hud.gd")
	var hud = HUDClass.new()
	add_child(hud)

	await get_tree().process_frame

	# 测试更新方法
	hud.update_level()
	print("  ✓ 等级更新")

	hud.update_exp_bar(50, 100)
	print("  ✓ 经验条更新")

	hud.update_gold(1000)
	print("  ✓ 金币更新")

	hud.update_skill_points(5)
	print("  ✓ 技能点更新")

	hud.update_health()
	print("  ✓ 生命值更新")

	hud.show_notification("测试通知", 1.0)
	print("  ✓ 通知显示")

	hud.queue_free()

## 测试 4: 背包面板
func test_inventory_panel() -> void:
	var InventoryPanelClass = load("res://scripts/ui/inventory_panel.gd")
	var panel = InventoryPanelClass.new()
	add_child(panel)

	await get_tree().process_frame

	# 测试刷新
	panel.refresh()
	print("  ✓ 背包面板刷新成功")

	# 检查槽位按钮
	print("  - 槽位按钮数量: %d" % panel.slot_buttons.size())

	# 添加测试物品
	var test_item = GameManager.item_database.get_item_by_id("health_potion")
	if test_item:
		GameManager.inventory_system.add_item(test_item, 5)
		await get_tree().process_frame
		print("  ✓ 测试物品添加成功")

	panel.queue_free()

## 测试 5: 装备面板
func test_equipment_panel() -> void:
	var EquipmentPanelClass = load("res://scripts/ui/equipment_panel.gd")
	var panel = EquipmentPanelClass.new()
	add_child(panel)

	await get_tree().process_frame

	# 测试刷新
	panel.refresh()
	print("  ✓ 装备面板刷新成功")

	# 检查装备槽位
	print("  - 装备槽位数量: %d" % panel.slot_buttons.size())

	# 显示总属性
	var stats = GameManager.equipment_system.get_total_stats()
	print("  - 装备总属性: %d 项" % stats.size())

	# 显示装备评分
	var score = GameManager.equipment_system.get_equipment_score()
	print("  - 装备评分: %d" % score)

	panel.queue_free()

## 测试 6: 技能树面板
func test_skill_tree_panel() -> void:
	var SkillTreePanelClass = load("res://scripts/ui/skill_tree_panel.gd")
	var panel = SkillTreePanelClass.new()
	add_child(panel)

	await get_tree().process_frame

	# 测试刷新
	panel.refresh()
	print("  ✓ 技能树面板刷新成功")

	# 检查技能树容器
	print("  - 技能树容器数量: %d" % panel.tree_containers.size())

	# 检查技能按钮
	print("  - 技能按钮数量: %d" % panel.skill_buttons.size())

	# 显示可用技能点
	var points = GameManager.skill_tree_system.available_skill_points
	print("  - 可用技能点: %d" % points)

	panel.queue_free()

## 测试 7: 成就面板
func test_achievement_panel() -> void:
	var AchievementPanelClass = load("res://scripts/ui/achievement_panel.gd")
	var panel = AchievementPanelClass.new()
	add_child(panel)

	await get_tree().process_frame

	# 测试刷新
	panel.refresh()
	print("  ✓ 成就面板刷新成功")

	# 显示成就统计
	var unlocked = GameManager.achievement_system.get_unlocked_count()
	var total = GameManager.achievement_system.get_total_count()
	print("  - 成就进度: %d/%d" % [unlocked, total])

	panel.queue_free()

## 测试 8: 商店面板
func test_shop_panel() -> void:
	var ShopPanelClass = load("res://scripts/ui/shop_panel.gd")
	var panel = ShopPanelClass.new()
	add_child(panel)

	await get_tree().process_frame

	# 测试刷新
	panel.refresh()
	print("  ✓ 商店面板刷新成功")

	# 检查商店容器
	print("  - 商店容器数量: %d" % panel.shop_containers.size())

	# 显示金币
	var gold = GameManager.shop_system.get_player_gold()
	print("  - 当前金币: %d" % gold)

	# 获取所有商店
	var shops = GameManager.shop_system.get_all_shops()
	print("  - 商店数量: %d" % shops.size())

	panel.queue_free()
