extends GutTest
## EquipmentSystem 单元测试

var equipment_system: EquipmentSystem
var mock_database: Node
var mock_player: Node3D

func before_each():
	# 创建系统
	equipment_system = EquipmentSystem.new()
	add_child_autofree(equipment_system)

	# 创建模拟数据库
	mock_database = Node.new()
	mock_database.set_script(load("res://scripts/equipment/equipment_database.gd"))
	add_child_autofree(mock_database)

	# 创建模拟玩家
	mock_player = Node3D.new()
	add_child_autofree(mock_player)

	equipment_system._ready()
	equipment_system.set_database(mock_database)
	equipment_system.set_player(mock_player)

func after_each():
	equipment_system = null
	mock_database = null
	mock_player = null

## 测试初始化
func test_initialization():
	assert_eq(equipment_system.equipped_items.size(), 9, "Should have 9 equipment slots")
	assert_null(equipment_system.equipped_items["main_hand"], "Main hand should be empty")
	assert_null(equipment_system.equipped_items["helmet"], "Helmet should be empty")

## 测试装备物品
func test_equip_item():
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)

	watch_signals(equipment_system)
	var success := equipment_system.equip_item(sword)

	assert_true(success, "Should equip successfully")
	assert_eq(equipment_system.equipped_items["main_hand"], sword, "Should be in main hand")
	assert_signal_emitted(equipment_system, "equipment_changed", "Should emit equipment_changed")

## 测试装备到正确槽位
func test_equip_to_correct_slot():
	var helmet := _create_test_armor("helmet_leather", "皮革头盔", EquipmentItem.EquipmentType.HELMET)

	equipment_system.equip_item(helmet)

	assert_eq(equipment_system.equipped_items["helmet"], helmet, "Should be in helmet slot")
	assert_null(equipment_system.equipped_items["chest"], "Chest should be empty")

## 测试替换装备
func test_replace_equipment():
	var sword1 := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	var sword2 := _create_test_weapon("sword_steel", "钢剑", 5, 25)

	equipment_system.equip_item(sword1)
	assert_eq(equipment_system.equipped_items["main_hand"], sword1, "Should equip first sword")

	equipment_system.equip_item(sword2)
	assert_eq(equipment_system.equipped_items["main_hand"], sword2, "Should replace with second sword")

## 测试戒指双槽位
func test_ring_dual_slots():
	var ring1 := _create_test_accessory("ring_power", "力量戒指", EquipmentItem.EquipmentType.RING)
	var ring2 := _create_test_accessory("ring_agility", "敏捷戒指", EquipmentItem.EquipmentType.RING)

	equipment_system.equip_item(ring1)
	equipment_system.equip_item(ring2)

	assert_eq(equipment_system.equipped_items["ring_1"], ring1, "Ring 1 should be equipped")
	assert_eq(equipment_system.equipped_items["ring_2"], ring2, "Ring 2 should be equipped")

## 测试卸下装备
func test_unequip_item():
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)

	equipment_system.equip_item(sword)
	watch_signals(equipment_system)

	var unequipped := equipment_system.unequip_item("main_hand")

	assert_eq(unequipped, sword, "Should return the unequipped item")
	assert_null(equipment_system.equipped_items["main_hand"], "Slot should be empty")
	assert_signal_emitted(equipment_system, "equipment_changed", "Should emit signal")

## 测试卸下空槽位
func test_unequip_empty_slot():
	var unequipped := equipment_system.unequip_item("main_hand")

	assert_null(unequipped, "Should return null for empty slot")

## 测试槽位检查
func test_slot_empty_check():
	assert_true(equipment_system.is_slot_empty("main_hand"), "Should be empty initially")

	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	equipment_system.equip_item(sword)

	assert_false(equipment_system.is_slot_empty("main_hand"), "Should not be empty after equip")

## 测试获取装备
func test_get_equipped_item():
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	equipment_system.equip_item(sword)

	var retrieved := equipment_system.get_equipped_item("main_hand")

	assert_eq(retrieved, sword, "Should retrieve the equipped item")

## 测试总属性计算
func test_total_stats_calculation():
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	sword.stats = {"physical_damage": 50, "crit_chance": 0.1}

	var helmet := _create_test_armor("helmet_leather", "皮革头盔", EquipmentItem.EquipmentType.HELMET)
	helmet.stats = {"defense": 20, "max_health": 100}

	equipment_system.equip_item(sword)
	equipment_system.equip_item(helmet)

	var total := equipment_system.get_total_stats()

	assert_eq(total["physical_damage"], 50.0, "Physical damage should be 50")
	assert_almost_eq(total["crit_chance"], 0.1, 0.01, "Crit chance should be 0.1")
	assert_eq(total["defense"], 20.0, "Defense should be 20")
	assert_eq(total["max_health"], 100.0, "Max health should be 100")

## 测试多件装备属性叠加
func test_multiple_equipment_stats_stacking():
	var sword := _create_test_weapon("sword", "剑", 1, 10)
	sword.stats = {"physical_damage": 50}

	var ring1 := _create_test_accessory("ring1", "戒指1", EquipmentItem.EquipmentType.RING)
	ring1.stats = {"physical_damage": 15}

	var ring2 := _create_test_accessory("ring2", "戒指2", EquipmentItem.EquipmentType.RING)
	ring2.stats = {"physical_damage": 15}

	equipment_system.equip_item(sword)
	equipment_system.equip_item(ring1)
	equipment_system.equip_item(ring2)

	var total := equipment_system.get_total_stats()

	assert_eq(total["physical_damage"], 80.0, "Total physical damage should be 80")

## 测试获取所有已装备物品
func test_get_all_equipped_items():
	var sword := _create_test_weapon("sword", "剑", 1, 10)
	var helmet := _create_test_armor("helmet", "头盔", EquipmentItem.EquipmentType.HELMET)

	equipment_system.equip_item(sword)
	equipment_system.equip_item(helmet)

	var all_items := equipment_system.get_all_equipped_items()

	assert_eq(all_items.size(), 2, "Should have 2 equipped items")
	assert_true(all_items.has(sword), "Should contain sword")
	assert_true(all_items.has(helmet), "Should contain helmet")

## 测试装备评分
func test_equipment_score():
	var common := _create_test_weapon("common", "普通", 1, 10)
	common.rarity = EquipmentItem.Rarity.COMMON

	var rare := _create_test_armor("rare", "稀有", EquipmentItem.EquipmentType.HELMET)
	rare.rarity = EquipmentItem.Rarity.RARE

	var epic := _create_test_accessory("epic", "史诗", EquipmentItem.EquipmentType.RING)
	epic.rarity = EquipmentItem.Rarity.EPIC

	equipment_system.equip_item(common)  # +10
	equipment_system.equip_item(rare)    # +50
	equipment_system.equip_item(epic)    # +100

	var score := equipment_system.get_equipment_score()

	assert_eq(score, 160, "Total score should be 160")

## 测试卸下所有装备
func test_unequip_all():
	var sword := _create_test_weapon("sword", "剑", 1, 10)
	var helmet := _create_test_armor("helmet", "头盔", EquipmentItem.EquipmentType.HELMET)
	var ring := _create_test_accessory("ring", "戒指", EquipmentItem.EquipmentType.RING)

	equipment_system.equip_item(sword)
	equipment_system.equip_item(helmet)
	equipment_system.equip_item(ring)

	var unequipped := equipment_system.unequip_all()

	assert_eq(unequipped.size(), 3, "Should unequip 3 items")
	assert_true(equipment_system.is_slot_empty("main_hand"), "Main hand should be empty")
	assert_true(equipment_system.is_slot_empty("helmet"), "Helmet should be empty")

## 测试存档保存
func test_save_data():
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	var helmet := _create_test_armor("helmet_leather", "皮革头盔", EquipmentItem.EquipmentType.HELMET)

	equipment_system.equip_item(sword)
	equipment_system.equip_item(helmet)

	var save_data := equipment_system.get_save_data()

	assert_true(save_data.has("main_hand"), "Should have main_hand data")
	assert_true(save_data.has("helmet"), "Should have helmet data")
	assert_true(save_data["main_hand"] is Dictionary, "Main hand should have save data")
	assert_null(save_data["chest"], "Empty slots should be null")

## 测试存档加载
func test_load_save_data():
	# 先装备一些物品
	var sword := _create_test_weapon("sword_iron", "铁剑", 1, 10)
	equipment_system.equip_item(sword)

	var save_data := equipment_system.get_save_data()

	# 清空
	equipment_system.unequip_all()
	assert_true(equipment_system.is_slot_empty("main_hand"), "Should be empty before load")

	# 加载（需要数据库支持）
	watch_signals(equipment_system)
	equipment_system.load_save_data(save_data)

	assert_signal_emitted(equipment_system, "equipment_changed", "Should emit signals on load")

## 辅助函数：创建测试武器
func _create_test_weapon(id: String, name: String, level: int, damage: float) -> EquipmentItem:
	var item := EquipmentItem.new()
	item.id = id
	item.item_name = name
	item.equipment_type = EquipmentItem.EquipmentType.MAIN_HAND
	item.level_requirement = level
	item.rarity = EquipmentItem.Rarity.COMMON
	item.stats = {"physical_damage": damage}
	return item

## 辅助函数：创建测试护甲
func _create_test_armor(id: String, name: String, type: EquipmentItem.EquipmentType) -> EquipmentItem:
	var item := EquipmentItem.new()
	item.id = id
	item.item_name = name
	item.equipment_type = type
	item.level_requirement = 1
	item.rarity = EquipmentItem.Rarity.COMMON
	item.stats = {"defense": 10}
	return item

## 辅助函数：创建测试饰品
func _create_test_accessory(id: String, name: String, type: EquipmentItem.EquipmentType) -> EquipmentItem:
	var item := EquipmentItem.new()
	item.id = id
	item.item_name = name
	item.equipment_type = type
	item.level_requirement = 1
	item.rarity = EquipmentItem.Rarity.COMMON
	item.stats = {"crit_chance": 0.05}
	return item
