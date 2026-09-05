# 🎯 下一步行动计划

## 当前状态：Phase 7 完成 ✅

所有8个核心系统和UI框架已经完成。现在需要在Godot编辑器中完善UI并开始游戏内容制作。

---

## 🚨 立即要做（必须在编辑器中完成）

### 1. 完善UI场景节点树 [优先级: 🔴 最高]

所有UI场景文件(.tscn)已创建，但需要在Godot编辑器中手动构建节点树。

#### HUD场景 (`scenes/ui/hud.tscn`)
```
HUD (Control)
├── TopBar (HBoxContainer)
│   ├── LeftSection (VBoxContainer)
│   │   ├── LevelLabel (Label)
│   │   └── ExpBar (ProgressBar)
│   └── RightSection (HBoxContainer)
│       ├── GoldIcon (TextureRect)
│       └── GoldLabel (Label)
├── QuickBar (HBoxContainer)
│   ├── Slot1 (Button)
│   ├── Slot2 (Button)
│   ├── ... (Slot3-8)
│   └── Slot8 (Button)
└── NotificationLabel (Label)
```

**操作步骤**:
1. 打开 `scenes/ui/hud.tscn`
2. 添加上述节点（右键 → Add Child Node）
3. 设置节点名称要**完全匹配**脚本中的get_node路径
4. 配置布局和锚点
5. 保存场景

#### 背包面板 (`scenes/ui/inventory_panel.tscn`)
```
InventoryPanel (Panel)
├── VBoxContainer
│   ├── Header (HBoxContainer)
│   │   ├── TitleLabel (Label) - "背包"
│   │   └── CloseButton (Button)
│   ├── TabContainer
│   │   ├── AllTab (ScrollContainer)
│   │   │   └── ItemGrid (GridContainer)
│   │   ├── EquipmentTab (ScrollContainer)
│   │   └── ConsumableTab (ScrollContainer)
│   └── Footer (HBoxContainer)
│       ├── SortButton (Button)
│       └── InfoLabel (Label)
```

**关键配置**:
- ItemGrid: columns = 8, 自动大小
- 所有ScrollContainer: 启用垂直滚动
- CloseButton: 连接到 `_on_close_button_pressed()`

#### 装备面板 (`scenes/ui/equipment_panel.tscn`)
```
EquipmentPanel (Panel)
├── VBoxContainer
│   ├── Header (同上)
│   ├── HSplitContainer
│   │   ├── EquipmentSlots (GridContainer)
│   │   │   ├── WeaponSlot (Button)
│   │   │   ├── HelmetSlot (Button)
│   │   │   └── ... (其他槽位)
│   │   └── StatsPanel (VBoxContainer)
│   │       ├── StatsLabel (Label) - "属性总览"
│   │       └── StatsList (VBoxContainer)
│   └── Footer
│       └── EquipmentScoreLabel (Label)
```

**装备槽位顺序**:
1. Weapon, 2. Helmet, 3. Chest, 4. Legs, 5. Boots
6. Gloves, 7. Ring1, 8. Ring2, 9. Amulet

#### 其他面板
- `skill_tree_panel.tscn` - 类似结构，添加技能节点按钮
- `achievement_panel.tscn` - 成就列表 + ScrollContainer
- `shop_panel.tscn` - 商品列表 + 买卖按钮

---

### 2. 测试UI在编辑器中运行 [优先级: 🔴 最高]

完成节点树后：

```bash
# 1. 在Godot中打开
scenes/ui/ui_manager.tscn

# 2. 点击运行场景 (F6)

# 3. 测试输入
- 按 I 打开/关闭背包
- 按 C 打开/关闭装备
- 按 K 打开技能树
- 按 ESC 关闭面板
```

**预期结果**:
- 面板正常打开/关闭
- 控制台输出 "[UIManager] Opening: inventory"
- 没有节点找不到的错误

---

## 🎨 短期目标（1-2周）

### 3. 添加UI样式和主题 [优先级: 🟡 高]

#### 创建主题资源
```
1. Project → Project Settings → GUI → Theme
2. Create New Theme
3. 配置颜色方案：
   - Background: #0F131C (深色背景)
   - Panel: #1E2636 (面板)
   - Accent: #38BDF8 (强调色-蓝色)
   - Text: #FFFFFF (白色文字)
```

#### 字体配置
```
1. 导入字体文件到 res://assets/fonts/
2. 在Theme中配置：
   - Title Font: 24px, Bold
   - Body Font: 16px, Regular
   - Small Font: 12px, Regular
```

#### 样式调整
- 按钮圆角: 8px
- 面板圆角: 12px
- 边距: 16px
- 间距: 8px

---

### 4. 添加图标资源 [优先级: 🟡 高]

#### 需要的图标类型
```
assets/icons/
├── items/           # 物品图标（17个）
│   ├── health_potion_small.png
│   ├── health_potion_medium.png
│   └── ...
├── equipment/       # 装备图标（25个）
│   ├── iron_sword.png
│   ├── steel_helmet.png
│   └── ...
├── skills/          # 技能图标（20个）
│   ├── power_strike.png
│   ├── double_strike.png
│   └── ...
├── ui/              # UI图标
│   ├── gold.png
│   ├── exp.png
│   └── close.png
└── slots/           # 槽位背景
    ├── weapon_slot.png
    ├── armor_slot.png
    └── ...
```

#### 图标规格
- 尺寸: 64x64 像素
- 格式: PNG，透明背景
- 风格: 扁平化，统一配色

#### 临时替代方案
在完成图标之前，可以使用：
1. Godot内置的ColorRect作为占位符
2. 简单的几何形状（圆形、方形）
3. 纯色 + 文字标签

---

### 5. 实现拖放功能 [优先级: 🟡 高]

#### 背包物品拖放
```gdscript
# 在 inventory_panel.gd 中添加
func _on_item_slot_gui_input(event: InputEvent, slot_index: int):
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _start_drag(slot_index)
    
func _start_drag(slot_index: int):
    var item_stack = inventory_system.get_slot(slot_index)
    if item_stack and item_stack.item:
        # 创建拖动预览
        var preview = TextureRect.new()
        preview.texture = item_stack.item.icon
        set_drag_preview(preview)
        
func _can_drop_data(at_position: Vector2, data) -> bool:
    return data is Dictionary and data.has("slot_index")
    
func _drop_data(at_position: Vector2, data):
    var from_slot = data.slot_index
    var to_slot = _get_slot_at_position(at_position)
    inventory_system.swap_slots(from_slot, to_slot)
```

#### 装备拖放
类似实现，但需要验证装备类型匹配槽位。

---

### 6. 添加物品工具提示 [优先级: 🟢 中]

```gdscript
# 在鼠标悬停时显示物品详情
func _on_item_mouse_entered(slot_index: int):
    var item_stack = inventory_system.get_slot(slot_index)
    if item_stack and item_stack.item:
        _show_tooltip(item_stack.item)

func _show_tooltip(item: InventoryItem):
    tooltip_panel.show()
    tooltip_label.text = """
    [b]%s[/b]
    类型: %s
    稀有度: %s
    %s
    """ % [item.item_name, item.item_type, item.rarity, item.description]
```

---

## 🎮 中期目标（2-4周）

### 7. 创建玩家角色场景

```
scenes/player/player.tscn
├── CharacterBody3D (KinematicBody)
│   ├── CollisionShape3D
│   ├── MeshInstance3D (临时立方体)
│   ├── Camera3D
│   ├── AnimationPlayer
│   └── Components
│       ├── HealthComponent
│       ├── MovementComponent
│       └── CombatComponent
```

**脚本**: `scripts/player/player.gd`

#### 基础功能
- [ ] WASD移动
- [ ] 鼠标视角控制
- [ ] 跳跃
- [ ] 生命值系统
- [ ] 与GameManager集成

---

### 8. 实现战斗系统

```gdscript
# scripts/combat/combat_system.gd
class_name CombatSystem

func calculate_damage(attacker_stats: Dictionary, defender_stats: Dictionary) -> int:
    var base_damage = attacker_stats.physical_damage
    var defense = defender_stats.physical_defense
    var crit_chance = attacker_stats.critical_chance
    
    # 暴击判定
    if randf() < crit_chance:
        base_damage *= (1.0 + attacker_stats.critical_damage)
    
    # 防御减伤
    var final_damage = max(1, base_damage - defense)
    return final_damage

func attack(attacker: Node, target: Node):
    var attacker_stats = GameManager.get_total_player_stats()
    var defender_stats = target.get_stats()
    
    var damage = calculate_damage(attacker_stats, defender_stats)
    target.take_damage(damage)
```

---

### 9. 创建敌人AI

```
scenes/enemies/goblin.tscn
├── CharacterBody3D
│   ├── CollisionShape3D
│   ├── MeshInstance3D
│   ├── NavigationAgent3D
│   └── Components
│       ├── HealthComponent
│       ├── AIComponent
│       └── DropComponent
```

**AI行为**:
- [ ] 巡逻
- [ ] 追击玩家
- [ ] 攻击
- [ ] 死亡掉落

---

### 10. 连接掉落系统到战斗

```gdscript
# 在敌人死亡时
func _on_enemy_died():
    var enemy_type = "goblin"
    var enemy_level = level
    
    # 调用GameManager的掉落处理
    GameManager.on_enemy_killed(enemy_type, enemy_level)
    
    # 生成掉落物品实体
    _spawn_loot_entities()
```

---

## 📦 长期目标（1-2月）

### 11. 关卡设计
- [ ] 新手村（教程）
- [ ] 森林关卡
- [ ] 洞穴关卡
- [ ] 城堡关卡
- [ ] Boss房间

### 12. 内容制作
- [ ] 10种敌人模型
- [ ] 3个Boss
- [ ] 50件装备模型
- [ ] 20种技能特效

### 13. 系统完善
- [ ] 音效系统实现
- [ ] 粒子特效
- [ ] 成就系统完整触发
- [ ] 商店NPC对话

### 14. 优化和发布
- [ ] 性能优化
- [ ] 移动端适配
- [ ] 多语言支持
- [ ] 打包发布

---

## 🔧 开发工具推荐

### 图标制作
- **Aseprite** - 像素图标制作
- **Figma** - UI设计
- **Kenney Assets** - 免费游戏资源

### 3D建模
- **Blender** - 免费3D建模
- **MagicaVoxel** - 体素建模（快速原型）

### 音效
- **SFXR** - 8bit音效生成
- **Audacity** - 音频编辑

### 版本控制
```bash
# 初始化Git仓库
git init
git add .
git commit -m "Phase 7 Complete - All core systems + UI framework"

# 添加 .gitignore
echo ".godot/" >> .gitignore
echo ".import/" >> .gitignore
echo "*.import" >> .gitignore
```

---

## 📋 检查清单

### UI完善
- [ ] HUD节点树完成
- [ ] 背包面板节点树完成
- [ ] 装备面板节点树完成
- [ ] 技能树面板节点树完成
- [ ] 成就面板节点树完成
- [ ] 商店面板节点树完成
- [ ] 主题和样式配置
- [ ] 图标资源导入
- [ ] 拖放功能实现
- [ ] 工具提示实现

### 游戏玩法
- [ ] 玩家角色创建
- [ ] 移动和控制
- [ ] 战斗系统
- [ ] 敌人AI
- [ ] 掉落连接

### 内容
- [ ] 3个测试关卡
- [ ] 5种敌人
- [ ] 1个Boss
- [ ] 音效和特效

### 发布准备
- [ ] 性能测试
- [ ] Bug修复
- [ ] 打包测试
- [ ] 文档完善

---

## 🎯 本周目标建议

**Week 1**:
- ✅ Phase 7 完成（已完成）
- 🔲 在Godot编辑器中完善HUD和背包面板节点树
- 🔲 测试UI打开/关闭功能
- 🔲 添加基础主题和颜色

**Week 2**:
- 🔲 完成所有UI面板节点树
- 🔲 实现拖放功能
- 🔲 添加工具提示
- 🔲 开始玩家角色制作

---

## 💡 快速参考

### 测试UI
```bash
# 运行UI测试
godot --path . tests/ui/test_ui_complete.tscn

# 检查脚本错误
godot --headless --path . --check-only
```

### 调试模式
```gdscript
# 在游戏中按 ` 键打开控制台，输入：
GameManager.level_system._debug_set_level(10)
GameManager.level_system._debug_add_exp(1000)
```

### 查看文档
- `README_QUICKSTART.md` - 快速开始
- `docs/UI_SYSTEM.md` - UI系统详解
- `docs/PROJECT_SUMMARY.md` - 项目总结

---

**开始游戏开发吧！** 🚀🎮

核心框架已完成，现在是创造游戏内容的时候了！
