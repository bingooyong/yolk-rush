# Phase 11 - 状态效果系统 实施计划

## 🎯 目标

实现完整的Buff/Debuff系统，让技能不仅造成瞬时伤害，还能施加持续效果。

---

## 📋 核心组件

### 1. StatusEffect（状态效果数据类）
**路径**: `scripts/status/status_effect.gd`

**字段**:
```gdscript
- effect_id: String          # 效果ID
- name: String               # 显示名称
- description: String        # 描述
- icon: String               # 图标路径
- effect_type: EffectType    # BUFF/DEBUFF
- duration: float            # 持续时间（秒）
- tick_interval: float       # 每次触发间隔（DOT/HOT）
- max_stacks: int            # 最大堆叠层数
- can_refresh: bool          # 是否可刷新时间
- stat_modifiers: Array      # 属性修改器
- tick_effect: Dictionary    # 每跳效果（DOT/HOT）
```

**枚举**:
```gdscript
enum EffectType {
    BUFF,      # 增益
    DEBUFF     # 减益
}

enum StackBehavior {
    NONE,           # 不堆叠
    REFRESH_TIME,   # 刷新时间
    ADD_STACK,      # 增加层数
    REPLACE         # 替换旧的
}
```

---

### 2. StatusEffectInstance（状态效果实例）
**路径**: `scripts/status/status_effect_instance.gd`

**字段**:
```gdscript
- effect_data: StatusEffect  # 效果数据引用
- caster: Node               # 施加者
- target: Node               # 目标
- remaining_time: float      # 剩余时间
- stacks: int                # 当前层数
- tick_timer: float          # 下次触发计时
- applied_modifiers: Array   # 已应用的属性修改
```

**方法**:
```gdscript
- update(delta: float) -> bool  # 更新计时，返回是否到期
- refresh() -> void             # 刷新持续时间
- add_stack() -> void           # 增加层数
- remove() -> void              # 移除效果
- apply_tick_effect() -> void   # 应用DOT/HOT
```

**信号**:
```gdscript
- stack_changed(new_stacks: int)
- expired()
- tick_applied(value: float)
```

---

### 3. StatusEffectSystem（状态效果系统）
**路径**: `scripts/status/status_effect_system.gd`

**职责**:
- 管理所有实体的状态效果
- _process更新所有效果
- DOT/HOT计算和应用
- 属性修改器应用/移除
- 效果到期自动清理

**数据结构**:
```gdscript
var entity_effects: Dictionary = {}  # {entity: [StatusEffectInstance]}
```

**方法**:
```gdscript
- apply_effect(effect_id: String, caster: Node, target: Node) -> void
- remove_effect(target: Node, effect_id: String) -> void
- remove_all_effects(target: Node) -> void
- has_effect(target: Node, effect_id: String) -> bool
- get_effect_stacks(target: Node, effect_id: String) -> int
- get_entity_effects(target: Node) -> Array
- _process(delta: float) -> void
- _apply_stat_modifiers(target: Node, effect: StatusEffect) -> void
- _remove_stat_modifiers(target: Node, instance: StatusEffectInstance) -> void
```

**信号**:
```gdscript
- effect_applied(target: Node, effect_id: String)
- effect_removed(target: Node, effect_id: String)
- effect_stacks_changed(target: Node, effect_id: String, stacks: int)
```

---

### 4. StatusEffectDatabase（状态效果数据库）
**路径**: `scripts/status/status_effect_database.gd`

**功能**:
- 从JSON加载状态效果定义
- 按ID索引
- 按类型分组

**JSON路径**: `data/status_effects/status_effects.json`

---

### 5. UI组件

#### StatusEffectIcon（状态图标）
**路径**: `scenes/ui/status_effect_icon.gd`

**功能**:
- 显示状态图标
- 显示层数（如果>1）
- 显示剩余时间
- 鼠标悬停显示详细信息

**尺寸**: 32x32像素

#### StatusEffectBar（状态栏）
**路径**: `scenes/ui/status_effect_bar.gd`

**功能**:
- 管理多个StatusEffectIcon
- 自动排列图标
- Buff在上方，Debuff在下方
- 横向滚动（如果过多）

---

## 📊 示例状态效果

### Buff（增益）

#### 1. 再生 (regeneration)
```json
{
  "effect_id": "regeneration",
  "name": "再生",
  "description": "每秒恢复生命值",
  "effect_type": "buff",
  "duration": 10.0,
  "tick_interval": 1.0,
  "max_stacks": 1,
  "tick_effect": {
    "type": "heal",
    "base_value": 5.0
  }
}
```

#### 2. 加速 (haste)
```json
{
  "effect_id": "haste",
  "name": "加速",
  "description": "提高移动速度30%",
  "effect_type": "buff",
  "duration": 6.0,
  "max_stacks": 1,
  "stat_modifiers": [
    {
      "stat": "move_speed",
      "modifier_type": "multiply",
      "value": 1.3
    }
  ]
}
```

#### 3. 力量 (strength)
```json
{
  "effect_id": "strength",
  "name": "力量",
  "description": "提高攻击力50%",
  "effect_type": "buff",
  "duration": 8.0,
  "max_stacks": 3,
  "stat_modifiers": [
    {
      "stat": "attack_power",
      "modifier_type": "multiply",
      "value": 1.5
    }
  ]
}
```

#### 4. 护盾 (shield)
```json
{
  "effect_id": "shield",
  "name": "护盾",
  "description": "吸收100点伤害",
  "effect_type": "buff",
  "duration": 10.0,
  "max_stacks": 1,
  "stat_modifiers": [
    {
      "stat": "shield_amount",
      "modifier_type": "add",
      "value": 100.0
    }
  ]
}
```

---

### Debuff（减益）

#### 1. 燃烧 (burning)
```json
{
  "effect_id": "burning",
  "name": "燃烧",
  "description": "每秒受到火焰伤害",
  "effect_type": "debuff",
  "duration": 6.0,
  "tick_interval": 1.0,
  "max_stacks": 3,
  "tick_effect": {
    "type": "damage",
    "base_value": 10.0
  }
}
```

#### 2. 中毒 (poisoned)
```json
{
  "effect_id": "poisoned",
  "name": "中毒",
  "description": "每秒受到毒素伤害",
  "effect_type": "debuff",
  "duration": 8.0,
  "tick_interval": 1.0,
  "max_stacks": 5,
  "tick_effect": {
    "type": "damage",
    "base_value": 8.0
  }
}
```

#### 3. 缓慢 (slow)
```json
{
  "effect_id": "slow",
  "name": "缓慢",
  "description": "降低移动速度50%",
  "effect_type": "debuff",
  "duration": 4.0,
  "max_stacks": 1,
  "stat_modifiers": [
    {
      "stat": "move_speed",
      "modifier_type": "multiply",
      "value": 0.5
    }
  ]
}
```

#### 4. 虚弱 (weakness)
```json
{
  "effect_id": "weakness",
  "name": "虚弱",
  "description": "降低攻击力30%",
  "effect_type": "debuff",
  "duration": 10.0,
  "max_stacks": 1,
  "stat_modifiers": [
    {
      "stat": "attack_power",
      "modifier_type": "multiply",
      "value": 0.7
    }
  ]
}
```

#### 5. 冰冻 (frozen)
```json
{
  "effect_id": "frozen",
  "name": "冰冻",
  "description": "无法移动",
  "effect_type": "debuff",
  "duration": 3.0,
  "max_stacks": 1,
  "stat_modifiers": [
    {
      "stat": "move_speed",
      "modifier_type": "multiply",
      "value": 0.0
    }
  ]
}
```

---

## 🔗 与技能系统集成

### 1. 扩展 SkillEffect
**路径**: `scripts/skill/skill_effect.gd`

**修改 _apply_buff 和 _apply_debuff**:
```gdscript
static func _apply_buff(effect: Dictionary, skill, caster: Node, target: Node) -> void:
    if target == null:
        return
    
    var effect_id = effect.get("effect_id", "")
    var duration = effect.get("duration", 0.0)
    var chance = effect.get("chance", 1.0)
    
    # 概率判定
    if randf() > chance:
        return
    
    # 获取状态效果系统
    var status_system = _get_status_effect_system()
    if status_system:
        status_system.apply_effect(effect_id, caster, target)
```

### 2. 扩展技能JSON
**添加 status_effect 效果类型**:
```json
{
  "skill_id": "poison_blade",
  "name": "毒刃",
  "effects": [
    {
      "type": "damage",
      "base_value": 50
    },
    {
      "type": "status_effect",
      "effect_id": "poisoned",
      "chance": 0.8
    }
  ]
}
```

---

## 🎨 UI集成

### CombatUI 扩展
**路径**: `scenes/ui/combat_ui.gd`

**新增方法**:
```gdscript
## 设置实体状态栏
func setup_status_bar(entity: Node) -> void:
    var status_bar = StatusEffectBarScript.new()
    status_bar.name = "StatusBar_%s" % entity.name
    status_bar.setup(entity)
    # 添加到UI容器
    
## 更新状态显示
func update_status_effects(entity: Node) -> void:
    var status_bar = get_status_bar(entity)
    if status_bar:
        status_bar.refresh()
```

---

## 🧪 测试计划

### 测试脚本
**路径**: `scripts/tests/phase_11_status_effect_test.gd`

### 测试套件

#### 1. 状态效果数据测试
- 从JSON加载10+个状态效果
- 验证数据完整性
- 验证类型分类

#### 2. 状态效果系统测试
- 应用Buff到实体
- 应用Debuff到实体
- 检查效果存在性
- 检查层数管理

#### 3. DOT/HOT测试
- 燃烧每秒造成伤害
- 再生每秒恢复生命
- 中毒堆叠伤害增加

#### 4. 属性修改器测试
- 加速提高移动速度
- 虚弱降低攻击力
- 效果移除后属性恢复

#### 5. 堆叠测试
- 单次应用
- 刷新时间
- 增加层数
- 最大层数限制

#### 6. 到期测试
- 效果自动移除
- 信号正确触发
- 属性正确恢复

#### 7. UI测试
- 状态图标显示
- 层数显示
- 倒计时显示
- Buff/Debuff分组

#### 8. 战斗集成测试
- 技能施加状态
- DOT持续伤害
- 战斗日志记录
- UI实时更新

---

## 📦 实施步骤

### Step 1: 核心数据结构（30分钟）
1. 创建 `StatusEffect` 类
2. 创建 `StatusEffectInstance` 类
3. 单元测试基础功能

### Step 2: 状态效果系统（45分钟）
1. 创建 `StatusEffectSystem` 类
2. 实现添加/移除效果
3. 实现 _process 更新
4. 实现属性修改器

### Step 3: 数据库和JSON（30分钟）
1. 创建 `StatusEffectDatabase` 类
2. 创建 `status_effects.json`
3. 定义10+个状态效果
4. 测试加载

### Step 4: UI组件（45分钟）
1. 创建 `StatusEffectIcon` 类
2. 创建 `StatusEffectBar` 类
3. 集成到 `CombatUI`
4. 测试显示

### Step 5: 技能系统集成（30分钟）
1. 修改 `SkillEffect._apply_buff()`
2. 修改 `SkillEffect._apply_debuff()`
3. 更新技能JSON
4. 测试技能施加状态

### Step 6: 完整测试（30分钟）
1. 编写 `phase_11_status_effect_test.gd`
2. 运行所有测试
3. 修复问题
4. 验证通过

### Step 7: 文档和提交（15分钟）
1. 编写完成报告
2. 更新 NEXT_STEPS.md
3. Git提交

**总计**: ~3小时

---

## ✅ 验收标准

- [ ] StatusEffect 数据类完整
- [ ] 从JSON加载至少10种状态效果
- [ ] StatusEffectSystem 正确管理所有效果
- [ ] DOT/HOT 每秒正确计算
- [ ] 效果堆叠规则正确
- [ ] 属性修改器正确应用和移除
- [ ] UI 显示状态图标和倒计时
- [ ] 与技能系统集成
- [ ] 战斗日志记录状态变化
- [ ] 所有测试通过

---

## 🎯 交付物清单

### 代码文件
- `scripts/status/status_effect.gd`
- `scripts/status/status_effect_instance.gd`
- `scripts/status/status_effect_system.gd`
- `scripts/status/status_effect_database.gd`
- `scenes/ui/status_effect_icon.gd`
- `scenes/ui/status_effect_bar.gd`

### 数据文件
- `data/status_effects/status_effects.json`

### 测试文件
- `scripts/tests/phase_11_status_effect_test.gd`

### 文档
- `docs/phase_11_report.md`
- `docs/NEXT_STEPS.md` (更新)
- `docs/PHASE_11_SUMMARY.md`

### 修改文件
- `scripts/skill/skill_effect.gd` (集成状态效果)
- `scripts/core/game_manager.gd` (添加StatusEffectSystem)
- `scenes/ui/combat_ui.gd` (添加状态栏)

---

**准备开始实施！** 🚀
