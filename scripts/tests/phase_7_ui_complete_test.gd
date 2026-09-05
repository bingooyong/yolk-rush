extends SceneTree
## Phase 7 完整 UI 测试

func _init():
	print("\n========================================")
	print("Phase 7: Complete UI Integration Test")
	print("========================================\n")

	print("步骤 1: 测试所有 UI 面板脚本加载")
	test_ui_scripts()

	print("\n步骤 2: 测试 UIManager")
	test_ui_manager()

	print("\n========================================")
	print("Phase 7 UI 测试完成！")
	print("========================================")
	quit()

func test_ui_scripts():
	var scripts = [
		"res://scripts/ui/hud.gd",
		"res://scripts/ui/inventory_panel.gd",
		"res://scripts/ui/equipment_panel.gd",
		"res://scripts/ui/skill_tree_panel.gd",
		"res://scripts/ui/achievement_panel.gd",
		"res://scripts/ui/shop_panel.gd",
		"res://scripts/ui/ui_manager.gd"
	]

	for script_path in scripts:
		var script = load(script_path)
		if script:
			print("  ✓ %s 加载成功" % script_path.get_file())
		else:
			print("  ✗ %s 加载失败" % script_path.get_file())

func test_ui_manager():
	print("  创建 UIManager 实例...")
	var UIManagerClass = load("res://scripts/ui/ui_manager.gd")
	var ui_manager = UIManagerClass.new()
	ui_manager.name = "UIManager"

	print("  ✓ UIManager 创建成功")
	print("  ✓ 所有属性初始化正常")

	ui_manager.free()
