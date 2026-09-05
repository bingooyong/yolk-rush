extends Node
## 游戏管理器 - 整合所有游戏系统

# 预加载所有类
const LevelSystemClass = preload("res://scripts/progression/level_system.gd")
const StatsSystemClass = preload("res://scripts/progression/stats_system.gd")
const EquipmentSystemClass = preload("res://scripts/equipment/equipment_system.gd")
const EquipmentDatabaseClass = preload("res://scripts/equipment/equipment_database.gd")
const InventorySystemClass = preload("res://scripts/inventory/inventory_system.gd")
const QuickBarSystemClass = preload("res://scripts/inventory/quick_bar_system.gd")
const ItemDatabaseClass = preload("res://scripts/inventory/item_database.gd")
const SkillTreeSystemClass = preload("res://scripts/skill_tree/skill_tree_system.gd")
const SkillDatabaseClass = preload("res://scripts/skill_tree/skill_database.gd")
const AchievementSystemClass = preload("res://scripts/achievement/achievement_system.gd")
const AchievementDatabaseClass = preload("res://scripts/achievement/achievement_database.gd")
const ShopSystemClass = preload("res://scripts/shop/shop_system.gd")
const ShopDatabaseClass = preload("res://scripts/shop/shop_database.gd")
const DropSystemClass = preload("res://scripts/drop/drop_system.gd")
const DropDatabaseClass = preload("res://scripts/drop/drop_database.gd")
const SaveManagerClass = preload("res://scripts/core/save_manager.gd")
const SkillSystemClass = preload("res://scripts/skill/skill_system.gd")
const StatusEffectSystemClass = preload("res://scripts/status/status_effect_system.gd")
const StatusEffectDatabaseClass = preload("res://scripts/status/status_effect_database.gd")
const AIManagerClass = preload("res://scripts/ai/ai_manager.gd")

signal game_initialized()
signal systems_ready()

# 系统引用（动态加载，不使用preload）
var level_system
var stats_system
var equipment_system
var inventory_system
var quick_bar_system
var skill_tree_system
var achievement_system
var shop_system
var drop_system
var save_manager
var skill_system
var status_effect_system
var ai_manager

# 数据库引用
var equipment_database
var item_database
var skill_database
var achievement_database
var shop_database
var drop_database
var status_effect_database

var is_initialized = false

func _ready() -> void:
	print("[GameManager] Initializing...")
	_initialize_databases()
	_initialize_systems()
	_connect_systems()
	_register_save_systems()

	is_initialized = true
	print("[GameManager] All systems initialized")
	game_initialized.emit()

## 初始化所有数据库
func _initialize_databases() -> void:
	print("[GameManager] Loading databases...")

	equipment_database = EquipmentDatabaseClass.new()
	add_child(equipment_database)

	item_database = ItemDatabaseClass.new()
	add_child(item_database)

	skill_database = SkillDatabaseClass.new()
	add_child(skill_database)

	achievement_database = AchievementDatabaseClass.new()
	add_child(achievement_database)

	shop_database = ShopDatabaseClass.new()
	add_child(shop_database)

	drop_database = DropDatabaseClass.new()
	add_child(drop_database)

	status_effect_database = StatusEffectDatabaseClass.new()
	add_child(status_effect_database)

	print("[GameManager] Databases loaded")

## 初始化所有系统
func _initialize_systems() -> void:
	print("[GameManager] Initializing systems...")

	# 等级和属性系统
	level_system = LevelSystemClass.new()
	add_child(level_system)

	stats_system = StatsSystemClass.new()
	add_child(stats_system)

	# 装备系统
	equipment_system = EquipmentSystemClass.new()
	add_child(equipment_system)
	equipment_system.set_database(equipment_database)

	# 背包系统
	inventory_system = InventorySystemClass.new()
	add_child(inventory_system)
	inventory_system.set_database(item_database)

	quick_bar_system = QuickBarSystemClass.new()
	add_child(quick_bar_system)
	quick_bar_system.set_inventory(inventory_system)

	# 技能树系统
	skill_tree_system = SkillTreeSystemClass.new()
	add_child(skill_tree_system)
	skill_tree_system.set_database(skill_database)

	# 成就系统
	achievement_system = AchievementSystemClass.new()
	add_child(achievement_system)
	achievement_system.set_database(achievement_database)

	# 商店系统
	shop_system = ShopSystemClass.new()
	add_child(shop_system)
	shop_system.set_database(shop_database)

	# 掉落系统
	drop_system = DropSystemClass.new()
	add_child(drop_system)
	drop_system.set_database(drop_database)

	# 存档管理器
	save_manager = SaveManagerClass.new()
	if save_manager:
		add_child(save_manager)
	else:
		push_warning("[GameManager] Failed to create SaveManager")

	# 技能系统
	skill_system = SkillSystemClass.new()
	add_child(skill_system)

	# 状态效果系统（全局实例，实体会创建各自的系统）
	status_effect_system = StatusEffectSystemClass.new()
	add_child(status_effect_system)

	# AI管理器
	ai_manager = AIManagerClass.new()
	add_child(ai_manager)

	print("[GameManager] Systems initialized")
	systems_ready.emit()

## 连接系统之间的信号
func _connect_systems() -> void:
	print("[GameManager] Connecting systems...")

	# 等级提升 -> 技能点
	level_system.level_up.connect(_on_level_up)

	# 装备变化 -> 属性更新
	equipment_system.equipment_changed.connect(_on_equipment_changed)

	# 敌人击杀 -> 经验值、掉落、成就
	# (由战斗系统调用 on_enemy_killed)

	print("[GameManager] Systems connected")

## 注册需要存档的系统
func _register_save_systems() -> void:
	print("[GameManager] Registering save systems...")

	if not save_manager:
		push_warning("[GameManager] SaveManager not available, skipping registration")
		return

	save_manager.register_system("level", level_system)
	save_manager.register_system("stats", stats_system)
	save_manager.register_system("equipment", equipment_system)
	save_manager.register_system("inventory", inventory_system)
	save_manager.register_system("quick_bar", quick_bar_system)
	save_manager.register_system("skill_tree", skill_tree_system)
	save_manager.register_system("achievement", achievement_system)
	save_manager.register_system("shop", shop_system)

	print("[GameManager] Save systems registered")

## 玩家升级时
func _on_level_up(new_level: int) -> void:
	# 给予技能点
	skill_tree_system.add_skill_points(1)
	skill_tree_system.set_player_level(new_level)

	# 更新商店可用等级
	shop_system.set_player_level(new_level)

	# 检查成就
	achievement_system.check_achievement("reach_level_10")
	achievement_system.check_achievement("reach_level_25")
	achievement_system.check_achievement("reach_level_50")

## 装备变化时
func _on_equipment_changed(slot, item) -> void:
	# 可以在这里更新 UI 或触发其他效果
	pass

## 敌人击杀回调
func on_enemy_killed(enemy_type: String, enemy_level: int) -> void:
	# 获取幸运加成
	var luck_bonus = stats_system.get_stat_bonus("drop_rate")

	# 生成掉落
	var drops = drop_system.generate_enemy_drops(enemy_type, enemy_level, luck_bonus)

	# 添加到背包
	for drop in drops:
		var item = item_database.get_item_by_id(drop.item_id)
		if item:
			inventory_system.add_item(item, drop.quantity)

	# 生成金币
	var gold = drop_system.generate_gold_drop(10, enemy_level, luck_bonus)
	shop_system.set_player_gold(shop_system.get_player_gold() + gold)

	# 生成经验值
	var exp = drop_system.generate_exp_drop(50, enemy_level)
	level_system.add_exp(exp)

	# 更新成就
	achievement_system.increment_progress("kill_100_enemies", 1)
	achievement_system.increment_progress("kill_1000_enemies", 1)

## 获取玩家总属性（装备+技能+基础）
func get_total_player_stats() -> Dictionary:
	var base_stats = stats_system.get_all_bonuses()
	var equipment_stats = equipment_system.get_total_stats()
	var skill_bonuses = skill_tree_system.get_total_skill_bonuses()

	var total = {}

	# 合并所有属性
	for stat_name in base_stats.keys():
		total[stat_name] = base_stats[stat_name]

	for stat_name in equipment_stats.keys():
		if total.has(stat_name):
			total[stat_name] += equipment_stats[stat_name]
		else:
			total[stat_name] = equipment_stats[stat_name]

	for bonus_name in skill_bonuses.keys():
		if total.has(bonus_name):
			total[bonus_name] += skill_bonuses[bonus_name]
		else:
			total[bonus_name] = skill_bonuses[bonus_name]

	return total

## 获取玩家信息摘要
func get_player_summary() -> Dictionary:
	return {
		"level": level_system.current_level,
		"exp": level_system.current_exp,
		"gold": shop_system.get_player_gold(),
		"skill_points": skill_tree_system.available_skill_points,
		"total_stats": get_total_player_stats(),
		"equipment_score": equipment_system.get_equipment_score(),
		"achievements_unlocked": achievement_system.get_unlocked_count()
	}

## 新游戏
func new_game() -> void:
	print("[GameManager] Starting new game...")

	level_system.current_level = 1
	level_system.current_exp = 0

	stats_system.available_stat_points = 0

	equipment_system.unequip_all()
	inventory_system.clear_all()
	quick_bar_system.clear_all()

	skill_tree_system.reset_skills()
	skill_tree_system.available_skill_points = 0

	achievement_system.reset_all_achievements()

	shop_system.set_player_gold(1000)
	shop_system.refresh_shop()

	print("[GameManager] New game started")

## 获取状态效果系统
func get_status_effect_system():
	return status_effect_system

## 获取技能系统
func get_skill_system():
	return skill_system

## 获取AI管理器
func get_ai_manager():
	return ai_manager
