# Yolk Rush - 快速启动指南

## 🚀 运行测试

### 运行所有核心测试
```bash
# 方法1: 使用测试脚本
/tmp/run_all_tests.sh

# 方法2: 手动运行每个测试
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

$GODOT --headless --script scripts/tests/phase_17_save_test.gd
$GODOT --headless --script scripts/tests/phase_19_game_loop_test.gd
$GODOT --headless --script scripts/tests/phase_22_alpha_integration_test.gd
$GODOT --headless --script scripts/tests/phase_23_content_test.gd
$GODOT --headless --script scripts/tests/phase_24_level_config_test.gd
```

### 运行单个测试
```bash
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

# 保存系统测试
$GODOT --headless --script scripts/tests/phase_17_save_test.gd

# 游戏循环测试
$GODOT --headless --script scripts/tests/phase_19_game_loop_test.gd

# Alpha集成测试
$GODOT --headless --script scripts/tests/phase_22_alpha_integration_test.gd

# 内容系统测试
$GODOT --headless --script scripts/tests/phase_23_content_test.gd

# 关卡配置测试
$GODOT --headless --script scripts/tests/phase_24_level_config_test.gd
```

---

## 📁 项目结构概览

```
yolk-rush/
├── scripts/
│   ├── core/          # 核心系统（状态管理、保存系统等）
│   ├── levels/        # 关卡系统（配置、模板、生成器）
│   ├── ui/            # UI系统（菜单、HUD、结算）
│   ├── player/        # 玩家系统
│   ├── enemies/       # 敌人系统
│   └── tests/         # 测试套件
├── scenes/            # Godot场景文件
└── assets/            # 游戏资源
```

---

## 🎮 核心系统说明

### 1. GameStateManager (游戏状态管理器)
- 位置: `scripts/core/game_state_manager.gd`
- 功能: 管理游戏状态流转
- 状态: BOOT → MAIN_MENU → LEVEL_SELECT → LOADING → PLAYING → VICTORY/DEFEAT

### 2. SaveManager (保存管理器)
- 位置: `scripts/core/save_manager.gd`
- 功能: 游戏存档管理
- 特性: 3个存档槽位、自动保存、数据加密

### 3. LevelFlowController (关卡流程控制器)
- 位置: `scripts/core/level_flow_controller.gd`
- 功能: 关卡内流程控制
- 特性: 目标系统、计时器、统计追踪

### 4. LevelTemplates (关卡模板)
- 位置: `scripts/levels/level_templates.gd`
- 功能: 存储10个预定义关卡配置
- 关卡: 草原(1-4) → 森林(5-6) → 火山(7-10)

### 5. GameConfig (游戏配置)
- 位置: `scripts/core/game_config.gd`
- 功能: 全局配置和进度管理
- 特性: 关卡解锁、评级存储

---

## 🔧 开发工作流

### 添加新关卡
1. 在 `LevelTemplates` 中创建新的 `create_level_X()` 函数
2. 配置关卡参数（敌人、障碍物、道具、目标）
3. 添加到 `get_all_levels()` 返回数组
4. 运行测试验证

### 添加新测试
1. 在 `scripts/tests/` 创建新测试文件
2. 继承 `SceneTree`
3. 实现 `_initialize()` 和测试函数
4. 使用 `assert()` 验证结果

### 修改游戏流程
1. 修改 `GameStateManager` 中的状态转换逻辑
2. 更新 `LevelFlowController` 的关卡流程
3. 运行集成测试验证

---

## 📊 测试结果解读

### 成功标志
```
✓ All tests passed! Phase XX is working correctly.
```

### 失败标志
```
✗ Some tests failed. Please check the implementation.
```

### 查看详细错误
```bash
# 运行测试并查看完整输出
$GODOT --headless --script scripts/tests/phase_XX_test.gd 2>&1
```

---

## 🐛 常见问题

### 问题1: 找不到 class_name
**症状**: `Invalid get index 'new' (on base: 'GDScript')`

**原因**: 使用了 `const Script = preload()` 后直接调用 `.new()`

**解决**: 
```gdscript
# 错误方式
const MyScript = preload("res://path.gd")
var obj = MyScript.new()  # 错误！

# 正确方式
var script = load("res://path.gd")
var obj = Node.new()
obj.set_script(script)
```

### 问题2: 测试中找不到节点
**症状**: `Cannot get node: /root/XXX`

**原因**: 测试环境中 autoload 节点不存在

**解决**: 在测试中手动创建节点
```gdscript
var manager = ManagerScript.new()
manager.name = "Manager"
root.add_child(manager)
```

### 问题3: 内存泄漏警告
**症状**: `ObjectDB instances were leaked at exit`

**原因**: 测试结束时未清理节点

**解决**: 不影响测试结果，可忽略或添加清理代码

---

## 📚 代码规范

### 命名约定
- 文件名: `snake_case.gd`
- 类名: `PascalCase`
- 函数名: `snake_case()`
- 变量名: `snake_case`
- 常量名: `UPPER_SNAKE_CASE`
- 信号名: `snake_case`

### 注释规范
```gdscript
## 类文档注释（使用双井号）
class_name ClassName

## 公共函数注释
func public_function() -> void:
    pass

# 私有函数注释（使用单井号）
func _private_function() -> void:
    pass
```

### 类型提示
```gdscript
# 始终使用类型提示
var health: int = 100
var name: String = "Player"
var position: Vector3 = Vector3.ZERO

func get_damage(amount: int) -> void:
    health -= amount
```

---

## 🎯 下一步开发建议

### 立即可做
1. ✅ 完善玩家控制器
2. ✅ 实现基础敌人AI
3. ✅ 添加碰撞检测

### 短期目标
1. 完成战斗系统
2. 创建关卡3D场景
3. 实现技能系统

### 长期目标
1. 添加VFX和音效
2. UI美化
3. 关卡设计和平衡

---

## 📞 获取帮助

### 查看文档
- `PROJECT_STATUS.md` - 项目状态总览
- `test_report.md` - 测试报告
- 各脚本文件内的注释

### 调试技巧
```bash
# 查看详细日志
$GODOT --verbose --headless --script test.gd

# 只看测试结果
$GODOT --headless --script test.gd 2>&1 | grep "✓\|✗"

# 查看特定测试
$GODOT --headless --script test.gd 2>&1 | grep -A 5 "Test 3"
```

---

**祝开发顺利！** 🎮✨
