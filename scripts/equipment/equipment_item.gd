extends Resource
class_name EquipmentItem
## 装备物品数据类

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum EquipmentType {
	MAIN_HAND,
	OFF_HAND,
	HELMET,
	CHEST,
	GLOVES,
	BOOTS,
	RING,
	NECKLACE
}

@export var id: String = ""
@export var item_name: String = ""
@export var equipment_type: EquipmentType = EquipmentType.MAIN_HAND
@export var rarity: Rarity = Rarity.COMMON
@export var level_requirement: int = 1
@export var icon_path: String = ""

## 装备属性加成
@export var stats: Dictionary = {}

## 从 JSON 数据创建装备
static func from_json(data: Dictionary) -> EquipmentItem:
	var item := EquipmentItem.new()

	item.id = data.get("id", "")
	item.item_name = data.get("name", "")
	item.level_requirement = data.get("level_requirement", 1)
	item.icon_path = data.get("icon", "")
	item.stats = data.get("stats", {})

	# 解析类型
	var type_str: String = data.get("type", "")
	match type_str:
		"main_hand": item.equipment_type = EquipmentType.MAIN_HAND
		"off_hand": item.equipment_type = EquipmentType.OFF_HAND
		"helmet": item.equipment_type = EquipmentType.HELMET
		"chest": item.equipment_type = EquipmentType.CHEST
		"gloves": item.equipment_type = EquipmentType.GLOVES
		"boots": item.equipment_type = EquipmentType.BOOTS
		"ring": item.equipment_type = EquipmentType.RING
		"necklace": item.equipment_type = EquipmentType.NECKLACE

	# 解析稀有度
	var rarity_str: String = data.get("rarity", "common")
	match rarity_str:
		"common": item.rarity = Rarity.COMMON
		"uncommon": item.rarity = Rarity.UNCOMMON
		"rare": item.rarity = Rarity.RARE
		"epic": item.rarity = Rarity.EPIC
		"legendary": item.rarity = Rarity.LEGENDARY

	return item

## 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color.WHITE
		Rarity.UNCOMMON: return Color(0.12, 1.0, 0.0)  # #1EFF00
		Rarity.RARE: return Color(0.0, 0.44, 0.87)     # #0070DD
		Rarity.EPIC: return Color(0.64, 0.21, 0.93)    # #A335EE
		Rarity.LEGENDARY: return Color(1.0, 0.5, 0.0)  # #FF8000
		_: return Color.WHITE

## 获取稀有度文本
func get_rarity_text() -> String:
	match rarity:
		Rarity.COMMON: return "普通"
		Rarity.UNCOMMON: return "优秀"
		Rarity.RARE: return "稀有"
		Rarity.EPIC: return "史诗"
		Rarity.LEGENDARY: return "传说"
		_: return "未知"

## 获取类型文本
func get_type_text() -> String:
	match equipment_type:
		EquipmentType.MAIN_HAND: return "主手武器"
		EquipmentType.OFF_HAND: return "副手武器"
		EquipmentType.HELMET: return "头盔"
		EquipmentType.CHEST: return "胸甲"
		EquipmentType.GLOVES: return "手套"
		EquipmentType.BOOTS: return "靴子"
		EquipmentType.RING: return "戒指"
		EquipmentType.NECKLACE: return "项链"
		_: return "未知"

## 获取属性描述文本
func get_stat_description() -> String:
	var lines: Array[String] = []

	for stat_key in stats.keys():
		var value = stats[stat_key]
		var stat_name := _get_stat_display_name(stat_key)

		# 判断是百分比还是固定值
		if stat_key in ["attack_speed", "crit_chance", "crit_damage", "evasion", "move_speed"]:
			lines.append("%s: +%.1f%%" % [stat_name, value * 100])
		else:
			lines.append("%s: +%d" % [stat_name, int(value)])

	return "\n".join(lines)

func _get_stat_display_name(stat_key: String) -> String:
	match stat_key:
		"physical_damage": return "物理攻击"
		"skill_damage": return "技能伤害"
		"attack_speed": return "攻击速度"
		"crit_chance": return "暴击率"
		"crit_damage": return "暴击伤害"
		"max_health": return "最大生命值"
		"defense": return "防御力"
		"evasion": return "闪避率"
		"move_speed": return "移动速度"
		_: return stat_key

## 获取完整描述（用于 Tooltip）
func get_tooltip_text() -> String:
	var text := ""
	text += "[color=%s]%s[/color]\n" % [get_rarity_color().to_html(), item_name]
	text += "[color=gray]%s | %s[/color]\n" % [get_type_text(), get_rarity_text()]
	text += "等级要求: %d\n" % level_requirement
	text += "\n"
	text += get_stat_description()

	return text

## 复制装备
func duplicate_item() -> EquipmentItem:
	var copy := EquipmentItem.new()
	copy.id = id
	copy.item_name = item_name
	copy.equipment_type = equipment_type
	copy.rarity = rarity
	copy.level_requirement = level_requirement
	copy.icon_path = icon_path
	copy.stats = stats.duplicate()
	return copy

## 转换为存档数据
func to_save_data() -> Dictionary:
	return {
		"id": id
	}

## 从存档数据加载（配合装备数据库）
static func from_save_data(save_data: Dictionary, database: Node) -> EquipmentItem:
	var item_id: String = save_data.get("id", "")
	if database and database.has_method("get_equipment_by_id"):
		return database.get_equipment_by_id(item_id)
	return null
