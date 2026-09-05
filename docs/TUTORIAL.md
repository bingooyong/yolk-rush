# 游戏系统使用教程

## 目录
1. [基础入门](#基础入门)
2. [等级和属性系统](#等级和属性系统)
3. [装备系统](#装备系统)
4. [背包和快捷栏](#背包和快捷栏)
5. [技能树系统](#技能树系统)
6. [成就系统](#成就系统)
7. [商店系统](#商店系统)
8. [掉落系统](#掉落系统)
9. [存档系统](#存档系统)
10. [综合应用](#综合应用)

---

## 基础入门

### 什么是 GameManager？

GameManager 是游戏的核心管理器，整合了所有游戏系统。你可以通过它访问任何系统。

```gdscript
# GameManager 是自动加载的单例，可以在任何地方访问
var current_level = GameManager.level_system.current_level
var player_gold = GameManager.shop_system.get_player_gold()
```

### 初始化检查

在使用任何系统前，确保 GameManager 已初始化：

```gdscript
func _ready():
    # 等待初始化完成
    if GameManager.is_initialized:
        _setup_game()
    else:
        GameManager.game_initialized.connect(_setup_game)

func _setup_game():
    print("游戏系统已就绪！")
    # 开始使用各个系统
```

---

## 等级和属性系统

### 经验值和升级

```gdscript
# 增加经验值
GameManager.level_system.add_exp(100)

# 监听升级事件
func _ready():
    GameManager.level_system.level_up.connect(_on_level_up)

func _on_level_up(new_level: int):
    print("恭喜升级到 %d 级！" % new_level)
    # 显示升级特效
    show_level_up_effect()
```

### 查询等级信息

```gdscript
# 获取详细信息
var info = GameManager.level_system.get_level_info()
print("等级：%d" % info.level)
print("经验：%d/%d" % [info.current_exp, info.required_exp])
print("进度：%.1f%%" % (info.progress * 100))

# 更新进度条
exp_bar.value = info.progress
```

### 属性点分配

```gdscript
# 分配属性点
if GameManager.stats_system.can_allocate_stat("strength", 5):
    GameManager.stats_system.allocate_stat("strength", 5)
    print("力量 +5")

# 查询属性值
var strength = GameManager.stats_system.get_stat_value("strength")
print("当前力量：%.0f" % strength)

# 获取所有加成
var bonuses = GameManager.stats_system.get_all_bonuses()
print("攻击力加成：%.0f" % bonuses.get("attack_damage", 0))
```

### 重置属性

```gdscript
# 重置所有属性（返还属性点）
var refunded = GameManager.stats_system.reset_stats()
print("返还 %d 属性点" % refunded)
```

---

## 装备系统

### 装备物品

```gdscript
# 从数据库获取装备
var sword = GameManager.equipment_database.get_equipment_by_id("iron_sword")

# 装备到玩家身上
if GameManager.equipment_system.equip_item(sword):
    print("装备成功：%s" % sword.item_name)
else:
    print("装备失败（可能等级不足）")
```

### 卸下装备

```gdscript
# 卸下指定槽位的装备
var old_weapon = GameManager.equipment_system.unequip_item("main_hand")
if old_weapon:
    print("卸下：%s" % old_weapon.item_name)
    # 自动返回背包
```

### 查询装备信息

```gdscript
# 获取当前装备
var weapon = GameManager.equipment_system.get_equipped_item("main_hand")
if weapon:
    print("主手武器：%s" % weapon.item_name)
    print("攻击力：+%.0f" % weapon.stats.get("physical_damage", 0))

# 检查槽位是否为空
if GameManager.equipment_system.is_slot_empty("helmet"):
    print("头盔槽位为空")

# 获取总属性加成
var stats = GameManager.equipment_system.get_total_stats()
print("装备总攻击力：+%.0f" % stats.physical_damage)

# 获取装备评分
var score = GameManager.equipment_system.get_equipment_score()
print("装备评分：%d" % score)
```

### 监听装备变化

```gdscript
func _ready():
    GameManager.equipment_system.equipment_changed.connect(_on_equipment_changed)

func _on_equipment_changed(slot: String, item):
    if item:
        print("装备了 %s：%s" % [slot, item.item_name])
    else:
        print("卸下了 %s" % slot)
    
    # 更新角色外观
    update_character_appearance()
```

---

## 背包和快捷栏

### 添加物品

```gdscript
# 从数据库获取物品
var potion = GameManager.item_database.get_item_by_id("health_potion_small")

# 添加到背包（自动堆叠）
if GameManager.inventory_system.add_item(potion, 5):
    print("获得：%s x5" % potion.item_name)
else:
    print("背包已满！")
```

### 移除物品

```gdscript
# 移除指定数量
var removed = GameManager.inventory_system.remove_item("health_potion_small", 1)
if removed > 0:
    print("使用了生命药水")
    # 恢复生命值
    heal_player(50)
```

### 查询物品

```gdscript
# 检查物品数量
var count = GameManager.inventory_system.get_item_count("iron_ore")
print("铁矿石数量：%d" % count)

# 查找物品槽位
var slot = GameManager.inventory_system.find_item("iron_ore")
if slot != -1:
    print("铁矿石在槽位 %d" % slot)

# 检查是否有物品
if GameManager.inventory_system.has_item("rare_gem"):
    print("拥有稀有宝石")
```

### 背包排序

```gdscript
# 按稀有度排序（稀有物品在前）
GameManager.inventory_system.sort_by("rarity")

# 按类型排序
GameManager.inventory_system.sort_by("type")

# 按名称排序
GameManager.inventory_system.sort_by("name")

# 按数量排序
GameManager.inventory_system.sort_by("quantity")
```

### 快捷栏使用

```gdscript
# 绑定背包物品到快捷栏
var potion_slot = GameManager.inventory_system.find_item("health_potion_small")
if potion_slot != -1:
    GameManager.quick_bar_system.bind_slot(0, potion_slot)
    print("药水绑定到快捷栏 1")

# 使用快捷栏物品
if GameManager.quick_bar_system.use_quick_bar_item(0):
    print("使用了快捷栏 1 的物品")

# 解绑快捷栏
GameManager.quick_bar_system.unbind_slot(0)

# 清理无效绑定（背包物品被删除后）
GameManager.quick_bar_system.cleanup_invalid_bindings()
```

### 监听背包变化

```gdscript
func _ready():
    GameManager.inventory_system.inventory_changed.connect(_on_inventory_changed)
    GameManager.inventory_system.item_added.connect(_on_item_added)

func _on_inventory_changed():
    # 刷新背包UI
    update_inventory_ui()

func _on_item_added(item, quantity: int):
    # 显示获得物品提示
    show_item_notification("获得：%s x%d" % [item.item_name, quantity])
```

---

## 技能树系统

### 技能点管理

```gdscript
# 添加技能点（通常在升级时自动获得）
GameManager.skill_tree_system.add_skill_points(1)

# 查询可用技能点
var points = GameManager.skill_tree_system.available_skill_points
print("可用技能点：%d" % points)
```

### 解锁技能

```gdscript
# 检查是否可以解锁
if GameManager.skill_tree_system.can_unlock_skill("fireball"):
    # 解锁技能
    if GameManager.skill_tree_system.unlock_skill("fireball"):
        print("学会了火球术！")
    else:
        print("解锁失败")
else:
    print("条件不满足：")
    print("- 技能点不足")
    print("- 等级不足")
    print("- 前置技能未解锁")
```

### 升级技能

```gdscript
# 检查是否可以升级
if GameManager.skill_tree_system.can_upgrade_skill("fireball"):
    # 升级技能
    if GameManager.skill_tree_system.upgrade_skill("fireball"):
        var level = GameManager.skill_tree_system.get_skill_level("fireball")
        print("火球术升级到 %d 级" % level)
```

### 查询技能加成

```gdscript
# 获取所有技能加成
var bonuses = GameManager.skill_tree_system.get_total_skill_bonuses()
print("技能伤害加成：+%.1f%%" % bonuses.get("skill_damage", 0))

# 获取指定技能树的加成
var combat_bonuses = GameManager.skill_tree_system.get_tree_bonuses("combat")
print("战斗树提供的攻击力：+%.0f" % combat_bonuses.get("attack", 0))
```

### 重置技能

```gdscript
# 重置所有技能（返还技能点）
var refunded = GameManager.skill_tree_system.reset_skills()
print("返还 %d 技能点" % refunded)

# 只重置指定技能树
var refunded_combat = GameManager.skill_tree_system.reset_tree("combat")
print("战斗树返还 %d 技能点" % refunded_combat)
```

---

## 成就系统

### 解锁成就

```gdscript
# 直接解锁成就
GameManager.achievement_system.unlock_achievement("first_kill")

# 检查成就条件
GameManager.achievement_system.check_achievement("reach_level_10")
```

### 更新进度

```gdscript
# 增加进度
GameManager.achievement_system.increment_progress("kill_100_enemies", 1)

# 设置进度
GameManager.achievement_system.set_progress("collect_10_gems", 5)

# 查询进度
var progress = GameManager.achievement_system.get_progress("kill_100_enemies")
print("击杀进度：%d/100" % progress)
```

### 查询成就信息

```gdscript
# 获取成就详情
var achievement = GameManager.achievement_system.get_achievement_info("first_kill")
if achievement:
    print("成就名称：%s" % achievement.title)
    print("成就描述：%s" % achievement.description)
    print("是否解锁：%s" % ("是" if achievement.is_unlocked else "否"))

# 获取解锁数量
var unlocked = GameManager.achievement_system.get_unlocked_count()
var total = GameManager.achievement_system.get_total_count()
print("成就进度：%d/%d" % [unlocked, total])
```

### 监听成就事件

```gdscript
func _ready():
    GameManager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
    GameManager.achievement_system.progress_updated.connect(_on_progress_updated)

func _on_achievement_unlocked(achievement_id: String):
    var achievement = GameManager.achievement_system.get_achievement_info(achievement_id)
    # 显示成就解锁动画
    show_achievement_popup(achievement)
    # 播放音效
    AudioManager.play_sfx("achievement")

func _on_progress_updated(achievement_id: String, current: int, target: int):
    print("成就进度更新：%d/%d" % [current, target])
```

---

## 商店系统

### 购买物品

```gdscript
# 检查是否可以购买
if GameManager.shop_system.can_buy("shop_main", "health_potion_small"):
    # 购买物品
    if GameManager.shop_system.buy_item("shop_main", "health_potion_small"):
        print("购买成功")
    else:
        print("购买失败（金币不足或库存不足）")
```

### 出售物品

```gdscript
# 出售物品
var earned = GameManager.shop_system.sell_item("iron_ore", 10)
if earned > 0:
    print("出售成功，获得 %d 金币" % earned)
```

### 金币管理

```gdscript
# 查询金币
var gold = GameManager.shop_system.get_player_gold()
print("当前金币：%d" % gold)

# 设置金币（用于调试）
GameManager.shop_system.set_player_gold(1000)
```

### 商店刷新

```gdscript
# 刷新商店（重新生成商品）
GameManager.shop_system.refresh_shop("shop_main")
print("商店已刷新")

# 查询刷新价格
var cost = GameManager.shop_system.get_refresh_cost("shop_main")
print("刷新费用：%d 金币" % cost)
```

### 监听商店事件

```gdscript
func _ready():
    GameManager.shop_system.item_bought.connect(_on_item_bought)
    GameManager.shop_system.gold_changed.connect(_on_gold_changed)

func _on_item_bought(shop_id: String, item_id: String):
    print("在 %s 购买了 %s" % [shop_id, item_id])

func _on_gold_changed(current_gold: int):
    # 更新金币显示
    gold_label.text = "%d" % current_gold
```

---

## 掉落系统

### 生成敌人掉落

```gdscript
# 敌人被击杀时生成掉落
func on_enemy_killed(enemy_type: String, enemy_level: int):
    # 计算幸运值加成
    var luck = GameManager.stats_system.get_stat_bonus("drop_rate")
    
    # 生成物品掉落
    var drops = GameManager.drop_system.generate_enemy_drops(enemy_type, enemy_level, luck)
    for drop in drops:
        print("掉落：%s x%d" % [drop.item_id, drop.quantity])
        # 添加到背包
        var item = GameManager.item_database.get_item_by_id(drop.item_id)
        if item:
            GameManager.inventory_system.add_item(item, drop.quantity)
    
    # 生成金币
    var gold = GameManager.drop_system.generate_gold_drop(10, enemy_level, luck)
    if gold > 0:
        print("获得金币：%d" % gold)
        var current_gold = GameManager.shop_system.get_player_gold()
        GameManager.shop_system.set_player_gold(current_gold + gold)
    
    # 生成经验值
    var exp = GameManager.drop_system.generate_exp_drop(50, enemy_level)
    if exp > 0:
        print("获得经验：%d" % exp)
        GameManager.level_system.add_exp(exp)
```

### 使用掉落表

```gdscript
# 从掉落表生成战利品
var luck = 1.0
var loot = GameManager.drop_system.roll_loot_table("boss_loot", luck)

for item in loot:
    print("战利品：%s x%d" % [item.item_id, item.quantity])
```

---

## 存档系统

### 保存游戏

```gdscript
# 保存到指定槽位
if GameManager.save_manager.save_game("slot_1"):
    print("游戏已保存")
    show_notification("保存成功")
else:
    print("保存失败")
    show_error("保存失败")
```

### 加载游戏

```gdscript
# 从指定槽位加载
if GameManager.save_manager.load_game("slot_1"):
    print("读取成功")
    # 进入游戏场景
    get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")
else:
    print("读取失败")
    show_error("存档不存在或已损坏")
```

### 存档管理

```gdscript
# 检查存档是否存在
if GameManager.save_manager.save_exists("slot_1"):
    print("存档 1 存在")
    # 显示"继续游戏"按钮
    continue_button.visible = true

# 获取存档列表
var saves = GameManager.save_manager.list_saves()
for save_name in saves:
    print("存档：%s" % save_name)

# 删除存档
if GameManager.save_manager.delete_save("slot_1"):
    print("存档已删除")
```

---

## 综合应用

### 完整的敌人击杀流程

```gdscript
# 敌人被击杀时调用
func on_enemy_defeated(enemy: Node3D):
    var enemy_type = enemy.enemy_type  # "goblin", "orc", etc.
    var enemy_level = enemy.level
    
    # 使用 GameManager 的统一处理
    GameManager.on_enemy_killed(enemy_type, enemy_level)
    
    # 以上会自动处理：
    # 1. 生成并添加掉落物品
    # 2. 给予金币
    # 3. 给予经验值（可能触发升级）
    # 4. 更新击杀类成就进度
    
    # 额外处理
    play_death_animation(enemy)
    spawn_loot_visual(enemy.global_position)
```

### 玩家信息面板

```gdscript
extends Control

@onready var level_label = $LevelLabel
@onready var exp_bar = $ExpBar
@onready var gold_label = $GoldLabel
@onready var skill_points_label = $SkillPointsLabel
@onready var stats_container = $StatsContainer

func _ready():
    # 监听变化
    GameManager.level_system.exp_gained.connect(_update_exp)
    GameManager.level_system.level_up.connect(_update_level)
    GameManager.shop_system.gold_changed.connect(_update_gold)
    GameManager.skill_tree_system.skill_points_changed.connect(_update_skill_points)
    
    # 初始显示
    update_all()

func update_all():
    var summary = GameManager.get_player_summary()
    
    # 等级
    level_label.text = "等级 %d" % summary.level
    
    # 经验条
    var info = GameManager.level_system.get_level_info()
    exp_bar.value = info.progress
    exp_bar.tooltip_text = "%d / %d" % [info.current_exp, info.required_exp]
    
    # 金币
    gold_label.text = "%d" % summary.gold
    
    # 技能点
    skill_points_label.text = "x%d" % summary.skill_points
    
    # 属性
    var stats = summary.total_stats
    update_stat_display("攻击力", stats.get("physical_damage", 0))
    update_stat_display("生命值", stats.get("max_health", 0))
    update_stat_display("防御力", stats.get("defense", 0))

func _update_exp(amount: int, current: int, required: int):
    exp_bar.value = float(current) / float(required)

func _update_level(new_level: int):
    level_label.text = "等级 %d" % new_level
    show_level_up_effect()

func _update_gold(current_gold: int):
    gold_label.text = "%d" % current_gold

func _update_skill_points(points: int):
    skill_points_label.text = "x%d" % points
```

### 新游戏初始化

```gdscript
func start_new_game():
    # 重置所有系统
    GameManager.new_game()
    
    # 给予新手装备
    var starter_pack = [
        {"type": "equipment", "id": "wooden_sword", "count": 1},
        {"type": "equipment", "id": "cloth_armor", "count": 1},
        {"type": "item", "id": "health_potion_small", "count": 5},
        {"type": "item", "id": "bread", "count": 10},
    ]
    
    for item_data in starter_pack:
        if item_data.type == "equipment":
            var item = GameManager.equipment_database.get_equipment_by_id(item_data.id)
            if item:
                GameManager.inventory_system.add_item(item, item_data.count)
        else:
            var item = GameManager.item_database.get_item_by_id(item_data.id)
            if item:
                GameManager.inventory_system.add_item(item, item_data.count)
    
    # 设置初始金币
    GameManager.shop_system.set_player_gold(100)
    
    # 进入游戏
    get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")
```

### 自动保存系统

```gdscript
extends Node

# 自动保存间隔（秒）
const AUTOSAVE_INTERVAL = 300.0  # 5分钟

var time_since_last_save = 0.0

func _process(delta):
    time_since_last_save += delta
    
    if time_since_last_save >= AUTOSAVE_INTERVAL:
        autosave()
        time_since_last_save = 0.0

func autosave():
    if GameManager.save_manager.save_game("autosave"):
        print("[自动保存] 游戏已保存")
        # 显示小提示
        show_autosave_notification()
    else:
        push_warning("[自动保存] 保存失败")
```

---

## 常见问题

### Q: 如何获取玩家的总战斗力？
```gdscript
var total_stats = GameManager.get_total_player_stats()
var combat_power = (
    total_stats.get("physical_damage", 0) +
    total_stats.get("skill_damage", 0) * 10 +
    total_stats.get("max_health", 0) / 10 +
    total_stats.get("defense", 0) * 5
)
print("战斗力：%.0f" % combat_power)
```

### Q: 如何在升级时自动学习技能？
```gdscript
func _on_level_up(new_level: int):
    # 某些等级自动解锁技能
    match new_level:
        5:
            GameManager.skill_tree_system.unlock_skill("basic_attack")
        10:
            GameManager.skill_tree_system.unlock_skill("heavy_strike")
```

### Q: 如何实现物品快速出售？
```gdscript
func sell_all_junk_items():
    var junk_items = ["broken_sword", "rusty_armor", "old_boot"]
    
    for item_id in junk_items:
        var count = GameManager.inventory_system.get_item_count(item_id)
        if count > 0:
            var earned = GameManager.shop_system.sell_item(item_id, count)
            print("出售 %s x%d，获得 %d 金币" % [item_id, count, earned])
```

---

## 总结

本教程涵盖了游戏所有核心系统的使用方法。记住：

1. **所有系统都通过 GameManager 访问**
2. **使用信号监听系统事件**
3. **定期保存游戏进度**
4. **查阅快速参考文档获取更多示例**

更多详细信息，请参阅：
- [系统集成文档](SYSTEMS_INTEGRATION.md)
- [快速参考](QUICK_REFERENCE.md)
- [完成报告](PHASE_1-7_COMPLETION_REPORT.md)
