# Task 4: 技能树系统设计

## 系统概述
实现一个基于节点的技能树系统，支持技能解锁、升级、前置条件验证。

## 核心类设计

### 1. SkillNode (技能节点)
```gdscript
class_name SkillNode extends Resource

# 基础属性
var id: String
var skill_name: String
var description: String
var icon_path: String
var max_level: int = 5

# 需求
var required_level: int = 1
var required_skill_points: int = 1
var prerequisites: Array = []  # [skill_id, ...]

# 效果
var effects: Dictionary = {}
# 示例：{"damage_bonus": 5, "crit_chance": 2}

# UI位置
var tree_position: Vector2
```

### 2. SkillTreeSystem (技能树管理)
```gdscript
class_name SkillTreeSystem extends Node

signal skill_unlocked(skill_id)
signal skill_upgraded(skill_id, new_level)
signal skill_points_changed(points)

var unlocked_skills: Dictionary = {}  # skill_id -> level
var available_skill_points: int = 0

# 核心方法
func can_unlock_skill(skill_id) -> bool
func unlock_skill(skill_id) -> bool
func can_upgrade_skill(skill_id) -> bool
func upgrade_skill(skill_id) -> bool
func get_skill_level(skill_id) -> int
func get_total_skill_bonuses() -> Dictionary
func add_skill_points(amount: int)
func reset_skills() -> int  # 返回退还的技能点
```

### 3. SkillDatabase (技能数据库)
```gdscript
class_name SkillDatabase extends Node

var skills: Dictionary = {}  # id -> SkillNode

func load_database() -> bool
func get_skill_by_id(skill_id) -> SkillNode
func get_skills_by_tree(tree_name) -> Array
```

## 数据结构 (skill_database.json)

```json
{
  "trees": {
    "combat": {
      "name": "战斗",
      "description": "提升战斗能力",
      "skills": [
        {
          "id": "power_strike",
          "skill_name": "强力打击",
          "description": "增加物理伤害",
          "icon_path": "res://assets/icons/skills/power_strike.png",
          "max_level": 5,
          "required_level": 1,
          "required_skill_points": 1,
          "prerequisites": [],
          "effects": {
            "physical_damage_bonus": 5
          },
          "tree_position": {"x": 0, "y": 0}
        },
        {
          "id": "critical_strike",
          "skill_name": "致命一击",
          "description": "增加暴击率",
          "max_level": 5,
          "required_level": 5,
          "required_skill_points": 1,
          "prerequisites": ["power_strike"],
          "effects": {
            "crit_chance": 2
          },
          "tree_position": {"x": 1, "y": 0}
        }
      ]
    },
    "defense": {
      "name": "防御",
      "description": "提升生存能力",
      "skills": [...]
    },
    "magic": {
      "name": "魔法",
      "description": "提升法术能力",
      "skills": [...]
    }
  }
}
```

## 实现步骤

1. 创建 SkillNode 资源类
2. 创建 SkillTreeSystem 管理类
3. 创建 SkillDatabase 数据库类
4. 创建技能树数据 (15-20个技能)
5. 编写单元测试
6. 编写集成测试

## 技能树示例

### 战斗树 (7个技能)
1. 强力打击 (基础) → +5% 物理伤害/等级
2. 致命一击 (需要强力打击) → +2% 暴击率/等级
3. 暴击伤害 (需要致命一击) → +10% 暴击伤害/等级
4. 攻击速度 (基础) → +3% 攻速/等级
5. 连击 (需要攻击速度) → +5% 伤害/等级，3次攻击后触发
6. 狂暴 (需要强力打击+攻击速度) → +15% 所有伤害/等级
7. 终极打击 (需要暴击伤害+狂暴) → +50% 终极技能伤害

### 防御树 (6个技能)
1. 铁壁 (基础) → +10 护甲/等级
2. 生命强化 (基础) → +50 生命/等级
3. 格挡 (需要铁壁) → +5% 格挡率/等级
4. 反击 (需要格挡) → 格挡后反击，造成20%伤害/等级
5. 回复 (需要生命强化) → +2 生命恢复/秒/等级
6. 不屈 (需要反击+回复) → 低于30%生命时+30%所有防御

### 魔法树 (7个技能)
1. 魔法增幅 (基础) → +5% 技能伤害/等级
2. 法力精通 (基础) → +30 最大法力/等级
3. 法术穿透 (需要魔法增幅) → +3% 法术穿透/等级
4. 法力恢复 (需要法力精通) → +2 法力恢复/秒/等级
5. 元素掌控 (需要魔法增幅) → +10% 元素伤害/等级
6. 法术连锁 (需要元素掌控) → 技能有15%概率触发两次
7. 奥术精通 (需要法术穿透+法术连锁) → +25% 所有魔法效果

## 测试策略

### 单元测试
- 技能节点数据解析
- 前置条件验证
- 技能解锁/升级逻辑
- 技能点消耗
- 奖励计算
- 技能重置

### 集成测试
- 完整技能树解锁流程
- 跨树技能依赖
- 存档/加载
- 与等级系统集成

## 与其他系统的集成

- **LevelSystem**: 等级提升时获得技能点
- **StatsSystem**: 技能效果应用到角色属性
- **EquipmentSystem**: 某些技能可能影响装备效果
- **CombatSystem**: 技能效果在战斗中生效

## 预期输出

- 3个核心类 (SkillNode, SkillTreeSystem, SkillDatabase)
- 1个数据文件 (skill_database.json, 20个技能)
- 4个测试文件 (单元测试 + 集成测试)
- 1个测试运行器
