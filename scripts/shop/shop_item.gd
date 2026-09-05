extends Resource
## 商店物品

@export var item_id = ""
@export var buy_price = 0
@export var sell_price = 0
@export var stock = -1  # -1 = 无限库存
@export var required_level = 1
@export var category = ""

## 从JSON创建
static func from_json(data: Dictionary):
	var ShopItemClass = load("res://scripts/shop/shop_item.gd")
	var shop_item = ShopItemClass.new()
	shop_item.item_id = data.get("item_id", "")
	shop_item.buy_price = data.get("buy_price", 0)
	shop_item.sell_price = data.get("sell_price", 0)
	shop_item.stock = data.get("stock", -1)
	shop_item.required_level = data.get("required_level", 1)
	shop_item.category = data.get("category", "")
	return shop_item
