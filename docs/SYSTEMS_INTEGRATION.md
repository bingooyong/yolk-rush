# 游戏系统整合文档

## 概述
本文档描述了 Yolk Rush 游戏中所有核心系统的整合架构。

## 系统架构

### 核心管理器
**GameManager** (`scripts/core/game_manager.gd`)
- 单例管理器，整合所有游戏系统
- 负责系统初始化、连接和协调
- 处理系统间的信号通信

### 已集成系统列表

#### Phase 1: 角色成长系统
1. **LevelSystem** - 等级系统
   - 经验值管理
   - 升级处理
   - 等级曲线配置
   - 信号：`level_up`, `exp_gained`

2. **StatsSystem** - 属性系统
   - 属性点分配
   - 属性加成计算
   - 支持多种属性类型
   - 信号：`stat_changed`, `stat_points_changed`

#### Phase 2: 装备系统
1. **EquipmentSystem** - 装备管理
   - 9个装备槽位（主手、副手、头盔、胸甲、手套、靴子、2个戒指、项链）
   - 装备属性加成
   - 等级需求检查
   - 信号：`equipment_changed`, `stats_updated`

2. **EquipmentDatabase** - 装备数据库
   - 加载装备配置
   - 按类型、稀有度分类
   - 随机掉落支持

3. **EquipmentItem** - 装备物品类
   - 装备类型和稀有度
   - 属性加成
   - 等级需求

#### Phase 3: 背包系统
1. **InventorySystem** - 背包管理
   - 48个物品槽位
   - 自动堆叠
   - 排序和过滤
   - 信号：`inventory_changed`, `item_added`, `item_removed`

2. **QuickBarSystem** - 快捷栏
   - 8个快捷栏槽位
   - 绑定背包槽位
   - 消耗品使用
   - 信号：`quick_bar_changed`, `item_used`

3. **ItemDatabase** - 物品数据库
   - 物品配置加载
   - 按类型、稀有度分类
   - 随机物品生成

4. **InventoryItem** - 物品类
   - 物品类型（装备、消耗品、材料、任务、货币）
   - 稀有度系统
   - 堆叠限制

#### Phase 4: 技能树系统
1. **SkillTreeSystem** - 技能树管理
   - 技能解锁和升级
   - 前置技能检查
   - 技能点管理
   - 效果加成计算
   - 信号：`skill_unlocked`, `skill_upgraded`, `skill_points_changed`

2. **SkillDatabase** - 技能数据库
   - 多技能树支持
   - 技能依赖关系验证
   - 技能链查询

3. **SkillNode** - 技能节点
   - 技能等级和效果
   - 前置技能列表
   - 技能点消耗

#### Phase 5: 成就系统
1. **AchievementSystem** - 成就管理
   - 成就解锁
   - 进度追踪
   - 奖励发放
   - 信号：`achievement_unlocked`, `progress_updated`

2. **AchievementDatabase** - 成就数据库
   - 成就配置加载
   - 按类型和稀有度分类

3. **Achievement** - 成就类
   - 成就类型（击杀、收集、等级、战斗、探索、社交）
   - 进度目标
   - 奖励系统

#### Phase 6: 经济和掉落系统
1. **ShopSystem** - 商店系统
   - 物品购买和出售
   - 库存管理
   - 等级限制
   - 金币管理
   - 信号：`item_bought`, `item_sold`, `gold_changed`

2. **ShopDatabase** - 商店数据库
   - 商店配置加载
   - 物品分类

3. **DropSystem** - 掉落系统
   - 战利品生成
   - 掉落表支持
   - 稀有度权重
   - 幸运值加成
   - 金币和经验掉落

4. **DropDatabase** - 掉落数据库
   - 掉落表配置
   - 敌人掉落关联

#### Phase 7: 存档系统
1. **SaveManager** - 存档管理
   - 统一存档接口
   - 多系统注册
   - 自动序列化
   - 存档槽位管理

## 系统交互流程

### 敌人击杀流程
```
敌人被击杀
    ↓
GameManager.on_enemy_killed(enemy_type, enemy_level)
    ↓
    ├→ DropSystem: 生成掉落物品 → InventorySystem.add_item()
    ├→ DropSystem: 生成金币 → ShopSystem 增加金币
    ├→ DropSystem: 生成经验值 → LevelSystem.add_exp()
    └→ AchievementSystem: 更新击杀成就进度
```

### 升级流程
```
LevelSystem 获得足够经验
    ↓
LevelSystem.level_up 信号
    ↓
GameManager._on_level_up()
    ↓
    ├→ SkillTreeSystem: 增加技能点
    ├→ ShopSystem: 更新等级限制
    └→ AchievementSystem: 检查等级成就
```

### 装备流程
```
玩家装备物品
    ↓
EquipmentSystem.equip_item()
    ↓
    ├→ 检查等级需求
    ├→ 卸下旧装备 → 返回背包
    ├→ 装备新物品
    └→ 更新角色属性（物理攻击、生命值、技能伤害等）
```

### 技能解锁流程
```
玩家尝试解锁技能
    ↓
SkillTreeSystem.unlock_skill()
    ↓
    ├→ 检查技能点
    ├→ 检查前置技能
    ├→ 检查玩家等级
    └→ 解锁成功 → 应用技能效果
```

## 属性计算

### 玩家总属性
```
总属性 = 基础属性 + 装备属性 + 技能树加成
```

通过 `GameManager.get_total_player_stats()` 获取：
- 物理伤害
- 技能伤害
- 攻击速度
- 暴击率和暴击伤害
- 最大生命值
- 防御力
- 闪避率
- 移动速度

## 数据持久化

### 存档内容
SaveManager 管理以下系统的存档：
- level: 等级和经验
- stats: 属性点分配
- equipment: 已装备物品
- inventory: 背包物品
- quick_bar: 快捷栏绑定
- skill_tree: 已解锁技能
- achievement: 成就进度
- shop: 金币和购买历史

### 存档操作
```gdscript
# 保存游戏
GameManager.save_manager.save_game("slot_1")

# 加载游戏
GameManager.save_manager.load_game("slot_1")

# 删除存档
GameManager.save_manager.delete_save("slot_1")
```

## 使用示例

### 初始化游戏
```gdscript
# 自动完成，GameManager 在场景树中自动初始化
# 监听初始化完成信号
GameManager.game_initialized.connect(_on_game_ready)
```

### 获取玩家信息
```gdscript
var summary = GameManager.get_player_summary()
# 返回：
# {
#   "level": 10,
#   "exp": 500,
#   "gold": 1500,
#   "skill_points": 3,
#   "total_stats": {...},
#   "equipment_score": 250,
#   "achievements_unlocked": 5
# }
```

### 处理战斗奖励
```gdscript
# 敌人被击杀时调用
GameManager.on_enemy_killed("goblin", 5)
# 自动处理：经验值、掉落、金币、成就
```

### 新游戏和继续游戏
```gdscript
# 开始新游戏
GameManager.new_game()

# 继续游戏
GameManager.load_game("slot_1")
```

## 扩展指南

### 添加新系统
1. 创建新系统脚本，继承 Node
2. 在 GameManager 中添加系统引用
3. 在 `_initialize_systems()` 中初始化
4. 如需存档，在 `_register_save_systems()` 中注册
5. 如需与其他系统交互，在 `_connect_systems()` 中连接信号

### 添加新的系统交互
在 GameManager 中添加响应函数，连接相关信号：
```gdscript
func _connect_systems() -> void:
    # 示例：技能升级后更新成就
    skill_tree_system.skill_upgraded.connect(_on_skill_upgraded)

func _on_skill_upgraded(skill_id: String, level: int) -> void:
    achievement_system.check_achievement("master_skills")
```

## 性能考虑

### 优化建议
1. **数据库加载**：所有数据库在游戏启动时一次性加载
2. **物品实例化**：使用 `duplicate()` 创建物品副本，避免共享引用
3. **信号连接**：避免在频繁调用的函数中连接/断开信号
4. **存档频率**：仅在重要节点保存（关卡结束、重要事件）

### 内存管理
- 所有系统作为 GameManager 的子节点，生命周期由场景树管理
- 数据库缓存物品数据，避免重复解析 JSON
- 背包和装备系统使用固定大小的数组，避免动态扩容

## 测试状态

✅ **所有系统集成测试通过**

- Phase 1-6 各系统单独测试通过
- Phase 7 完整集成测试通过
- 所有系统能正确初始化和协同工作
- 信号通信正常
- 存档系统正常工作

## 已知问题和限制

1. **编译依赖**：项目中其他脚本（audio_manager.gd 等）有编译错误，但不影响核心系统
2. **UI 集成**：系统逻辑已完成，UI 层待集成
3. **网络同步**：当前为单机版本，未实现网络功能

## 文档维护

- 创建日期：2025
- 最后更新：Phase 7 集成完成
- 维护者：开发团队
