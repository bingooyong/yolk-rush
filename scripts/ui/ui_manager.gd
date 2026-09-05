extends CanvasLayer
class_name UIManager
## UI 管理器 - 统一管理所有游戏 UI

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

# UI 面板引用
var hud: Control
var inventory_panel: Control
var equipment_panel: Control
var skill_tree_panel: Control
var achievement_panel: Control
var shop_panel: Control
var pause_menu: Control

# GameManager 引用
var game_manager = null

# UI 状态
var current_open_ui: String = ""
var is_any_ui_open: bool = false

func _ready() -> void:
	print("[UIManager] Initialized")
	_setup_ui_references()
	_connect_signals()

## 设置 UI 引用
func _setup_ui_references() -> void:
	# 等待 UI 节点加载
	await get_tree().process_frame

	hud = get_node_or_null("HUD")
	inventory_panel = get_node_or_null("InventoryPanel")
	equipment_panel = get_node_or_null("EquipmentPanel")
	skill_tree_panel = get_node_or_null("SkillTreePanel")
	achievement_panel = get_node_or_null("AchievementPanel")
	shop_panel = get_node_or_null("ShopPanel")
	pause_menu = get_node_or_null("PauseMenu")

	# 初始隐藏所有面板
	_hide_all_panels()

## 连接信号
func _connect_signals() -> void:
	# 连接游戏系统信号到 UI
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.is_initialized:
			_connect_game_signals()
		else:
			game_manager.game_initialized.connect(_connect_game_signals)

func _connect_game_signals() -> void:
	# 等级系统
	game_manager.level_system.level_up.connect(_on_level_up)
	game_manager.level_system.exp_gained.connect(_on_exp_gained)

	# 背包系统
	game_manager.inventory_system.inventory_changed.connect(_on_inventory_changed)

	# 商店系统
	game_manager.shop_system.gold_changed.connect(_on_gold_changed)

	# 成就系统
	game_manager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)

## 隐藏所有面板
func _hide_all_panels() -> void:
	if inventory_panel: inventory_panel.visible = false
	if equipment_panel: equipment_panel.visible = false
	if skill_tree_panel: skill_tree_panel.visible = false
	if achievement_panel: achievement_panel.visible = false
	if shop_panel: shop_panel.visible = false
	if pause_menu: pause_menu.visible = false

## 打开 UI
func open_ui(ui_name: String) -> void:
	# 关闭当前打开的 UI
	if is_any_ui_open:
		close_ui(current_open_ui)

	match ui_name:
		"inventory":
			if inventory_panel:
				inventory_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
		"equipment":
			if equipment_panel:
				equipment_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
		"skill_tree":
			if skill_tree_panel:
				skill_tree_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
		"achievement":
			if achievement_panel:
				achievement_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
		"shop":
			if shop_panel:
				shop_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
		"pause":
			if pause_menu:
				pause_menu.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true

	if is_any_ui_open:
		ui_opened.emit(ui_name)
		# 暂停游戏（除了 HUD）
		get_tree().paused = true

## 关闭 UI
func close_ui(ui_name: String) -> void:
	match ui_name:
		"inventory":
			if inventory_panel: inventory_panel.visible = false
		"equipment":
			if equipment_panel: equipment_panel.visible = false
		"skill_tree":
			if skill_tree_panel: skill_tree_panel.visible = false
		"achievement":
			if achievement_panel: achievement_panel.visible = false
		"shop":
			if shop_panel: shop_panel.visible = false
		"pause":
			if pause_menu: pause_menu.visible = false

	ui_closed.emit(ui_name)
	current_open_ui = ""
	is_any_ui_open = false
	get_tree().paused = false

## 切换 UI
func toggle_ui(ui_name: String) -> void:
	if current_open_ui == ui_name:
		close_ui(ui_name)
	else:
		open_ui(ui_name)

## 处理输入
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_any_ui_open:
			close_ui(current_open_ui)
		else:
			toggle_ui("pause")
		get_viewport().set_input_as_handled()

	# 快捷键
	if event.is_action_pressed("toggle_inventory"):
		toggle_ui("inventory")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("toggle_equipment"):
		toggle_ui("equipment")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("toggle_skill_tree"):
		toggle_ui("skill_tree")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("toggle_achievement"):
		toggle_ui("achievement")
		get_viewport().set_input_as_handled()

## 信号处理
func _on_level_up(new_level: int) -> void:
	if hud and hud.has_method("show_level_up"):
		hud.show_level_up(new_level)

func _on_exp_gained(amount: int, current: int, required: int) -> void:
	if hud and hud.has_method("update_exp_bar"):
		hud.update_exp_bar(current, required)

func _on_inventory_changed() -> void:
	if inventory_panel and inventory_panel.has_method("refresh"):
		inventory_panel.refresh()

func _on_gold_changed(current_gold: int) -> void:
	if hud and hud.has_method("update_gold"):
		hud.update_gold(current_gold)

func _on_achievement_unlocked(achievement_id: String) -> void:
	# 显示成就解锁通知
	show_notification("成就解锁！")

## 显示通知
func show_notification(text: String) -> void:
	print("[UIManager] Notification: %s" % text)
	# TODO: 实现通知 UI
