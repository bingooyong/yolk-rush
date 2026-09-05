# Yolk Rush - 开发者快速开始指南

## 目录
1. [项目结构](#项目结构)
2. [运行测试](#运行测试)
3. [使用系统](#使用系统)
4. [添加内容](#添加内容)
5. [常见问题](#常见问题)

## 项目结构

```
yolk-rush/
├── data/                           # JSON 数据文件
│   ├── progression/
│   │   └── level_curve.json       # 等级曲线
│   ├── equipment/
│   │   └── equipment_database.json # 装备数据
│   ├── inventory/
│   │   └── item_database.json      # 物品数据
│   ├── skill_tree/
│   │   └── skill_database.json     # 技能数据
│   ├── achievement/
│   │   └── achievement_database.json # 成就数据
│   ├── shop/
│   │   └── shop_database.json      # 商店数据
│   └── drop/
│       └── drop_database.json      # 掉落数据
│
├── scripts/
│   ├── core/
│   │   ├── app.gd                 # 应用入口
│   │   ├── game_manager.gd        # 游戏管理器 (Autoload)
│   │   └── save_manager.gd        # 存档管理器
│   ├── progression/               # Phase 1: 等级和属性
│   │   ├── level_system.gd
│   │   └── stats_system.gd
│   ├── equipment/                 # Phase 2: 装备系统
│   │   ├── equipment_item.gd
│   │   ├── equipment_database.gd
│   │   └── equipment_system.gd
│   ├── inventory/                 # Phase 3: 背包系统
│   │   ├── inventory_item.gd
│   │   ├── item_database.gd
│   │   ├── inventory_system.gd
│   │   └── quick_bar_system.gd
│   ├── skill_tree/                # Phase 4: 技能树
│   │   ├── skill_node.gd
│   │   ├── skill_database.gd
│   │   └── skill_tree_system.gd
│   ├── achievement/               # Phase 5: 成就系统
│   │   ├── achievement.gd
│   │   ├── achievement_database.gd
│   │   └── achievement_system.gd
│   ├── shop/                      # Phase 6a: 商店
│   │   ├── shop_item.gd
│   │   ├── shop_database.gd
│   │   └── shop_system.gd
│   ├── drop/                      # Phase 6b: 掉落
│   │   ├── loot_table.gd
│   │   ├── loot_entry.gd
│   │   ├── drop_database.gd
│   │   └── drop_system.gd
│   ├── ui/                        # Phase 7: UI 系统
│   │   ├── hud.gd
│   │   ├── inventory_panel.gd
│   │   ├── equipment_panel.gd
│   │   ├── skill_tree_panel.gd
│   │   ├── achievement_panel.gd
│   │   ├── shop_panel.gd
│   │   └── ui_manager.gd
│   └── tests/                     # 测试脚本
│       └── complete_integration_test.gd
│
└── docs/                          # 文档
    ├── PROJECT_SUMMARY.md
    ├── PHASE_1_COMPLETE.md
    ├── PHASE_2_COMPLETE.md
    └── ...
```

## 运行测试

### 完整集成测试
```bash
# 在项目根目录运行
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --script scripts/tests/complete_integration_test.gd
```

### 单个阶段测试
```bash
# Phase 1: 等级和属性
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --script scripts/tests/phase_1_test.gd

# Phase 2: 装备系统
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --script scripts/tests/phase_2_equipment_test.gd

# ... 以此类推
```

## 使用系统

### 1. 通过 GameManager 访问（推荐）

GameManager 是 Autoload 单例，包含所有系统的引用：

```gdscript
# 在任何脚本中访问
extends Node

func _ready():
    # 等待 GameManager 初始化
    if GameManager.is_initialized:
        _on_game_ready()
    else:
        GameManager.game_initialized.connect(_on_game_ready)

func _on_game_ready():
    # 访问等级系统
    GameManager.level_system.add_exp(100)
    
    # 访问背包系统
    var item = GameManager.item_database.get_item_by_id("health_potion")
    GameManager.inventory_system.add_item(item)
    
    # 访问技能树
    GameManager.skill_tree_system.unlock_skill("fireball")
    
    # 访问成就系统
    GameManager.achievement_system.unlock_achievement("first_kill")
```

### 2. 等级和属性系统

```gdscript
# 添加经验值
GameManager.level_system.add_exp(100)

# 分配属性点
GameManager.stats_system.add_stat_points(5)
GameManager.stats_system.allocate_stat("str", 3)  # 力量 +3
GameManager.stats_system.allocate_stat("agi", 2)  # 敏捷 +2

# 获取属性加成
var physical_damage = GameManager.stats_system.get_stat_bonus("physical_damage")
var max_health = GameManager.stats_system.get_stat_bonus("max_health")
```

### 3. 装备系统

```gdscript
# 获取装备
var sword = GameManager.equipment_database.get_equipment_by_id("iron_sword")

# 装备物品
GameManager.equipment_system.equip_item(sword)

# 卸下装备
var old_item = GameManager.equipment_system.unequip_item("main_hand")

# 获取总属性
var total_stats = GameManager.equipment_system.get_total_stats()
print("总物理伤害: ", total_stats["physical_damage"])
```

### 4. 背包系统

```gdscript
# 添加物品
var potion = GameManager.item_database.get_item_by_id("health_potion")
GameManager.inventory_system.add_item(potion, 5)  # 添加 5 个

# 使用物品
GameManager.inventory_system.use_item(0)  # 使用第 0 格的物品

# 移除物品
GameManager.inventory_system.remove_item(0, 1)  # 移除 1 个

# 快捷栏
GameManager.quick_bar_system.assign_slot(0, 5)  # 将背包第 5 格分配到快捷栏 0
GameManager.quick_bar_system.use_slot(0)  # 使用快捷栏 0
```

### 5. 技能树系统

```gdscript
# 解锁技能
if GameManager.skill_tree_system.can_unlock_skill("fireball"):
    GameManager.skill_tree_system.unlock_skill("fireball")

# 升级技能
if GameManager.skill_tree_system.can_upgrade_skill("fireball"):
    GameManager.skill_tree_system.upgrade_skill("fireball")

# 获取技能效果
var effects = GameManager.skill_tree_system.get_skill_effects("fireball")
print("伤害: ", effects.get("damage", 0))

# 重置技能树
GameManager.skill_tree_system.reset_all_skills()
```

### 6. 成就系统

```gdscript
# 解锁成就
GameManager.achievement_system.unlock_achievement("first_kill")

# 更新进度
GameManager.achievement_system.increment_progress("kill_100_enemies", 1)

# 检查成就
GameManager.achievement_system.check_achievement("reach_level_10")

# 获取统计
var total = GameManager.achievement_system.get_total_count()
var unlocked = GameManager.achievement_system.get_unlocked_count()
```

### 7. 商店系统

```gdscript
# 购买物品
if GameManager.shop_system.can_buy("health_potion", 1):
    GameManager.shop_system.buy_item("health_potion", 1)

# 出售物品
var item = GameManager.inventory_system.get_item_at_slot(0)
GameManager.shop_system.sell_item(item, 1)

# 刷新商店
GameManager.shop_system.refresh_stock()
```

### 8. 掉落系统

```gdscript
# 敌人死亡时
func on_enemy_killed(enemy_type: String, enemy_level: int):
    # 通过 GameManager 的统一接口
    GameManager.on_enemy_killed(enemy_type, enemy_level)
    
    # 或手动处理
    var luck = GameManager.stats_system.get_stat_bonus("drop_rate")
    var drops = GameManager.drop_system.generate_enemy_drops(enemy_type, enemy_level, luck)
    
    for drop in drops:
        var item = GameManager.item_database.get_item_by_id(drop.item_id)
        GameManager.inventory_system.add_item(item, drop.quantity)
```

### 9. UI 系统

```gdscript
# UI 由 UIManager 统一管理
# 打开 UI
UIManager.open_ui("inventory")
UIManager.open_ui("equipment")
UIManager.open_ui("skill_tree")

# 关闭 UI
UIManager.close_ui("inventory")

# 切换 UI
UIManager.toggle_ui("inventory")

# 快捷键已配置（在 UIManager 中）
# I - 背包
# C - 装备
# K - 技能树
# A - 成就
# ESC - 暂停菜单
```

## 添加内容

### 添加新装备

1. 编辑 `data/equipment/equipment_database.json`
2. 添加新条目：
```json
{
  "id": "legendary_sword",
  "name": "传说之剑",
  "equipment_type": "main_hand",
  "rarity": "legendary",
  "level_requirement": 50,
  "stats": {
    "physical_damage": 150,
    "crit_chance": 15,
    "attack_speed": 10
  },
  "description": "传说中的神器"
}
```

### 添加新物品

编辑 `data/inventory/item_database.json`：
```json
{
  "id": "super_potion",
  "name": "超级药水",
  "type": "consumable",
  "max_stack": 20,
  "description": "恢复 200 生命值",
  "sell_price": 100,
  "effect": {
    "type": "heal",
    "value": 200
  }
}
```

### 添加新技能

编辑 `data/skill_tree/skill_database.json`：
```json
{
  "id": "meteor",
  "name": "陨石术",
  "tree": "combat",
  "description": "召唤陨石",
  "max_level": 5,
  "level_requirement": 30,
  "skill_point_cost": 2,
  "prerequisites": ["fireball"],
  "effects_per_level": [
    {"damage": 100, "area": 5},
    {"damage": 150, "area": 6},
    {"damage": 200, "area": 7}
  ]
}
```

### 添加新成就

编辑 `data/achievement/achievement_database.json`：
```json
{
  "id": "master_warrior",
  "title": "战斗大师",
  "description": "击败 10000 个敌人",
  "achievement_type": "kill",
  "rarity": "legendary",
  "target_value": 10000,
  "reward_gold": 10000,
  "reward_exp": 50000
}
```

## 常见问题

### Q: 如何保存游戏？
```gdscript
GameManager.save_manager.save_game("save_slot_1")
```

### Q: 如何加载游戏？
```gdscript
GameManager.save_manager.load_game("save_slot_1")
```

### Q: 如何获取玩家总属性？
```gdscript
var total_stats = GameManager.get_total_player_stats()
# 包含：基础属性 + 装备属性 + 技能加成
```

### Q: 如何监听系统事件？
```gdscript
func _ready():
    # 等级提升
    GameManager.level_system.level_up.connect(_on_level_up)
    
    # 装备变化
    GameManager.equipment_system.equipment_changed.connect(_on_equipment_changed)
    
    # 成就解锁
    GameManager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_level_up(new_level: int):
    print("升级到 ", new_level)

func _on_equipment_changed(slot: String, item):
    print("装备变化: ", slot)

func _on_achievement_unlocked(achievement_id: String):
    print("成就解锁: ", achievement_id)
```

### Q: 如何调试？
所有系统都有内置的 debug 方法：
```gdscript
# 设置等级
GameManager.level_system._debug_set_level(50)

# 添加经验
GameManager.level_system._debug_add_exp(10000)

# 装备物品
GameManager.equipment_system._debug_equip_by_id("legendary_sword")

# 打印统计
GameManager.equipment_database._debug_print_all_equipment()
GameManager.skill_database._debug_print_stats()
```

### Q: 系统初始化顺序？
1. App (Autoload)
2. AudioManager (Autoload)
3. GameManager (Autoload)
   - 加载所有数据库
   - 初始化所有系统
   - 连接系统信号
   - 注册存档系统
4. UIManager (场景加载时)

### Q: 如何扩展系统？
每个系统都设计为可扩展：
- 继承现有类
- 添加新的信号
- 扩展 JSON 数据结构
- 实现新的效果类型

## 性能建议

1. **数据库加载**: 数据库在 `_ready()` 时加载，大型数据库考虑异步加载
2. **UI 刷新**: UI 通过信号自动刷新，避免手动轮询
3. **存档频率**: 不要每帧保存，在关键时刻保存（升级、获得装备等）
4. **物品堆叠**: 相同物品自动堆叠，节省背包空间

## 下一步

查看各个阶段的详细文档：
- [Phase 1: 等级和属性系统](PHASE_1_COMPLETE.md)
- [Phase 2: 装备系统](PHASE_2_COMPLETE.md)
- [Phase 3: 背包系统](PHASE_3_COMPLETE.md)
- [Phase 4: 技能树系统](PHASE_4_COMPLETE.md)
- [Phase 5: 成就系统](PHASE_5_COMPLETE.md)
- [Phase 6: 商店和掉落系统](PHASE_6_COMPLETE.md)
- [Phase 7: UI 系统](PHASE_7_COMPLETE.md)

---

**需要帮助？** 查看测试脚本以了解更多使用示例。
