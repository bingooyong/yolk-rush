# Phase 4: Animation System

**Status**: 📋 Planning  
**Priority**: P1  
**Dependencies**: Phase 1-3 完成 ✅  
**Estimated Effort**: 3-4 weeks  
**Target Date**: TBD

---

## 概述

在 GLB 模型加载基础上，实现完整的角色动画系统，包括状态机、动画混合、IK 系统。

## 前置条件

- ✅ Phase 1-3 已完成
- ✅ GLB 加载系统就绪
- ✅ CharacterVisual 已支持骨架识别
- ⚠️ 需要美术提供动画资源（Idle, Walk, Run, Jump, Land）

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Hero 添加流畅的角色动画，支持：
1. 基础移动动画（Idle, Walk, Run）
2. 跳跃动画（Jump, Fall, Land）
3. 动画状态机
4. 混合树（Walk → Run 平滑过渡）
5. 根运动（Root Motion）支持

### 用户故事

**作为玩家**：
- 我希望角色移动时有相应的走路/跑步动画
- 我希望跳跃时看到起跳和落地动画
- 我希望动画过渡自然流畅

**作为开发者**：
- 我希望通过 JSON 配置动画参数
- 我希望动画系统与 Gameplay 解耦
- 我希望能轻松添加新动画状态

### 非目标（本 Phase 不做）

- ❌ 战斗动画
- ❌ 技能特效
- ❌ 表情系统
- ❌ 布料模拟
- ❌ IK 手部对齐（放到 Phase 5）

---

## Design (设计方案)

### 架构设计

```
CharacterGameplay (物理层)
    ↓ 信号：velocity, is_grounded, is_jumping
CharacterAnimation (动画层)
    ├── AnimationStateMachine
    ├── AnimationTree
    └── AnimationBlender
    ↓
CharacterVisual (视觉层 - GLB Model)
    └── Skeleton3D + AnimationPlayer
```

### 核心组件

#### 1. CharacterAnimation.gd

**职责**：
- 监听 Gameplay 层信号
- 驱动 AnimationTree
- 管理状态机转换

**接口**：
```gdscript
class_name CharacterAnimation extends Node

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)

func setup(gameplay: CharacterGameplay, visual: CharacterVisual) -> void
func update_movement_speed(speed: float) -> void
func trigger_jump() -> void
func trigger_land() -> void
```

#### 2. 动画状态机

**状态列表**：
- `idle` - 静止
- `walk` - 慢速移动（< 3 m/s）
- `run` - 快速移动（≥ 3 m/s）
- `jump` - 跳跃上升
- `fall` - 空中下落
- `land` - 落地缓冲

**转换规则**：
```
idle → walk: speed > 0.1
walk → run: speed > 3.0
run → walk: speed < 2.5 (滞后避免抖动)
any → jump: is_jumping && is_grounded
jump → fall: velocity.y < 0
fall → land: is_grounded
land → idle: animation_finished
```

#### 3. 混合树

使用 AnimationTree + Blend2D：
- X 轴：移动速度（0.0 → 6.0 m/s）
- Y 轴：未来扩展（转向角度）

### 数据驱动配置

**data/contracts/animation_config.json**：

```json
{
  "$schema": "../schemas/animation_config_schema.json",
  "state_machine": {
    "default_state": "idle",
    "states": [
      {
        "name": "idle",
        "animation": "Idle",
        "loop": true,
        "transitions": [
          {"to": "walk", "condition": "speed > 0.1"}
        ]
      },
      {
        "name": "walk",
        "animation": "Walk",
        "loop": true,
        "speed_scale_curve": "linear",
        "transitions": [
          {"to": "idle", "condition": "speed < 0.1"},
          {"to": "run", "condition": "speed > 3.0"}
        ]
      },
      {
        "name": "run",
        "animation": "Run",
        "loop": true,
        "speed_scale_curve": "linear",
        "transitions": [
          {"to": "walk", "condition": "speed < 2.5"}
        ]
      },
      {
        "name": "jump",
        "animation": "Jump",
        "loop": false,
        "transitions": [
          {"to": "fall", "condition": "velocity_y < 0"}
        ]
      },
      {
        "name": "fall",
        "animation": "Fall",
        "loop": true,
        "transitions": [
          {"to": "land", "condition": "is_grounded"}
        ]
      },
      {
        "name": "land",
        "animation": "Land",
        "loop": false,
        "transitions": [
          {"to": "idle", "condition": "animation_finished"}
        ]
      }
    ]
  },
  "blend_tree": {
    "locomotion": {
      "type": "Blend2D",
      "points": [
        {"position": [0.0, 0.0], "animation": "Idle"},
        {"position": [2.0, 0.0], "animation": "Walk"},
        {"position": [6.0, 0.0], "animation": "Run"}
      ]
    }
  },
  "parameters": {
    "walk_speed_threshold": 0.1,
    "run_speed_threshold": 3.0,
    "transition_duration": 0.15,
    "root_motion_enabled": false
  }
}
```

### 美术资源要求

**动画列表**（从 Mixamo 或自制）：

1. **Idle.glb** - 待机动画
   - 时长：2-3秒循环
   - 微微晃动，自然呼吸

2. **Walk.glb** - 走路动画
   - 时长：1秒循环（约2步）
   - 速度：2 m/s

3. **Run.glb** - 跑步动画
   - 时长：0.6秒循环
   - 速度：5-6 m/s

4. **Jump.glb** - 起跳动画
   - 时长：0.3秒（不循环）
   - 双脚蹬地 → 双臂上扬

5. **Fall.glb** - 空中下落
   - 时长：0.5秒循环
   - 双臂展开，身体微微前倾

6. **Land.glb** - 落地缓冲
   - 时长：0.25秒（不循环）
   - 膝盖弯曲 → 站直

**导出规范**（同 Phase 1 GLB 规范）：
- Feet at origin (0, 0, 0)
- Facing -Z axis
- Height: 1.4-1.7m
- 30 FPS
- Baked animations

---

## Implementation Plan

### Task 1: Animation Infrastructure (2 days)

**文件**：
- `scripts/animation/character_animation.gd`
- `data/contracts/animation_config.json`
- `data/schemas/animation_config_schema.json`

**实现**：
1. 创建 CharacterAnimation 节点类
2. 定义动画配置 JSON Schema
3. 实现 JSON 加载器
4. 添加到 Character 场景树

**验证**：
- [ ] CharacterAnimation 成功加载配置
- [ ] Schema 验证通过

### Task 2: State Machine Core (3 days)

**实现**：
1. 实现状态机基类（State/Transition）
2. 从 JSON 动态构建状态机
3. 监听 CharacterGameplay 信号
4. 实现状态转换逻辑

**测试**：
```gdscript
# 测试用例
func test_idle_to_walk():
    animation.update_movement_speed(0.5)
    await get_tree().create_timer(0.2).timeout
    assert(animation.current_state == "walk")
```

**验证**：
- [ ] Idle → Walk 转换成功
- [ ] Walk → Run 转换成功
- [ ] 边界值测试通过（滞后避免抖动）

### Task 3: AnimationTree Integration (3 days)

**实现**：
1. 在 CharacterVisual 中创建 AnimationTree 节点
2. 配置 Blend2D 混合树
3. 连接状态机到 AnimationTree
4. 实现速度参数映射

**验证**：
- [ ] Walk → Run 平滑过渡（无突变）
- [ ] 速度变化与动画速率同步

### Task 4: Jump/Fall/Land States (2 days)

**实现**：
1. 添加 Jump 状态（触发式）
2. 添加 Fall 状态（自动转换）
3. 添加 Land 状态（One-shot）
4. 实现空中状态检测

**验证**：
- [ ] 跳跃触发 Jump 动画
- [ ] 空中自动转 Fall
- [ ] 落地播放 Land 后回 Idle

### Task 5: Animation Events (2 days)

**实现**：
1. 在动画中添加事件标记（Godot Track）
2. 监听动画事件信号
3. 触发音效/特效占位

**示例**：
- Walk 动画：每步触发 `footstep` 事件
- Land 动画：触发 `land_impact` 事件

**验证**：
- [ ] 事件在正确帧触发
- [ ] 事件携带正确参数

### Task 6: Root Motion (可选, 2 days)

**实现**：
1. 启用 AnimationTree Root Motion
2. 将动画位移应用到 CharacterBody3D
3. 平衡 Gameplay 物理与动画驱动

**验证**：
- [ ] 角色移动与脚步同步（无滑步）
- [ ] 物理碰撞仍正确工作

### Task 7: Tools & Validation (2 days)

**工具**：
- `tools/validate_animation_config.py` - 配置验证器
- `tools/preview_animation.gd` - 动画预览工具
- `.agents/skills/add-character-animation.md` - AI Skill

**验证**：
- [ ] 工具正确检测配置错误
- [ ] 预览工具可独立运行

### Task 8: Testing & Polish (3 days)

**测试场景**：
- `scenes/studio/animation_test.tscn` - 动画测试场景
  * UI 显示当前状态
  * 滑块控制移动速度
  * 按钮触发跳跃

**性能测试**：
- AnimationTree 开销
- 骨骼动画 CPU 占用
- 多角色同屏性能

**验证**：
- [ ] 所有状态转换流畅
- [ ] 无卡顿或抖动
- [ ] 性能满足基准（≥60 FPS）

---

## Acceptance Criteria

### 功能验收

- [ ] 6 个动画状态全部实现（Idle/Walk/Run/Jump/Fall/Land）
- [ ] 状态机转换正确且流畅
- [ ] Walk ↔ Run 平滑混合（无突变）
- [ ] 跳跃/落地动画触发正确
- [ ] 动画速度随移动速度调整
- [ ] 配置完全数据驱动（JSON）

### 技术验收

- [ ] 动画系统与 Gameplay 层解耦
- [ ] 所有配置通过 Schema 验证
- [ ] 单元测试覆盖核心逻辑
- [ ] 工具链完备（验证、预览、AI Skill）
- [ ] 文档完整（架构、API、配置指南）

### 性能验收

- [ ] 单角色动画开销 < 1ms
- [ ] 内存增加 < 20MB
- [ ] Snow Island 场景仍 ≥60 FPS

### 用户体验验收

- [ ] 移动感觉自然流畅
- [ ] 跳跃/落地有打击感
- [ ] 无明显滑步或抖动
- [ ] 动画与音效同步（事件系统）

---

## Risks & Mitigations

### Risk 1: 美术资源缺失

**影响**: 高（阻塞开发）  
**缓解**:
- 使用 Mixamo 免费动画作为占位符
- 提前定义动画规范文档
- 使用程序化动画作为 fallback

### Risk 2: Root Motion 与物理冲突

**影响**: 中（影响手感）  
**缓解**:
- Root Motion 设为可选配置
- 提供混合模式（物理主导 vs 动画主导）
- 充分测试边缘情况

### Risk 3: 性能开销

**影响**: 中（影响 Mobile 平台）  
**缓解**:
- 使用 LOD 系统（远距离简化骨骼）
- 优化 AnimationTree 复杂度
- 提供降级选项（禁用混合）

### Risk 4: 状态机复杂度

**影响**: 低（维护困难）  
**缓解**:
- 保持状态少而精（< 10 个）
- 可视化工具（Godot AnimationTree UI）
- 完整的文档和注释

---

## Out of Scope (Phase 5+)

以下功能**不在本 Phase 实现**：

- ❌ IK 系统（手部对齐、脚部贴地）
- ❌ 表情/口型同步
- ❌ 战斗动画
- ❌ 技能特效
- ❌ 动态换装（骨骼附加物）
- ❌ 布料/头发物理模拟

---

## Dependencies

### 上游依赖

- ✅ Phase 1: GLB 加载系统
- ✅ CharacterGameplay: velocity, is_grounded 信号
- ✅ CharacterVisual: Skeleton3D 支持

### 下游影响

- Phase 5 IK 系统将依赖本 Phase
- Phase 6 战斗系统将扩展状态机
- 音效系统将监听动画事件

---

## Estimated Timeline

```
Week 1: Infrastructure + State Machine
  Day 1-2: Animation Infrastructure
  Day 3-5: State Machine Core

Week 2: Integration + Jump States
  Day 1-3: AnimationTree Integration
  Day 4-5: Jump/Fall/Land States

Week 3: Events + Root Motion + Testing
  Day 1-2: Animation Events
  Day 3-4: Root Motion (可选)
  Day 5: Buffer

Week 4: Tools + Polish
  Day 1-2: Tools & Validation
  Day 3-5: Testing & Polish
```

**Total**: 3-4 weeks (含 Buffer)

---

## Success Metrics

### 开发效率

- JSON 配置新动画 < 10 分钟
- 添加新状态 < 30 分钟
- 调试动画过渡 < 5 分钟（可视化工具）

### 运行时性能

- 动画系统 CPU < 1ms/frame
- 内存占用 < 20MB
- 多角色支持 ≥ 10 个同屏

### 用户满意度

- 内测反馈："移动流畅自然"
- 无滑步/抖动投诉
- 动画评分 ≥ 4/5

---

## References

### Godot 文档

- [AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)
- [Root Motion](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html#root-motion)
- [Animation State Machine](https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachinetransition.html)

### 外部资源

- [Mixamo](https://www.mixamo.com/) - 免费角色动画
- [Blender NLA Editor](https://docs.blender.org/manual/en/latest/editors/nla/index.html) - 动画编辑

### 项目文档

- `docs/GLB_INTEGRATION.md` - GLB 导入指南
- `docs/architecture/CORE_ARCHITECTURE.md` - 架构设计
- `PHASE_1_3_REPORT.md` - Phase 1-3 实现细节

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 等待 Phase 4 启动批准
