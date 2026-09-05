extends Node
class_name StatusEffectSystem
## 状态效果系统 - 管理所有实体的状态效果

signal effect_applied(target: Node, effect_id: String, stacks: int)
signal effect_removed(target: Node, effect_id: String)
signal effect_stacks_changed(target: Node, effect_id: String, stacks: int)
signal effect_tick(target: Node, effect_id: String, value: float, tick_type: String)

# 预加载脚本
const StatusEffectScript = preload("res://scripts/status/status_effect.gd")
const StatusEffectInstanceScript = preload("res://scripts/status/status_effect_instance.gd")

var database: Node = null  # StatusEffectDatabase
var entity_effects: Dictionary = {}  # {entity: [StatusEffectInstance]}

func _ready() -> void:
	print("[StatusEffectSystem] Initialized")

## 设置数据库
func set_database(db: Node) -> void:
	database = db
	print("[StatusEffectSystem] Database set")

## 应用状态效果
func apply_effect(effect_id: String, caster: Node, target: Node) -> void:
	if database == null:
		push_warning("[StatusEffectSystem] Database not set")
		return

	if target == null or not is_instance_valid(target):
		return

	# 从数据库获取效果数据
	var effect_data = database.get_effect(effect_id)
	if effect_data == null:
		push_warning("[StatusEffectSystem] Effect not found: %s" % effect_id)
		return

	# 确保实体有效果列表
	if target not in entity_effects:
		entity_effects[target] = []

	# 检查是否已有相同效果
	var existing = _find_effect(target, effect_id)

	if existing:
		_handle_existing_effect(existing, effect_data)
	else:
		_create_new_effect(effect_data, caster, target)

## 处理已存在的效果
func _handle_existing_effect(instance, effect_data) -> void:
	var target = instance.target

	match effect_data.stack_behavior:
		StatusEffectScript.StackBehavior.NONE:
			# 不堆叠，忽略新的
			pass

		StatusEffectScript.StackBehavior.REFRESH_TIME:
			# 刷新时间
			instance.refresh()

		StatusEffectScript.StackBehavior.ADD_STACK:
			# 增加层数
			if instance.stacks < effect_data.max_stacks:
				instance.add_stack()
				instance.refresh()
				effect_stacks_changed.emit(target, effect_data.effect_id, instance.stacks)

		StatusEffectScript.StackBehavior.REPLACE:
			# 移除旧的，创建新的
			remove_effect(target, effect_data.effect_id)
			_create_new_effect(effect_data, instance.caster, target)

## 创建新效果实例
func _create_new_effect(effect_data, caster: Node, target: Node) -> void:
	var instance = StatusEffectInstanceScript.new(effect_data, caster, target)

	# 连接信号
	instance.expired.connect(_on_effect_expired.bind(target, instance))
	instance.stack_changed.connect(_on_effect_stack_changed.bind(target, effect_data.effect_id))
	instance.tick_applied.connect(_on_effect_tick.bind(target, effect_data.effect_id))

	# 应用属性修改器
	_apply_stat_modifiers(target, instance)

	# 添加到列表
	entity_effects[target].append(instance)

	# 触发信号
	effect_applied.emit(target, effect_data.effect_id, instance.stacks)

	# 通知战斗UI
	_notify_combat_ui(target, effect_data, true)

	print("[StatusEffectSystem] Applied %s to %s" % [effect_data.name, target.name])

## 移除状态效果
func remove_effect(target: Node, effect_id: String) -> void:
	if target not in entity_effects:
		return

	var instance = _find_effect(target, effect_id)
	if instance == null:
		return

	# 移除属性修改器
	_remove_stat_modifiers(target, instance)

	# 从列表移除
	entity_effects[target].erase(instance)

	# 触发信号
	effect_removed.emit(target, effect_id)

	# 通知战斗UI
	_notify_combat_ui(target, instance.effect_data, false)

	print("[StatusEffectSystem] Removed %s from %s" % [instance.effect_data.name, target.name])

## 移除实体所有效果
func remove_all_effects(target: Node) -> void:
	if target not in entity_effects:
		return

	# 复制数组避免迭代时修改
	var effects = entity_effects[target].duplicate()

	for instance in effects:
		remove_effect(target, instance.get_effect_id())

## 检查是否有效果
func has_effect(target: Node, effect_id: String) -> bool:
	return _find_effect(target, effect_id) != null

## 获取效果层数
func get_effect_stacks(target: Node, effect_id: String) -> int:
	var instance = _find_effect(target, effect_id)
	return instance.stacks if instance else 0

## 获取实体所有效果
func get_entity_effects(target: Node) -> Array:
	if target not in entity_effects:
		return []
	return entity_effects[target]

## 查找效果实例
func _find_effect(target: Node, effect_id: String):
	if target not in entity_effects:
		return null

	for instance in entity_effects[target]:
		if instance.get_effect_id() == effect_id:
			return instance

	return null

## 更新所有效果
func _process(delta: float) -> void:
	var entities_to_clean = []

	for entity in entity_effects.keys():
		if not is_instance_valid(entity):
			entities_to_clean.append(entity)
			continue

		var effects = entity_effects[entity]
		var effects_to_remove = []

		for instance in effects:
			var should_remove = instance.update(delta)
			if should_remove:
				effects_to_remove.append(instance)

		# 移除过期效果
		for instance in effects_to_remove:
			remove_effect(entity, instance.get_effect_id())

	# 清理无效实体
	for entity in entities_to_clean:
		entity_effects.erase(entity)

## 应用属性修改器
func _apply_stat_modifiers(target: Node, instance) -> void:
	if not instance.effect_data.has_stat_modifiers():
		return

	# 检查目标是否有属性系统
	var stats_component = null

	if target.has_node("StatsComponent"):
		stats_component = target.get_node("StatsComponent")
	elif target.has_method("get_stats"):
		stats_component = target.get_stats()

	if stats_component == null:
		return

	# 应用每个修改器
	for modifier in instance.effect_data.stat_modifiers:
		var stat = modifier.get("stat", "")
		var mod_type = modifier.get("modifier_type", "add")
		var value = modifier.get("value", 0.0)

		# 记录已应用的修改器（用于移除）
		instance.applied_modifiers.append({
			"stat": stat,
			"type": mod_type,
			"value": value
		})

		# 应用修改器
		if stats_component.has_method("add_modifier"):
			stats_component.add_modifier(stat, mod_type, value, instance.get_effect_id())

## 移除属性修改器
func _remove_stat_modifiers(target: Node, instance) -> void:
	if instance.applied_modifiers.is_empty():
		return

	# 检查目标是否有属性系统
	var stats_component = null

	if target.has_node("StatsComponent"):
		stats_component = target.get_node("StatsComponent")
	elif target.has_method("get_stats"):
		stats_component = target.get_stats()

	if stats_component == null:
		return

	# 移除每个修改器
	for modifier in instance.applied_modifiers:
		if stats_component.has_method("remove_modifier"):
			stats_component.remove_modifier(instance.get_effect_id())

## 信号回调
func _on_effect_expired(target: Node, instance) -> void:
	remove_effect(target, instance.get_effect_id())

func _on_effect_stack_changed(new_stacks: int, target: Node, effect_id: String) -> void:
	effect_stacks_changed.emit(target, effect_id, new_stacks)

## 获取实体的某个状态效果实例
func get_effect(target: Node, effect_id: String):
	return _find_effect(target, effect_id)

## 获取实体的所有激活状态效果
func get_active_effects(target: Node) -> Array:
	if target not in entity_effects:
		return []
	return entity_effects[target].duplicate()

## 获取实体的所有Buff
func get_active_buffs(target: Node) -> Array:
	var buffs = []
	for instance in get_active_effects(target):
		if instance.is_buff():
			buffs.append(instance)
	return buffs

## 获取实体的所有Debuff
func get_active_debuffs(target: Node) -> Array:
	var debuffs = []
	for instance in get_active_effects(target):
		if instance.is_debuff():
			debuffs.append(instance)
	return debuffs

## 按类型移除状态效果
func remove_effects_by_type(target: Node, effect_type: int) -> void:
	if target not in entity_effects:
		return

	var effects_to_remove = []
	for instance in entity_effects[target]:
		if instance.effect_data.effect_type == effect_type:
			effects_to_remove.append(instance.get_effect_id())

	for effect_id in effects_to_remove:
		remove_effect(target, effect_id)

## 移除所有Buff
func remove_all_buffs(target: Node) -> void:
	remove_effects_by_type(target, 0)  # StatusEffect.EffectType.BUFF

## 移除所有Debuff
func remove_all_debuffs(target: Node) -> void:
	remove_effects_by_type(target, 1)  # StatusEffect.EffectType.DEBUFF

## 移除所有状态效果
func remove_all_effects(target: Node) -> void:
	if target not in entity_effects:
		return

	var effect_ids = []
	for instance in entity_effects[target]:
		effect_ids.append(instance.get_effect_id())

	for effect_id in effect_ids:
		remove_effect(target, effect_id)

func _on_effect_tick(value: float, tick_type: String, target: Node, effect_id: String) -> void:
	effect_tick.emit(target, effect_id, value, tick_type)

	# 通知战斗UI显示伤害/治疗数字
	var combat_ui = _get_combat_ui()
	if combat_ui:
		var target_pos = _get_world_position(target)

		if tick_type == "damage":
			combat_ui.show_damage(value, target_pos, false)
			combat_ui.log_damage(effect_id, target.name, value)
		elif tick_type == "heal":
			combat_ui.show_heal(value, target_pos)
			combat_ui.log_heal(effect_id, target.name, value)

## 通知战斗UI
func _notify_combat_ui(target: Node, effect_data, is_applied: bool) -> void:
	var combat_ui = _get_combat_ui()
	if combat_ui == null:
		return

	if is_applied:
		var msg = "%s gained %s" % [target.name, effect_data.name]
		combat_ui.log_info(msg)
	else:
		var msg = "%s's %s faded" % [target.name, effect_data.name]
		combat_ui.log_info(msg)

## 获取战斗UI
func _get_combat_ui() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var root = tree.root
		if root:
			var combat_ui = root.find_child("CombatUI", true, false)
			if combat_ui:
				return combat_ui
	return null

## 获取世界坐标
func _get_world_position(node: Node) -> Vector2:
	if node is Node3D:
		return Vector2(node.global_position.x, node.global_position.y)
	elif node is Node2D:
		return node.global_position
	return Vector2.ZERO
