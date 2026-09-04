extends GutTest
## EquipmentItem 单元测试

var item: EquipmentItem

func before_each():
	item = EquipmentItem.new()

func after_each():
	item = null

## 测试初始化
func test_initialization():
	assert_eq(item.id, "", "Initial id should be empty")
	assert_eq(item.item_name, "", "Initial name should be empty")
	assert_eq(item.level_requirement, 1, "Initial level requirement should be 1")
	assert_eq(item.rarity, EquipmentItem.Rarity.COMMON, "Initial rarity should be COMMON")

## 测试从 JSON 创建
func test_from_json():
	var data := {
		"id": "sword_iron",
		"name": "铁剑",
		"type": "main_hand",
		"rarity": "common",
		"level_requirement": 1,
		"stats": {
			"physical_damage": 10
		},
		"icon": "res://assets/icons/weapons/sword_iron.png"
	}

	var sword := EquipmentItem.from_json(data)

	assert_eq(sword.id, "sword_iron", "ID should match")
	assert_eq(sword.item_name, "铁剑", "Name should match")
	assert_eq(sword.equipment_type, EquipmentItem.EquipmentType.MAIN_HAND, "Type should be MAIN_HAND")
	assert_eq(sword.rarity, EquipmentItem.Rarity.COMMON, "Rarity should be COMMON")
	assert_eq(sword.level_requirement, 1, "Level requirement should be 1")
	assert_eq(sword.stats["physical_damage"], 10, "Physical damage should be 10")

## 测试稀有度解析
func test_rarity_parsing():
	var uncommon_data := {"rarity": "uncommon"}
	var uncommon := EquipmentItem.from_json(uncommon_data)
	assert_eq(uncommon.rarity, EquipmentItem.Rarity.UNCOMMON, "Should parse uncommon")

	var rare_data := {"rarity": "rare"}
	var rare := EquipmentItem.from_json(rare_data)
	assert_eq(rare.rarity, EquipmentItem.Rarity.RARE, "Should parse rare")

	var epic_data := {"rarity": "epic"}
	var epic := EquipmentItem.from_json(epic_data)
	assert_eq(epic.rarity, EquipmentItem.Rarity.EPIC, "Should parse epic")

	var legendary_data := {"rarity": "legendary"}
	var legendary := EquipmentItem.from_json(legendary_data)
	assert_eq(legendary.rarity, EquipmentItem.Rarity.LEGENDARY, "Should parse legendary")

## 测试类型解析
func test_type_parsing():
	var helmet_data := {"type": "helmet"}
	var helmet := EquipmentItem.from_json(helmet_data)
	assert_eq(helmet.equipment_type, EquipmentItem.EquipmentType.HELMET, "Should parse helmet")

	var chest_data := {"type": "chest"}
	var chest := EquipmentItem.from_json(chest_data)
	assert_eq(chest.equipment_type, EquipmentItem.EquipmentType.CHEST, "Should parse chest")

	var ring_data := {"type": "ring"}
	var ring := EquipmentItem.from_json(ring_data)
	assert_eq(ring.equipment_type, EquipmentItem.EquipmentType.RING, "Should parse ring")

## 测试稀有度颜色
func test_rarity_colors():
	item.rarity = EquipmentItem.Rarity.COMMON
	assert_eq(item.get_rarity_color(), Color.WHITE, "Common should be white")

	item.rarity = EquipmentItem.Rarity.LEGENDARY
	assert_eq(item.get_rarity_color(), Color(1.0, 0.5, 0.0), "Legendary should be orange")

## 测试稀有度文本
func test_rarity_text():
	item.rarity = EquipmentItem.Rarity.COMMON
	assert_eq(item.get_rarity_text(), "普通", "Common text should be correct")

	item.rarity = EquipmentItem.Rarity.EPIC
	assert_eq(item.get_rarity_text(), "史诗", "Epic text should be correct")

## 测试类型文本
func test_type_text():
	item.equipment_type = EquipmentItem.EquipmentType.MAIN_HAND
	assert_eq(item.get_type_text(), "主手武器", "Main hand text should be correct")

	item.equipment_type = EquipmentItem.EquipmentType.NECKLACE
	assert_eq(item.get_type_text(), "项链", "Necklace text should be correct")

## 测试属性描述
func test_stat_description():
	item.stats = {
		"physical_damage": 50,
		"crit_chance": 0.15,
		"max_health": 100
	}

	var desc := item.get_stat_description()

	assert_true(desc.contains("物理攻击"), "Should contain physical damage")
	assert_true(desc.contains("50"), "Should show damage value")
	assert_true(desc.contains("暴击率"), "Should contain crit chance")
	assert_true(desc.contains("15.0%"), "Should show percentage")
	assert_true(desc.contains("最大生命值"), "Should contain max health")

## 测试复制装备
func test_duplicate_item():
	item.id = "test_item"
	item.item_name = "测试装备"
	item.stats = {"physical_damage": 10}

	var copy := item.duplicate_item()

	assert_eq(copy.id, item.id, "ID should match")
	assert_eq(copy.item_name, item.item_name, "Name should match")
	assert_eq(copy.stats["physical_damage"], 10, "Stats should be copied")
	assert_ne(copy.stats, item.stats, "Stats should be a new dictionary")

## 测试存档数据转换
func test_save_data():
	item.id = "sword_steel"
	item.item_name = "钢剑"

	var save_data := item.to_save_data()

	assert_eq(save_data["id"], "sword_steel", "Save data should contain ID")
	assert_true(save_data is Dictionary, "Save data should be a dictionary")

## 测试 Tooltip 文本
func test_tooltip_text():
	item.item_name = "传说圣剑"
	item.rarity = EquipmentItem.Rarity.LEGENDARY
	item.equipment_type = EquipmentItem.EquipmentType.MAIN_HAND
	item.level_requirement = 30
	item.stats = {"physical_damage": 150}

	var tooltip := item.get_tooltip_text()

	assert_true(tooltip.contains("传说圣剑"), "Should contain item name")
	assert_true(tooltip.contains("主手武器"), "Should contain type")
	assert_true(tooltip.contains("等级要求: 30"), "Should contain level requirement")
	assert_true(tooltip.contains("物理攻击"), "Should contain stats")
