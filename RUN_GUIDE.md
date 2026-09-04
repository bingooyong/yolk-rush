# Yolk Rush - 运行指南

## 快速开始

### 方式 1: Godot 编辑器（推荐）

**打开编辑器**:
```bash
./tools/open_godot.sh
```

**直接运行雪岛场景**:
```bash
./tools/open_godot.sh scenes/game/snow_island.tscn
```

**直接运行 Hero Studio**:
```bash
./tools/open_godot.sh scenes/studio/hero_studio.tscn
```

在编辑器中，按 **F5** 或点击右上角的播放按钮运行当前场景。

### 方式 2: 命令行 Headless 测试

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/game/snow_island.tscn
```

### 方式 3: iOS 模拟器（需要 Xcode）

⚠️ **注意**: iOS 导出需要配置签名和 provisioning profile。

```bash
./tools/run_ios_simulator.sh
```

这个脚本会：
1. 导出 iOS Xcode 项目
2. 启动 iOS 模拟器
3. 构建并安装应用
4. 自动启动游戏

## 游戏操作

### 键盘控制
- **W/A/S/D** - 移动
- **空格** - 跳跃
- **ESC** - 退出

### 触摸控制（移动设备）
- 项目已配置触摸输入，但当前 Phase 未实现触摸 UI

## 可运行的场景

1. **Snow Island** (`scenes/game/snow_island.tscn`)
   - 完整可玩的雪岛关卡
   - WASD 移动 + 空格跳跃
   - 第三人称相机跟随

2. **Hero Studio** (`scenes/studio/hero_studio.tscn`)
   - 角色展示场景
   - 四机位视角（front/back/left/right）
   - 用于角色视觉验收

3. **QA Test Runner** (`scenes/qa/qa_test_runner.tscn`)
   - 自动化 QA 测试场景
   - 性能监控 + 截图对比
   - 主要用于 CI/CD

## 测试与验证

### 运行 QA 测试
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tools/run_phase3_qa.gd
```

### 验证角色数据
```bash
python3 tools/validate_character.py data/characters/yolk_hero.json
```

### 验证关卡数据
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script tools/validate_level.gd -- data/levels/snow_island_01.json
```

## 性能基准

当前实测性能（Headless 模式）:
- **FPS**: 145.0
- **帧时间**: 0.10ms
- **内存**: 57.5MB
- **Draw Calls**: 0（占位符阶段）

目标性能:
- **Mobile**: FPS ≥ 30, Frame Time ≤ 33.33ms, Memory ≤ 150MB
- **Desktop**: FPS ≥ 60, Frame Time ≤ 16.67ms, Memory ≤ 100MB

## 故障排查

### Godot 找不到
如果 Godot 不在 `/Applications/Godot.app`，编辑脚本修改 `GODOT` 路径。

### 场景加载失败
确保在项目根目录运行脚本：
```bash
cd /Users/bingooyong/Code/01Code/github.com/bingooyong/yolk-rush
./tools/open_godot.sh
```

### iOS 导出失败
iOS 导出需要：
1. Xcode 已安装
2. 在 Godot 编辑器中配置 iOS 签名
3. 选择 Development 或 Ad Hoc provisioning profile

## 下一步

Phase 1-3 已完成，建议：

1. ✅ **本地 GUI 验证** - 在 Godot 编辑器中 F5 运行，确认视觉效果
2. ✅ **建立 Visual Baseline** - 运行 QA 测试，保存首次截图
3. ⏸️ **Phase 4+** - 已规划但本轮禁止开工（商城、抽卡、联机等）

详细信息请参考：
- `TRELLIS_COMPLETION_SUMMARY.md` - 完整任务报告
- `PHASE_1_3_REPORT.md` - 技术实现细节
- `CLAUDE.md` - 项目架构说明
