extends RefCounted
class_name ItemStack
## 物品堆叠数据

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")

var item = null  # InventoryItem
var quantity: int = 0

func _init(p_item = null, p_quantity: int = 1) -> void:
	item = p_item
	quantity = p_quantity

## 是否为空堆叠
func is_empty() -> bool:
	return item == null or quantity <= 0

## 是否可以堆叠更多
func can_add(amount: int) -> bool:
	if not item or not item.is_stackable():
		return false
	return quantity + amount <= item.max_stack_size

## 添加数量
func add(amount: int) -> int:
	if not item:
		return amount

	var space = item.max_stack_size - quantity
	var added = mini(amount, space)
	quantity += added
	return amount - added  # 返回溢出数量

## 移除数量
func remove(amount: int) -> int:
	var removed = mini(amount, quantity)
	quantity -= removed

	if quantity <= 0:
		clear()

	return removed

## 是否已满
func is_full() -> bool:
	if not item:
		return false
	return quantity >= item.max_stack_size

## 获取剩余空间
func get_free_space() -> int:
	if not item:
		return 0
	return item.max_stack_size - quantity

## 清空堆叠
func clear() -> void:
	item = null
	quantity = 0

## 复制堆叠
func duplicate_stack():
	var copy = ItemStackClass.new()
	if item:
		copy.item = item.duplicate_item()
		copy.quantity = quantity
	return copy

## 转换为存档数据
func to_save_data() -> Dictionary:
	if is_empty():
		return {}

	return {
		"item_id": item.id,
		"quantity": quantity
	}

## 从存档数据加载
static func from_save_data(data: Dictionary, item_database: Node = null):
	if data.is_empty():
		var empty_stack = ItemStackClass.new()
		return empty_stack

	var item_id: String = data.get("item_id", "")
	var quantity: int = data.get("quantity", 1)

	# 需要通过物品数据库获取物品
	var loaded_item = null  # InventoryItem
	if item_database and item_database.has_method("get_item_by_id"):
		loaded_item = item_database.get_item_by_id(item_id)

	if loaded_item:
		return ItemStackClass.new(loaded_item, quantity)

	var empty_stack = ItemStackClass.new()
	return empty_stack

## 合并两个堆叠
static func merge(stack_a: ItemStack, stack_b: ItemStack) -> bool:
	if not stack_a.item or not stack_b.item:
		return false

	if stack_a.item.id != stack_b.item.id:
		return false

	if not stack_a.item.is_stackable():
		return false

	var overflow := stack_a.add(stack_b.quantity)
	stack_b.quantity = overflow

	if overflow <= 0:
		stack_b.clear()

	return true

## 分割堆叠
func split(amount: int):
	if not item or amount <= 0 or amount >= quantity:
		return ItemStackClass.new()

	var split_quantity = mini(amount, quantity)
	quantity -= split_quantity

	return ItemStackClass.new(item.duplicate_item(), split_quantity)

## 获取显示文本
func get_display_text() -> String:
	if is_empty():
		return ""

	if quantity > 1:
		return "%s x%d" % [item.item_name, quantity]
	else:
		return item.item_name
