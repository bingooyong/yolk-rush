extends Node
class_name QuickBarSystem
## 快捷栏系统

const ItemStackClass = preload("res://scripts/inventory/item_stack.gd")
const InventoryItemClass = preload("res://scripts/inventory/inventory_item.gd")

signal quick_bar_changed(slot_index: int)
signal item_used(slot_index: int, item)

const QUICK_BAR_SLOTS: int = 8

var quick_bar_slots: Array = []  # 存储背包槽位索引
var inventory_system = null

func _ready() -> void:
	_initialize_quick_bar()
	print("[QuickBarSystem] Initialized with %d slots" % QUICK_BAR_SLOTS)

## 初始化快捷栏
func _initialize_quick_bar() -> void:
	quick_bar_slots.clear()
	for i in range(QUICK_BAR_SLOTS):
		quick_bar_slots.append(-1)  # -1 表示未绑定

## 设置背包系统引用
func set_inventory(inv) -> void:
	inventory_system = inv
	print("[QuickBarSystem] Inventory reference set")

## 绑定背包槽位到快捷栏
func bind_slot(quick_bar_index: int, inventory_slot: int) -> bool:
	if not _is_quick_bar_slot_valid(quick_bar_index):
		push_error("[QuickBarSystem] Invalid quick bar slot: %d" % quick_bar_index)
		return false

	if not inventory_system:
		push_error("[QuickBarSystem] Inventory system not set")
		return false

	if inventory_slot != -1 and not inventory_system.is_slot_valid(inventory_slot):
		push_error("[QuickBarSystem] Invalid inventory slot: %d" % inventory_slot)
		return false

	quick_bar_slots[quick_bar_index] = inventory_slot
	quick_bar_changed.emit(quick_bar_index)

	if inventory_slot == -1:
		print("[QuickBarSystem] Unbound quick bar slot %d" % quick_bar_index)
	else:
		print("[QuickBarSystem] Bound inventory slot %d to quick bar %d" % [inventory_slot, quick_bar_index])

	return true

## 解绑快捷栏槽位
func unbind_slot(quick_bar_index: int) -> bool:
	return bind_slot(quick_bar_index, -1)

## 获取快捷栏绑定的背包槽位
func get_bound_inventory_slot(quick_bar_index: int) -> int:
	if not _is_quick_bar_slot_valid(quick_bar_index):
		return -1
	return quick_bar_slots[quick_bar_index]

## 获取快捷栏物品堆叠
func get_quick_bar_stack(quick_bar_index: int) :
	if not inventory_system:
		return ItemStackClass.new()

	var inv_slot = get_bound_inventory_slot(quick_bar_index)
	if inv_slot == -1:
		return ItemStackClass.new()

	return inventory_system.get_slot(inv_slot)

## 快捷栏槽位是否为空
func is_quick_bar_slot_empty(quick_bar_index: int) -> bool:
	var stack = get_quick_bar_stack(quick_bar_index)
	return stack.is_empty()

## 使用快捷栏物品
func use_quick_bar_item(quick_bar_index: int) -> bool:
	if not inventory_system:
		push_error("[QuickBarSystem] Inventory system not set")
		return false

	var stack = get_quick_bar_stack(quick_bar_index)
	if stack.is_empty():
		print("[QuickBarSystem] Quick bar slot %d is empty" % quick_bar_index)
		return false

	var item = stack.item

	# 只有消耗品可以使用
	if item.item_type != InventoryItemClass.ItemType.CONSUMABLE:
		print("[QuickBarSystem] Item %s is not consumable" % item.item_name)
		return false

	# 移除一个物品
	var inv_slot = get_bound_inventory_slot(quick_bar_index)
	inventory_system.remove_from_slot(inv_slot, 1)

	print("[QuickBarSystem] Used %s from quick bar %d" % [item.item_name, quick_bar_index])
	item_used.emit(quick_bar_index, item)
	quick_bar_changed.emit(quick_bar_index)

	return true

## 交换快捷栏槽位
func swap_quick_bar_slots(slot_a: int, slot_b: int) -> bool:
	if not _is_quick_bar_slot_valid(slot_a) or not _is_quick_bar_slot_valid(slot_b):
		return false

	if slot_a == slot_b:
		return true

	var temp = quick_bar_slots[slot_a]
	quick_bar_slots[slot_a] = quick_bar_slots[slot_b]
	quick_bar_slots[slot_b] = temp

	quick_bar_changed.emit(slot_a)
	quick_bar_changed.emit(slot_b)

	print("[QuickBarSystem] Swapped quick bar slots %d <-> %d" % [slot_a, slot_b])
	return true

## 自动绑定物品到空闲快捷栏
func auto_bind_item(inventory_slot: int) -> int:
	if not inventory_system:
		return -1

	if not inventory_system.is_slot_valid(inventory_slot):
		return -1

	# 查找空闲快捷栏槽位
	for i in range(QUICK_BAR_SLOTS):
		if quick_bar_slots[i] == -1:
			bind_slot(i, inventory_slot)
			return i

	return -1  # 没有空闲槽位

## 清空快捷栏
func clear_all() -> void:
	_initialize_quick_bar()
	for i in range(QUICK_BAR_SLOTS):
		quick_bar_changed.emit(i)
	print("[QuickBarSystem] Cleared all quick bar slots")

## 清理无效绑定（背包槽位已空）
func cleanup_invalid_bindings() -> void:
	if not inventory_system:
		return

	var cleaned = 0

	for i in range(QUICK_BAR_SLOTS):
		var inv_slot = quick_bar_slots[i]
		if inv_slot != -1:
			if inventory_system.is_slot_empty(inv_slot):
				unbind_slot(i)
				cleaned += 1

	if cleaned > 0:
		print("[QuickBarSystem] Cleaned up %d invalid bindings" % cleaned)

## 获取所有绑定信息
func get_all_bindings() -> Dictionary:
	var bindings = {}
	for i in range(QUICK_BAR_SLOTS):
		bindings[i] = quick_bar_slots[i]
	return bindings

## 快捷栏槽位是否有效
func _is_quick_bar_slot_valid(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < QUICK_BAR_SLOTS

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"bindings": quick_bar_slots.duplicate()
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	if not data.has("bindings"):
		push_warning("[QuickBarSystem] No bindings data in save")
		return

	var bindings: Array = data["bindings"]

	_initialize_quick_bar()

	for i in range(mini(bindings.size(), QUICK_BAR_SLOTS)):
		quick_bar_slots[i] = bindings[i]
		quick_bar_changed.emit(i)

	print("[QuickBarSystem] Loaded save data")

## 调试：打印快捷栏
func _debug_print_quick_bar() -> void:
	print("[QuickBarSystem] === Quick Bar ===")
	for i in range(QUICK_BAR_SLOTS):
		var inv_slot = quick_bar_slots[i]
		if inv_slot == -1:
			print("  Slot %d: [Empty]" % i)
		else:
			var stack = get_quick_bar_stack(i)
			if stack.is_empty():
				print("  Slot %d: Inventory[%d] (Invalid)" % [i, inv_slot])
			else:
				print("  Slot %d: Inventory[%d] %s" % [i, inv_slot, stack.get_display_text()])
