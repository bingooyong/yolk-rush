extends Resource
## 背包物品基类

enum ItemType {
	EQUIPMENT,
	CONSUMABLE,
	MATERIAL,
	QUEST,
	CURRENCY
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: String = ""
@export var item_name: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var max_stack_size: int = 99
@export var icon_path: String = ""
@export var description: String = ""
@export var sell_price: int = 0
@export var buy_price: int = 0

## 是否可堆叠
func is_stackable() -> bool:
	return max_stack_size > 1

## 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color.WHITE
		Rarity.UNCOMMON: return Color(0.12, 1.0, 0.0)
		Rarity.RARE: return Color(0.0, 0.44, 0.87)
		Rarity.EPIC: return Color(0.64, 0.21, 0.93)
		Rarity.LEGENDARY: return Color(1.0, 0.5, 0.0)
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
	match item_type:
		ItemType.EQUIPMENT: return "装备"
		ItemType.CONSUMABLE: return "消耗品"
		ItemType.MATERIAL: return "材料"
		ItemType.QUEST: return "任务物品"
		ItemType.CURRENCY: return "货币"
		_: return "未知"

## 获取 Tooltip 文本
func get_tooltip_text() -> String:
	var text := ""
	text += "[color=%s]%s[/color]\n" % [get_rarity_color().to_html(), item_name]
	text += "[color=gray]%s | %s[/color]\n" % [get_type_text(), get_rarity_text()]

	if not description.is_empty():
		text += "\n%s\n" % description

	if sell_price > 0:
		text += "\n[color=yellow]售价: %d 金币[/color]" % sell_price

	return text

## 复制物品
func duplicate_item():
	var copy = duplicate()
	return copy

## 转换为存档数据
func to_save_data() -> Dictionary:
	return {
		"id": id
	}
