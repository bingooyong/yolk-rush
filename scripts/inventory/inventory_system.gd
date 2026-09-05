extends Node
class_name InventorySystem
## 背包系统 - 管理物品存储

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")

signal inventory_changed()
signal item_added(item, quantity: int)
signal item_removed(item, quantity: int)
signal slot_changed(slot_index: int)

const MAX_SLOTS: int = 48

var slots: Array = []
var item_database: Node = null

func _ready() -> void:
	_initialize_slots()
	print("[InventorySystem] Initialized with %d slots" % MAX_SLOTS)

## 初始化槽位
func _initialize_slots() -> void:
	slots.clear()
	for i in range(MAX_SLOTS):
		slots.append(ItemStackClass.new())

## 设置物品数据库
func set_database(db: Node) -> void:
	item_database = db
	print("[InventorySystem] Database set")

## 添加物品
func add_item(item, quantity: int = 1) -> bool:
	if not item or quantity <= 0:
		push_error("[InventorySystem] Invalid item or quantity")
		return false

	var remaining = quantity

	# 如果可堆叠，先尝试堆叠到现有物品
	if item.is_stackable():
		for i in range(MAX_SLOTS):
			if remaining <= 0:
				break

			var stack = slots[i]
			if not stack.is_empty() and stack.item.id == item.id:
				var added = stack.add(remaining)
				remaining -= (quantity - remaining - added)
				slot_changed.emit(i)

				if remaining <= 0:
					break

	# 将剩余物品放入空槽位
	while remaining > 0:
		var empty_slot = find_empty_slot()
		if empty_slot == -1:
			push_warning("[InventorySystem] Inventory full, added %d/%d" % [quantity - remaining, quantity])
			break

		var stack_size = mini(remaining, item.max_stack_size)
		slots[empty_slot] = ItemStackClass.new(item.duplicate_item(), stack_size)
		remaining -= stack_size
		slot_changed.emit(empty_slot)

	var actually_added = quantity - remaining

	if actually_added > 0:
		print("[InventorySystem] Added %d x %s" % [actually_added, item.item_name])
		item_added.emit(item, actually_added)
		inventory_changed.emit()

	return remaining == 0

## 移除物品（按 ID）
func remove_item(item_id: String, quantity: int = 1) -> int:
	if quantity <= 0:
		return 0

	var remaining = quantity

	for i in range(MAX_SLOTS):
		if remaining <= 0:
			break

		var stack = slots[i]
		if not stack.is_empty() and stack.item.id == item_id:
			var removed = stack.remove(remaining)
			remaining -= removed

			if stack.is_empty():
				slots[i] = ItemStackClass.new()

			slot_changed.emit(i)

	var actually_removed = quantity - remaining

	if actually_removed > 0:
		print("[InventorySystem] Removed %d x %s" % [actually_removed, item_id])
		inventory_changed.emit()

	return actually_removed

## 移除槽位物品
func remove_from_slot(slot_index: int, quantity: int = 1) -> int:
	if not is_slot_valid(slot_index):
		return 0

	var stack = slots[slot_index]
	if stack.is_empty():
		return 0

	var removed = stack.remove(quantity)

	if stack.is_empty():
		slots[slot_index] = ItemStackClass.new()

	slot_changed.emit(slot_index)
	inventory_changed.emit()

	return removed

## 获取物品数量
func get_item_count(item_id: String) -> int:
	var total = 0
	for stack in slots:
		if not stack.is_empty() and stack.item.id == item_id:
			total += stack.quantity
	return total

## 是否有物品
func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity

## 查找空槽位
func find_empty_slot() -> int:
	for i in range(MAX_SLOTS):
		if slots[i].is_empty():
			return i
	return -1

## 获取空槽位数量
func get_empty_slot_count() -> int:
	var count = 0
	for stack in slots:
		if stack.is_empty():
			count += 1
	return count

## 是否已满
func is_full() -> bool:
	return get_empty_slot_count() == 0

## 获取槽位堆叠
func get_slot(slot_index: int) :
	if not is_slot_valid(slot_index):
		return ItemStackClass.new()
	return slots[slot_index]

## 槽位是否有效
func is_slot_valid(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < MAX_SLOTS

## 槽位是否为空
func is_slot_empty(slot_index: int) -> bool:
	if not is_slot_valid(slot_index):
		return true
	return slots[slot_index].is_empty()

## 交换槽位
func swap_slots(slot_a: int, slot_b: int) -> bool:
	if not is_slot_valid(slot_a) or not is_slot_valid(slot_b):
		return false

	if slot_a == slot_b:
		return true

	var temp = slots[slot_a]
	slots[slot_a] = slots[slot_b]
	slots[slot_b] = temp

	slot_changed.emit(slot_a)
	slot_changed.emit(slot_b)
	inventory_changed.emit()

	print("[InventorySystem] Swapped slots %d <-> %d" % [slot_a, slot_b])
	return true

## 合并槽位（将 B 合并到 A）
func merge_slots(slot_a: int, slot_b: int) -> bool:
	if not is_slot_valid(slot_a) or not is_slot_valid(slot_b):
		return false

	if slot_a == slot_b:
		return false

	var stack_a = slots[slot_a]
	var stack_b = slots[slot_b]

	if stack_a.is_empty() or stack_b.is_empty():
		return false

	if stack_a.item.id != stack_b.item.id:
		return false

	if not stack_a.item.is_stackable():
		return false

	var merged = ItemStackClass.merge(stack_a, stack_b)

	if stack_b.is_empty():
		slots[slot_b] = ItemStackClass.new()

	slot_changed.emit(slot_a)
	slot_changed.emit(slot_b)
	inventory_changed.emit()

	print("[InventorySystem] Merged slots %d -> %d" % [slot_b, slot_a])
	return merged

## 分割槽位
func split_slot(slot_index: int, amount: int, target_slot: int) -> bool:
	if not is_slot_valid(slot_index) or not is_slot_valid(target_slot):
		return false

	if slot_index == target_slot:
		return false

	if not is_slot_empty(target_slot):
		return false

	var stack = slots[slot_index]
	if stack.is_empty() or amount <= 0 or amount >= stack.quantity:
		return false

	var split_stack = stack.split(amount)
	if split_stack.is_empty():
		return false

	slots[target_slot] = split_stack

	slot_changed.emit(slot_index)
	slot_changed.emit(target_slot)
	inventory_changed.emit()

	print("[InventorySystem] Split slot %d (%d) -> %d" % [slot_index, amount, target_slot])
	return true

## 排序背包
func sort_by(mode: String) -> void:
	# 收集所有非空堆叠
	var non_empty_stacks: Array = []
	for stack in slots:
		if not stack.is_empty():
			non_empty_stacks.append(stack)

	# 排序
	match mode:
		"rarity":
			non_empty_stacks.sort_custom(func(a, b): return a.item.rarity > b.item.rarity)
		"type":
			non_empty_stacks.sort_custom(func(a, b): return a.item.item_type < b.item.item_type)
		"name":
			non_empty_stacks.sort_custom(func(a, b): return a.item.item_name < b.item.item_name)
		"quantity":
			non_empty_stacks.sort_custom(func(a, b): return a.quantity > b.quantity)
		_:
			push_warning("[InventorySystem] Unknown sort mode: %s" % mode)
			return

	# 重新分配槽位
	_initialize_slots()
	for i in range(non_empty_stacks.size()):
		slots[i] = non_empty_stacks[i]

	print("[InventorySystem] Sorted by %s" % mode)
	inventory_changed.emit()

## 清空背包
func clear_all() -> void:
	_initialize_slots()
	print("[InventorySystem] Cleared all items")
	inventory_changed.emit()

## 获取所有物品
func get_all_items() -> Array:
	var result: Array = []
	for stack in slots:
		if not stack.is_empty():
			result.append(stack)
	return result

## 按类型过滤物品
func get_items_by_type(item_type):
	var result = []
	for stack in slots:
		if not stack.is_empty() and stack.item.item_type == item_type:
			result.append(stack)
	return result

## 获取背包使用率
func get_usage_percentage() -> float:
	var used = MAX_SLOTS - get_empty_slot_count()
	return (float(used) / float(MAX_SLOTS)) * 100.0

## 存档数据
func get_save_data() -> Dictionary:
	var data = {
		"slots": []
	}

	for stack in slots:
		data["slots"].append(stack.to_save_data())

	return data

## 加载存档
func load_save_data(data: Dictionary) -> void:
	_initialize_slots()

	if not data.has("slots"):
		push_warning("[InventorySystem] No slots data in save")
		return

	var slots_data: Array = data["slots"]

	for i in range(mini(slots_data.size(), MAX_SLOTS)):
		var stack_data = slots_data[i]
		if stack_data is Dictionary and not stack_data.is_empty():
			slots[i] = ItemStackClass.from_save_data(stack_data, item_database)

	print("[InventorySystem] Loaded save data")
	inventory_changed.emit()

## 调试：打印背包内容
func _debug_print_inventory() -> void:
	print("[InventorySystem] === Inventory Contents ===")
	for i in range(MAX_SLOTS):
		var stack = slots[i]
		if not stack.is_empty():
			print("  Slot %d: %s" % [i, stack.get_display_text()])
	print("  Empty slots: %d/%d" % [get_empty_slot_count(), MAX_SLOTS])
