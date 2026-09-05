# Yolk Rush - 下一步任务选择

## 🎯 当前进度

### ✅ 已完成阶段
- **Phase 8**: 战斗系统 ✅
- **Phase 9A**: 战斗UI（HealthBar, DamageNumber, CombatLog, CombatUI）✅
- **Phase 10**: 技能系统 ✅

### 🎉 最新成就
刚刚完成 **Phase 10 - 技能系统**！
- 10个可用技能（火球术、治疗术、闪电箭等）
- 完整冷却机制
- 技能UI和快捷键（1-6）
- 战斗效果执行（伤害、治疗）
- 所有测试通过 ✨

---

## 📋 Phase 11: 状态效果系统 - 任务列表

**Phase 11 (状态效果系统)** 是下一个推荐的高优先级任务。

### 📝 核心目标
实现游戏中的Buff/Debuff系统，让技能不仅造成瞬时伤害，还能施加持续效果。

---

## 🎯 Phase 11 子任务

### 任务清单

```
[ ] 1. 创建 StatusEffect 状态效果数据类
    - 效果ID、名称、描述、图标
    - 效果类型（buff/debuff）
    - 持续时间、堆叠规则
    - 每秒效果（DOT/HOT）
    - 属性修改器

[ ] 2. 创建 StatusEffectInstance 状态效果实例
    - 施加者引用
    - 目标引用
    - 剩余时间追踪
    - 堆叠层数管理

[ ] 3. 创建 StatusEffectSystem 状态效果系统
    - 状态效果注册和移除
    - _process更新所有效果
    - DOT/HOT计算
    - 效果到期自动清理
    - 信号：效果添加、移除、刷新

[ ] 4. 创建 StatusEffectDatabase 数据库
    - 从JSON加载状态效果定义
    - data/status_effects/status_effects.json

[ ] 5. UI组件
    - StatusEffectIcon - 状态图标组件
    - StatusEffectBar - 状态栏容器
    - 集成到CombatUI

[ ] 6. 集成到技能系统
    - SkillEffect支持施加状态
    - 技能JSON中添加status_effect字段

[ ] 7. 测试和验证
    - phase_11_status_effect_test.gd
    - 测试添加/移除/堆叠
    - 测试DOT/HOT效果
    - 测试UI显示
```

**预计时间**: 2-3天  
**依赖**: Phase 10 ✅

---

## 💡 示例状态效果

### Buff（增益）
- **再生** (Regeneration) - 每秒回复HP
- **加速** (Haste) - 提高移动速度
- **护盾** (Shield) - 吸收伤害
- **力量** (Strength) - 提高攻击力

### Debuff（减益）
- **燃烧** (Burning) - 每秒火焰伤害
- **中毒** (Poisoned) - 每秒毒素伤害
- **冰冻** (Frozen) - 无法移动
- **虚弱** (Weakness) - 降低攻击力
- **缓慢** (Slow) - 降低移动速度

---

## 🔗 技能系统集成示例

### 修改后的技能JSON
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
      "duration": 6.0,
      "chance": 1.0
    }
  ]
}
```

---

## 🎯 其他可选路径

### 选项 B: Phase 12 - AI系统
**目标**: 实现敌人AI，让敌人智能使用技能

**任务清单**:
```
[ ] 1. AIController基类
[ ] 2. AIBehaviorTree行为树
[ ] 3. AIState状态机
[ ] 4. 敌人技能决策
[ ] 5. 巡逻和追击逻辑
[ ] 6. 测试AI战斗
```

**预计时间**: 3-4天  
**依赖**: Phase 10 ✅

---

### 选项 C: Phase 9B - 主界面UI
**目标**: 实现游戏主菜单和核心界面

**任务清单**:
```
[ ] 1. 主菜单 (MainMenu)
[ ] 2. 角色面板 (CharacterPanel)
[ ] 3. 背包UI (InventoryUI)
[ ] 4. 装备界面 (EquipmentUI)
```

**预计时间**: 3-4天  
**依赖**: Phase 1-10 ✅

---

### 选项 D: Phase 9C - HUD系统
**目标**: 实现游戏中的抬头显示

**任务清单**:
```
[ ] 1. 玩家HUD（血条、能量条、头像）
[ ] 2. 快捷栏（物品、技能）
[ ] 3. 小地图
[ ] 4. 任务提示
```

**预计时间**: 2-3天  
**依赖**: 需要地图系统（Phase 13）

---

## 🌟 推荐路径

### 路径 1: 战斗深度优先 ⭐⭐⭐ (强烈推荐)
```
Phase 11 (状态效果) 
  → Phase 12 (AI系统)
  → Phase 13 (地图系统)
  → Phase 9C (HUD)
```

**优点**:
- 形成完整的战斗循环
- Buff/Debuff丰富战斗策略
- AI让战斗更有挑战性
- 技能 → 状态 → AI 逻辑自然衔接

**理由**:
1. ✅ Phase 10技能系统已预留状态效果接口
2. ✅ 可立即在现有战斗中看到效果
3. ✅ 为后续AI系统打基础
4. ✅ 战斗体验完整度高

---

### 路径 2: 系统完善优先
```
Phase 9B (主界面UI) 
  → Phase 9C (HUD)
  → Phase 11 (状态效果)
  → Phase 12 (AI系统)
```

**优点**:
- UI系统一次性完成
- 玩家体验更完整
- 避免频繁切换任务

---

### 路径 3: 快速可玩版本
```
Phase 13 (地图系统) 
  → Phase 9C (HUD)
  → Phase 11 (状态效果)
  → Phase 12 (AI系统)
```

**优点**:
- 尽快实现完整关卡
- 早期测试玩法循环
- 有助于调整游戏平衡

---

## 💡 我的建议

**强烈推荐: Phase 11 - 状态效果系统 ⭐⭐⭐**

### 推荐理由

#### 1. 技术衔接完美 ✅
- Phase 10 SkillEffect 已预留 `_apply_buff()` 和 `_apply_debuff()` 接口
- 代码注释明确标记 "TODO: Phase 11"
- 无需重构现有代码，直接扩展

#### 2. 战斗体验跃升 ✅
- **当前**: 技能只有瞬时效果（打一下就完了）
- **Phase 11后**: 
  - 毒刃持续掉血 💀
  - 治疗术 + 再生Buff = 持续回血 💚
  - 冰冻敌人无法移动 ❄️
  - 战斗策略丰富10倍！

#### 3. 可立即验证 ✅
- 现有战斗系统可直接测试
- 无需等待其他系统
- Phase 9A的UI可直接显示状态图标

#### 4. 为AI铺路 ✅
- Phase 12 AI需要状态效果来做决策
- "敌人中毒了，不用再攻击" → AI逻辑
- "玩家有护盾，切换目标" → AI策略

#### 5. 工作量适中 ✅
- 2-3天可完成
- 不依赖未完成系统
- 架构清晰，风险低

---

## 🚀 如何开始 Phase 11

### 立即开始的步骤

1. **创建状态效果数据类**
   ```gdscript
   # scripts/status/status_effect.gd
   class_name StatusEffect
   ```

2. **创建状态效果数据库**
   ```json
   // data/status_effects/status_effects.json
   {
     "effects": [...]
   }
   ```

3. **创建状态效果系统**
   ```gdscript
   # scripts/status/status_effect_system.gd
   extends Node
   class_name StatusEffectSystem
   ```

4. **集成到GameManager**
   ```gdscript
   var status_effect_system: StatusEffectSystem
   ```

5. **创建UI组件**
   ```gdscript
   # scenes/ui/status_effect_icon.gd
   # scenes/ui/status_effect_bar.gd
   ```

6. **编写测试**
   ```gdscript
   # scripts/tests/phase_11_status_effect_test.gd
   ```

---

## 📊 Phase 11 验收标准

完成时应满足：

- [ ] StatusEffect数据类完整
- [ ] 从JSON加载至少10种状态效果
- [ ] StatusEffectSystem正确管理所有效果
- [ ] DOT/HOT每秒正确计算
- [ ] 效果堆叠规则正确
- [ ] UI显示状态图标和倒计时
- [ ] 与技能系统集成
- [ ] 所有测试通过

---

## ❓ 你想要：

**A.** 开始 Phase 11 - 状态效果系统（我的强烈推荐）✨✨✨  
**B.** 开始 Phase 12 - AI系统  
**C.** 开始 Phase 9B - 主界面UI  
**D.** 开始 Phase 9C - HUD系统  
**E.** 开始 Phase 13 - 地图系统  
**F.** 其他想法  

---

**请告诉我你的选择，我会立即开始工作！** 🎮

---

## 📈 整体项目进度

```
Phase 1-7:  基础系统 ████████████████████ 100% ✅
Phase 8:    战斗系统 ████████████████████ 100% ✅
Phase 9A:   战斗UI   ████████████████████ 100% ✅
Phase 10:   技能系统 ████████████████████ 100% ✅
Phase 11:   状态效果 ░░░░░░░░░░░░░░░░░░░░   0% ⏳ ← 当前推荐
Phase 12:   AI系统   ░░░░░░░░░░░░░░░░░░░░   0%
Phase 13:   地图系统 ░░░░░░░░░░░░░░░░░░░░   0%
Phase 9B/C: 完整UI   ░░░░░░░░░░░░░░░░░░░░   0%
```

**已完成核心功能**: 战斗 + UI + 技能 = 可玩垂直切片 ✨  
**下一目标**: 状态效果 → 完整战斗体验 🎯
