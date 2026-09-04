# Phase 6: UI/音效/相机系统 - 实施计划

**版本**: 1.0  
**状态**: Ready to Start  
**开始日期**: 2026-09-05  
**预计完成**: 2026-09-19

---

## 📅 时间线

### Week 1: 核心系统（9月5日-9月11日）

#### Day 1-2: UI场景制作
**目标**: 创建HUD和菜单场景文件

**任务**:
- [x] game_hud.gd 脚本（已完成）
- [ ] game_hud.tscn 场景
  - ProgressBar (血条)
  - ProgressBar (护盾条)
  - Label (血量文字)
  - 4个 TextureRect (技能UI)
  - Label (Combo计数器)
- [ ] main_menu.tscn
  - VBoxContainer (按钮容器)
  - Button x3 (开始/设置/退出)
- [ ] pause_menu.tscn
  - VBoxContainer
  - Button x3 (继续/重新开始/返回)

**验收**:
- 场景可以在编辑器中打开
- 节点层级正确
- 脚本正确附加

---

#### Day 3-4: 音频资源集成
**目标**: 收集和集成音效音乐资源

**任务**:
- [ ] 收集免费音效
  - Freesound.org
  - OpenGameArt.org
  - 需要的音效类型（见列表）
- [ ] 转换格式（OGG Vorbis）
- [ ] 导入到项目
  - `audio/sfx/combat/`
  - `audio/sfx/movement/`
  - `audio/sfx/ui/`
  - `audio/music/`
- [ ] 更新 AudioManager 资源路径
- [ ] 测试音效播放

**音效清单**:
```
必需音效 (P0):
- attack_light.ogg
- attack_heavy.ogg
- hit_received.ogg
- skill_cast.ogg
- death.ogg

推荐音效 (P1):
- footstep.ogg
- jump.ogg
- land.ogg
- ui_click.ogg
- ui_hover.ogg

音乐 (P1):
- menu.ogg
- battle.ogg
- victory.ogg
- defeat.ogg
```

**验收**:
- 音效文件导入无错误
- 音效可以通过代码播放
- 音量合适，无爆音

---

#### Day 5: 相机场景集成
**目标**: 将CameraController集成到游戏场景

**任务**:
- [x] camera_controller.gd 脚本（已完成）
- [ ] 创建相机场景 camera_rig.tscn
  - Node3D (CameraController)
  - SpringArm3D
  - Camera3D
- [ ] 集成到 Snow Island 场景
- [ ] 设置跟随目标（玩家）
- [ ] 测试跟随、震动效果

**验收**:
- 相机平滑跟随玩家
- 不穿墙（SpringArm碰撞）
- 震动效果可见

---

### Week 2: 完善和测试（9月12日-9月19日）

#### Day 6-7: 系统集成
**目标**: 连接所有系统

**任务**:
- [x] game_manager.gd 脚本（已完成）
- [ ] 将 GameManager 添加为 Autoload
- [ ] 连接战斗系统回调
  - CharacterCombat → GameManager
  - EnemyAI → GameManager
- [ ] 测试完整战斗循环
  - 攻击 → 音效 + 震动 + Combo
  - 受击 → 音效 + 震动 + 血条
  - 技能 → 音效 + 震动 + 冷却UI

**验收**:
- 所有回调正常触发
- UI/Audio/Camera同步响应
- 无明显延迟或卡顿

---

#### Day 8: 菜单功能
**目标**: 实现菜单交互

**任务**:
- [ ] 主菜单脚本
  - "开始游戏" → 加载关卡
  - "设置" → 打开设置菜单
  - "退出" → 退出游戏
- [ ] 暂停菜单脚本
  - ESC键触发
  - "继续" → 恢复游戏
  - "重新开始" → 重新加载关卡
  - "返回主菜单" → 回到主菜单
- [ ] 设置菜单脚本
  - 音效音量滑块
  - 音乐音量滑块
  - 画质选项（可选）

**验收**:
- 按钮点击正常
- 场景切换流畅
- 设置可以保存

---

#### Day 9: 打磨和优化
**目标**: 细节完善

**任务**:
- [ ] UI动画调整
  - 血条过渡时间
  - Combo放大效果
  - 飘字速度
- [ ] 音效音量平衡
  - 调整各音效相对音量
  - 避免刺耳或过小
- [ ] 相机参数调整
  - 跟随速度
  - 震动强度
  - 距离范围
- [ ] 性能测试
  - 检查帧率
  - 检查内存占用

**验收**:
- 手感舒适
- 视听平衡
- 性能稳定

---

#### Day 10: 测试和文档
**目标**: 全面测试和总结

**任务**:
- [ ] 完整测试清单
  - UI显示测试
  - 音效播放测试
  - 相机跟随测试
  - 菜单交互测试
  - 完整战斗循环
- [ ] 录制演示视频
  - 主菜单 → 开始游戏
  - 完整战斗（展示UI/音效/相机）
  - 胜利/失败画面
- [ ] 更新文档
  - task.json 状态更新
  - IMPLEMENTATION.md 完成记录
  - 已知问题列表

**验收**:
- 所有测试通过
- 演示视频质量合格
- 文档更新完整

---

## 🛠️ 技术实施细节

### 1. HUD场景结构

```
game_hud.tscn (CanvasLayer)
├── MarginContainer
│   └── VBoxContainer
│       ├── TopBar (HBoxContainer)
│       │   ├── HealthBar (VBoxContainer)
│       │   │   ├── ProgressBar (Health)
│       │   │   ├── ProgressBar (Shield)
│       │   │   └── Label (HealthText)
│       │   └── ComboLabel (Label)
│       │
│       └── BottomBar (HBoxContainer)
│           ├── Spacer (Control)
│           ├── SkillBar (HBoxContainer)
│           │   ├── SkillQ (TextureRect)
│           │   ├── SkillE (TextureRect)
│           │   ├── SkillR (TextureRect)
│           │   └── SkillF (TextureRect)
│           └── Spacer (Control)
```

### 2. 相机场景结构

```
camera_rig.tscn (Node3D)
└── SpringArm3D
    └── Camera3D

Script: camera_controller.gd 附加到根节点
```

### 3. 音频总线设置

```
AudioBus 配置:
Master
├── SFX (音效总线)
└── Music (音乐总线)

在 Project Settings → Audio → Buses 中配置
```

### 4. Autoload配置

```
Project Settings → Autoload:
- AudioManager: scripts/audio/audio_manager.gd
- GameManager: scripts/core/game_manager.gd
```

---

## 🎯 里程碑检查点

### Checkpoint 1 (Day 5)
- [ ] UI场景创建完成
- [ ] 音频资源导入完成
- [ ] 相机集成完成
- **标准**: 可以看到HUD，听到音效，相机跟随

### Checkpoint 2 (Day 7)
- [ ] 系统全部集成
- [ ] 战斗循环正常
- **标准**: 完整战斗有UI/音效/相机反馈

### Checkpoint 3 (Day 10)
- [ ] 所有测试通过
- [ ] 演示视频录制
- **标准**: 可发布的演示版本

---

## ⚠️ 风险和应对

### 风险1: 音频资源质量不佳
**应对**: 
- 多收集几个候选
- 优先使用付费音效包样本
- 后期可替换

### 风险2: UI在移动端显示问题
**应对**:
- 使用Anchor和Container
- 测试不同分辨率
- 字体大小响应式

### 风险3: 相机穿墙
**应对**:
- SpringArm3D自动处理
- 调整collision_mask
- 增加margin

### 风险4: 性能问题
**应对**:
- 音效池已实现
- UI只更新变化部分
- 相机优化震动算法

---

## 📋 检查清单

### 开始前检查
- [x] Phase 4.5 已完成
- [x] 核心脚本已实现
- [x] 测试框架就绪
- [ ] Godot 4.7.2 可用

### 实施中检查（每日）
- [ ] 代码提交到Git
- [ ] 测试通过
- [ ] 文档更新

### 完成后检查
- [ ] 所有P0任务完成
- [ ] 演示视频录制
- [ ] task.json状态更新为completed
- [ ] Git commit with summary

---

## 🚀 启动命令

```bash
# 1. 确认Godot可用
godot --version  # 应显示 4.7.2.stable

# 2. 运行测试
python3 tools/test_phase_6_systems.py

# 3. 打开Godot编辑器
godot project.godot

# 4. 开始实施！
```

---

**准备开始 Phase 6 实施？** 🎬

**下一步**: 创建 game_hud.tscn 场景文件
