extends Control
class_name SkillBar
## 技能快捷栏UI - 管理多个技能槽位

signal skill_activated(slot_index: int)

# 预加载脚本
const SkillSlotScript = preload("res://scenes/ui/skill_slot.gd")

@export var skill_slots_count: int = 6
@export var slot_spacing: float = 8.0

var skill_slots: Array = []  # Array[SkillSlot]
var entity: Node  # 绑定的实体
var container: HBoxContainer

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# 创建主容器
	container = HBoxContainer.new()
	container.anchor_left = 0.5
	container.anchor_right = 0.5
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = -((64 + slot_spacing) * skill_slots_count) / 2.0
	container.offset_right = ((64 + slot_spacing) * skill_slots_count) / 2.0
	container.offset_top = -80
	container.offset_bottom = -8
	container.add_theme_constant_override("separation", int(slot_spacing))
	add_child(container)

	# 创建技能槽位
	for i in range(skill_slots_count):
		var slot = SkillSlotScript.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.slot_pressed.connect(_on_slot_pressed)
		container.add_child(slot)
		skill_slots.append(slot)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# 数字键 1-6 释放技能
		match event.keycode:
			KEY_1:
				_activate_skill(0)
			KEY_2:
				_activate_skill(1)
			KEY_3:
				_activate_skill(2)
			KEY_4:
				_activate_skill(3)
			KEY_5:
				_activate_skill(4)
			KEY_6:
				_activate_skill(5)

## 设置技能
func setup_skills(p_entity: Node, skill_instances: Array) -> void:
	entity = p_entity

	for i in range(min(skill_instances.size(), skill_slots.size())):
		var slot = skill_slots[i]
		var skill_instance = skill_instances[i]
		slot.set_skill(skill_instance, i)

	# 隐藏未使用的槽位
	for i in range(skill_instances.size(), skill_slots.size()):
		skill_slots[i].visible = false

	print("[SkillBar] Setup %d skills for %s" % [skill_instances.size(), entity.name])

## 激活技能
func _activate_skill(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= skill_slots.size():
		return

	var slot = skill_slots[slot_index]
	if not slot.visible or not slot.is_enabled:
		return

	if slot.skill_instance and slot.skill_instance.is_ready():
		skill_activated.emit(slot_index)
		print("[SkillBar] Activated skill slot %d" % slot_index)

## 槽位点击处理
func _on_slot_pressed(slot) -> void:
	_activate_skill(slot.slot_index)

## 设置槽位启用状态
func set_slot_enabled(slot_index: int, enabled: bool) -> void:
	if slot_index >= 0 and slot_index < skill_slots.size():
		skill_slots[slot_index].set_slot_enabled(enabled)

## 设置所有槽位启用状态
func set_all_slots_enabled(enabled: bool) -> void:
	for slot in skill_slots:
		slot.set_slot_enabled(enabled)

## 清空技能栏
func clear_skills() -> void:
	for slot in skill_slots:
		slot.skill_instance = null
		slot.visible = false

## 获取技能槽位
func get_skill_slot(slot_index: int):
	if slot_index >= 0 and slot_index < skill_slots.size():
		return skill_slots[slot_index]
	return null
