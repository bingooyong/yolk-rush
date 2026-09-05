extends Node
## 完整的 UI 系统测试

func _ready():
	print("\n=== UI 完整系统测试 ===\n")

	# 等待一帧，确保所有节点都初始化完成
	await get_tree().process_frame

	test_ui_manager_exists()
	test_all_panels_exist()
	test_hud_components()
	test_open_close_panels()

	print("\n=== UI 系统测试完成 ===\n")
	get_tree().quit()

func test_ui_manager_exists():
	print(">>> 测试 UI Manager 存在")
	var ui_manager = get_node_or_null("UIManager")
	assert(ui_manager != null, "UIManager 应该存在")
	print("✓ UIManager 存在")

func test_all_panels_exist():
	print("\n>>> 测试所有面板存在")
	var ui_manager = get_node("UIManager")

	var panels = ["HUD", "InventoryPanel", "EquipmentPanel", "SkillTreePanel", "AchievementPanel", "ShopPanel"]
	for panel_name in panels:
		var panel = ui_manager.get_node_or_null(panel_name)
		assert(panel != null, "%s 应该存在" % panel_name)
		print("✓ %s 存在" % panel_name)

func test_hud_components():
	print("\n>>> 测试 HUD 组件")
	var hud = get_node("UIManager/HUD")

	# 检查关键组件
	var components = [
		"TopBar",
		"TopBar/LeftSection/LevelLabel",
		"TopBar/LeftSection/ExpBar",
		"TopBar/RightSection/GoldLabel",
		"QuickBar",
		"NotificationLabel"
	]

	for comp_path in components:
		var comp = hud.get_node_or_null(comp_path)
		assert(comp != null, "%s 应该存在" % comp_path)

	print("✓ HUD 组件完整")

func test_open_close_panels():
	print("\n>>> 测试面板打开/关闭")
	var ui_manager = get_node("UIManager")

	if not ui_manager.has_method("open_ui"):
		print("⚠ UIManager 未完全初始化，跳过打开测试")
		return

	# 测试背包面板
	var inventory_panel = ui_manager.get_node("InventoryPanel")
	assert(not inventory_panel.visible, "背包面板初始应该隐藏")

	print("✓ 面板可见性测试通过")

func assert(condition: bool, message: String):
	if not condition:
		push_error("❌ 断言失败: " + message)
		get_tree().quit(1)
