# 系统快速参考

## 快速开始

### 访问游戏管理器
```gdscript
# GameManager 是自动加载的单例
var level = GameManager.level_system.current_level
var gold = GameManager.shop_system.get_player_gold()
```

## 常用操作

### 等级系统
```gdscript
# 增加经验值
GameManager.level_system.add_exp(100)

# 获取等级信息
var info = GameManager.level_system.get_level_info()
# { level: 10, current_exp: 500, required_exp: 1000, progress: 0.5 }

# 监听升级
GameManager.level_system.level_up.connect(func(new_level):
    print("升级到 %d 级！" % new_level)
)
```

### 属性系统
```gdscript
# 分配属性点
GameManager.stats_system.allocate_stat("strength", 5)

# 获取属性加成
var strength_bonus = GameManager.stats_system.get_stat_value("strength")

# 重置属性
GameManager.stats_system.reset_stats()
```

### 装备系统
```gdscript
# 装备物品
var sword = GameManager.equipment_database.get_equipment_by_id("iron_sword")
GameManager.equipment_system.equip_item(sword)

# 卸下装备
var old_item = GameManager.equipment_system.unequip_item("main_hand")

# 获取总属性
var stats = GameManager.equipment_system.get_total_stats()

# 获取装备评分
var score = GameManager.equipment_system.get_equipment_score()
```

### 背包系统
```gdscript
# 添加物品
var potion = GameManager.item_database.get_item_by_id("health_potion_small")
GameManager.inventory_system.add_item(potion, 5)

# 移除物品
var removed = GameManager.inventory_system.remove_item("health_potion_small", 1)

# 检查物品数量
var count = GameManager.inventory_system.get_item_count("health_potion_small")

# 查找物品
var slot = GameManager.inventory_system.find_item("health_potion_small")

# 排序背包
GameManager.inventory_system.sort_by("rarity")  # "rarity", "type", "name", "quantity"

# 获取使用率
var usage = GameManager.inventory_system.get_usage_percentage()
```

### 快捷栏系统
```gdscript
# 绑定物品到快捷栏
GameManager.quick_bar_system.bind_slot(0, inventory_slot_index)

# 使用快捷栏物品
GameManager.quick_bar_system.use_quick_bar_item(0)

# 解绑快捷栏
GameManager.quick_bar_system.unbind_slot(0)

# 自动绑定物品
var quick_slot = GameManager.quick_bar_system.auto_bind_item(inventory_slot)

# 清理无效绑定
GameManager.quick_bar_system.cleanup_invalid_bindings()
```

### 技能树系统
```gdscript
# 添加技能点
GameManager.skill_tree_system.add_skill_points(3)

# 解锁技能
if GameManager.skill_tree_system.can_unlock_skill("fireball"):
    GameManager.skill_tree_system.unlock_skill("fireball")

# 升级技能
if GameManager.skill_tree_system.can_upgrade_skill("fireball"):
    GameManager.skill_tree_system.upgrade_skill("fireball")

# 获取技能等级
var level = GameManager.skill_tree_system.get_skill_level("fireball")

# 获取所有技能加成
var bonuses = GameManager.skill_tree_system.get_total_skill_bonuses()

# 重置技能树
var refunded = GameManager.skill_tree_system.reset_skills()
```

### 成就系统
```gdscript
# 解锁成就
GameManager.achievement_system.unlock_achievement("first_kill")

# 更新进度
GameManager.achievement_system.increment_progress("kill_100_enemies", 1)

# 检查成就
GameManager.achievement_system.check_achievement("reach_level_10")

# 获取成就信息
var achievement = GameManager.achievement_system.get_achievement_info("first_kill")

# 获取已解锁数量
var count = GameManager.achievement_system.get_unlocked_count()
```

### 商店系统
```gdscript
# 购买物品
if GameManager.shop_system.can_buy("shop_main", "health_potion_small"):
    GameManager.shop_system.buy_item("shop_main", "health_potion_small")

# 出售物品
var price = GameManager.shop_system.sell_item("iron_ore", 10)

# 获取金币
var gold = GameManager.shop_system.get_player_gold()

# 刷新商店
GameManager.shop_system.refresh_shop("shop_main")
```

### 掉落系统
```gdscript
# 生成敌人掉落
var luck = 1.2  # 幸运加成
var drops = GameManager.drop_system.generate_enemy_drops("goblin", 5, luck)

# 生成金币
var gold = GameManager.drop_system.generate_gold_drop(10, 5, luck)

# 生成经验值
var exp = GameManager.drop_system.generate_exp_drop(50, 5)

# 使用掉落表
var loot = GameManager.drop_system.roll_loot_table("goblin_loot", luck)
```

### 存档系统
```gdscript
# 保存游戏
GameManager.save_manager.save_game("slot_1")

# 加载游戏
if GameManager.save_manager.load_game("slot_1"):
    print("加载成功")

# 删除存档
GameManager.save_manager.delete_save("slot_1")

# 获取存档列表
var saves = GameManager.save_manager.list_saves()

# 检查存档是否存在
if GameManager.save_manager.save_exists("slot_1"):
    print("存档存在")
```

## 综合示例

### 敌人击杀处理
```gdscript
func on_enemy_defeated(enemy_type: String, enemy_level: int):
    # 调用 GameManager 的统一处理
    GameManager.on_enemy_killed(enemy_type, enemy_level)
    # 自动处理：经验值、掉落、金币、成就
```

### 玩家信息面板
```gdscript
func update_player_panel():
    var summary = GameManager.get_player_summary()
    
    level_label.text = "等级 %d" % summary.level
    exp_bar.value = GameManager.level_system.get_exp_progress()
    gold_label.text = "%d 金币" % summary.gold
    skill_points_label.text = "%d 技能点" % summary.skill_points
    
    # 显示总属性
    var stats = summary.total_stats
    attack_label.text = "攻击: %.0f" % stats.get("physical_damage", 0)
    health_label.text = "生命: %.0f" % stats.get("max_health", 0)
    
    # 装备评分
    score_label.text = "装备评分: %d" % summary.equipment_score
    
    # 成就进度
    achievement_label.text = "成就: %d" % summary.achievements_unlocked
```

### 新游戏流程
```gdscript
func start_new_game():
    # 重置所有系统
    GameManager.new_game()
    
    # 给予初始物品
    var starter_weapon = GameManager.equipment_database.get_equipment_by_id("wooden_sword")
    GameManager.inventory_system.add_item(starter_weapon, 1)
    
    var health_potion = GameManager.item_database.get_item_by_id("health_potion_small")
    GameManager.inventory_system.add_item(health_potion, 5)
    
    # 设置初始金币
    GameManager.shop_system.set_player_gold(100)
    
    # 进入游戏场景
    get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")
```

### 继续游戏流程
```gdscript
func continue_game(slot_name: String):
    if GameManager.load_game(slot_name):
        # 加载成功，进入游戏
        get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")
    else:
        # 加载失败，显示错误
        show_error("无法加载存档")
```

### 升级奖励处理
```gdscript
func _ready():
    # 监听升级信号
    GameManager.level_system.level_up.connect(_on_player_level_up)

func _on_player_level_up(new_level: int):
    # 显示升级特效
    show_level_up_effect()
    
    # 播放音效
    AudioManager.play_sfx("level_up")
    
    # 显示奖励提示
    var skill_points = GameManager.skill_tree_system.available_skill_points
    show_notification("升级到 %d 级！\n+1 技能点" % new_level)
    
    # 检查等级相关成就
    GameManager.achievement_system.check_achievement("reach_level_10")
    GameManager.achievement_system.check_achievement("reach_level_25")
```

## 信号参考

### 等级系统
- `level_up(new_level: int)` - 升级时触发
- `exp_gained(amount: int, current_exp: int, required_exp: int)` - 获得经验时触发

### 属性系统
- `stat_changed(stat_name: String, value: float)` - 属性改变时触发
- `stat_points_changed(available_points: int)` - 属性点改变时触发

### 装备系统
- `equipment_changed(slot: String, item)` - 装备改变时触发
- `stats_updated(total_stats: Dictionary)` - 属性更新时触发

### 背包系统
- `inventory_changed()` - 背包改变时触发
- `item_added(item, quantity: int)` - 添加物品时触发
- `item_removed(item, quantity: int)` - 移除物品时触发
- `slot_changed(slot_index: int)` - 槽位改变时触发

### 快捷栏系统
- `quick_bar_changed(slot_index: int)` - 快捷栏改变时触发
- `item_used(slot_index: int, item)` - 使用物品时触发

### 技能树系统
- `skill_unlocked(skill_id: String)` - 解锁技能时触发
- `skill_upgraded(skill_id: String, new_level: int)` - 升级技能时触发
- `skill_points_changed(current_points: int)` - 技能点改变时触发
- `skills_reset()` - 重置技能时触发

### 成就系统
- `achievement_unlocked(achievement_id: String)` - 解锁成就时触发
- `progress_updated(achievement_id: String, current: int, target: int)` - 进度更新时触发

### 商店系统
- `item_bought(shop_id: String, item_id: String)` - 购买物品时触发
- `item_sold(item_id: String, quantity: int, price: int)` - 出售物品时触发
- `gold_changed(current_gold: int)` - 金币改变时触发
- `shop_refreshed(shop_id: String)` - 商店刷新时触发

## 数据结构参考

### 物品类型
- `EQUIPMENT` = 0 - 装备
- `CONSUMABLE` = 1 - 消耗品
- `MATERIAL` = 2 - 材料
- `QUEST` = 3 - 任务物品
- `CURRENCY` = 4 - 货币

### 稀有度
- `COMMON` = 0 - 普通（白色）
- `UNCOMMON` = 1 - 优秀（绿色）
- `RARE` = 2 - 稀有（蓝色）
- `EPIC` = 3 - 史诗（紫色）
- `LEGENDARY` = 4 - 传说（橙色）

### 装备类型
- `MAIN_HAND` = 0 - 主手武器
- `OFF_HAND` = 1 - 副手（盾牌）
- `HELMET` = 2 - 头盔
- `CHEST` = 3 - 胸甲
- `GLOVES` = 4 - 手套
- `BOOTS` = 5 - 靴子
- `RING` = 6 - 戒指
- `NECKLACE` = 7 - 项链

### 成就类型
- `KILL` = 0 - 击杀类
- `COLLECT` = 1 - 收集类
- `LEVEL` = 2 - 等级类
- `COMBAT` = 3 - 战斗类
- `EXPLORATION` = 4 - 探索类
- `SOCIAL` = 5 - 社交类

## 调试命令

```gdscript
# 设置等级
GameManager.level_system._debug_set_level(10)

# 添加经验
GameManager.level_system._debug_add_exp(1000)

# 添加金币
GameManager.shop_system.set_player_gold(99999)

# 添加技能点
GameManager.skill_tree_system.add_skill_points(10)

# 添加属性点
GameManager.stats_system.add_stat_points(20)

# 装备物品（通过ID）
GameManager.equipment_system._debug_equip_by_id("legendary_sword")

# 打印背包
GameManager.inventory_system._debug_print_inventory()

# 打印技能树
GameManager.skill_tree_system._debug_print_skills()

# 打印成就
GameManager.achievement_system._debug_print_achievements()
```
