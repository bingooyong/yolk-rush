# Phase 10 - 技能系统 实施计划

## 📋 项目信息

- **阶段**: Phase 10
- **优先级**: 高（核心玩法）
- **依赖**: Phase 8 (战斗系统) ✅, Phase 9A (战斗UI) ✅
- **开始时间**: 2026-09-05

---

## 🎯 核心目标

实现完整的技能释放和效果系统，使玩家和敌人能够使用技能进行战斗，并在UI中正确显示技能效果。

---

## 📐 系统架构设计

### 1. 数据层 (Data Layer)

#### 技能定义数据结构
```json
{
  "skill_id": "fireball",
  "name": "火球术",
  "description": "向目标发射火球，造成火焰伤害",
  "icon": "res://assets/icons/skills/fireball.png",
  "type": "active",
  "target_type": "enemy_single",
  "cooldown": 3.0,
  "cost": {
    "type": "mana",
    "value": 20
  },
  "cast_time": 0.5,
  "range": 10.0,
  "effects": [
    {
      "type": "damage",
      "value": 50,
      "scaling": {
        "stat": "intelligence",
        "ratio": 0.8
      },
      "element": "fire",
      "can_crit": true
    }
  ],
  "animation": "cast_spell",
  "projectile": "res://scenes/projectiles/fireball.tscn",
  "sound": "res://audio/sfx/fireball_cast.ogg"
}
```

#### 技能类型枚举
```gdscript
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

enum EffectType {
    DAMAGE,         # 伤害
    HEAL,           # 治疗
    BUFF,           # 增益
    DEBUFF,         # 减益
    SUMMON,         # 召唤
    TELEPORT        # 传送
}
```

### 2. 逻辑层 (Logic Layer)

#### 核心类设计

**Skill (技能数据类)**
```gdscript
class_name Skill
extends Resource

var skill_id: String
var skill_name: String
var description: String
var type: SkillType
var target_type: TargetType
var cooldown: float
var cost: Dictionary
var cast_time: float
var range_value: float
var effects: Array[Dictionary]

func can_use(caster: Node, target: Node = null) -> bool
func get_targets(caster: Node, target_position: Vector3) -> Array
func calculate_effect(effect: Dictionary, caster: Node) -> float
```

**SkillInstance (技能实例)**
```gdscript
class_name SkillInstance
extends RefCounted

var skill: Skill
var caster: Node
var current_cooldown: float = 0.0
var is_on_cooldown: bool = false

func use(target: Node) -> bool
func start_cooldown() -> void
func reduce_cooldown(delta: float) -> void
func is_ready() -> bool
```

**SkillSystem (技能系统管理器)**
```gdscript
class_name SkillSystem
extends Node

signal skill_used(caster: Node, skill: Skill, target: Node)
signal skill_failed(caster: Node, skill: Skill, reason: String)
signal cooldown_started(skill_instance: SkillInstance)
signal cooldown_finished(skill_instance: SkillInstance)

var skill_database: SkillDatabase
var active_skills: Dictionary = {}  # {entity: [SkillInstance]}

func register_entity(entity: Node, skill_ids: Array) -> void
func use_skill(entity: Node, skill_index: int, target: Node) -> bool
func update_cooldowns(delta: float) -> void
func get_entity_skills(entity: Node) -> Array[SkillInstance]
```

**SkillDatabase (技能数据库)**
```gdscript
class_name SkillDatabase
extends Node

var skills: Dictionary = {}  # {skill_id: Skill}

func load_from_json(path: String) -> void
func get_skill(skill_id: String) -> Skill
func get_all_skills() -> Array[Skill]
```

**SkillEffect (技能效果执行器)**
```gdscript
class_name SkillEffect
extends RefCounted

static func apply_effect(effect: Dictionary, caster: Node, target: Node) -> void:
    match effect.type:
        "damage":
            _apply_damage(effect, caster, target)
        "heal":
            _apply_heal(effect, caster, target)
        "buff":
            _apply_buff(effect, caster, target)
        "debuff":
            _apply_debuff(effect, caster, target)

static func _apply_damage(effect: Dictionary, caster: Node, target: Node) -> void
static func _apply_heal(effect: Dictionary, caster: Node, target: Node) -> void
static func _apply_buff(effect: Dictionary, caster: Node, target: Node) -> void
static func _apply_debuff(effect: Dictionary, caster: Node, target: Node) -> void
```

### 3. 表现层 (Presentation Layer)

#### SkillBar (技能快捷栏)
```gdscript
class_name SkillBar
extends Control

@export var skill_slots: int = 6
var slot_buttons: Array[SkillSlot] = []

signal skill_activated(slot_index: int)

func setup_skills(skills: Array[SkillInstance]) -> void
func update_cooldowns() -> void
func set_slot_enabled(slot_index: int, enabled: bool) -> void
```

#### SkillSlot (技能槽位)
```gdscript
class_name SkillSlot
extends TextureButton

var skill_instance: SkillInstance
var cooldown_overlay: ColorRect
var cooldown_label: Label
var hotkey_label: Label

func set_skill(skill: SkillInstance) -> void
func update_cooldown() -> void
func set_enabled(enabled: bool) -> void
```

---

## 🔧 实施步骤

### Step 1: 数据结构和数据库 (30分钟)

**文件**:
- `data/skills/skill_database.json`
- `scripts/skill/skill.gd`
- `scripts/skill/skill_database.gd`

**任务**:
1. 创建技能数据JSON格式
2. 实现 Skill 资源类
3. 实现 SkillDatabase 加载器
4. 创建5-10个测试技能数据

**测试技能示例**:
- 火球术 (远程伤害)
- 治疗术 (单体治疗)
- 冲锋 (近战伤害 + 位移)
- 防御姿态 (增加防御)
- 毒刃 (伤害 + 持续伤害debuff)

### Step 2: 技能系统核心逻辑 (45分钟)

**文件**:
- `scripts/skill/skill_instance.gd`
- `scripts/skill/skill_system.gd`
- `scripts/skill/skill_effect.gd`

**任务**:
1. 实现 SkillInstance (技能实例 + 冷却管理)
2. 实现 SkillSystem (技能注册 + 释放 + 更新)
3. 实现 SkillEffect (效果执行器)
4. 集成到 GameManager autoload

**核心功能**:
- 技能释放验证（冷却、资源、距离、目标）
- 冷却计时器管理
- 效果计算（基础值 + 属性加成）
- 暴击判定
- 事件信号发送

### Step 3: UI集成 (45分钟)

**文件**:
- `scenes/ui/skill_slot.gd`
- `scenes/ui/skill_bar.gd`
- `scenes/ui/skill_bar.tscn`

**任务**:
1. 创建 SkillSlot 组件（图标 + 冷却遮罩 + 快捷键）
2. 创建 SkillBar 组件（管理多个槽位）
3. 集成到 CombatUI
4. 实现键盘快捷键绑定 (1-6)

**UI功能**:
- 技能图标显示
- 冷却进度显示（径向填充 + 倒计时文字）
- 不可用状态（资源不足、超出范围）
- 鼠标悬停提示（技能名、描述、快捷键）
- 点击/按键释放技能

### Step 4: 战斗系统集成 (30分钟)

**修改文件**:
- `scripts/player/player_controller.gd`
- `scripts/enemy/enemy_ai.gd`
- `scripts/combat/combat_system.gd`

**任务**:
1. 在 PlayerController 中添加技能输入处理
2. 在 EnemyAI 中添加技能使用逻辑
3. 在 CombatSystem 中集成技能伤害计算
4. 连接技能事件到 CombatUI（显示伤害数字和日志）

### Step 5: 视觉反馈 (30分钟)

**任务**:
1. 技能释放时显示施法动画（可选，先用简单特效）
2. 技能命中时显示伤害数字（集成现有 DamageNumber）
3. 技能日志记录（集成现有 CombatLog）
4. 技能音效触发点（预留，暂时静音）

### Step 6: 测试场景 (30分钟)

**文件**:
- `scripts/tests/phase_10_skill_test.gd`

**测试覆盖**:
1. 技能数据加载测试
2. 技能释放流程测试
3. 冷却系统测试
4. 技能效果测试（伤害、治疗）
5. UI更新测试
6. 完整战斗场景测试（玩家+敌人使用技能）

---

## 📊 技能数据示例

### 战士技能

```json
{
  "skill_id": "heavy_strike",
  "name": "重击",
  "description": "全力一击，造成高额伤害",
  "type": "active",
  "target_type": "enemy_single",
  "cooldown": 5.0,
  "cost": {"type": "stamina", "value": 30},
  "cast_time": 0.3,
  "range": 2.0,
  "effects": [
    {
      "type": "damage",
      "value": 80,
      "scaling": {"stat": "strength", "ratio": 1.2},
      "can_crit": true
    }
  ]
}
```

### 法师技能

```json
{
  "skill_id": "fireball",
  "name": "火球术",
  "description": "向目标发射火球",
  "type": "active",
  "target_type": "enemy_single",
  "cooldown": 3.0,
  "cost": {"type": "mana", "value": 20},
  "cast_time": 0.5,
  "range": 10.0,
  "effects": [
    {
      "type": "damage",
      "value": 50,
      "scaling": {"stat": "intelligence", "ratio": 0.8},
      "element": "fire",
      "can_crit": true
    }
  ]
}
```

### 治疗技能

```json
{
  "skill_id": "heal",
  "name": "治疗术",
  "description": "恢复目标生命值",
  "type": "active",
  "target_type": "ally_single",
  "cooldown": 8.0,
  "cost": {"type": "mana", "value": 25},
  "cast_time": 1.0,
  "range": 8.0,
  "effects": [
    {
      "type": "heal",
      "value": 60,
      "scaling": {"stat": "intelligence", "ratio": 0.6}
    }
  ]
}
```

---

## 🎯 质量标准

### 架构符合度检查
- ✅ Gameplay 与 Visual 完全解耦
- ✅ Scene 不承担业务规则
- ✅ 数据驱动（技能完全由JSON定义）
- ✅ 技能效果与表现分离
- ✅ UI与逻辑解耦

### 功能完整性检查
- ✅ 技能数据加载正常
- ✅ 技能可以正确释放
- ✅ 冷却系统工作正常
- ✅ 技能效果正确计算
- ✅ UI正确显示技能状态
- ✅ 键盘快捷键响应
- ✅ 战斗日志记录技能使用
- ✅ 伤害数字正确显示

### 测试覆盖检查
- ✅ 单元测试（技能数据、冷却、效果计算）
- ✅ 集成测试（技能系统与战斗系统）
- ✅ UI测试（技能栏显示和交互）
- ✅ 完整战斗测试（玩家和敌人使用技能）

---

## 🚀 预期成果

### 交付物清单

**代码文件** (11个):
- `data/skills/skill_database.json`
- `scripts/skill/skill.gd`
- `scripts/skill/skill_instance.gd`
- `scripts/skill/skill_system.gd`
- `scripts/skill/skill_database.gd`
- `scripts/skill/skill_effect.gd`
- `scenes/ui/skill_slot.gd`
- `scenes/ui/skill_bar.gd`
- `scenes/ui/skill_bar.tscn`
- `scripts/tests/phase_10_skill_test.gd`
- 修改: `scripts/core/game_manager.gd` (集成 SkillSystem)

**数据文件**:
- 5-10个测试技能定义

**文档**:
- `docs/PHASE_10_COMPLETION_REPORT.md`

### 功能演示

玩家可以：
1. 看到技能栏显示自己的技能
2. 按数字键 1-6 释放技能
3. 看到技能冷却进度
4. 看到技能伤害数字飘出
5. 看到战斗日志记录技能使用

敌人可以：
1. AI自动选择和释放技能
2. 技能效果正确作用于玩家

---

## 📈 后续扩展方向

Phase 10 完成后，自然衔接：

1. **Phase 11 - 状态效果系统**
   - Buff/Debuff 系统
   - 持续伤害 (DoT)
   - 控制效果 (眩晕、定身)

2. **技能树系统扩展**
   - 技能升级
   - 技能解锁
   - 技能变体

3. **技能组合系统**
   - 连招系统
   - 技能链
   - 组合技

---

## ✅ 准备开始

所有依赖已满足：
- ✅ Phase 8 战斗系统
- ✅ Phase 9A 战斗UI
- ✅ StatsSystem (属性系统)
- ✅ CombatUI (UI框架)

**立即开始实施 Phase 10！**
