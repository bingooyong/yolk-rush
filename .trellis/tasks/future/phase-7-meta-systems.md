# Phase 7: Meta Systems & Progression

**Status**: 📋 Planning  
**Priority**: P2  
**Dependencies**: Phase 6 完成  
**Estimated Effort**: 5-6 weeks  
**Target Date**: TBD

---

## 概述

实现游戏元系统（Meta Systems）和角色成长系统，包括经验值、等级、装备、技能树、成就系统。

## 前置条件

- ✅ Phase 1-6 已完成
- ✅ 战斗系统稳定（Phase 5）
- ✅ 多人游戏运行（Phase 6）
- ⚠️ 需要数值策划（经济平衡）
- ⚠️ 需要 UI/UX 设计（菜单系统）

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Rush 添加深度和长期可玩性：
1. 经验值与等级系统
2. 装备系统（武器、防具）
3. 技能树（天赋系统）
4. 成就与任务系统
5. 玩家数据持久化

### 用户故事

**作为玩家**：
- 我希望通过战斗获得经验和升级
- 我希望获得更强的装备
- 我希望自定义角色技能路线
- 我希望完成成就获得奖励
- 我希望数据在设备间同步

**作为设计师**：
- 我希望通过数值配置控制成长曲线
- 我希望装备系统易于扩展
- 我希望玩家有明确的短期和长期目标
- 我希望数据可追踪和分析

### 非目标（本 Phase 不做）

- ❌ 商城系统（Phase 8）
- ❌ 抽卡/Gacha（Phase 8）
- ❌ 公会系统（Phase 9）
- ❌ PvP 排位赛（Phase 9）
- ❌ 赛季系统（Phase 10）

---

## Design (设计方案)

### 架构设计

```
PlayerProfile (玩家档案)
    ├── ProgressionSystem (成长系统)
    │   ├── ExperienceManager (经验管理)
    │   ├── LevelSystem (等级系统)
    │   └── StatsCalculator (属性计算)
    ├── EquipmentSystem (装备系统)
    │   ├── InventoryManager (背包管理)
    │   ├── EquipmentSlots (装备槽位)
    │   └── ItemDatabase (物品数据库)
    ├── SkillTreeSystem (技能树)
    │   ├── TalentNodes (天赋节点)
    │   ├── SkillUnlocker (技能解锁)
    │   └── SkillPointManager (技能点管理)
    ├── AchievementSystem (成就系统)
    │   ├── AchievementTracker (成就追踪)
    │   └── RewardDispenser (奖励分发)
    └── DataPersistence (数据持久化)
        ├── LocalSave (本地存档)
        └── CloudSync (云同步)
```

### 核心组件

#### 1. ExperienceManager.gd

```gdscript
class_name ExperienceManager extends Node

signal level_up(new_level: int)
signal experience_gained(amount: int)

var current_level: int = 1
var current_exp: int = 0
var max_level: int = 50

func add_experience(amount: int) -> void:
    current_exp += amount
    experience_gained.emit(amount)
    
    while current_exp >= get_exp_for_next_level():
        level_up_internal()

func get_exp_for_next_level() -> int:
    # 经验曲线：指数增长
    return int(100 * pow(current_level, 1.5))

func get_exp_for_level(level: int) -> int:
    # 累计经验：从 1 级到目标等级
    var total = 0
    for i in range(1, level):
        total += int(100 * pow(i, 1.5))
    return total

func level_up_internal() -> void:
    if current_level >= max_level:
        return
    
    current_level += 1
    current_exp -= get_exp_for_next_level()
    level_up.emit(current_level)
    
    # 奖励技能点、属性点
    PlayerProfile.skill_points += 1
    PlayerProfile.stat_points += 3
```

#### 2. EquipmentSystem.gd

```gdscript
class_name EquipmentSystem extends Node

enum EquipSlot {
    WEAPON,
    HELMET,
    CHEST,
    GLOVES,
    BOOTS,
    ACCESSORY_1,
    ACCESSORY_2
}

var equipped_items: Dictionary = {}  # EquipSlot -> ItemData
var inventory: Array[ItemData] = []
var max_inventory_size: int = 50

func equip_item(item: ItemData, slot: EquipSlot) -> bool:
    if not can_equip(item, slot):
        return false
    
    # 卸下旧装备
    if equipped_items.has(slot):
        var old_item = equipped_items[slot]
        inventory.append(old_item)
    
    # 装备新物品
    equipped_items[slot] = item
    inventory.erase(item)
    
    # 重新计算属性
    recalculate_stats()
    return true

func recalculate_stats() -> void:
    var base_stats = PlayerProfile.get_base_stats()
    var equipment_bonus = {}
    
    for slot in equipped_items:
        var item: ItemData = equipped_items[slot]
        for stat in item.stats:
            equipment_bonus[stat] = equipment_bonus.get(stat, 0) + item.stats[stat]
    
    PlayerProfile.current_stats = base_stats.merge(equipment_bonus)
```

#### 3. SkillTreeSystem.gd

```gdscript
class_name SkillTreeSystem extends Node

class TalentNode:
    var id: String
    var name: String
    var description: String
    var icon: Texture2D
    var max_rank: int = 1
    var current_rank: int = 0
    var cost: int = 1
    var requirements: Array[String] = []  # 前置节点 ID
    var effects: Dictionary = {}  # stat -> bonus

var talent_tree: Dictionary = {}  # node_id -> TalentNode
var unlocked_talents: Dictionary = {}  # node_id -> rank
var available_points: int = 0

func unlock_talent(node_id: String) -> bool:
    var node: TalentNode = talent_tree[node_id]
    
    # 检查前置条件
    for req in node.requirements:
        if not unlocked_talents.has(req):
            return false
    
    # 检查技能点
    if available_points < node.cost:
        return false
    
    # 检查最大等级
    var current_rank = unlocked_talents.get(node_id, 0)
    if current_rank >= node.max_rank:
        return false
    
    # 解锁
    available_points -= node.cost
    unlocked_talents[node_id] = current_rank + 1
    
    # 应用效果
    apply_talent_effects(node)
    return true

func reset_talents(free: bool = false) -> void:
    if not free:
        # 重置需要消耗货币
        if not PlayerProfile.can_afford(reset_cost):
            return
        PlayerProfile.spend_currency(reset_cost)
    
    # 退还技能点
    for node_id in unlocked_talents:
        var node = talent_tree[node_id]
        available_points += node.cost * unlocked_talents[node_id]
    
    unlocked_talents.clear()
    recalculate_stats()
```

#### 4. AchievementSystem.gd

```gdscript
class_name AchievementSystem extends Node

class Achievement:
    var id: String
    var title: String
    var description: String
    var icon: Texture2D
    var points: int
    var rewards: Dictionary  # type -> amount
    var criteria: Dictionary  # type -> target_value
    var hidden: bool = false

var achievements: Dictionary = {}  # achievement_id -> Achievement
var unlocked: Dictionary = {}  # achievement_id -> unlock_timestamp
var progress: Dictionary = {}  # achievement_id -> current_value

signal achievement_unlocked(achievement: Achievement)

func track_event(event_type: String, value: int = 1) -> void:
    for ach_id in achievements:
        var ach: Achievement = achievements[ach_id]
        if unlocked.has(ach_id):
            continue
        
        if ach.criteria.has(event_type):
            progress[ach_id] = progress.get(ach_id, 0) + value
            
            if progress[ach_id] >= ach.criteria[event_type]:
                unlock_achievement(ach_id)

func unlock_achievement(ach_id: String) -> void:
    if unlocked.has(ach_id):
        return
    
    var ach: Achievement = achievements[ach_id]
    unlocked[ach_id] = Time.get_unix_time_from_system()
    
    # 分发奖励
    for reward_type in ach.rewards:
        PlayerProfile.add_reward(reward_type, ach.rewards[reward_type])
    
    achievement_unlocked.emit(ach)
```

### 数据驱动配置

**data/progression/level_curve.json**：

```json
{
  "$schema": "../schemas/level_curve_schema.json",
  "max_level": 50,
  "exp_formula": {
    "type": "polynomial",
    "base": 100,
    "exponent": 1.5
  },
  "level_rewards": [
    {
      "level": 1,
      "skill_points": 0,
      "stat_points": 0
    },
    {
      "level": 2,
      "skill_points": 1,
      "stat_points": 3
    },
    {
      "level_range": [3, 50],
      "skill_points": 1,
      "stat_points": 3
    }
  ],
  "milestones": [
    {
      "level": 10,
      "title": "Apprentice",
      "rewards": {
        "gold": 1000,
        "items": ["rare_weapon_box"]
      }
    },
    {
      "level": 25,
      "title": "Veteran",
      "rewards": {
        "gold": 5000,
        "items": ["epic_armor_box"]
      }
    },
    {
      "level": 50,
      "title": "Master",
      "rewards": {
        "gold": 20000,
        "items": ["legendary_weapon"]
      }
    }
  ]
}
```

**data/items/weapons.json**：

```json
{
  "$schema": "../schemas/item_schema.json",
  "items": [
    {
      "id": "wooden_sword",
      "name": "木剑",
      "type": "weapon",
      "rarity": "common",
      "level_requirement": 1,
      "stats": {
        "attack_power": 5
      },
      "icon": "res://assets/icons/weapons/wooden_sword.png",
      "model": "res://assets/models/weapons/wooden_sword.glb"
    },
    {
      "id": "iron_sword",
      "name": "铁剑",
      "type": "weapon",
      "rarity": "uncommon",
      "level_requirement": 5,
      "stats": {
        "attack_power": 12,
        "crit_rate": 0.05
      },
      "icon": "res://assets/icons/weapons/iron_sword.png",
      "model": "res://assets/models/weapons/iron_sword.glb"
    },
    {
      "id": "flame_blade",
      "name": "烈焰之刃",
      "type": "weapon",
      "rarity": "rare",
      "level_requirement": 15,
      "stats": {
        "attack_power": 25,
        "crit_rate": 0.1,
        "elemental_damage": 10
      },
      "special_effect": "burn_on_hit",
      "icon": "res://assets/icons/weapons/flame_blade.png",
      "model": "res://assets/models/weapons/flame_blade.glb"
    }
  ]
}
```

**data/progression/skill_tree.json**：

```json
{
  "$schema": "../schemas/skill_tree_schema.json",
  "trees": [
    {
      "id": "combat_tree",
      "name": "战斗天赋",
      "icon": "res://assets/icons/trees/combat.png",
      "nodes": [
        {
          "id": "combat_base",
          "name": "战斗基础",
          "description": "攻击力 +5",
          "position": [0, 0],
          "max_rank": 5,
          "cost": 1,
          "effects": {
            "attack_power": 5
          }
        },
        {
          "id": "heavy_strike",
          "name": "重击",
          "description": "重击伤害 +20%",
          "position": [1, 1],
          "max_rank": 3,
          "cost": 1,
          "requirements": ["combat_base"],
          "effects": {
            "heavy_attack_damage": 0.2
          }
        },
        {
          "id": "combo_master",
          "name": "连击大师",
          "description": "连击窗口 +0.5s",
          "position": [1, -1],
          "max_rank": 3,
          "cost": 1,
          "requirements": ["combat_base"],
          "effects": {
            "combo_window": 0.5
          }
        },
        {
          "id": "berserker",
          "name": "狂战士",
          "description": "生命值低于 30% 时攻击力 +50%",
          "position": [2, 0],
          "max_rank": 1,
          "cost": 3,
          "requirements": ["heavy_strike", "combo_master"],
          "effects": {
            "berserker_bonus": 0.5
          }
        }
      ]
    },
    {
      "id": "defense_tree",
      "name": "防御天赋",
      "icon": "res://assets/icons/trees/defense.png",
      "nodes": [
        {
          "id": "defense_base",
          "name": "防御基础",
          "description": "防御力 +5",
          "position": [0, 0],
          "max_rank": 5,
          "cost": 1,
          "effects": {
            "defense": 5
          }
        },
        {
          "id": "iron_skin",
          "name": "铁皮",
          "description": "受到伤害减少 10%",
          "position": [1, 0],
          "max_rank": 3,
          "cost": 1,
          "requirements": ["defense_base"],
          "effects": {
            "damage_reduction": 0.1
          }
        }
      ]
    }
  ]
}
```

**data/achievements/achievements.json**：

```json
{
  "$schema": "../schemas/achievement_schema.json",
  "achievements": [
    {
      "id": "first_blood",
      "title": "First Blood",
      "description": "击败第一个敌人",
      "icon": "res://assets/icons/achievements/first_blood.png",
      "points": 10,
      "rewards": {
        "gold": 100
      },
      "criteria": {
        "enemies_killed": 1
      }
    },
    {
      "id": "enemy_slayer",
      "title": "敌人杀手",
      "description": "击败 100 个敌人",
      "icon": "res://assets/icons/achievements/enemy_slayer.png",
      "points": 50,
      "rewards": {
        "gold": 1000,
        "items": ["rare_weapon_box"]
      },
      "criteria": {
        "enemies_killed": 100
      }
    },
    {
      "id": "level_10",
      "title": "学徒",
      "description": "达到 10 级",
      "icon": "res://assets/icons/achievements/level_10.png",
      "points": 25,
      "rewards": {
        "gold": 500
      },
      "criteria": {
        "level_reached": 10
      }
    },
    {
      "id": "no_damage_run",
      "title": "完美战斗",
      "description": "在一场战斗中不受伤害",
      "icon": "res://assets/icons/achievements/perfect.png",
      "points": 100,
      "rewards": {
        "gold": 5000,
        "title": "无伤战神"
      },
      "criteria": {
        "no_damage_battles": 1
      },
      "hidden": true
    }
  ]
}
```

### 数据持久化

#### LocalSave 系统

```gdscript
# scripts/persistence/save_manager.gd
class_name SaveManager extends Node

const SAVE_PATH = "user://save_data.json"
const BACKUP_PATH = "user://save_data_backup.json"

func save_game() -> Error:
    var save_data = {
        "version": "1.0.0",
        "timestamp": Time.get_unix_time_from_system(),
        "player_profile": PlayerProfile.serialize(),
        "progression": {
            "level": ExperienceManager.current_level,
            "exp": ExperienceManager.current_exp,
            "skill_points": SkillTreeSystem.available_points,
            "unlocked_talents": SkillTreeSystem.unlocked_talents
        },
        "equipment": {
            "equipped": EquipmentSystem.serialize_equipped(),
            "inventory": EquipmentSystem.serialize_inventory()
        },
        "achievements": {
            "unlocked": AchievementSystem.unlocked,
            "progress": AchievementSystem.progress
        }
    }
    
    # 备份旧存档
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
    
    # 写入新存档
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        return FileAccess.get_open_error()
    
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    return OK

func load_game() -> Error:
    if not FileAccess.file_exists(SAVE_PATH):
        return ERR_FILE_NOT_FOUND
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        # 尝试加载备份
        return load_backup()
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        return load_backup()
    
    var save_data = json.data
    
    # 版本检查
    if save_data.version != "1.0.0":
        migrate_save_data(save_data)
    
    # 恢复数据
    PlayerProfile.deserialize(save_data.player_profile)
    ExperienceManager.current_level = save_data.progression.level
    ExperienceManager.current_exp = save_data.progression.exp
    SkillTreeSystem.available_points = save_data.progression.skill_points
    SkillTreeSystem.unlocked_talents = save_data.progression.unlocked_talents
    EquipmentSystem.deserialize(save_data.equipment)
    AchievementSystem.unlocked = save_data.achievements.unlocked
    AchievementSystem.progress = save_data.achievements.progress
    
    return OK
```

#### CloudSync 系统（可选）

```gdscript
# scripts/persistence/cloud_sync.gd
class_name CloudSync extends Node

signal sync_started()
signal sync_completed(success: bool)
signal conflict_detected(local_data: Dictionary, remote_data: Dictionary)

var api_endpoint: String = "https://api.yolkrush.com/v1/save"
var auth_token: String = ""

func sync_to_cloud() -> void:
    sync_started.emit()
    
    var local_data = SaveManager.get_save_data()
    var headers = [
        "Authorization: Bearer " + auth_token,
        "Content-Type: application/json"
    ]
    
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_upload_completed)
    
    http.request(
        api_endpoint + "/upload",
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(local_data)
    )

func sync_from_cloud() -> void:
    sync_started.emit()
    
    var headers = ["Authorization: Bearer " + auth_token]
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_download_completed)
    
    http.request(
        api_endpoint + "/download",
        headers,
        HTTPClient.METHOD_GET
    )

func resolve_conflict(use_local: bool) -> void:
    if use_local:
        sync_to_cloud()
    else:
        sync_from_cloud()
```

---

## Implementation Plan

### Task 1: Experience & Level System (4 days)

**文件**：
- `scripts/progression/experience_manager.gd`
- `scripts/progression/level_system.gd`
- `data/progression/level_curve.json`
- `data/schemas/level_curve_schema.json`

**实现**：
1. 经验值管理
2. 等级计算（指数曲线）
3. 升级事件与奖励
4. UI 显示（经验条）

**验收**：
- [ ] 击败敌人获得经验
- [ ] 经验累积触发升级
- [ ] 升级获得技能点和属性点
- [ ] 经验曲线平滑合理

### Task 2: Equipment System Core (5 days)

**文件**：
- `scripts/equipment/equipment_system.gd`
- `scripts/equipment/item_data.gd`
- `scripts/equipment/inventory_manager.gd`
- `data/items/weapons.json`
- `data/items/armor.json`

**实现**：
1. 物品数据结构
2. 背包系统（增删查）
3. 装备槽位（7 个槽位）
4. 装备/卸下逻辑
5. 属性重新计算

**验收**：
- [ ] 物品从 JSON 正确加载
- [ ] 背包增删改查正常
- [ ] 装备正确影响属性
- [ ] 装备切换平滑

### Task 3: Item Drops & Loot (3 days)

**实现**：
1. 战利品表系统
2. 随机掉落算法（稀有度权重）
3. 掉落物生成
4. 拾取交互

**验收**：
- [ ] 敌人死亡掉落物品
- [ ] 稀有度权重正确
- [ ] 玩家可拾取物品
- [ ] 背包满时处理正确

### Task 4: Skill Tree System (5 days)

**文件**：
- `scripts/progression/skill_tree_system.gd`
- `scripts/progression/talent_node.gd`
- `data/progression/skill_tree.json`

**实现**：
1. 技能树数据结构
2. 天赋节点依赖检查
3. 技能点消耗
4. 技能效果应用
5. 重置天赋功能

**验收**：
- [ ] 技能树从 JSON 加载
- [ ] 前置条件正确检查
- [ ] 技能效果正确应用
- [ ] 重置天赋功能正常

### Task 5: Achievement System (4 days)

**文件**：
- `scripts/progression/achievement_system.gd`
- `scripts/progression/achievement_tracker.gd`
- `data/achievements/achievements.json`

**实现**：
1. 成就数据结构
2. 事件追踪系统
3. 成就解锁逻辑
4. 奖励分发

**验收**：
- [ ] 成就正确追踪进度
- [ ] 解锁触发正确
- [ ] 奖励正确分发
- [ ] 隐藏成就功能正常

### Task 6: Progression UI (6 days)

**文件**：
- `scenes/ui/player_menu.tscn`
- `scenes/ui/equipment_panel.tscn`
- `scenes/ui/skill_tree_panel.tscn`
- `scenes/ui/achievement_panel.tscn`

**UI 组件**：
1. 角色面板（等级、属性、头像）
2. 背包界面（网格布局、拖拽）
3. 装备界面（7 个槽位 + 纸娃娃）
4. 技能树界面（节点图、连线）
5. 成就界面（分类、进度条）

**验收**：
- [ ] 所有面板可打开/关闭
- [ ] 装备可拖拽
- [ ] 技能树可点击解锁
- [ ] 成就显示进度

### Task 7: Save System (4 days)

**文件**：
- `scripts/persistence/save_manager.gd`
- `scripts/persistence/serialization.gd`

**实现**：
1. 本地存档（JSON）
2. 自动保存
3. 多存档槽位
4. 备份机制
5. 版本迁移

**验收**：
- [ ] 游戏进度正确保存
- [ ] 加载恢复所有数据
- [ ] 存档损坏时加载备份
- [ ] 旧版本存档可迁移

### Task 8: Cloud Sync (Optional, 3 days)

**实现**：
1. 云存档上传/下载
2. 冲突检测
3. 合并策略
4. 离线队列

**验收**：
- [ ] 存档上传到云端
- [ ] 跨设备同步成功
- [ ] 冲突提示玩家选择
- [ ] 离线时队列等待

### Task 9: Data Balance & Testing (5 days)

**数值调整**：
1. 经验曲线平衡
2. 装备属性平衡
3. 技能效果平衡
4. 掉落概率调整

**测试**：
- 快速升级测试（作弊码）
- 边界测试（背包满、等级上限）
- 存档兼容性测试

**验收**：
- [ ] 升级速度合理（1-10 级 ~1 小时）
- [ ] 装备稀有度合理（白 60% / 绿 30% / 蓝 9% / 紫 1%）
- [ ] 技能平衡无明显 OP
- [ ] 所有边界情况处理正确

### Task 10: Documentation & Tools (2 days)

**工具**：
- `tools/item_editor.gd` - 物品编辑器
- `tools/skill_tree_visualizer.gd` - 技能树可视化
- `.agents/skills/add-item.md` - AI Skill

**文档**：
- 数值策划表格
- 装备设计指南
- 技能树设计模板

**验收**：
- [ ] 工具可用于快速配置
- [ ] 文档完整
- [ ] AI Skill 正常工作

---

## Acceptance Criteria

### 功能验收

- [ ] 经验系统完整（获得、升级、奖励）
- [ ] 装备系统可用（7 槽位 + 背包）
- [ ] 至少 20 个可装备物品
- [ ] 技能树完整（2 棵树 + 10+ 节点）
- [ ] 成就系统可用（20+ 成就）
- [ ] 数据可保存和加载

### 技术验收

- [ ] 所有配置数据驱动（JSON）
- [ ] 存档系统稳定可靠
- [ ] 云同步可选功能（如实现）
- [ ] 数值平衡工具完备

### 性能验收

- [ ] 保存/加载时间 < 1 秒
- [ ] UI 响应延迟 < 50ms
- [ ] 内存增加 < 30MB

### 用户体验验收

- [ ] 升级有明显反馈
- [ ] 装备获得有满足感
- [ ] 技能树有策略深度
- [ ] 成就解锁有惊喜感

---

## Risks & Mitigations

### Risk 1: 数值平衡困难

**影响**: 高（影响可玩性）  
**缓解**:
- 提供数值调整工具
- 内测收集反馈
- 参考成功游戏案例

### Risk 2: 存档损坏

**影响**: 高（用户流失）  
**缓解**:
- 多重备份机制
- 版本兼容性测试
- 云同步作为保险

### Risk 3: 技能树设计复杂

**影响**: 中（开发周期）  
**缓解**:
- 先实现简单版本
- 可视化工具辅助
- 参考成熟设计（PoE, Diablo）

---

## Out of Scope (Phase 8+)

- ❌ 商城系统
- ❌ 抽卡/Gacha
- ❌ 内购（IAP）
- ❌ 皮肤系统

---

## Estimated Timeline

```
Week 1: Experience + Equipment Core
Week 2: Item Drops + Skill Tree
Week 3: Achievement + Progression UI
Week 4: Progression UI (continued)
Week 5: Save System + Cloud Sync
Week 6: Balance + Testing + Documentation
```

**Total**: 5-6 weeks

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 依赖 Phase 6 完成
