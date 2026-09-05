# Phase 24 - 关卡内容扩展

## 📋 任务概述

**目标**: 大幅扩展游戏内容，从3个基础关卡扩展到10+关卡，添加Boss战、新敌人、新技能和新道具。

**优先级**: ⭐⭐⭐⭐⭐ (最高)

**预期成果**:
- 10个完整关卡（涵盖不同难度和主题）
- 2-3个Boss战
- 5种新敌人类型
- 3种新技能
- 8种新道具
- 15+种新障碍和陷阱

---

## 🎯 设计目标

### 1. 关卡进度曲线
```
关卡1-2:  教学关卡（简单，引导玩家）
关卡3-4:  基础关卡（中等难度）
关卡5:    Mini Boss（第一个挑战）
关卡6-7:  进阶关卡（较难）
关卡8-9:  高难度关卡（复杂机制）
关卡10:   Final Boss（终极挑战）
```

### 2. 关卡主题
- **主题1**: 草原（教学区）- 关卡1-2
- **主题2**: 森林（基础区）- 关卡3-4
- **主题3**: 山洞（挑战区）- 关卡5-7
- **主题4**: 火山（困难区）- 关卡8-9
- **主题5**: 城堡（Boss区）- 关卡10

### 3. 难度递增
- 敌人数量：2-3 → 5-8 → 10-15
- 敌人强度：基础 → 精英 → Boss
- 障碍密度：稀疏 → 中等 → 密集
- 时间限制：宽松 → 紧张 → 极限

---

## 📦 实施计划

### 阶段1: 关卡设计和配置系统
**任务**:
1. 创建关卡配置数据结构
2. 实现关卡生成器
3. 设计关卡模板系统
4. 创建关卡编辑器（可选）

**文件**:
- `scripts/levels/level_config.gd` - 关卡配置
- `scripts/levels/level_generator.gd` - 关卡生成器
- `scripts/levels/level_templates.gd` - 关卡模板

### 阶段2: 新敌人类型
**任务**:
1. 设计5种新敌人
2. 实现敌人AI变体
3. 创建敌人技能和攻击模式
4. 平衡敌人数值

**新敌人**:
- **飞行敌人**: 空中巡逻，远程攻击
- **坦克敌人**: 高血量，慢速，近战
- **法师敌人**: 远程魔法攻击，召唤小怪
- **刺客敌人**: 快速移动，高伤害，低血量
- **治疗敌人**: 为其他敌人回血

**文件**:
- `scripts/entities/enemies/flying_enemy.gd`
- `scripts/entities/enemies/tank_enemy.gd`
- `scripts/entities/enemies/mage_enemy.gd`
- `scripts/entities/enemies/assassin_enemy.gd`
- `scripts/entities/enemies/healer_enemy.gd`

### 阶段3: Boss战系统
**任务**:
1. 创建Boss基类
2. 设计Boss战机制
3. 实现2-3个Boss
4. 创建Boss战专用UI

**Boss设计**:
- **Mini Boss (关卡5)**: 森林守卫
  - 3个阶段
  - 召唤小怪
  - 范围攻击
  
- **Final Boss (关卡10)**: 火焰领主
  - 5个阶段
  - 多种攻击模式
  - 场景互动

**文件**:
- `scripts/entities/bosses/boss_base.gd`
- `scripts/entities/bosses/forest_guardian.gd`
- `scripts/entities/bosses/flame_lord.gd`
- `scripts/ui/boss_health_bar.gd`

### 阶段4: 新技能系统
**任务**:
1. 设计3种新技能
2. 实现技能效果
3. 添加技能升级系统
4. 平衡技能数值

**新技能**:
- **护盾技能**: 吸收伤害，持续5秒
- **传送技能**: 瞬移到指定位置
- **时间减速**: 减慢敌人速度50%，持续3秒

**文件**:
- `scripts/systems/skills/shield_skill.gd`
- `scripts/systems/skills/teleport_skill.gd`
- `scripts/systems/skills/time_slow_skill.gd`

### 阶段5: 新道具系统
**任务**:
1. 设计8种新道具
2. 实现道具效果
3. 创建道具稀有度系统
4. 平衡道具掉落率

**新道具**:
- **生命药水**: 恢复50% HP
- **能量药水**: 恢复技能CD
- **攻击宝石**: 永久+10% 攻击
- **防御宝石**: 永久+10% 防御
- **速度药剂**: 临时+50% 移速
- **无敌星星**: 5秒无敌
- **磁铁**: 自动吸引道具
- **炸弹**: 范围伤害

**文件**:
- `scripts/systems/items/consumable_items.gd`
- `scripts/systems/items/permanent_items.gd`
- `scripts/systems/items/item_rarity.gd`

### 阶段6: 新障碍和陷阱
**任务**:
1. 设计15种新障碍
2. 实现障碍机制
3. 创建障碍组合模式
4. 平衡障碍难度

**新障碍**:
- **移动平台**: 周期性移动
- **激光陷阱**: 间歇性激光
- **火焰喷射**: 定时喷火
- **毒气区域**: 持续伤害
- **冰冻地面**: 减速区域
- **传送门**: 传送到另一位置
- **旋转刀片**: 持续旋转
- **塌陷地板**: 踩上后坠落
- **弹射板**: 弹射玩家
- **重力区域**: 改变重力方向

**文件**:
- `scripts/objects/obstacles/moving_platform.gd`
- `scripts/objects/obstacles/laser_trap.gd`
- `scripts/objects/obstacles/flame_trap.gd`
- 等等...

### 阶段7: 关卡内容实现
**任务**:
1. 实现10个关卡
2. 配置关卡目标
3. 放置敌人和道具
4. 调整难度平衡

**关卡列表**:
1. **关卡1 - 草原初章**: 教学关卡，2个基础敌人
2. **关卡2 - 草原试炼**: 基础战斗，3-4个敌人
3. **关卡3 - 森林入口**: 引入飞行敌人，5个敌人
4. **关卡4 - 森林深处**: 多种敌人组合，7个敌人
5. **关卡5 - 森林守卫 (Mini Boss)**: 第一个Boss战
6. **关卡6 - 山洞探索**: 黑暗环境，8个敌人
7. **关卡7 - 山洞险境**: 复杂地形+障碍，10个敌人
8. **关卡8 - 火山前哨**: 火焰陷阱，12个敌人
9. **关卡9 - 火山核心**: 极限挑战，15个敌人
10. **关卡10 - 火焰领主 (Final Boss)**: 最终Boss战

### 阶段8: 测试和平衡
**任务**:
1. 创建测试套件
2. 测试所有新内容
3. 平衡难度曲线
4. 修复Bug

**文件**:
- `scripts/tests/phase_24_content_test.gd`

---

## 📊 详细设计

### 关卡配置数据结构

```gdscript
# LevelConfig
{
    "id": 1,
    "name": "草原初章",
    "theme": "grassland",
    "description": "欢迎来到蛋黄冒险的第一关",
    "difficulty": 1,
    "time_limit": 120,
    "objectives": [
        {
            "type": "defeat_all",
            "description": "击败所有敌人"
        }
    ],
    "enemies": [
        {"type": "basic", "position": Vector3(10, 0, 10), "level": 1},
        {"type": "basic", "position": Vector3(-10, 0, -10), "level": 1}
    ],
    "obstacles": [
        {"type": "spike", "position": Vector3(0, 0, 5)},
        {"type": "spike", "position": Vector3(0, 0, -5)}
    ],
    "items": [
        {"type": "health_potion", "position": Vector3(5, 0, 0)},
        {"type": "coin", "position": Vector3(-5, 0, 0)}
    ],
    "spawn_point": Vector3(0, 0, -15),
    "exit_point": Vector3(0, 0, 15),
    "requirements": {
        "unlocked_by": null  # 默认解锁
    }
}
```

### 新敌人属性

```gdscript
# 飞行敌人
{
    "name": "Flying Enemy",
    "hp": 60,
    "damage": 15,
    "speed": 4.0,
    "attack_range": 8.0,
    "attack_cooldown": 2.0,
    "fly_height": 3.0,
    "abilities": ["ranged_attack", "dodge"]
}

# 坦克敌人
{
    "name": "Tank Enemy",
    "hp": 200,
    "damage": 30,
    "speed": 1.5,
    "attack_range": 2.0,
    "attack_cooldown": 3.0,
    "abilities": ["heavy_strike", "damage_reduction"]
}

# 法师敌人
{
    "name": "Mage Enemy",
    "hp": 80,
    "damage": 20,
    "speed": 2.0,
    "attack_range": 10.0,
    "attack_cooldown": 4.0,
    "abilities": ["magic_missile", "summon_minion"]
}

# 刺客敌人
{
    "name": "Assassin Enemy",
    "hp": 40,
    "damage": 40,
    "speed": 6.0,
    "attack_range": 1.5,
    "attack_cooldown": 1.5,
    "abilities": ["dash", "backstab"]
}

# 治疗敌人
{
    "name": "Healer Enemy",
    "hp": 70,
    "damage": 10,
    "speed": 2.5,
    "attack_range": 12.0,
    "attack_cooldown": 5.0,
    "abilities": ["heal", "buff_allies"]
}
```

### Boss设计 - 森林守卫

```gdscript
# Forest Guardian Boss
{
    "name": "森林守卫",
    "hp": 500,
    "phases": [
        {
            "hp_threshold": 100,  # 100% - 66%
            "abilities": ["slash", "stomp"],
            "summon_count": 0
        },
        {
            "hp_threshold": 66,   # 66% - 33%
            "abilities": ["slash", "stomp", "root_trap"],
            "summon_count": 2
        },
        {
            "hp_threshold": 33,   # 33% - 0%
            "abilities": ["slash", "stomp", "root_trap", "enrage"],
            "summon_count": 4
        }
    ],
    "attacks": {
        "slash": {
            "damage": 30,
            "cooldown": 2.0,
            "range": 5.0
        },
        "stomp": {
            "damage": 50,
            "cooldown": 5.0,
            "range": 8.0,
            "aoe": true
        },
        "root_trap": {
            "damage": 20,
            "cooldown": 8.0,
            "effect": "slow",
            "duration": 3.0
        }
    }
}
```

### Boss设计 - 火焰领主

```gdscript
# Flame Lord Boss
{
    "name": "火焰领主",
    "hp": 1000,
    "phases": [
        {
            "hp_threshold": 100,  # 100% - 80%
            "abilities": ["fireball", "flame_wave"],
            "arena_hazards": []
        },
        {
            "hp_threshold": 80,   # 80% - 60%
            "abilities": ["fireball", "flame_wave", "meteor"],
            "arena_hazards": ["lava_pool"]
        },
        {
            "hp_threshold": 60,   # 60% - 40%
            "abilities": ["fireball", "flame_wave", "meteor", "fire_shield"],
            "arena_hazards": ["lava_pool", "flame_pillar"],
            "summon_count": 2
        },
        {
            "hp_threshold": 40,   # 40% - 20%
            "abilities": ["fireball", "flame_wave", "meteor", "fire_shield", "lava_geyser"],
            "arena_hazards": ["lava_pool", "flame_pillar"],
            "summon_count": 4
        },
        {
            "hp_threshold": 20,   # 20% - 0%
            "abilities": ["all_abilities", "enrage", "inferno"],
            "arena_hazards": ["lava_pool", "flame_pillar", "fire_tornado"],
            "summon_count": 6
        }
    ]
}
```

---

## 🔨 实施步骤

### Step 1: 创建关卡配置系统

首先实现关卡配置和生成系统，让后续内容可以快速添加。

**优先级**: 最高  
**依赖**: 无  
**产出**: 关卡配置框架

### Step 2: 实现新敌人类型

一次实现一种敌人，确保每种敌人都经过测试和平衡。

**顺序**: 飞行 → 坦克 → 法师 → 刺客 → 治疗  
**优先级**: 高  
**依赖**: Step 1  
**产出**: 5种新敌人

### Step 3: 实现Mini Boss

先实现较简单的Mini Boss，为Final Boss积累经验。

**优先级**: 高  
**依赖**: Step 2  
**产出**: 森林守卫Boss

### Step 4: 实现新技能

添加新技能，丰富玩家战术选择。

**优先级**: 中高  
**依赖**: Step 1  
**产出**: 3种新技能

### Step 5: 实现新道具

添加新道具，增加游戏深度。

**优先级**: 中高  
**依赖**: Step 1  
**产出**: 8种新道具

### Step 6: 实现新障碍

添加新障碍，增加关卡挑战性。

**优先级**: 中  
**依赖**: Step 1  
**产出**: 10+种新障碍

### Step 7: 创建关卡内容

使用所有新内容创建10个关卡。

**优先级**: 高  
**依赖**: Step 1-6  
**产出**: 10个完整关卡

### Step 8: 实现Final Boss

最复杂的Boss，放在最后实现。

**优先级**: 高  
**依赖**: Step 3  
**产出**: 火焰领主Boss

### Step 9: 测试和平衡

全面测试，调整难度曲线。

**优先级**: 最高  
**依赖**: Step 1-8  
**产出**: 稳定的游戏体验

---

## ✅ 验收标准

### 功能完整性
- [ ] 10个关卡全部可玩
- [ ] 5种新敌人正常工作
- [ ] 2个Boss战正常工作
- [ ] 3种新技能可用
- [ ] 8种新道具可用
- [ ] 10+种新障碍正常工作

### 质量标准
- [ ] 所有测试通过
- [ ] 无严重Bug
- [ ] 难度曲线合理
- [ ] 性能稳定（60fps）

### 游戏体验
- [ ] 关卡有区分度
- [ ] Boss战有挑战性
- [ ] 敌人平衡合理
- [ ] 道具有用且有趣

---

## 📈 预期成果

完成Phase 24后，游戏将拥有：

- **10个完整关卡** - 从教学到终极挑战
- **8种敌人类型** - 丰富的战斗体验
- **2个Boss战** - 高潮战斗
- **6种技能** - 多样战术选择
- **15+种道具** - 丰富收集体验
- **20+种障碍** - 复杂关卡设计

**游戏时长**: 从30分钟扩展到2-3小时  
**重玩价值**: 显著提升  
**发布就绪度**: 90%+

---

## 🚀 开始实施

**当前任务**: Step 1 - 创建关卡配置系统

让我们开始吧！


