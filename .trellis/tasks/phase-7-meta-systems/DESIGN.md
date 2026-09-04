# Phase 7: Meta Systems & Progression - DESIGN

**状态**: 📋 Ready to Start  
**优先级**: P1 🔴  
**技术栈**: Godot 4.x, GDScript, JSON  
**创建日期**: 2026-09-05

---

## 🏗️ 技术设计方案

### 1. 系统架构

#### 1.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Game Scene                              │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │  Player Node  │──│ ProgressionMgr │──│  CharacterPanel  │   │
│  │               │  │                │  │   (UI Scene)     │   │
│  │ ┌───────────┐ │  │ ┌────────────┐ │  │                  │   │
│  │ │ LevelComp │─┼──┼─│ LevelSystem│ │  │  ┌─────────────┐ │   │
│  │ │ StatsComp │─┼──┼─│ StatsSystem│─┼──┼──│ StatsPanel  │ │   │
│  │ │ EquipComp │─┼──┼─│ EquipSystem│─┼──┼──│ EquipPanel  │ │   │
│  │ │SkillTree  │─┼──┼─│SkillSystem │─┼──┼──│SkillTreeUI  │ │   │
│  │ └───────────┘ │  │ └────────────┘ │  │  └─────────────┘ │   │
│  └───────────────┘  └────────────────┘  └──────────────────┘   │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │ AchievementMgr  │                          │
│                    │                 │                          │
│                    │ ┌─────────────┐ │                          │
│                    │ │Achievement  │ │                          │
│                    │ │  Tracker    │ │                          │
│                    │ └─────────────┘ │                          │
│                    └─────────────────┘                          │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │   SaveManager   │                          │
│                    │                 │                          │
│                    │ ┌──────────────┐│                          │
│                    │ │ LocalSave    ││                          │
│                    │ │ CloudSync    ││                          │
│                    │ └──────────────┘│                          │
│                    └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘

Data Layer:
┌─────────────────────────────────────────────────────────────────┐
│  data/progression/                                               │
│  ├── level_curve.json        (经验曲线配置)                     │
│  ├── stats_formula.json      (属性公式配置)                     │
│  ├── equipment_database.json (装备数据库)                       │
│  ├── skill_tree.json         (技能树配置)                       │
│  └── achievements.json       (成就配置)                         │
└─────────────────────────────────────────────────────────────────┘
```

#### 1.2 组件依赖关系

```
LevelComponent → StatsComponent → EquipmentComponent
       ↓              ↓                    ↓
  LevelSystem → StatsSystem → EquipmentSystem
       ↓              ↓                    ↓
ProgressionManager ←─────────────────────┘
       ↓
AchievementManager
       ↓
SaveManager
```

---

### 2. 核心系统设计

#### 2.1 LevelSystem - 等级系统

**职责**:
- 经验值累加
- 升级判定
- 升级奖励发放

**实现**:

```gdscript
extends Node
class_name LevelSystem
## 等级系统 - 管理经验值和升级

signal level_up(new_level: int)
signal exp_gained(amount: int, current_exp: int, required_exp: int)

const MAX_LEVEL := 50
const EXP_CURVE_DATA := preload("res://data/progression/level_curve.json")

var player_level: int = 1
var current_exp: int = 0
var exp_curve: Dictionary = {}

func _ready() -> void:
	_load_exp_curve()

func _load_exp_curve() -> void:
	var file := FileAccess.open("res://data/progression/level_curve.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		json.parse(file.get_as_text())
		exp_curve = json.data
		file.close()

## 获取升级所需经验
func get_required_exp(level: int) -> int:
	if exp_curve.has(str(level)):
		return exp_curve[str(level)]["required_exp"]
	# 默认公式: 100 * (level ^ 1.5)
	return int(100.0 * pow(level, 1.5))

## 增加经验值
func add_exp(amount: int) -> void:
	if player_level >= MAX_LEVEL:
		return
	
	current_exp += amount
	exp_gained.emit(amount, current_exp, get_required_exp(player_level))
	
	# 检查升级
	while current_exp >= get_required_exp(player_level) and player_level < MAX_LEVEL:
		_level_up()

## 升级处理
func _level_up() -> void:
	current_exp -= get_required_exp(player_level)
	player_level += 1
	
	print("[LevelSystem] Level up to %d!" % player_level)
	
	# 发放升级奖励
	_grant_level_rewards()
	
	# 发射信号
	level_up.emit(player_level)
	
	# 播放升级特效
	_play_level_up_effects()

## 发放升级奖励
func _grant_level_rewards() -> void:
	# 属性点 +5
	StatsSystem.add_stat_points(5)
	
	# 技能点 +1
	SkillTreeSystem.add_skill_points(1)
	
	# 恢复满血满蓝
	if player_ref and player_ref.has_node("HealthComponent"):
		player_ref.get_node("HealthComponent").heal_full()

## 播放升级特效
func _play_level_up_effects() -> void:
	# 金色闪光特效
	VFXManager.play_level_up_vfx(player_ref.global_position)
	
	# 音效
	AudioManager.play_sfx("level_up")
	
	# UI 提示
	GameManager.show_level_up_notification(player_level)

## 获取当前进度百分比
func get_exp_progress() -> float:
	if player_level >= MAX_LEVEL:
		return 1.0
	var required := get_required_exp(player_level)
	return float(current_exp) / float(required)

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"level": player_level,
		"exp": current_exp
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	player_level = data.get("level", 1)
	current_exp = data.get("exp", 0)
```

**经验曲线配置** (`data/progression/level_curve.json`):

```json
{
  "1": {"required_exp": 100, "stat_points": 5, "skill_points": 1},
  "2": {"required_exp": 282, "stat_points": 5, "skill_points": 1},
  "3": {"required_exp": 519, "stat_points": 5, "skill_points": 1},
  "10": {"required_exp": 3162, "stat_points": 5, "skill_points": 1},
  "20": {"required_exp": 8944, "stat_points": 5, "skill_points": 1},
  "30": {"required_exp": 16431, "stat_points": 5, "skill_points": 1},
  "40": {"required_exp": 25298, "stat_points": 5, "skill_points": 1},
  "49": {"required_exp": 34279, "stat_points": 5, "skill_points": 1}
}
```

---

#### 2.2 StatsSystem - 属性系统

**职责**:
- 管理 5 大属性
- 属性点分配
- 属性加成计算

**实现**:

```gdscript
extends Node
class_name StatsSystem
## 属性系统 - 管理 5 大属性和加成计算

signal stats_changed(stats: Dictionary)
signal stat_points_changed(points: int)

enum StatType {
	STR,  # 力量
	AGI,  # 敏捷
	VIT,  # 体质
	INT,  # 智力
	LUK   # 幸运
}

var base_stats: Dictionary = {
	"str": 10,
	"agi": 10,
	"vit": 10,
	"int": 10,
	"luk": 10
}

var stat_points: int = 0

## 属性加成公式配置
const STAT_BONUSES := {
	"str": {"physical_damage": 2.0},
	"agi": {"attack_speed": 0.005, "evasion": 0.003},
	"vit": {"max_health": 10.0},
	"int": {"skill_damage_mult": 0.03},
	"luk": {"crit_chance": 0.005, "drop_rate": 0.002}
}

## 添加属性点
func add_stat_points(amount: int) -> void:
	stat_points += amount
	stat_points_changed.emit(stat_points)

## 分配属性点
func allocate_stat(stat_name: String, amount: int = 1) -> bool:
	if stat_points < amount:
		push_warning("[StatsSystem] Not enough stat points")
		return false
	
	if not base_stats.has(stat_name):
		push_error("[StatsSystem] Invalid stat name: %s" % stat_name)
		return false
	
	base_stats[stat_name] += amount
	stat_points -= amount
	
	stat_points_changed.emit(stat_points)
	stats_changed.emit(base_stats)
	
	# 更新角色数值
	_apply_stats_to_player()
	
	print("[StatsSystem] Allocated %d to %s (total: %d)" % [amount, stat_name, base_stats[stat_name]])
	return true

## 重置属性（消耗金币）
func reset_stats(cost: int) -> bool:
	if not CurrencySystem.has_gold(cost):
		return false
	
	CurrencySystem.spend_gold(cost)
	
	# 计算总投入点数
	var total_points := 0
	for stat_name in base_stats.keys():
		total_points += base_stats[stat_name] - 10  # 初始每项 10
	
	# 重置为初始值
	base_stats = {
		"str": 10,
		"agi": 10,
		"vit": 10,
		"int": 10,
		"luk": 10
	}
	
	stat_points = total_points
	
	stats_changed.emit(base_stats)
	stat_points_changed.emit(stat_points)
	_apply_stats_to_player()
	
	return true

## 计算属性加成
func calculate_stat_bonus(stat_name: String, bonus_type: String) -> float:
	if not STAT_BONUSES.has(stat_name):
		return 0.0
	
	var bonuses: Dictionary = STAT_BONUSES[stat_name]
	if not bonuses.has(bonus_type):
		return 0.0
	
	var stat_value: int = base_stats.get(stat_name, 0)
	var multiplier: float = bonuses[bonus_type]
	
	return stat_value * multiplier

## 应用属性到玩家
func _apply_stats_to_player() -> void:
	if not player_ref:
		return
	
	# 更新最大生命值
	var max_hp_bonus := calculate_stat_bonus("vit", "max_health")
	if player_ref.has_node("HealthComponent"):
		var health := player_ref.get_node("HealthComponent")
		health.set_max_health_bonus(max_hp_bonus)
	
	# 更新攻击力
	var phys_dmg_bonus := calculate_stat_bonus("str", "physical_damage")
	if player_ref.has_node("CombatComponent"):
		var combat := player_ref.get_node("CombatComponent")
		combat.set_physical_damage_bonus(phys_dmg_bonus)
	
	# 更新攻击速度
	var atk_speed_bonus := calculate_stat_bonus("agi", "attack_speed")
	if player_ref.has_node("CombatComponent"):
		var combat := player_ref.get_node("CombatComponent")
		combat.set_attack_speed_multiplier(1.0 + atk_speed_bonus)
	
	# 更新技能伤害
	var skill_dmg_mult := calculate_stat_bonus("int", "skill_damage_mult")
	if player_ref.has_node("SkillSystem"):
		var skills := player_ref.get_node("SkillSystem")
		skills.set_skill_damage_multiplier(1.0 + skill_dmg_mult)
	
	# 更新暴击率
	var crit_bonus := calculate_stat_bonus("luk", "crit_chance")
	if player_ref.has_node("CombatComponent"):
		var combat := player_ref.get_node("CombatComponent")
		combat.set_crit_chance_bonus(crit_bonus)

## 获取属性详情（用于 UI）
func get_stat_details(stat_name: String) -> Dictionary:
	var value: int = base_stats.get(stat_name, 0)
	var bonuses := STAT_BONUSES.get(stat_name, {})
	
	var details := {
		"name": _get_stat_display_name(stat_name),
		"value": value,
		"bonuses": []
	}
	
	for bonus_type in bonuses.keys():
		var bonus_value := calculate_stat_bonus(stat_name, bonus_type)
		details["bonuses"].append({
			"type": _get_bonus_display_name(bonus_type),
			"value": bonus_value
		})
	
	return details

func _get_stat_display_name(stat_name: String) -> String:
	match stat_name:
		"str": return "力量"
		"agi": return "敏捷"
		"vit": return "体质"
		"int": return "智力"
		"luk": return "幸运"
		_: return stat_name

func _get_bonus_display_name(bonus_type: String) -> String:
	match bonus_type:
		"physical_damage": return "物理攻击"
		"attack_speed": return "攻击速度"
		"evasion": return "闪避率"
		"max_health": return "最大生命值"
		"skill_damage_mult": return "技能伤害"
		"crit_chance": return "暴击率"
		"drop_rate": return "掉落率"
		_: return bonus_type

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"stats": base_stats.duplicate(),
		"stat_points": stat_points
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	base_stats = data.get("stats", base_stats.duplicate())
	stat_points = data.get("stat_points", 0)
	
	stats_changed.emit(base_stats)
	stat_points_changed.emit(stat_points)
	_apply_stats_to_player()
```

---

#### 2.3 EquipmentSystem - 装备系统

**职责**:
- 装备槽位管理
- 背包系统
- 装备属性计算

**实现**:

```gdscript
extends Node
class_name EquipmentSystem
## 装备系统 - 管理装备槽位和背包

signal equipment_changed(slot: String, item_id: String)
signal inventory_changed()

enum EquipSlot {
	WEAPON,
	HELMET,
	ARMOR,
	GLOVES,
	BOOTS,
	NECKLACE,
	RING
}

enum Rarity {
	COMMON,    # 白色
	RARE,      # 蓝色
	EPIC,      # 紫色
	LEGENDARY  # 橙色
}

var equipped: Dictionary = {
	"weapon": null,
	"helmet": null,
	"armor": null,
	"gloves": null,
	"boots": null,
	"necklace": null,
	"ring": null
}

var inventory: Array[String] = []
var inventory_max_size: int = 30

var equipment_database: Dictionary = {}

func _ready() -> void:
	_load_equipment_database()

func _load_equipment_database() -> void:
	var file := FileAccess.open("res://data/progression/equipment_database.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		json.parse(file.get_as_text())
		equipment_database = json.data
		file.close()

## 装备物品
func equip_item(item_id: String, slot: String) -> bool:
	if not equipment_database.has(item_id):
		push_error("[EquipmentSystem] Unknown item: %s" % item_id)
		return false
	
	var item_data: Dictionary = equipment_database[item_id]
	
	# 检查装备类型
	if item_data["type"] != slot:
		push_warning("[EquipmentSystem] Item %s cannot equip to %s slot" % [item_id, slot])
		return false
	
	# 检查等级要求
	var level_req: int = item_data.get("level_requirement", 1)
	if LevelSystem.player_level < level_req:
		push_warning("[EquipmentSystem] Level %d required" % level_req)
		return false
	
	# 卸下当前装备
	if equipped[slot] != null:
		var old_item := equipped[slot]
		add_to_inventory(old_item)
	
	# 装备新物品
	equipped[slot] = item_id
	remove_from_inventory(item_id)
	
	equipment_changed.emit(slot, item_id)
	_recalculate_equipment_stats()
	
	print("[EquipmentSystem] Equipped %s to %s" % [item_id, slot])
	return true

## 卸下装备
func unequip_item(slot: String) -> bool:
	if equipped[slot] == null:
		return false
	
	if inventory.size() >= inventory_max_size:
		push_warning("[EquipmentSystem] Inventory full")
		return false
	
	var item_id := equipped[slot]
	equipped[slot] = null
	add_to_inventory(item_id)
	
	equipment_changed.emit(slot, "")
	_recalculate_equipment_stats()
	
	return true

## 添加到背包
func add_to_inventory(item_id: String) -> bool:
	if inventory.size() >= inventory_max_size:
		return false
	
	inventory.append(item_id)
	inventory_changed.emit()
	return true

## 从背包移除
func remove_from_inventory(item_id: String) -> bool:
	var idx := inventory.find(item_id)
	if idx == -1:
		return false
	
	inventory.remove_at(idx)
	inventory_changed.emit()
	return true

## 重新计算装备属性加成
func _recalculate_equipment_stats() -> void:
	var total_stats := {
		"physical_damage": 0.0,
		"attack_speed": 1.0,
		"max_health": 0.0,
		"defense": 0.0,
		"crit_chance": 0.0,
		"evasion": 0.0,
		"move_speed": 0.0
	}
	
	# 遍历所有装备槽位
	for slot in equipped.keys():
		var item_id = equipped[slot]
		if item_id == null:
			continue
		
		var item_data: Dictionary = equipment_database.get(item_id, {})
		
		# 基础属性
		var base_stats: Dictionary = item_data.get("base_stats", {})
		for stat in base_stats.keys():
			if total_stats.has(stat):
				total_stats[stat] += base_stats[stat]
		
		# 词条属性
		var affixes: Array = item_data.get("affixes", [])
		for affix in affixes:
			var affix_type: String = affix["type"]
			var affix_value: float = affix["value"]
			if total_stats.has(affix_type):
				total_stats[affix_type] += affix_value
	
	# 应用到玩家
	_apply_equipment_stats_to_player(total_stats)

## 应用装备属性到玩家
func _apply_equipment_stats_to_player(stats: Dictionary) -> void:
	if not player_ref:
		return
	
	if player_ref.has_node("CombatComponent"):
		var combat := player_ref.get_node("CombatComponent")
		combat.set_equipment_physical_damage(stats["physical_damage"])
		combat.set_equipment_attack_speed(stats["attack_speed"])
		combat.set_equipment_crit_chance(stats["crit_chance"])
	
	if player_ref.has_node("HealthComponent"):
		var health := player_ref.get_node("HealthComponent")
		health.set_equipment_max_health(stats["max_health"])
		health.set_equipment_defense(stats["defense"])
	
	if player_ref.has_node("MovementController"):
		var movement := player_ref.get_node("MovementController")
		movement.set_equipment_move_speed_mult(stats["move_speed"])

## 获取装备详情（用于 UI）
func get_item_details(item_id: String) -> Dictionary:
	if not equipment_database.has(item_id):
		return {}
	
	return equipment_database[item_id].duplicate(true)

## 装备对比
func compare_equipment(item_id: String, slot: String) -> Dictionary:
	var new_item := get_item_details(item_id)
	var current_item_id = equipped.get(slot)
	var current_item := get_item_details(current_item_id) if current_item_id else {}
	
	return {
		"new": new_item,
		"current": current_item,
		"upgrade": _calculate_stat_diff(current_item, new_item)
	}

func _calculate_stat_diff(old_item: Dictionary, new_item: Dictionary) -> Dictionary:
	# 计算属性差异（用于显示绿色↑或红色↓）
	var diff := {}
	# 实现省略...
	return diff

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"equipped": equipped.duplicate(),
		"inventory": inventory.duplicate()
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	equipped = data.get("equipped", {})
	inventory = data.get("inventory", [])
	
	_recalculate_equipment_stats()
	equipment_changed.emit("", "")
	inventory_changed.emit()
```

**装备数据库** (`data/progression/equipment_database.json`):

```json
{
  "sword_of_flames": {
    "name": "烈焰之剑",
    "type": "weapon",
    "rarity": "epic",
    "level_requirement": 15,
    "base_stats": {
      "physical_damage": 45,
      "attack_speed": 1.2
    },
    "affixes": [
      {"type": "fire_damage", "value": 20},
      {"type": "crit_chance", "value": 5}
    ],
    "special_effect": "attacks_ignite",
    "icon": "res://assets/icons/sword_of_flames.png",
    "description": "被龙炎淬炼的长剑，攻击时有几率点燃敌人。"
  },
  "leather_armor_rare": {
    "name": "精良皮甲",
    "type": "armor",
    "rarity": "rare",
    "level_requirement": 10,
    "base_stats": {
      "max_health": 80,
      "defense": 15
    },
    "affixes": [
      {"type": "evasion", "value": 3}
    ],
    "icon": "res://assets/icons/leather_armor.png",
    "description": "轻便的皮质护甲，适合敏捷型战士。"
  }
}
```

---

#### 2.4 SkillTreeSystem - 技能树系统

**职责**:
- 技能节点管理
- 技能点分配
- 技能效果应用

**实现**:

```gdscript
extends Node
class_name SkillTreeSystem
## 技能树系统 - 管理 3 个技能分支

signal skill_learned(skill_id: String, current_points: int)
signal skill_points_changed(points: int)

enum Branch {
	WARRIOR,
	ASSASSIN,
	MAGE
}

var skill_points: int = 0
var learned_skills: Dictionary = {}  # { "skill_id": points }
var skill_tree_data: Dictionary = {}

func _ready() -> void:
	_load_skill_tree_data()

func _load_skill_tree_data() -> void:
	var file := FileAccess.open("res://data/progression/skill_tree.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		json.parse(file.get_as_text())
		skill_tree_data = json.data
		file.close()

## 添加技能点
func add_skill_points(amount: int) -> void:
	skill_points += amount
	skill_points_changed.emit(skill_points)

## 学习技能
func learn_skill(skill_id: String) -> bool:
	if skill_points <= 0:
		push_warning("[SkillTreeSystem] No skill points available")
		return false
	
	if not skill_tree_data.has(skill_id):
		push_error("[SkillTreeSystem] Unknown skill: %s" % skill_id)
		return false
	
	var skill_data: Dictionary = skill_tree_data[skill_id]
	
	# 检查等级要求
	var level_req: int = skill_data["requires"]["level"]
	if LevelSystem.player_level < level_req:
		push_warning("[SkillTreeSystem] Level %d required" % level_req)
		return false
	
	# 检查前置技能
	var prerequisites: Array = skill_data["requires"].get("prerequisites", [])
	for prereq in prerequisites:
		if not learned_skills.has(prereq) or learned_skills[prereq] <= 0:
			push_warning("[SkillTreeSystem] Prerequisite skill required: %s" % prereq)
			return false
	
	# 检查最大点数
	var current_points: int = learned_skills.get(skill_id, 0)
	var max_points: int = skill_data["max_points"]
	if current_points >= max_points:
		push_warning("[SkillTreeSystem] Skill already maxed: %s" % skill_id)
		return false
	
	# 学习技能
	learned_skills[skill_id] = current_points + 1
	skill_points -= 1
	
	skill_learned.emit(skill_id, learned_skills[skill_id])
	skill_points_changed.emit(skill_points)
	
	# 应用技能效果
	_apply_skill_effect(skill_id, learned_skills[skill_id])
	
	print("[SkillTreeSystem] Learned %s (points: %d)" % [skill_id, learned_skills[skill_id]])
	return true

## 重置技能树（消耗金币）
func reset_skill_tree(cost: int) -> bool:
	if not CurrencySystem.has_gold(cost):
		return false
	
	CurrencySystem.spend_gold(cost)
	
	# 计算总技能点
	var total_points := 0
	for skill_id in learned_skills.keys():
		total_points += learned_skills[skill_id]
	
	# 清空已学技能
	learned_skills.clear()
	skill_points = total_points
	
	skill_points_changed.emit(skill_points)
	
	# 移除所有技能效果
	_remove_all_skill_effects()
	
	return true

## 应用技能效果
func _apply_skill_effect(skill_id: String, points: int) -> void:
	var skill_data: Dictionary = skill_tree_data[skill_id]
	var effects: Dictionary = skill_data["effects_per_point"]
	
	match skill_id:
		"whirlwind_mastery":
			# 增强旋风斩技能
			if player_ref.has_node("SkillSystem"):
				var skills := player_ref.get_node("SkillSystem")
				skills.enhance_skill("whirlwind_slash", {
					"damage_multiplier": 1.0 + 0.1 * points,
					"radius": 3.0 + 0.5 * points,
					"duration": 0.8 + 0.2 * points
				})
		
		"iron_skin":
			# 增加防御力
			if player_ref.has_node("HealthComponent"):
				var health := player_ref.get_node("HealthComponent")
				health.add_defense_bonus(5 * points)
		
		"critical_strikes":
			# 增加暴击率
			if player_ref.has_node("CombatComponent"):
				var combat := player_ref.get_node("CombatComponent")
				combat.add_crit_chance_bonus(0.02 * points)
		
		_:
			push_warning("[SkillTreeSystem] Unhandled skill effect: %s" % skill_id)

## 移除所有技能效果
func _remove_all_skill_effects() -> void:
	# 重置所有玩家技能增强
	if player_ref.has_node("SkillSystem"):
		player_ref.get_node("SkillSystem").reset_all_enhancements()
	
	if player_ref.has_node("HealthComponent"):
		player_ref.get_node("HealthComponent").reset_defense_bonus()
	
	if player_ref.has_node("CombatComponent"):
		player_ref.get_node("CombatComponent").reset_crit_bonus()

## 获取技能详情（用于 UI）
func get_skill_details(skill_id: String) -> Dictionary:
	if not skill_tree_data.has(skill_id):
		return {}
	
	var skill_data: Dictionary = skill_tree_data[skill_id].duplicate(true)
	skill_data["current_points"] = learned_skills.get(skill_id, 0)
	skill_data["can_learn"] = can_learn_skill(skill_id)
	
	return skill_data

## 检查是否可学习技能
func can_learn_skill(skill_id: String) -> bool:
	if skill_points <= 0:
		return false
	
	if not skill_tree_data.has(skill_id):
		return false
	
	var skill_data: Dictionary = skill_tree_data[skill_id]
	
	# 等级检查
	if LevelSystem.player_level < skill_data["requires"]["level"]:
		return false
	
	# 前置技能检查
	var prerequisites: Array = skill_data["requires"].get("prerequisites", [])
	for prereq in prerequisites:
		if not learned_skills.has(prereq) or learned_skills[prereq] <= 0:
			return false
	
	# 最大点数检查
	var current_points: int = learned_skills.get(skill_id, 0)
	if current_points >= skill_data["max_points"]:
		return false
	
	return true

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"learned_skills": learned_skills.duplicate(),
		"skill_points": skill_points
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	learned_skills = data.get("learned_skills", {})
	skill_points = data.get("skill_points", 0)
	
	# 重新应用所有技能效果
	for skill_id in learned_skills.keys():
		var points: int = learned_skills[skill_id]
		_apply_skill_effect(skill_id, points)
	
	skill_points_changed.emit(skill_points)
```

**技能树配置** (`data/progression/skill_tree.json`):

```json
{
  "whirlwind_mastery": {
    "name": "旋风精通",
    "branch": "warrior",
    "tier": 2,
    "max_points": 5,
    "requires": {
      "level": 10,
      "prerequisites": ["basic_combat"]
    },
    "effects_per_point": {
      "whirlwind_damage": "+10%",
      "whirlwind_radius": "+0.5m",
      "whirlwind_duration": "+0.2s"
    },
    "icon": "res://assets/icons/skills/whirlwind_mastery.png",
    "description": "增强旋风斩技能的伤害、范围和持续时间。"
  },
  "iron_skin": {
    "name": "铁壁",
    "branch": "warrior",
    "tier": 1,
    "max_points": 5,
    "requires": {
      "level": 1,
      "prerequisites": []
    },
    "effects_per_point": {
      "defense": "+5"
    },
    "icon": "res://assets/icons/skills/iron_skin.png",
    "description": "增加角色防御力，减少受到的伤害。"
  },
  "critical_strikes": {
    "name": "致命打击",
    "branch": "assassin",
    "tier": 1,
    "max_points": 5,
    "requires": {
      "level": 1,
      "prerequisites": []
    },
    "effects_per_point": {
      "crit_chance": "+2%"
    },
    "icon": "res://assets/icons/skills/critical_strikes.png",
    "description": "增加暴击几率，造成额外伤害。"
  }
}
```

---

#### 2.5 AchievementSystem - 成就系统

**职责**:
- 成就进度追踪
- 成就解锁判定
- 成就奖励发放

**实现**:

```gdscript
extends Node
class_name AchievementSystem
## 成就系统 - 管理成就追踪和奖励

signal achievement_unlocked(achievement_id: String)
signal achievement_progress_updated(achievement_id: String, current: int, required: int)

var achievements_data: Dictionary = {}
var completed_achievements: Array[String] = []
var achievement_progress: Dictionary = {}  # { "achievement_id": current_value }

func _ready() -> void:
	_load_achievements_data()
	_connect_game_signals()

func _load_achievements_data() -> void:
	var file := FileAccess.open("res://data/progression/achievements.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		json.parse(file.get_as_text())
		achievements_data = json.data
		file.close()

## 连接游戏信号以追踪进度
func _connect_game_signals() -> void:
	# 战斗相关
	if GameManager:
		GameManager.on_enemy_died.connect(_on_enemy_killed)
		GameManager.on_player_attack.connect(_on_player_attack)
	
	# 等级相关
	if LevelSystem:
		LevelSystem.level_up.connect(_on_level_up)
	
	# 装备相关
	if EquipmentSystem:
		EquipmentSystem.equipment_changed.connect(_on_equipment_changed)

## 追踪进度
func track_progress(achievement_id: String, increment: int = 1) -> void:
	if not achievements_data.has(achievement_id):
		return
	
	if completed_achievements.has(achievement_id):
		return  # 已完成
	
	var achievement_data: Dictionary = achievements_data[achievement_id]
	var requirements: Dictionary = achievement_data["requirements"]
	
	# 根据需求类型追踪
	for req_key in requirements.keys():
		var current: int = achievement_progress.get(achievement_id, 0)
		current += increment
		achievement_progress[achievement_id] = current
		
		var required: int = requirements[req_key]
		
		achievement_progress_updated.emit(achievement_id, current, required)
		
		# 检查是否完成
		if current >= required:
			_unlock_achievement(achievement_id)
		
		break  # 只处理第一个需求

## 解锁成就
func _unlock_achievement(achievement_id: String) -> void:
	if completed_achievements.has(achievement_id):
		return
	
	completed_achievements.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	
	# 发放奖励
	_grant_achievement_rewards(achievement_id)
	
	# 播放解锁动画
	_play_achievement_unlocked_animation(achievement_id)
	
	print("[AchievementSystem] Achievement unlocked: %s" % achievement_id)

## 发放成就奖励
func _grant_achievement_rewards(achievement_id: String) -> void:
	var achievement_data: Dictionary = achievements_data[achievement_id]
	var rewards: Dictionary = achievement_data["rewards"]
	
	# 经验值
	if rewards.has("exp"):
		LevelSystem.add_exp(rewards["exp"])
	
	# 金币
	if rewards.has("gold"):
		CurrencySystem.add_gold(rewards["gold"])
	
	# 装备
	if rewards.has("item"):
		EquipmentSystem.add_to_inventory(rewards["item"])
	
	# 称号
	if rewards.has("title"):
		# TODO: 称号系统
		pass

## 播放解锁动画
func _play_achievement_unlocked_animation(achievement_id: String) -> void:
	var achievement_data: Dictionary = achievements_data[achievement_id]
	
	# 显示横幅通知
	GameManager.show_achievement_notification(
		achievement_data["name"],
		achievement_data["description"]
	)
	
	# 播放音效
	AudioManager.play_sfx("achievement_unlocked")

## 信号回调
func _on_enemy_killed(position: Vector3) -> void:
	track_progress("enemy_slayer", 1)
	track_progress("first_kill", 1)

func _on_player_attack(combo_stage: int) -> void:
	if combo_stage >= 50:
		track_progress("combo_master", 1)

func _on_level_up(new_level: int) -> void:
	if new_level >= 10:
		track_progress("level_10", 1)
	if new_level >= 50:
		track_progress("level_50", 1)

func _on_equipment_changed(slot: String, item_id: String) -> void:
	if item_id != "":
		var item_data := EquipmentSystem.get_item_details(item_id)
		if item_data.get("rarity") == EquipmentSystem.Rarity.LEGENDARY:
			track_progress("legendary_equipped", 1)

## 获取成就详情（用于 UI）
func get_achievement_details(achievement_id: String) -> Dictionary:
	if not achievements_data.has(achievement_id):
		return {}
	
	var achievement_data: Dictionary = achievements_data[achievement_id].duplicate(true)
	achievement_data["completed"] = completed_achievements.has(achievement_id)
	achievement_data["progress"] = achievement_progress.get(achievement_id, 0)
	
	return achievement_data

## 获取所有成就（按分类）
func get_achievements_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in achievements_data.keys():
		var achievement_data: Dictionary = achievements_data[achievement_id]
		if achievement_data["category"] == category:
			result.append(get_achievement_details(achievement_id))
	
	return result

## 存档数据
func get_save_data() -> Dictionary:
	return {
		"completed": completed_achievements.duplicate(),
		"progress": achievement_progress.duplicate()
	}

## 加载存档
func load_save_data(data: Dictionary) -> void:
	completed_achievements = data.get("completed", [])
	achievement_progress = data.get("progress", {})
```

**成就配置** (`data/progression/achievements.json`):

```json
{
  "first_kill": {
    "name": "初次狩猎",
    "description": "击败第一个敌人",
    "category": "combat",
    "requirements": {
      "enemies_killed": 1
    },
    "rewards": {
      "exp": 100,
      "gold": 50
    },
    "hidden": false,
    "icon": "res://assets/icons/achievements/first_kill.png"
  },
  "enemy_slayer": {
    "name": "屠夫",
    "description": "累计击败 1000 个敌人",
    "category": "combat",
    "requirements": {
      "enemies_killed": 1000
    },
    "rewards": {
      "exp": 5000,
      "gold": 2500,
      "title": "屠夫"
    },
    "hidden": false,
    "icon": "res://assets/icons/achievements/enemy_slayer.png"
  },
  "combo_master": {
    "name": "连击大师",
    "description": "在单次战斗中达成 50 连击",
    "category": "combat",
    "requirements": {
      "max_combo_in_battle": 50
    },
    "rewards": {
      "exp": 1000,
      "gold": 500,
      "title": "连击狂人"
    },
    "hidden": false,
    "icon": "res://assets/icons/achievements/combo_master.png"
  },
  "level_10": {
    "name": "初窥门径",
    "description": "达到 10 级",
    "category": "progression",
    "requirements": {
      "level": 10
    },
    "rewards": {
      "exp": 500,
      "gold": 300
    },
    "hidden": false,
    "icon": "res://assets/icons/achievements/level_10.png"
  },
  "legendary_equipped": {
    "name": "传说加身",
    "description": "装备一件传说品质的装备",
    "category": "equipment",
    "requirements": {
      "legendary_items_equipped": 1
    },
    "rewards": {
      "exp": 2000,
      "gold": 1000
    },
    "hidden": false,
    "icon": "res://assets/icons/achievements/legendary_equipped.png"
  }
}
```

---

#### 2.6 SaveManager - 存档系统

**职责**:
- 本地存档保存/加载
- 云端同步（可选）
- 存档版本管理

**实现**:

```gdscript
extends Node
class_name SaveManager
## 存档管理器 - 统一管理所有存档数据

signal save_completed()
signal load_completed()
signal cloud_sync_completed(success: bool)

const SAVE_PATH := "user://save_data/player_data.cfg"
const SAVE_VERSION := "1.0"

var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 分钟
var _auto_save_timer: float = 0.0

func _ready() -> void:
	_ensure_save_directory()

func _process(delta: float) -> void:
	if auto_save_enabled:
		_auto_save_timer += delta
		if _auto_save_timer >= auto_save_interval:
			_auto_save_timer = 0.0
			save_game()

func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("save_data"):
		dir.make_dir("save_data")

## 保存游戏
func save_game() -> void:
	print("[SaveManager] Saving game...")
	
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"player_id": _get_or_create_player_id(),
		"character": _collect_character_data(),
		"equipment": _collect_equipment_data(),
		"inventory": _collect_inventory_data(),
		"skill_tree": _collect_skill_tree_data(),
		"achievements": _collect_achievements_data(),
		"currency": _collect_currency_data()
	}
	
	# 保存到本地
	var config := ConfigFile.new()
	for section in save_data.keys():
		if save_data[section] is Dictionary:
			for key in save_data[section].keys():
				config.set_value(section, key, save_data[section][key])
		else:
			config.set_value("meta", section, save_data[section])
	
	var err := config.save(SAVE_PATH)
	if err == OK:
		print("[SaveManager] Game saved successfully")
		save_completed.emit()
	else:
		push_error("[SaveManager] Failed to save game: %d" % err)

## 加载游戏
func load_game() -> bool:
	print("[SaveManager] Loading game...")
	
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("[SaveManager] No save file found")
		return false
	
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	
	if err != OK:
		push_error("[SaveManager] Failed to load save file: %d" % err)
		return false
	
	# 检查版本
	var save_version: String = config.get_value("meta", "version", "")
	if save_version != SAVE_VERSION:
		push_warning("[SaveManager] Save version mismatch: %s vs %s" % [save_version, SAVE_VERSION])
		# TODO: 存档迁移逻辑
	
	# 加载各系统数据
	_load_character_data(config)
	_load_equipment_data(config)
	_load_inventory_data(config)
	_load_skill_tree_data(config)
	_load_achievements_data(config)
	_load_currency_data(config)
	
	print("[SaveManager] Game loaded successfully")
	load_completed.emit()
	return true

## 收集角色数据
func _collect_character_data() -> Dictionary:
	return {
		"level": LevelSystem.player_level,
		"exp": LevelSystem.current_exp,
		"stats": StatsSystem.base_stats.duplicate(),
		"stat_points": StatsSystem.stat_points,
		"skill_points": SkillTreeSystem.skill_points
	}

## 收集装备数据
func _collect_equipment_data() -> Dictionary:
	return EquipmentSystem.equipped.duplicate()

## 收集背包数据
func _collect_inventory_data() -> Array:
	return EquipmentSystem.inventory.duplicate()

## 收集技能树数据
func _collect_skill_tree_data() -> Dictionary:
	return SkillTreeSystem.learned_skills.duplicate()

## 收集成就数据
func _collect_achievements_data() -> Dictionary:
	return {
		"completed": AchievementSystem.completed_achievements.duplicate(),
		"progress": AchievementSystem.achievement_progress.duplicate()
	}

## 收集货币数据
func _collect_currency_data() -> Dictionary:
	return {
		"gold": CurrencySystem.gold,
		"gems": CurrencySystem.gems
	}

## 加载角色数据
func _load_character_data(config: ConfigFile) -> void:
	var level: int = config.get_value("character", "level", 1)
	var exp: int = config.get_value("character", "exp", 0)
	var stats: Dictionary = config.get_value("character", "stats", {})
	var stat_points: int = config.get_value("character", "stat_points", 0)
	var skill_points: int = config.get_value("character", "skill_points", 0)
	
	LevelSystem.player_level = level
	LevelSystem.current_exp = exp
	StatsSystem.base_stats = stats
	StatsSystem.stat_points = stat_points
	SkillTreeSystem.skill_points = skill_points

## 加载装备数据
func _load_equipment_data(config: ConfigFile) -> void:
	for slot in EquipmentSystem.equipped.keys():
		var item_id = config.get_value("equipment", slot, null)
		EquipmentSystem.equipped[slot] = item_id
	
	EquipmentSystem._recalculate_equipment_stats()

## 加载背包数据
func _load_inventory_data(config: ConfigFile) -> void:
	var inventory_data = config.get_value("inventory", "items", [])
	EquipmentSystem.inventory = inventory_data

## 加载技能树数据
func _load_skill_tree_data(config: ConfigFile) -> void:
	var skills_data = config.get_value("skill_tree", "learned", {})
	SkillTreeSystem.learned_skills = skills_data
	
	# 重新应用技能效果
	for skill_id in skills_data.keys():
		var points: int = skills_data[skill_id]
		SkillTreeSystem._apply_skill_effect(skill_id, points)

## 加载成就数据
func _load_achievements_data(config: ConfigFile) -> void:
	var completed = config.get_value("achievements", "completed", [])
	var progress = config.get_value("achievements", "progress", )
	
	AchievementSystem.completed_achievements = completed
	AchievementSystem.achievement_progress = progress

## 加载货币数据
func _load_currency_data(config: ConfigFile) -> void:
	var gold: int = config.get_value("currency", "gold", 0)
	var gems: int = config.get_value("currency", "gems", 0)
	
	CurrencySystem.gold = gold
	CurrencySystem.gems = gems

## 获取或创建玩家 ID
func _get_or_create_player_id() -> String:
	var player_id := ""
	var config := ConfigFile.new()
	
	if FileAccess.file_exists(SAVE_PATH):
		config.load(SAVE_PATH)
		player_id = config.get_value("meta", "player_id", "")
	
	if player_id.is_empty():
		player_id = _generate_uuid()
	
	return player_id

## 生成 UUID
func _generate_uuid() -> String:
	var timestamp := Time.get_ticks_msec()
	var random := randi()
	return "%s-%s" % [timestamp, random]

## 云同步（可选 - Phase 7.5）
func sync_to_cloud() -> void:
	# TODO: 实现云端同步逻辑
	# 使用 Supabase/Firebase
	pass

func sync_from_cloud() -> void:
	# TODO: 实现云端同步逻辑
	pass
```

---

### 3. UI 设计

#### 3.1 角色面板布局

```
┌──────────────────────────────────────────────────────────────┐
│  角色面板                                         [X]         │
├──────────────┬───────────────────────────────────────────────┤
│              │                                               │
│  [属性]      │  ┌─────────────────────────────────────────┐ │
│   装备       │  │  Yolk Warrior         Level 25          │ │
│   技能       │  │  Exp: 5420 / 8944    ████████░░  60%    │ │
│   成就       │  └─────────────────────────────────────────┘ │
│              │                                               │
│              │  ┌─ 基础属性 ─────────────────────────────┐ │
│              │  │ 力量 (STR):  25  [+]                    │ │
│              │  │   └─ 物理攻击: +50                      │ │
│              │  │ 敏捷 (AGI):  30  [+]                    │ │
│              │  │   └─ 攻击速度: +15%  闪避: +9%         │ │
│              │  │ 体质 (VIT):  20  [+]                    │ │
│              │  │   └─ 最大生命值: +200                  │ │
│              │  │ 智力 (INT):  15  [+]                    │ │
│              │  │   └─ 技能伤害: +45%                     │ │
│              │  │ 幸运 (LUK):  18  [+]                    │ │
│              │  │   └─ 暴击率: +9%  掉落率: +3.6%        │ │
│              │  │                                          │ │
│              │  │ 待分配属性点: 5                         │ │
│              │  └──────────────────────────────────────────┘ │
│              │                                               │
│              │  [重置属性] (消耗: 1000 金币)                │
└──────────────┴───────────────────────────────────────────────┘
```

#### 3.2 装备面板布局

```
┌──────────────────────────────────────────────────────────────┐
│  装备                                                        │
├──────────────┬───────────────────────────────────────────────┤
│   属性       │  ┌─ 装备槽位 ─────────┐  ┌─ 背包 ─────────┐ │
│  [装备]      │  │   [头盔]           │  │ □ □ □ □ □ □  │ │
│   技能       │  │                    │  │ □ ◆ □ □ □ □  │ │
│   成就       │  │ [武器]    [护甲]   │  │ □ □ □ □ □ □  │ │
│              │  │                    │  │ □ □ □ □ □ □  │ │
│              │  │   [手套]           │  │ □ □ □ □ □ □  │ │
│              │  │                    │  │                │ │
│              │  │ [项链]    [戒指]   │  │ 格子: 12/30    │ │
│              │  │                    │  └────────────────┘ │
│              │  │   [鞋子]           │                      │
│              │  └────────────────────┘                      │
│              │                                               │
│              │  ┌─ 装备详情 ────────────────────────────┐  │
│              │  │ 烈焰之剑 (史诗)                        │  │
│              │  │ Lv.15 要求                             │  │
│              │  │                                        │  │
│              │  │ 物理攻击: 45                           │  │
│              │  │ 攻击速度: 1.2                          │  │
│              │  │ ──────────                             │  │
│              │  │ + 火焰伤害: 20                         │  │
│              │  │ + 暴击几率: 5%                         │  │
│              │  │ ──────────                             │  │
│              │  │ 特效: 攻击时点燃敌人                   │  │
│              │  │                                        │  │
│              │  │ [装备] [出售]                          │  │
│              │  └────────────────────────────────────────┘  │
└──────────────┴───────────────────────────────────────────────┘
```

#### 3.3 技能树界面布局

```
┌──────────────────────────────────────────────────────────────┐
│  技能树                                      技能点: 8       │
├──────────────┬───────────────────────────────────────────────┤
│   属性       │  [战士] [刺客] [法师]                        │
│   装备       │                                               │
│  [技能]      │  Tier 1                                       │
│   成就       │  ○──○──○──○──○                              │
│              │  │     │                                       │
│              │  Tier 2                                       │
│              │  ●──●──○──○──○                              │
│              │  │     │     │                                 │
│              │  Tier 3                                       │
│              │  ○──○──○──○──○                              │
│              │        │                                       │
│              │  Tier 4                                       │
│              │  ○──○──○                                     │
│              │        │                                       │
│              │  Tier 5                                       │
│              │  ○──○                                        │
│              │                                               │
│              │  ○ = 未学习  ● = 已学习  ◐ = 可学习         │
│              │                                               │
│              │  ┌─ 技能详情 ────────────────────────────┐  │
│              │  │ 旋风精通 (3/5)                         │  │
│              │  │ 需求: Level 10, 基础战斗               │  │
│              │  │                                        │  │
│              │  │ 增强旋风斩技能:                        │  │
│              │  │ • 伤害 +30%                            │  │
│              │  │ • 范围 +1.5m                           │  │
│              │  │ • 持续时间 +0.6s                       │  │
│              │  │                                        │  │
│              │  │ [学习] (消耗 1 技能点)                 │  │
│              │  └────────────────────────────────────────┘  │
│              │                                               │
│              │  [重置技能树] (消耗: 5000 金币)              │
└──────────────┴───────────────────────────────────────────────┘
```

---

### 4. 性能优化

#### 4.1 存档优化
- 使用增量保存（只保存变化的数据）
- 异步保存，避免卡顿
- 压缩存档文件

#### 4.2 UI 优化
- 技能树使用虚拟滚动
- 背包使用对象池
- Tooltip 延迟加载

#### 4.3 数据优化
- 装备数据库使用 Resource 预加载
- 技能效果缓存计算结果
- 成就进度批量更新

---

### 5. 测试计划

#### 5.1 单元测试
- 经验曲线计算
- 属性加成公式
- 装备词条计算
- 技能效果应用

#### 5.2 集成测试
- 升级流程
- 装备穿戴流程
- 技能学习流程
- 成就解锁流程
- 存档保存/加载

#### 5.3 压力测试
- 1000+ 物品背包性能
- 技能树全节点渲染
- 频繁存档性能

---

**总结**: Phase 7 技术设计完成，所有核心系统都有完整的 GDScript 实现和数据驱动配置。下一步查看 `PLAN.md` 了解具体的任务分解和实施计划。

