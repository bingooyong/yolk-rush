extends Resource
class_name Skill
## 技能数据类 - 定义技能的所有属性

enum SkillType {
	ACTIVE,      # 主动技能
	PASSIVE,     # 被动技能
	TOGGLE       # 切换技能
}

enum TargetType {
	SELF,           # 自身
	ENEMY_SINGLE,   # 单个敌人
	ENEMY_AOE,      # 敌人范围
	ALLY_SINGLE,    # 单个队友
	ALLY_AOE,       # 队友范围
	GROUND          # 地面位置
}

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var target_type: TargetType = TargetType.ENEMY_SINGLE
@export var cooldown: float = 0.0
@export var cost: Dictionary = {}  # {type: "mana/stamina/health", value: float}
@export var cast_time: float = 0.0
@export var range_value: float = 0.0
@export var aoe_radius: float = 0.0
@export var effects: Array = []  # Array[Dictionary]
@export var animation: String = ""
@export var projectile: String = ""
@export var sound: String = ""

## 从JSON数据创建技能
static func from_dict(data: Dictionary):
	var SkillScript = load("res://scripts/skill/skill.gd")
	var skill = SkillScript.new()

	skill.skill_id = data.get("skill_id", "")
	skill.skill_name = data.get("name", "")
	skill.description = data.get("description", "")
	skill.icon = data.get("icon", "")

	# 解析类型
	match data.get("type", "active"):
		"active":
			skill.type = SkillType.ACTIVE
		"passive":
			skill.type = SkillType.PASSIVE
		"toggle":
			skill.type = SkillType.TOGGLE

	# 解析目标类型
	match data.get("target_type", "enemy_single"):
		"self":
			skill.target_type = TargetType.SELF
		"enemy_single":
			skill.target_type = TargetType.ENEMY_SINGLE
		"enemy_aoe":
			skill.target_type = TargetType.ENEMY_AOE
		"ally_single":
			skill.target_type = TargetType.ALLY_SINGLE
		"ally_aoe":
			skill.target_type = TargetType.ALLY_AOE
		"ground":
			skill.target_type = TargetType.GROUND

	skill.cooldown = data.get("cooldown", 0.0)
	skill.cost = data.get("cost", {})
	skill.cast_time = data.get("cast_time", 0.0)
	skill.range_value = data.get("range", 0.0)
	skill.aoe_radius = data.get("aoe_radius", 0.0)
	skill.effects = data.get("effects", [])
	skill.animation = data.get("animation", "")
	skill.projectile = data.get("projectile", "")
	skill.sound = data.get("sound", "")

	return skill

## 检查技能是否可以使用
func can_use(caster: Node, target: Node = null) -> Dictionary:
	var result = {"can_use": true, "reason": ""}

	# 检查目标类型
	if target_type != TargetType.SELF and target == null:
		result.can_use = false
		result.reason = "需要目标"
		return result

	# 检查距离（如果需要目标）
	if target != null and range_value > 0:
		if not caster is Node3D or not target is Node3D:
			# 2D 版本
			if caster is Node2D and target is Node2D:
				var distance = caster.global_position.distance_to(target.global_position)
				if distance > range_value:
					result.can_use = false
					result.reason = "目标超出范围"
					return result
		else:
			# 3D 版本
			var distance = caster.global_position.distance_to(target.global_position)
			if distance > range_value:
				result.can_use = false
				result.reason = "目标超出范围"
				return result

	# 检查资源（由调用者在外部检查，这里只返回需求）
	if cost.has("type") and cost.has("value"):
		result.cost_type = cost.type
		result.cost_value = cost.value

	return result

## 计算效果值（基础值 + 属性加成）
func calculate_effect_value(effect: Dictionary, caster: Node) -> float:
	var base_value = effect.get("value", 0.0)

	# 如果没有属性加成，直接返回基础值
	if not effect.has("scaling"):
		return base_value

	var scaling = effect.scaling
	var stat_name = scaling.get("stat", "")
	var ratio = scaling.get("ratio", 0.0)

	# 获取施法者的属性值
	var stat_value = 0.0
	if caster.has_method("get_stat"):
		stat_value = caster.get_stat(stat_name)
	elif caster.has_node("StatsComponent"):
		var stats = caster.get_node("StatsComponent")
		if stats.has_method("get_stat"):
			stat_value = stats.get_stat(stat_name)

	# 计算最终值：基础值 + (属性值 * 比例)
	return base_value + (stat_value * ratio)

## 获取技能显示信息
func get_display_info() -> Dictionary:
	return {
		"name": skill_name,
		"description": description,
		"cooldown": cooldown,
		"cost": cost,
		"range": range_value,
		"cast_time": cast_time
	}
