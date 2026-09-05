# Phase 7 元系统 - 快速使用指南

## 🚀 5分钟上手

### 1. 初始化游戏（自动加载所有系统）

```gdscript
# 在主场景中添加游戏管理器
const GameManagerClass = preload("res://scripts/core/game_manager.gd")

func _ready():
    var game_manager = GameManagerClass.new()
    add_child(game_manager)
    await game_manager.game_initialized
    
    # 所有系统已就绪！
    start_new_game(game_manager)

func start_new_game(game_manager):
    # 初始化新游戏
    game_manager.new_game()
    
    # 开始游戏循环
    play_game(game_manager)
```

### 2. 战斗事件处理

```gdscript
# 玩家击杀敌人
func on_enemy_defeated(enemy_type: String, enemy_level: int):
    game_manager.on_enemy_killed(enemy_type, enemy_level)
    # 自动处理：经验值、掉落物品、金币、成就检查
```

### 3. 装备系统

```gdscript
# 获取装备
var sword = game_manager.equipment_database.get_equipment_by_id("iron_sword")

# 穿戴装备
if game_manager.equipment_system.equip_item(sword):
    print("装备成功！")

# 卸下装备
var old_item = game_manager.equipment_system.unequip_item("main_hand")

# 获取总属性加成
var total_stats = game_manager.equipment_system.get_total_stats()
print("物理伤害: %d" % total_stats.get("physical_damage", 0))
```

### 4. 背包系统

```gdscript
# 获取物品
var potion = game_manager.item_database.get_item_by_id("health_potion_small")

# 添加到背包
if game_manager.inventory_system.add_item(potion, 5):
    print("添加了5个生命药水")

# 绑定到快捷栏
var slot_index = 0  # 背包槽位
game_manager.quick_bar_system.bind_slot(0, slot_index)

# 使用快捷栏物品
if game_manager.quick_bar_system.use_quick_bar_item(0):
    print("使用了快捷栏物品")
```

### 5. 技能树

```gdscript
# 检查能否解锁
if game_manager.skill_tree_system.can_unlock_skill("warrior_str_1"):
    # 解锁技能
    game_manager.skill_tree_system.unlock_skill("warrior_str_1")
    print("解锁了力量强化！")

# 升级技能
if game_manager.skill_tree_system.can_upgrade_skill("warrior_str_1"):
    game_manager.skill_tree_system.upgrade_skill("warrior_str_1")

# 获取技能加成
var bonuses = game_manager.skill_tree_system.get_total_skill_bonuses()
print("物理伤害加成: %d" % bonuses.get("physical_damage", 0))
```

### 6. 商店系统

```gdscript
# 购买物品
if game_manager.shop_system.buy_item("health_potion_small", 3):
    print("购买成功！")
else:
    print("金币不足或库存不够")

# 出售物品
var sell_price = game_manager.shop_system.sell_item("iron_ore", 10)
if sell_price > 0:
    print("出售成功，获得 %d 金币" % sell_price)
```

### 7. 存档系统

```gdscript
# 保存游戏（槽位0）
if game_manager.save_manager.save_game(0):
    print("保存成功！")

# 加载游戏
if game_manager.save_manager.load_game(0):
    print("加载成功！")

# 快速存档
game_manager.save_manager.quick_save()

# 快速加载
game_manager.save_manager.quick_load()

# 获取存档信息
var save_info = game_manager.save_manager.get_save_info(0)
if save_info:
    print("等级: %d, 金币: %d" % [save_info.level, save_info.gold])
```

### 8. 成就系统

```gdscript
# 增量式成就（如击杀数）
game_manager.achievement_system.increment_achievement("kill_100_enemies", 1)

# 检查式成就（如等级达成）
game_manager.achievement_system.check_achievement("reach_level_10")

# 获取成就进度
var progress = game_manager.achievement_system.get_achievement_progress("kill_100_enemies")
print("进度: %d / %d" % [progress.current, progress.required])
```

---

## 📊 信号监听（UI更新）

### 等级提升

```gdscript
func _ready():
    game_manager.level_system.level_up.connect(_on_level_up)

func _on_level_up(new_level: int):
    # 更新UI，播放特效
    update_level_display(new_level)
    play_level_up_effect()
```

### 装备变化

```gdscript
func _ready():
    game_manager.equipment_system.equipment_changed.connect(_on_equipment_changed)

func _on_equipment_changed(slot: String, item):
    # 更新装备栏UI
    update_equipment_slot(slot, item)
```

### 背包变化

```gdscript
func _ready():
    game_manager.inventory_system.slot_changed.connect(_on_slot_changed)

func _on_slot_changed(slot_index: int):
    # 更新背包UI
    update_inventory_slot(slot_index)
```

### 快捷栏变化

```gdscript
func _ready():
    game_manager.quick_bar_system.quick_bar_changed.connect(_on_quick_bar_changed)

func _on_quick_bar_changed(slot_index: int):
    # 更新快捷栏UI
    update_quick_bar_slot(slot_index)
```

### 技能解锁

```gdscript
func _ready():
    game_manager.skill_tree_system.skill_unlocked.connect(_on_skill_unlocked)

func _on_skill_unlocked(skill_id: String):
    # 播放解锁特效
    play_skill_unlock_effect(skill_id)
```

### 成就解锁

```gdscript
func _ready():
    game_manager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String):
    # 显示成就通知
    show_achievement_notification(achievement_id)
```

---

## 🎮 完整示例：战斗循环

```gdscript
extends Node

const GameManagerClass = preload("res://scripts/core/game_manager.gd")

var game_manager

func _ready():
    # 初始化
    game_manager = GameManagerClass.new()
    add_child(game_manager)
    await game_manager.game_initialized
    
    # 连接信号
    setup_signals()
    
    # 开始新游戏
    game_manager.new_game()
    
    # 模拟战斗
    simulate_combat()

func setup_signals():
    game_manager.level_system.level_up.connect(_on_level_up)
    game_manager.achievement_system.achievement_unlocked.connect(_on_achievement)

func simulate_combat():
    print("\n=== 开始战斗 ===\n")
    
    # 击杀5只哥布林
    for i in range(5):
        print("击杀哥布林 #%d" % (i + 1))
        game_manager.on_enemy_killed("goblin", 5)
    
    # 检查状态
    var summary = game_manager.get_player_summary()
    print("\n当前状态:")
    print("  等级: %d" % summary.level)
    print("  经验: %d" % summary.exp)
    print("  金币: %d" % summary.gold)
    
    # 购买装备
    if game_manager.shop_system.buy_item("iron_sword", 1):
        print("\n购买了铁剑！")
        
        # 穿戴装备
        var sword = game_manager.equipment_database.get_equipment_by_id("iron_sword")
        if game_manager.equipment_system.equip_item(sword):
            print("装备了铁剑！")
    
    # 保存游戏
    game_manager.save_manager.save_game(0)
    print("\n游戏已保存\n")

func _on_level_up(new_level: int):
    print("🎉 升级到 %d 级！" % new_level)

func _on_achievement(achievement_id: String):
    var achievement = game_manager.achievement_system.get_achievement(achievement_id)
    print("🏆 成就解锁: %s" % achievement.name)
```

---

## 💡 高级用法

### 自定义经验公式

```gdscript
# 在 data/progression/level_curve.json 中修改
# 公式: 100 * (level ^ 1.5)
# 可改为线性增长: 100 * level
```

### 添加新装备

```gdscript
# 编辑 data/equipment/equipment_database.json
{
  "id": "mythril_sword",
  "name": "秘银剑",
  "equipment_type": "main_hand",
  "rarity": "epic",
  "required_level": 20,
  "stats": {
    "physical_damage": 50,
    "crit_chance": 10
  }
}
```

### 添加新技能

```gdscript
# 编辑 data/skill_tree/skill_database.json
{
  "id": "warrior_ult",
  "skill_name": "战神降临",
  "description": "终极技能",
  "max_level": 1,
  "required_level": 30,
  "required_skill_points": 5,
  "prerequisites": ["warrior_str_5"],
  "effects": {
    "physical_damage": 100
  }
}
```

### 自定义掉落表

```gdscript
# 编辑 data/drop/loot_tables.json
{
  "boss_dragon": {
    "gold_range": [500, 1000],
    "exp_range": [1000, 2000],
    "items": [
      {
        "item_id": "dragon_scale",
        "drop_chance": 100,
        "quantity_range": [1, 3]
      }
    ]
  }
}
```

---

## 🔧 调试技巧

### 查看所有数据

```gdscript
# 打印等级系统
game_manager.level_system._debug_print_level_info()

# 打印装备
game_manager.equipment_system._debug_print_equipment()

# 打印背包
game_manager.inventory_system._debug_print_inventory()

# 打印技能树
game_manager.skill_tree_system._debug_print_skills()
```

### 作弊指令（测试用）

```gdscript
# 添加经验
game_manager.level_system.add_exp(1000)

# 添加金币
game_manager.shop_system.add_gold(9999)

# 添加技能点
game_manager.skill_tree_system.add_skill_points(10)

# 解锁所有成就（手动）
for ach_id in game_manager.achievement_system.get_all_achievement_ids():
    game_manager.achievement_system.unlock_achievement(ach_id)
```

---

## 📝 常见问题

**Q: 如何修改初始金币？**  
A: 在 `game_manager.gd` 的 `new_game()` 中修改 `shop_system.set_gold(1000)`

**Q: 如何调整经验曲线？**  
A: 编辑 `data/progression/level_curve.json`，修改各级所需经验值

**Q: 如何增加背包容量？**  
A: 在 `inventory_system.gd` 中修改 `MAX_SLOTS` 常量

**Q: 如何添加新的属性类型？**  
A: 在 `stats_system.gd` 的 `StatType` 枚举中添加，并更新 `calculate_stat_bonus()`

**Q: 存档保存在哪里？**  
A: `user://saves/` 目录，JSON格式，可直接编辑

---

**快速使用指南完成！查看各系统详细文档获取更多信息。** 📚
