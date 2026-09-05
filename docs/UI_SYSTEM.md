# UI 系统文档

## 概述

UI 系统提供了完整的游戏界面，包括 HUD、背包、装备、技能树、成就和商店面板。

## 系统架构

```
UIManager (CanvasLayer)
├── HUD - 游戏抬头显示
├── InventoryPanel - 背包面板
├── EquipmentPanel - 装备面板
├── SkillTreePanel - 技能树面板
├── AchievementPanel - 成就面板
├── ShopPanel - 商店面板
└── PauseMenu - 暂停菜单
```

## 核心脚本

### UIManager
**路径**: `scripts/ui/ui_manager.gd`

统一管理所有 UI 面板的显示和隐藏。

**主要功能**：
- 打开/关闭 UI 面板
- 处理 UI 输入快捷键
- 连接游戏系统信号
- 管理游戏暂停状态

**使用示例**：
```gdscript
# 打开背包
UIManager.open_ui("inventory")

# 关闭当前 UI
UIManager.close_ui(UIManager.current_open_ui)

# 切换装备面板
UIManager.toggle_ui("equipment")
```

### HUD (抬头显示)
**路径**: `scripts/ui/hud.gd`

显示玩家的基本信息。

**显示内容**：
- 等级和经验条
- 金币数量
- 技能点数量
- 生命值/魔法值
- 快捷栏
- 通知消息
- 升级弹窗

**更新方法**：
```gdscript
hud.update_level()
hud.update_exp_bar(current, required)
hud.update_gold(amount)
hud.update_skill_points(points)
hud.show_level_up(new_level)
hud.show_notification("文本", 2.0)
```

### InventoryPanel (背包面板)
**路径**: `scripts/ui/inventory_panel.gd`

**功能**：
- 显示 48 个背包槽位（8x6 网格）
- 物品信息显示
- 物品使用功能
- 排序功能（按稀有度、类型、名称、数量）
- 背包使用率显示

**快捷键**：`I` 键

**信号**：
```gdscript
signal slot_clicked(slot_index: int)
signal item_used(slot_index: int)
```

### EquipmentPanel (装备面板)
**路径**: `scripts/ui/equipment_panel.gd`

**功能**：
- 显示 9 个装备槽位
  - 主手武器
  - 副手武器
  - 头盔
  - 胸甲
  - 手套
  - 靴子
  - 戒指
  - 项链
- 装备总属性显示
- 装备评分显示
- 装备/卸下功能

**快捷键**：`C` 键

### SkillTreePanel (技能树面板)
**路径**: `scripts/ui/skill_tree_panel.gd`

**功能**：
- 3 个技能树标签页（战斗、生存、工艺）
- 技能节点显示
- 技能信息面板
- 解锁/升级技能
- 技能点显示
- 重置技能功能

**快捷键**：`K` 键

**技能状态颜色**：
- 灰色 - 未解锁且无法解锁
- 绿色 - 已解锁但未满级
- 金色 - 已满级

### AchievementPanel (成就面板)
**路径**: `scripts/ui/achievement_panel.gd`

**功能**：
- 成就列表显示
- 类型过滤（全部、击杀、收集、等级、战斗、探索、社交）
- 进度条显示
- 完成度统计
- 奖励信息显示

**快捷键**：`A` 键

### ShopPanel (商店面板)
**路径**: `scripts/ui/shop_panel.gd`

**功能**：
- 多个商店标签页
- 物品购买
- 价格显示
- 金币余额显示
- 购买限制检查

## 输入映射

在 `project.godot` 中配置的快捷键：

| 功能 | 按键 | 说明 |
|------|------|------|
| `toggle_inventory` | I | 打开/关闭背包 |
| `toggle_equipment` | C | 打开/关闭装备 |
| `toggle_skill_tree` | K | 打开/关闭技能树 |
| `toggle_achievement` | A | 打开/关闭成就 |
| `quick_bar_1~8` | 1-8 | 使用快捷栏物品 |
| `ui_cancel` | ESC | 关闭当前 UI |

## 集成到游戏

### 1. 添加 UIManager 到场景

```gdscript
# 在主场景的 _ready() 中
var ui_manager = preload("res://scripts/ui/ui_manager.gd").new()
add_child(ui_manager)
```

### 2. 创建 UI 场景结构

创建一个 `ui.tscn` 场景：

```
CanvasLayer (UIManager script)
├── HUD (Control, HUD script)
│   ├── TopLeft (MarginContainer)
│   │   ├── LevelLabel
│   │   ├── ExpBar
│   │   └── ExpLabel
│   ├── TopRight (MarginContainer)
│   │   ├── GoldLabel
│   │   └── SkillPointsLabel
│   ├── BottomLeft (MarginContainer)
│   │   ├── HealthBar
│   │   └── HealthLabel
│   ├── Bottom (MarginContainer)
│   │   └── QuickBarContainer (HBoxContainer)
│   └── Center (CenterContainer)
│       ├── NotificationLabel
│       └── LevelUpPopup
│
├── InventoryPanel (Panel, InventoryPanel script)
│   └── VBox
│       ├── TopBar (HBoxContainer)
│       │   ├── UsageLabel
│       │   ├── SortButton
│       │   └── CloseButton
│       ├── ScrollContainer
│       │   └── GridContainer (8 columns)
│       └── ItemInfoPanel
│
├── EquipmentPanel (Panel, EquipmentPanel script)
│   └── VBox
│       ├── TopBar
│       │   ├── ScoreLabel
│       │   └── CloseButton
│       ├── EquipmentContainer (Control)
│       └── StatsPanel
│           └── StatsLabel
│
├── SkillTreePanel (Panel, SkillTreePanel script)
│   ├── VBox
│   │   ├── TopBar
│   │   │   ├── SkillPointsLabel
│   │   │   ├── ResetButton
│   │   │   └── CloseButton
│   │   └── TreeTabs (TabContainer)
│   └── SkillInfoPanel
│
├── AchievementPanel (Panel, AchievementPanel script)
│   └── VBox
│       ├── TopBar
│       │   ├── FilterTabs (TabBar)
│       │   ├── ProgressLabel
│       │   └── CloseButton
│       └── ScrollContainer
│           └── AchievementList (VBoxContainer)
│
└── ShopPanel (Panel, ShopPanel script)
    └── VBox
        ├── TopBar
        │   ├── GoldLabel
        │   └── CloseButton
        └── ShopTabs (TabContainer)
```

### 3. 自动连接到 GameManager

UI 系统会自动连接到 GameManager 的信号：

```gdscript
# 在 UIManager._connect_game_signals() 中自动完成
GameManager.level_system.level_up.connect(_on_level_up)
GameManager.level_system.exp_gained.connect(_on_exp_gained)
GameManager.inventory_system.inventory_changed.connect(_on_inventory_changed)
# ... 等等
```

## 自定义和扩展

### 添加新的 UI 面板

1. 创建新的脚本继承 `Control` 或 `Panel`
2. 在 `UIManager` 中添加引用
3. 在 `open_ui()` 和 `close_ui()` 中添加处理逻辑
4. 添加输入映射（如果需要快捷键）

示例：
```gdscript
# 在 UIManager 中
var quest_panel: Control

func open_ui(ui_name: String) -> void:
	match ui_name:
		# ... 现有的 UI
		"quest":
			if quest_panel:
				quest_panel.visible = true
				current_open_ui = ui_name
				is_any_ui_open = true
```

### 自定义物品显示

在 `InventoryPanel._create_slot_button()` 中：

```gdscript
# 添加物品图标
var icon = TextureRect.new()
icon.texture = item.icon_texture
vbox.add_child(icon)
```

### 添加动画效果

```gdscript
# 在面板打开时添加淡入动画
var tween = create_tween()
tween.tween_property(panel, "modulate:a", 1.0, 0.3).from(0.0)
```

## 性能优化

1. **延迟刷新**：只在必要时刷新 UI
   ```gdscript
   # 避免每帧刷新
   func _on_inventory_changed() -> void:
       if not refresh_pending:
           refresh_pending = true
           call_deferred("refresh")
   ```

2. **对象池**：重用 UI 元素而不是频繁创建/销毁

3. **虚拟滚动**：大列表只渲染可见部分

## 故障排查

### UI 不显示
- 检查 GameManager 是否已初始化
- 检查面板的 `visible` 属性
- 检查 CanvasLayer 的层级

### 输入无响应
- 检查输入映射是否正确配置
- 检查是否有其他节点捕获了输入
- 确保 `get_viewport().set_input_as_handled()` 被正确调用

### 信号未触发
- 检查信号连接是否正确
- 确保 GameManager 已初始化
- 查看控制台是否有错误消息

## 下一步

1. **创建实际的场景文件** (`ui.tscn`)
2. **添加样式和主题**
3. **实现物品拖放功能**
4. **添加 UI 动画和过渡效果**
5. **优化移动端触摸控制**
6. **添加 UI 音效**
