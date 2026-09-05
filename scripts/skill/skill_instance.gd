extends RefCounted
class_name SkillInstance
## 技能实例 - 代表一个实体的技能及其冷却状态

signal cooldown_started(skill_instance)
signal cooldown_finished(skill_instance)
signal cooldown_updated(skill_instance, remaining: float)

var skill  # Skill
var caster: Node
var current_cooldown: float = 0.0
var is_casting: bool = false
var cast_time_remaining: float = 0.0

## 初始化技能实例（可选参数）
func _init(p_skill = null, p_caster: Node = null) -> void:
	if p_skill:
		skill = p_skill
	if p_caster:
		caster = p_caster

## 检查技能是否就绪
func is_ready() -> bool:
	return current_cooldown <= 0.0 and not is_casting

## 检查技能是否在冷却中
func is_on_cooldown() -> bool:
	return current_cooldown > 0.0

## 获取冷却剩余时间
func get_cooldown_remaining() -> float:
	return current_cooldown

## 获取冷却进度（0.0 - 1.0）
func get_cooldown_progress() -> float:
	if skill.cooldown <= 0.0:
		return 1.0
	return 1.0 - (current_cooldown / skill.cooldown)

## 开始冷却
func start_cooldown() -> void:
	current_cooldown = skill.cooldown
	cooldown_started.emit(self)

## 减少冷却时间
func reduce_cooldown(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta
		cooldown_updated.emit(self, current_cooldown)

		if current_cooldown <= 0.0:
			current_cooldown = 0.0
			cooldown_finished.emit(self)

## 开始施法
func start_casting() -> void:
	is_casting = true
	cast_time_remaining = skill.cast_time

## 更新施法进度
func update_casting(delta: float) -> bool:
	if not is_casting:
		return false

	cast_time_remaining -= delta

	if cast_time_remaining <= 0.0:
		is_casting = false
		cast_time_remaining = 0.0
		return true  # 施法完成

	return false  # 施法中

## 取消施法
func cancel_casting() -> void:
	is_casting = false
	cast_time_remaining = 0.0

## 检查是否可以使用（包含资源检查）
func can_use(target: Node = null) -> Dictionary:
	var result = skill.can_use(caster, target)

	# 检查冷却
	if not is_ready():
		result.can_use = false
		if is_casting:
			result.reason = "正在施法"
		else:
			result.reason = "冷却中"
		return result

	# 检查资源消耗
	if result.has("cost_type") and result.has("cost_value"):
		var cost_type = result.cost_type
		var cost_value = result.cost_value

		# 检查施法者是否有足够资源
		var has_resource = false
		match cost_type:
			"mana":
				if caster.has_method("get_mana"):
					has_resource = caster.get_mana() >= cost_value
			"stamina":
				if caster.has_method("get_stamina"):
					has_resource = caster.get_stamina() >= cost_value
			"health":
				if caster.has_method("get_health"):
					has_resource = caster.get_health() > cost_value  # 不能用完生命值

		if not has_resource:
			result.can_use = false
			result.reason = "资源不足"
			return result

	return result

## 消耗资源
func consume_cost() -> bool:
	if not skill.cost.has("type") or not skill.cost.has("value"):
		return true  # 无消耗

	var cost_type = skill.cost.type
	var cost_value = skill.cost.value

	match cost_type:
		"mana":
			if caster.has_method("consume_mana"):
				return caster.consume_mana(cost_value)
		"stamina":
			if caster.has_method("consume_stamina"):
				return caster.consume_stamina(cost_value)
		"health":
			if caster.has_method("take_damage"):
				caster.take_damage(cost_value)
				return true

	return false

## 获取技能信息字符串
func get_info_string() -> String:
	var info = "%s [%s]\n" % [skill.skill_name, skill.skill_id]

	if is_casting:
		info += "施法中: %.1fs\n" % cast_time_remaining
	elif is_on_cooldown():
		info += "冷却: %.1fs / %.1fs\n" % [current_cooldown, skill.cooldown]
	else:
		info += "就绪\n"

	if skill.cost.has("type") and skill.cost.has("value"):
		info += "消耗: %s %.0f\n" % [skill.cost.type, skill.cost.value]

	return info
