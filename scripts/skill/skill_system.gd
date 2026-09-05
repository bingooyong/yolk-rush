extends Node
class_name SkillSystem
## 技能系统管理器 - 管理所有实体的技能实例和冷却

# 预加载依赖类
const SkillScript = preload("res://scripts/skill/skill.gd")
const SkillInstanceScript = preload("res://scripts/skill/skill_instance.gd")
const SkillDatabaseScript = preload("res://scripts/skill/skill_database.gd")
const SkillEffectScript = preload("res://scripts/skill/skill_effect.gd")

signal skill_used(caster: Node, skill: Resource, target: Node)
signal skill_failed(caster: Node, skill: Resource, reason: String)
signal skill_cast_started(caster: Node, skill: Resource)
signal skill_cast_finished(caster: Node, skill: Resource)
signal cooldown_started(entity: Node, skill_instance: RefCounted)
signal cooldown_finished(entity: Node, skill_instance: RefCounted)

var skill_database: Node
var active_skills: Dictionary = {}  # {entity: Array}
var casting_entities: Dictionary = {}  # {entity: Dictionary}

func _ready() -> void:
	# 创建技能数据库
	skill_database = SkillDatabaseScript.new()
	add_child(skill_database)

	# 加载技能数据
	var db_path = "res://data/skills/skill_database.json"
	if skill_database.load_from_json(db_path):
		print("[SkillSystem] Initialized with %d skills" % skill_database.get_skill_count())
	else:
		push_error("[SkillSystem] Failed to load skill database")

func _process(delta: float) -> void:
	_update_cooldowns(delta)
	_update_casting(delta)

## 为实体注册技能
func register_entity(entity: Node, skill_ids: Array) -> void:
	if active_skills.has(entity):
		push_warning("[SkillSystem] Entity already registered: %s" % entity.name)
		return

	var skill_instances: Array = []

	for skill_id in skill_ids:
		var skill = skill_database.get_skill(skill_id)
		if skill:
			var instance = SkillInstanceScript.new(skill, entity)
			# 连接信号
			instance.cooldown_started.connect(_on_skill_cooldown_started.bind(entity))
			instance.cooldown_finished.connect(_on_skill_cooldown_finished.bind(entity))
			skill_instances.append(instance)
		else:
			push_warning("[SkillSystem] Skill not found: %s" % skill_id)

	active_skills[entity] = skill_instances
	print("[SkillSystem] Registered %s with %d skills" % [entity.name, skill_instances.size()])

## 取消注册实体
func unregister_entity(entity: Node) -> void:
	if active_skills.has(entity):
		active_skills.erase(entity)
		casting_entities.erase(entity)
		print("[SkillSystem] Unregistered entity: %s" % entity.name)

## 使用技能
func use_skill(entity: Node, skill_index: int, target: Node = null) -> bool:
	if not active_skills.has(entity):
		push_warning("[SkillSystem] Entity not registered: %s" % entity.name)
		return false

	var skills = active_skills[entity]
	if skill_index < 0 or skill_index >= skills.size():
		push_warning("[SkillSystem] Invalid skill index: %d" % skill_index)
		return false

	var skill_instance = skills[skill_index]
	var skill = skill_instance.skill

	# 检查是否可以使用
	var can_use_result = skill_instance.can_use(target)
	if not can_use_result.can_use:
		skill_failed.emit(entity, skill, can_use_result.reason)
		print("[SkillSystem] %s cannot use %s: %s" % [entity.name, skill.skill_name, can_use_result.reason])
		return false

	# 如果需要施法时间
	if skill.cast_time > 0:
		skill_instance.start_casting()
		casting_entities[entity] = {
			"instance": skill_instance,
			"target": target
		}
		skill_cast_started.emit(entity, skill)
		print("[SkillSystem] %s started casting %s" % [entity.name, skill.skill_name])
		return true

	# 立即释放技能
	return _execute_skill(entity, skill_instance, target)

## 取消施法
func cancel_casting(entity: Node) -> void:
	if casting_entities.has(entity):
		var cast_data = casting_entities[entity]
		var skill_instance = cast_data.instance
		skill_instance.cancel_casting()
		casting_entities.erase(entity)
		print("[SkillSystem] %s canceled casting" % entity.name)

## 执行技能（内部方法）
func _execute_skill(entity: Node, skill_instance, target: Node) -> bool:
	var skill = skill_instance.skill

	# 消耗资源
	if not skill_instance.consume_cost():
		skill_failed.emit(entity, skill, "资源消耗失败")
		return false

	# 应用所有效果
	for effect in skill.effects:
		SkillEffectScript.apply_effect(effect, skill, entity, target)

	# 开始冷却
	skill_instance.start_cooldown()

	# 发送事件
	skill_used.emit(entity, skill, target)
	print("[SkillSystem] %s used %s" % [entity.name, skill.skill_name])

	return true

## 更新冷却
func _update_cooldowns(delta: float) -> void:
	for entity in active_skills.keys():
		var skills = active_skills[entity]
		for skill_instance in skills:
			skill_instance.reduce_cooldown(delta)

## 更新施法
func _update_casting(delta: float) -> void:
	var finished_casts: Array = []

	for entity in casting_entities.keys():
		var cast_data = casting_entities[entity]
		var skill_instance = cast_data.instance
		var target = cast_data.target

		if skill_instance.update_casting(delta):
			# 施法完成
			finished_casts.append(entity)
			_execute_skill(entity, skill_instance, target)
			skill_cast_finished.emit(entity, skill_instance.skill)

	# 清理完成的施法
	for entity in finished_casts:
		casting_entities.erase(entity)

## 获取实体的所有技能
func get_entity_skills(entity: Node) -> Array:
	if active_skills.has(entity):
		return active_skills[entity]
	return []

## 获取实体的技能数量
func get_skill_count(entity: Node) -> int:
	if active_skills.has(entity):
		return active_skills[entity].size()
	return 0

## 通过ID获取技能实例
func get_skill_by_id(entity: Node, skill_id: String):
	if not active_skills.has(entity):
		return null

	var skills = active_skills[entity]
	for skill_instance in skills:
		if skill_instance.skill.skill_id == skill_id:
			return skill_instance

	return null

## 检查实体是否在施法
func is_casting(entity: Node) -> bool:
	return casting_entities.has(entity)

## 信号处理
func _on_skill_cooldown_started(skill_instance, entity: Node) -> void:
	cooldown_started.emit(entity, skill_instance)

func _on_skill_cooldown_finished(skill_instance, entity: Node) -> void:
	cooldown_finished.emit(entity, skill_instance)
