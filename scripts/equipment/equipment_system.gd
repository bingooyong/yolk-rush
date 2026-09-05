extends Node
class_name EquipmentSystem
## 装备系统 - 管理玩家装备栏

const EquipmentItemClass = preload("res://scripts/equipment/equipment_item.gd")

signal equipment_changed(slot: String, item)
signal stats_updated(total_stats: Dictionary)

## 装备槽位
var equipped_items: Dictionary = {
	"main_hand": null,
	"off_hand": null,
	"helmet": null,
	"chest": null,
	"gloves": null,
	"boots": null,
	"ring_1": null,
	"ring_2": null,
	"necklace": null
}

var equipment_database: Node = null
var player_ref: Node3D = null

func _ready() -> void:
	print("[EquipmentSystem] Initialized")

## 设置装备数据库
func set_database(db: Node) -> void:
	equipment_database = db
	print("[EquipmentSystem] Database set")

## 设置玩家引用
func set_player(player: Node3D) -> void:
	player_ref = player
	print("[EquipmentSystem] Player reference set")

## 装备物品
func equip_item(item) -> bool:
	if not item:
		push_error("[EquipmentSystem] Cannot equip null item")
		return false

	# 检查等级要求
	if not _check_level_requirement(item):
		print("[EquipmentSystem] Level requirement not met: %d" % item.level_requirement)
		return false

	# 确定装备槽位
	var slot := _get_slot_for_item(item)
	if slot.is_empty():
		push_error("[EquipmentSystem] No available slot for item type")
		return false

	# 卸下旧装备
	var old_item = equipped_items[slot]
	if old_item:
		print("[EquipmentSystem] Unequipping old item: %s" % old_item.item_name)

	# 装备新物品
	equipped_items[slot] = item
	print("[EquipmentSystem] Equipped %s to slot %s" % [item.item_name, slot])

	# 发射信号
	equipment_changed.emit(slot, item)

	# 更新角色属性
	_update_player_stats()

	# 返回旧装备到背包
	# if old_item and InventorySystem:
	# 	InventorySystem.add_item(old_item)

	return true

## 卸下装备
func unequip_item(slot: String):
	if not equipped_items.has(slot):
		push_error("[EquipmentSystem] Invalid slot: %s" % slot)
		return null

	var item = equipped_items[slot]
	if not item:
		print("[EquipmentSystem] No item in slot: %s" % slot)
		return null

	equipped_items[slot] = null
	print("[EquipmentSystem] Unequipped from slot %s" % slot)

	# 发射信号
	equipment_changed.emit(slot, null)

	# 更新角色属性
	_update_player_stats()

	return item

## 获取槽位装备
func get_equipped_item(slot: String):
	return equipped_items.get(slot, null)

## 检查槽位是否为空
func is_slot_empty(slot: String) -> bool:
	return equipped_items.get(slot, null) == null

## 检查等级要求
func _check_level_requirement(item) -> bool:
	# if not LevelSystem:
	# 	return true
	# return LevelSystem.player_level >= item.level_requirement
	return true  # 测试环境跳过等级检查

## 确定装备槽位
func _get_slot_for_item(item) -> String:
	match item.equipment_type:
		EquipmentItemClass.EquipmentType.MAIN_HAND:
			return "main_hand"
		EquipmentItemClass.EquipmentType.OFF_HAND:
			return "off_hand"
		EquipmentItemClass.EquipmentType.HELMET:
			return "helmet"
		EquipmentItemClass.EquipmentType.CHEST:
			return "chest"
		EquipmentItemClass.EquipmentType.GLOVES:
			return "gloves"
		EquipmentItemClass.EquipmentType.BOOTS:
			return "boots"
		EquipmentItemClass.EquipmentType.RING:
			# 优先装备空槽
			if is_slot_empty("ring_1"):
				return "ring_1"
			elif is_slot_empty("ring_2"):
				return "ring_2"
			else:
				return "ring_1"  # 替换第一个戒指
		EquipmentItemClass.EquipmentType.NECKLACE:
			return "necklace"
		_:
			return ""

## 计算总装备属性
func get_total_stats() -> Dictionary:
	var total := {
		"physical_damage": 0.0,
		"skill_damage": 0.0,
		"attack_speed": 0.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"max_health": 0.0,
		"defense": 0.0,
		"evasion": 0.0,
		"move_speed": 0.0
	}

	# 累加所有装备的属性
	for slot in equipped_items.keys():
		var item = equipped_items[slot]
		if item:
			for stat_key in item.stats.keys():
				if total.has(stat_key):
					total[stat_key] += item.stats[stat_key]

	return total

## 更新玩家属性
func _update_player_stats() -> void:
	if not player_ref:
		return

	var total_stats := get_total_stats()

	# 应用物理攻击
	if player_ref.has_node("CombatComponent"):
		var combat = player_ref.get_node("CombatComponent")
		if combat.has_method("set_equipment_bonus"):
			combat.set_equipment_bonus(total_stats["physical_damage"])

	# 应用生命值
	if player_ref.has_node("HealthComponent"):
		var health = player_ref.get_node("HealthComponent")
		if health.has_method("set_equipment_health_bonus"):
			health.set_equipment_health_bonus(total_stats["max_health"])

	# 应用技能伤害
	if player_ref.has_node("SkillSystem"):
		var skills = player_ref.get_node("SkillSystem")
		if skills.has_method("set_equipment_damage_multiplier"):
			skills.set_equipment_damage_multiplier(1.0 + total_stats["skill_damage"] / 100.0)

	# 应用攻击速度
	if player_ref.has_node("CombatComponent"):
		var combat = player_ref.get_node("CombatComponent")
		if combat.has_method("set_equipment_attack_speed"):
			combat.set_equipment_attack_speed(total_stats["attack_speed"])

	# 应用暴击
	if player_ref.has_node("CombatComponent"):
		var combat = player_ref.get_node("CombatComponent")
		if combat.has_method("set_equipment_crit_stats"):
			combat.set_equipment_crit_stats(total_stats["crit_chance"], total_stats["crit_damage"])

	print("[EquipmentSystem] Updated player stats")
	stats_updated.emit(total_stats)

## 获取所有已装备物品
func get_all_equipped_items() -> Array:
	var items: Array = []
	for slot in equipped_items.keys():
		var item = equipped_items[slot]
		if item:
			items.append(item)
	return items

## 获取装备评分
func get_equipment_score() -> int:
	var score := 0
	for item in get_all_equipped_items():
		match item.rarity:
			EquipmentItemClass.Rarity.COMMON: score += 10
			EquipmentItemClass.Rarity.UNCOMMON: score += 25
			EquipmentItemClass.Rarity.RARE: score += 50
			EquipmentItemClass.Rarity.EPIC: score += 100
			EquipmentItemClass.Rarity.LEGENDARY: score += 250
	return score

## 卸下所有装备
func unequip_all() -> Array:
	var unequipped_items: Array = []

	for slot in equipped_items.keys():
		var item = unequip_item(slot)
		if item:
			unequipped_items.append(item)

	return unequipped_items

## 存档数据
func get_save_data() -> Dictionary:
	var data := {}

	for slot in equipped_items.keys():
		var item = equipped_items[slot]
		if item:
			data[slot] = item.to_save_data()
		else:
			data[slot] = null

	return data

## 加载存档
func load_save_data(data: Dictionary) -> void:
	if not equipment_database:
		push_error("[EquipmentSystem] Cannot load without database")
		return

	# 清空当前装备
	for slot in equipped_items.keys():
		equipped_items[slot] = null

	# 加载装备
	for slot in data.keys():
		var item_data = data[slot]
		if item_data and item_data is Dictionary:
			var item = EquipmentItemClass.from_save_data(item_data, equipment_database)
			if item:
				equipped_items[slot] = item

	print("[EquipmentSystem] Loaded save data")

	# 更新属性
	_update_player_stats()

	# 发射所有槽位变化信号
	for slot in equipped_items.keys():
		equipment_changed.emit(slot, equipped_items[slot])

## 调试：装备指定 ID 的物品
func _debug_equip_by_id(item_id: String) -> void:
	if not equipment_database:
		push_error("[EquipmentSystem] Database not set")
		return

	if equipment_database.has_method("get_equipment_by_id"):
		var item = equipment_database.get_equipment_by_id(item_id)
		if item:
			equip_item(item)
		else:
			push_error("[EquipmentSystem] Item not found: %s" % item_id)
