# Phase 5: Combat System & Skills

**Status**: 📋 Planning  
**Priority**: P1  
**Dependencies**: Phase 4 完成  
**Estimated Effort**: 4-5 weeks  
**Target Date**: TBD

---

## 概述

实现基础战斗系统和技能框架，包括普攻、技能系统、伤害计算、战斗特效。

## 前置条件

- ✅ Phase 1-3 已完成
- ✅ Phase 4 动画系统完成
- ⚠️ 需要战斗动画资源（Attack, Cast, Hit, Die）
- ⚠️ 需要特效资源（粒子、光效）

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Rush 添加战斗能力：
1. 普通攻击系统
2. 技能系统框架
3. 伤害计算与生命值
4. 战斗特效与音效
5. 简单 AI 敌人

### 用户故事

**作为玩家**：
- 我希望点击/按键触发攻击动作
- 我希望看到攻击命中效果和伤害数字
- 我希望使用技能有冷却和反馈
- 我希望击败敌人有满足感

**作为设计师**：
- 我希望通过 JSON 配置技能参数
- 我希望快速迭代技能数值
- 我希望复用技能组件（伤害/范围/CD）

### 非目标（本 Phase 不做）

- ❌ 复杂连招系统
- ❌ PvP 对战
- ❌ Buff/Debuff 系统
- ❌ 装备系统
- ❌ 组队/副本系统

---

## Design (设计方案)

### 架构设计

```
CharacterGameplay (物理层)
    ↓
CombatController (战斗层)
    ├── AttackSystem
    ├── SkillSystem
    ├── HealthSystem
    └── DamageCalculator
    ↓ 信号
CharacterAnimation (动画层)
    ├── AttackAnimations
    └── HitReactions
    ↓
CombatVFX (特效层)
    ├── ParticleEffects
    ├── HitSpark
    └── DamageNumbers
```

### 核心组件

#### 1. CombatController.gd

```gdscript
class_name CombatController extends Node

signal attack_started(attack_data: Dictionary)
signal attack_hit(target: Node, damage: float)
signal skill_cast(skill_id: String)
signal health_changed(current: float, max: float)
signal died()

var health: float = 100.0
var max_health: float = 100.0
var attack_power: float = 10.0

func perform_attack() -> void
func cast_skill(skill_id: String) -> bool
func take_damage(amount: float, source: Node) -> void
func heal(amount: float) -> void
```

#### 2. SkillSystem.gd

```gdscript
class_name SkillSystem extends Node

var skills: Dictionary = {}  # skill_id -> SkillData
var cooldowns: Dictionary = {}  # skill_id -> remaining_time

func register_skill(skill_data: SkillData) -> void
func can_cast(skill_id: String) -> bool
func cast(skill_id: String, caster: Node, target_pos: Vector3) -> bool
func update(delta: float) -> void  # 更新冷却
```

#### 3. DamageCalculator.gd

```gdscript
class_name DamageCalculator extends Node

static func calculate_damage(
    base_damage: float,
    attacker_power: float,
    defender_defense: float,
    is_critical: bool = false
) -> float:
    var damage = base_damage * (attacker_power / 10.0)
    damage *= (100.0 / (100.0 + defender_defense))
    if is_critical:
        damage *= 2.0
    return damage

static func check_critical(crit_rate: float) -> bool:
    return randf() < crit_rate
```

### 数据驱动配置

**data/contracts/skills_config.json**：

```json
{
  "$schema": "../schemas/skills_config_schema.json",
  "skills": [
    {
      "id": "yolk_hero_basic_attack",
      "name": "基础攻击",
      "type": "instant",
      "cooldown": 0.5,
      "cast_time": 0.0,
      "range": 2.0,
      "damage": {
        "base": 10.0,
        "scaling": "attack_power",
        "scaling_ratio": 1.0
      },
      "animation": "Attack_1",
      "vfx": "slash_effect",
      "sfx": "sword_swing"
    },
    {
      "id": "yolk_hero_power_strike",
      "name": "重击",
      "type": "channeled",
      "cooldown": 5.0,
      "cast_time": 0.8,
      "range": 3.0,
      "damage": {
        "base": 50.0,
        "scaling": "attack_power",
        "scaling_ratio": 2.5
      },
      "area_of_effect": {
        "shape": "sphere",
        "radius": 2.0
      },
      "animation": "Power_Attack",
      "vfx": "explosion_effect",
      "sfx": "heavy_impact"
    },
    {
      "id": "yolk_hero_dash",
      "name": "突进",
      "type": "mobility",
      "cooldown": 8.0,
      "cast_time": 0.0,
      "range": 10.0,
      "damage": {
        "base": 20.0
      },
      "movement": {
        "type": "dash",
        "distance": 8.0,
        "duration": 0.3
      },
      "animation": "Dash",
      "vfx": "dash_trail",
      "sfx": "whoosh"
    }
  ],
  "combat_parameters": {
    "default_health": 100.0,
    "default_attack_power": 10.0,
    "default_defense": 5.0,
    "default_crit_rate": 0.1,
    "hit_stun_duration": 0.2,
    "knockback_force": 5.0
  }
}
```

**data/characters/yolk_hero.json** 扩展：

```json
{
  "character_id": "yolk_hero",
  "display_name": "Yolk Hero",
  "combat_stats": {
    "health": 120.0,
    "attack_power": 12.0,
    "defense": 8.0,
    "crit_rate": 0.15,
    "move_speed": 5.0
  },
  "skills": [
    "yolk_hero_basic_attack",
    "yolk_hero_power_strike",
    "yolk_hero_dash"
  ],
  "attack_combo": [
    "Attack_1",
    "Attack_2",
    "Attack_3"
  ]
}
```

### 战斗动画

**新增动画需求**：

1. **Attack_1/2/3** - 三连击
2. **Power_Attack** - 重击蓄力
3. **Cast** - 施法动作
4. **Hit** - 受击反应
5. **Die** - 死亡动画
6. **Block** - 格挡动作（可选）

### 碰撞检测

**HitBox 系统**：

```gdscript
# scripts/combat/hitbox.gd
class_name HitBox extends Area3D

signal hit_detected(target: Node)

@export var damage: float = 10.0
@export var knockback_force: float = 5.0
@export var hit_once: bool = true  # 每次攻击只命中一次

var hit_targets: Array[Node] = []

func activate() -> void:
    monitoring = true
    hit_targets.clear()

func deactivate() -> void:
    monitoring = false

func _on_area_entered(area: Area3D) -> void:
    if area is HurtBox:
        var target = area.get_parent()
        if hit_once and target in hit_targets:
            return
        hit_targets.append(target)
        hit_detected.emit(target)
```

**HurtBox 系统**：

```gdscript
# scripts/combat/hurtbox.gd
class_name HurtBox extends Area3D

signal damage_received(amount: float, source: Node)

func take_hit(damage: float, source: Node) -> void:
    damage_received.emit(damage, source)
```

---

## Implementation Plan

### Task 1: Combat Infrastructure (3 days)

**文件**：
- `scripts/combat/combat_controller.gd`
- `scripts/combat/health_system.gd`
- `scripts/combat/damage_calculator.gd`
- `data/schemas/skills_config_schema.json`

**验证**：
- [ ] CombatController 正确初始化
- [ ] 生命值系统工作正常
- [ ] 伤害计算公式准确

### Task 2: Attack System (4 days)

**文件**：
- `scripts/combat/attack_system.gd`
- `scripts/combat/hitbox.gd`
- `scripts/combat/hurtbox.gd`

**实现**：
1. HitBox/HurtBox 碰撞检测
2. 攻击判定时机（动画事件）
3. 连击系统（Combo Counter）
4. 攻击取消/打断

**验证**：
- [ ] 攻击正确命中目标
- [ ] 伤害计算准确
- [ ] 连击流畅

### Task 3: Skill System Core (5 days)

**文件**：
- `scripts/combat/skill_system.gd`
- `scripts/combat/skill_data.gd`
- `data/contracts/skills_config.json`

**实现**：
1. 技能数据结构（SkillData）
2. 技能注册与加载
3. 冷却管理
4. 施法系统（Instant/Channeled）
5. 技能范围检测

**验证**：
- [ ] 技能从 JSON 正确加载
- [ ] 冷却系统工作正常
- [ ] 施法打断逻辑正确

### Task 4: Skill Types Implementation (4 days)

**技能类型**：

1. **Instant** - 瞬发技能
   - 立即生效
   - 示例：基础攻击

2. **Channeled** - 引导技能
   - 需要蓄力
   - 可被打断
   - 示例：重击

3. **Projectile** - 投射物
   - 生成飞行物体
   - 碰撞检测
   - 示例：火球术

4. **Mobility** - 位移技能
   - 改变角色位置
   - 示例：突进、闪现

**验证**：
- [ ] 四种技能类型全部实现
- [ ] 每种类型有测试用例

### Task 5: Combat VFX System (4 days)

**文件**：
- `scripts/combat/combat_vfx.gd`
- `scripts/combat/damage_number.gd`
- `scenes/vfx/*.tscn` (特效预制体)

**实现**：
1. 粒子特效管理
2. Hit Spark（命中火花）
3. Damage Numbers（浮动伤害数字）
4. Screen Shake（屏幕震动）
5. Hit Pause（打击停顿）

**验证**：
- [ ] 特效在正确时机播放
- [ ] 伤害数字正确显示
- [ ] 屏幕震动增强打击感

### Task 6: Simple AI Enemy (5 days)

**文件**：
- `scripts/ai/enemy_controller.gd`
- `scripts/ai/enemy_behavior.gd`
- `data/enemies/dummy_enemy.json`

**AI 状态**：
- Idle - 待机
- Patrol - 巡逻
- Chase - 追击
- Attack - 攻击
- Retreat - 撤退
- Dead - 死亡

**实现**：
1. 视野检测（玩家进入范围）
2. 导航系统（NavigationAgent3D）
3. 攻击决策（距离、冷却）
4. 受击反应
5. 死亡处理

**验证**：
- [ ] 敌人正确检测玩家
- [ ] 导航系统工作正常
- [ ] 战斗循环流畅

### Task 7: Combat UI (3 days)

**文件**：
- `scenes/ui/combat_hud.tscn`
- `scripts/ui/health_bar.gd`
- `scripts/ui/skill_button.gd`

**UI 组件**：
1. 生命条（玩家 + 敌人）
2. 技能图标 + 冷却遮罩
3. 伤害数字（3D Billboard）
4. 战斗提示（"Critical Hit!", "Miss!")

**验证**：
- [ ] 生命条实时更新
- [ ] 技能冷却可视化
- [ ] UI 响应流畅

### Task 8: Animation Integration (3 days)

**动画事件标记**：

```gdscript
# 在 Attack_1 动画中添加事件
[0.3s] -> "activate_hitbox"
[0.5s] -> "play_vfx"
[0.6s] -> "deactivate_hitbox"
```

**实现**：
1. 连接动画事件到 CombatController
2. 实现攻击判定窗口
3. 添加受击硬直
4. 实现格挡/闪避动画

**验证**：
- [ ] 攻击判定时机正确
- [ ] 动画与逻辑同步
- [ ] 无错帧或延迟

### Task 9: Tools & Validation (2 days)

**工具**：
- `tools/validate_skills.py` - 技能配置验证
- `tools/combat_debugger.gd` - 战斗调试器（显示 HitBox）
- `.agents/skills/create-skill.md` - AI Skill

**Combat Debugger 功能**：
- 显示 HitBox/HurtBox 边界
- 显示伤害计算日志
- 显示 AI 状态机
- 慢动作播放

**验证**：
- [ ] 验证器检测错误配置
- [ ] 调试器正确显示碰撞盒

### Task 10: Testing & Balance (5 days)

**测试场景**：
- `scenes/combat/combat_test.tscn`
  * 玩家 vs 木桩（测试伤害）
  * 玩家 vs 单个敌人（测试 AI）
  * 玩家 vs 多个敌人（测试群战）

**数值平衡**：
- 攻击速度/伤害平衡
- 技能冷却时间调整
- 生命值/防御力调整
- 击败敌人时间目标：5-10秒

**性能测试**：
- 10 个敌人同屏
- 特效爆发时 FPS
- 内存占用

**验证**：
- [ ] 战斗手感流畅
- [ ] 数值平衡合理
- [ ] 性能满足基准

---

## Acceptance Criteria

### 功能验收

- [ ] 基础攻击系统完整（普攻 + 连击）
- [ ] 技能系统支持 4 种类型
- [ ] 至少 3 个可用技能
- [ ] 生命值系统正确工作
- [ ] 伤害计算准确
- [ ] 简单 AI 敌人可战斗
- [ ] 战斗 UI 完整显示

### 技术验收

- [ ] 战斗系统与 Gameplay 解耦
- [ ] 所有配置数据驱动
- [ ] HitBox/HurtBox 系统可复用
- [ ] 技能插件化（易扩展）
- [ ] Combat Debugger 工具完备

### 性能验收

- [ ] 10 敌人同屏 ≥60 FPS
- [ ] 战斗特效开销 < 2ms
- [ ] 内存增加 < 50MB

### 用户体验验收

- [ ] 攻击有打击感
- [ ] 技能释放有反馈
- [ ] 受击有明显表现
- [ ] 战斗节奏紧凑

---

## Risks & Mitigations

### Risk 1: 战斗手感调整耗时

**影响**: 高  
**缓解**:
- 提供丰富的调试工具
- 参数全部外置配置
- 快速迭代流程（热重载）

### Risk 2: 特效性能问题

**影响**: 中  
**缓解**:
- 使用 GPU Particles
- 特效池化复用
- 提供质量档位

### Risk 3: AI 行为不自然

**影响**: 中  
**缓解**:
- 行为树可视化
- 简化 AI 逻辑
- 充分测试边缘情况

---

## Out of Scope (Phase 6+)

- ❌ Buff/Debuff 系统
- ❌ 元素系统（火/冰/电）
- ❌ 组队机制
- ❌ Boss 战斗
- ❌ 装备/升级系统

---

## Estimated Timeline

```
Week 1: Infrastructure + Attack System
  Day 1-3: Combat Infrastructure
  Day 4-5: Attack System (Part 1)

Week 2: Attack System + Skill Core
  Day 1-2: Attack System (Part 2)
  Day 3-5: Skill System Core

Week 3: Skill Types + VFX
  Day 1-4: Skill Types Implementation
  Day 5: Combat VFX (Part 1)

Week 4: VFX + AI + UI
  Day 1-3: Combat VFX (Part 2)
  Day 4-5: Simple AI Enemy (Part 1)

Week 5: AI + Animation + Testing
  Day 1-3: Simple AI Enemy (Part 2) + Combat UI
  Day 4: Animation Integration + Tools
  Day 5: Testing & Balance (Part 1)

Week 6: Testing & Polish
  Day 1-5: Testing & Balance (Part 2)
```

**Total**: 4-5 weeks

---

## References

- Godot Physics & Collisions
- Area3D & CollisionShape3D
- NavigationAgent3D
- GPUParticles3D

**项目文档**：
- Phase 4 Animation System
- Combat System Best Practices

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 依赖 Phase 4 完成
