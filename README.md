# 🥚 Yolk Rush

一个基于 Godot 4.7.2 开发的 3D 动作 RPG 游戏，具有完整的等级、装备、技能、成就等系统。

## ✨ 特性

- 🎮 **完整的 RPG 系统**
  - 等级和经验系统
  - 5 大属性系统（力量、敏捷、体质、智力、幸运）
  - 装备系统（9 个槽位）
  - 背包和快捷栏
  - 技能树系统（3 条技能树）
  - 成就系统
  - 商店系统
  - 掉落系统

- 🎨 **现代化 UI (Phase 19 升级完成)**
  - 统一的深色设计系统
  - 主菜单带动画效果
  - 实时游戏 HUD（生命值、能量、技能、目标）
  - 暂停菜单带统计显示
  - 结算界面带评分系统 (S/A/B/C/F)
  - 流畅的过渡动画和反馈
  - 程序化 UI 生成，无需额外资源
  - 完整的背包、装备、技能树面板
  - 成就和商店面板
  - 响应式设计

- 🎨 **粒子效果系统 (Phase 20 完成)**
  - 12种预制粒子效果（灰尘、火花、爆炸、轨迹等）
  - 高性能池化系统（最多120个粒子复用）
  - 玩家动作反馈（跳跃、着陆、冲刺、受击）
  - 道具拾取特效（空闲发光、拾取闪光）
  - 战斗视觉反馈（攻击、受击、技能、死亡）
  - 关卡环境氛围（灰尘/雪花/雨滴）
  - 完整的集成组件（4个集成类）
  - 自动化事件检测

- 💾 **数据驱动**
  - JSON 配置文件
  - 易于修改和平衡
  - 完整的存档系统

- 🔧 **开发友好**
  - 模块化架构
  - 清晰的代码组织
  - 完善的测试覆盖
  - 详细的文档

## 🚀 快速开始

### 环境要求
- Godot 4.7.2 或更高版本
- macOS / Windows / Linux

### 运行项目
1. 克隆仓库
```bash
git clone https://github.com/yourusername/yolk-rush.git
cd yolk-rush
```

2. 用 Godot 4.7.2 打开项目

3. 运行主场景（开发中）或运行测试：
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --script scripts/tests/complete_integration_test.gd
```

### 运行测试

**完整集成测试**（验证所有系统）：
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --script scripts/tests/complete_integration_test.gd
```

**单独阶段测试**：
```bash
# Phase 1: 等级和属性
godot --headless --script scripts/tests/phase_1_test.gd

# Phase 7: UI 系统
godot --headless --script scripts/tests/phase_7_ui_complete_test.gd
```

## 📚 文档

- [📖 快速开始指南](docs/QUICK_START.md) - 开发者入门
- [📊 项目总结](docs/PROJECT_SUMMARY.md) - 完整的开发总结
- [🎯 Phase 1: 等级和属性系统](docs/PHASE_1_COMPLETE.md)
- [⚔️ Phase 2: 装备系统](docs/PHASE_2_COMPLETE.md)
- [🎒 Phase 3: 背包系统](docs/PHASE_3_COMPLETE.md)
- [🌳 Phase 4: 技能树系统](docs/PHASE_4_COMPLETE.md)
- [🏆 Phase 5: 成就系统](docs/PHASE_5_COMPLETE.md)
- [🛒 Phase 6: 商店和掉落系统](docs/PHASE_6_COMPLETE.md)
- [🎨 Phase 7: UI 系统](docs/PHASE_7_COMPLETE.md)
- [🎵 Phase 16: 音效系统](docs/Phase_16_Audio.md)
- [💾 Phase 17: 保存系统](docs/Phase_17_Save.md)
- [🎮 Phase 19: 游戏循环](docs/Phase_19_Game_Loop.md)
- [✨ Phase 20: 粒子效果系统](docs/Phase_20_VFX.md)
- [🎨 Phase 20: VFX集成系统](docs/Phase_20_VFX_Integration.md)

## 🏗️ 项目结构

```
yolk-rush/
├── data/                    # JSON 数据文件
│   ├── progression/         # 等级曲线
│   ├── equipment/           # 装备数据
│   ├── inventory/           # 物品数据
│   ├── skill_tree/          # 技能数据
│   ├── achievement/         # 成就数据
│   ├── shop/               # 商店数据
│   └── drop/               # 掉落数据
├── scripts/
│   ├── core/               # 核心管理器
│   ├── progression/        # 等级和属性
│   ├── equipment/          # 装备系统
│   ├── inventory/          # 背包系统
│   ├── skill_tree/         # 技能树
│   ├── achievement/        # 成就系统
│   ├── shop/              # 商店系统
│   ├── drop/              # 掉落系统
│   ├── ui/                # UI 系统
│   ├── audio/             # 音效系统 (Phase 16)
│   ├── vfx/               # 粒子效果系统 (Phase 20)
│   ├── player/            # 玩家系统
│   ├── items/             # 道具系统
│   ├── combat/            # 战斗系统
│   ├── level/             # 关卡系统
│   └── tests/             # 测试脚本
├── scenes/                 # 游戏场景
└── docs/                  # 文档
```

## 🎮 系统概览

### GameManager（核心管理器）
所有游戏系统的统一入口点，作为 Autoload 单例：

```gdscript
# 访问等级系统
GameManager.level_system.add_exp(100)

# 访问背包系统
var item = GameManager.item_database.get_item_by_id("health_potion")
GameManager.inventory_system.add_item(item)

# 访问技能树
GameManager.skill_tree_system.unlock_skill("fireball")

# 访问成就
GameManager.achievement_system.unlock_achievement("first_kill")
```

### 数据流架构
```
JSON 数据 → Database → System → GameManager → UI
         ↓                              ↑
    热重载支持                    信号驱动更新
```

## 🧪 测试状态

| Phase | 系统 | 状态 |
|-------|------|------|
| Phase 1 | 等级和属性系统 | ✅ 通过 |
| Phase 2 | 装备系统 | ✅ 通过 |
| Phase 3 | 背包系统 | ✅ 通过 |
| Phase 4 | 技能树系统 | ✅ 通过 |
| Phase 5 | 成就系统 | ✅ 通过 |
| Phase 6 | 商店和掉落系统 | ✅ 通过 |
| Phase 7 | UI 系统 | ✅ 通过 |

**集成测试**: ✅ 所有系统集成成功

## 📊 代码统计

- **脚本总数**: 50+
- **代码总行数**: 8,000+
- **JSON 数据文件**: 10+
- **测试覆盖**: 7 个阶段测试 + 完整集成测试

## 🎯 开发进度

### ✅ 已完成
- [x] Phase 1: 等级和属性系统
- [x] Phase 2: 装备系统
- [x] Phase 3: 背包系统
- [x] Phase 4: 技能树系统
- [x] Phase 5: 成就系统
- [x] Phase 6: 商店和掉落系统
- [x] Phase 7: UI 系统

### 🚧 进行中
- [ ] Phase 8: 场景和关卡设计
- [ ] Phase 9: 战斗系统和敌人 AI
- [ ] Phase 10: 游戏内容制作

### 📋 计划中
- [ ] 音效和音乐
- [ ] 特效和动画
- [ ] 性能优化
- [ ] 平衡性调整

## 💡 使用示例

### 基础操作
```gdscript
# 等待 GameManager 初始化
if GameManager.is_initialized:
    _setup_game()
else:
    GameManager.game_initialized.connect(_setup_game)

func _setup_game():
    # 添加经验
    GameManager.level_system.add_exp(100)
    
    # 分配属性点
    GameManager.stats_system.allocate_stat("str", 5)
    
    # 获取并装备物品
    var sword = GameManager.equipment_database.get_equipment_by_id("iron_sword")
    GameManager.equipment_system.equip_item(sword)
    
    # 添加物品到背包
    var potion = GameManager.item_database.get_item_by_id("health_potion")
    GameManager.inventory_system.add_item(potion, 5)
    
    # 解锁技能
    GameManager.skill_tree_system.unlock_skill("fireball")
    
    # 解锁成就
    GameManager.achievement_system.unlock_achievement("first_blood")
```

### 监听事件
```gdscript
func _ready():
    # 等级提升
    GameManager.level_system.level_up.connect(_on_level_up)
    
    # 装备变化
    GameManager.equipment_system.equipment_changed.connect(_on_equipment_changed)
    
    # 成就解锁
    GameManager.achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_level_up(new_level: int):
    print("升级到等级 ", new_level)

func _on_equipment_changed(slot: String, item):
    print("装备槽 ", slot, " 已更新")

func _on_achievement_unlocked(achievement_id: String):
    print("成就解锁: ", achievement_id)
```

## 🛠️ 开发

### 添加新内容
所有游戏内容都通过 JSON 文件配置，无需修改代码：

**添加新装备**：编辑 `data/equipment/equipment_database.json`  
**添加新物品**：编辑 `data/inventory/item_database.json`  
**添加新技能**：编辑 `data/skill_tree/skill_database.json`  
**添加新成就**：编辑 `data/achievement/achievement_database.json`

详见 [快速开始指南](docs/QUICK_START.md)。

### 调试工具
所有系统都有内置的调试方法：
```gdscript
# 设置等级
GameManager.level_system._debug_set_level(50)

# 装备指定物品
GameManager.equipment_system._debug_equip_by_id("legendary_sword")

# 打印统计信息
GameManager.skill_database._debug_print_stats()
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发规范
- 遵循 GDScript 代码风格
- 为新功能添加测试
- 更新相关文档
- 使用清晰的提交信息

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 👥 团队

- **开发团队**: Yolk Rush Team
- **技术栈**: Godot 4.7.2, GDScript
- **联系方式**: [GitHub Issues](https://github.com/yourusername/yolk-rush/issues)

## 🙏 致谢

感谢 Godot Engine 社区的支持和贡献。

---

**当前版本**: v0.1.0-alpha  
**最后更新**: 2026-09-05  
**状态**: 核心系统 + 视觉反馈系统完成 ✅
