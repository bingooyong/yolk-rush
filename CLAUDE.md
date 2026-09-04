# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**Yolk Rush** 是一个 AI-native 的 3D 派对障碍竞速游戏，iOS 优先。这不是简单的"克隆 Eggy Party"，而是一个 Godot **游戏工厂**：运行时 + 资产管线 + AI 代理。Yolk Rush 是第一个产品。

## 技术栈（已冻结）

- **引擎**: Godot 4.7.2 stable（不使用 4.8）
- **语言**: 仅 GDScript
- **渲染器**: Mobile
- **资产格式**: glTF 2.0 / GLB
- **多人游戏**: 服务器权威（后期）
- **目标平台**: iPhone / iPad（通过 macOS 上的 Xcode 导出）

## 核心架构原则（不可协商）

1. **Gameplay 与 Visual 完全解耦** — 游戏逻辑与视觉表现分离
2. **Scene 不承担业务规则** — 场景仅用于布局和视觉
3. **数据驱动的游戏规则** — 游戏规则从 JSON 数据加载
4. **角色模型永远不能决定碰撞** — 碰撞由 gameplay 层的胶囊体处理
5. **Level Scene 只表达布局** — 关卡场景不包含游戏逻辑
6. **AI 生成资产必须通过 Asset Contract** — 所有 AI 生成的资产需符合规范
7. **所有新增能力必须有 Skill** — 新功能需要对应的 AI Skill
8. **视觉改动必须经过 Visual Benchmark** — 评分：<70 拒绝，70-84 需改进，≥85 通过
9. **移动端改动必须经过 Performance Benchmark** — 性能必须达标
10. **临时代码不得进入 Runtime** — 架构冲突时：停止、报告、最小修改、等待决策

## 项目结构

```
project.godot           # Godot 项目配置
export_presets.cfg      # iOS 和 Dedicated Server 导出配置
data/
  characters/           # 角色定义 JSON（如 yolk_hero.json）
  levels/               # 关卡定义 JSON（如 snow_island_01.json）
  contracts/            # 资产规范 JSON（如 lighting_profile.json）
docs/architecture/      # 架构文档
scenes/bootstrap/       # 启动场景
scripts/core/           # 核心脚本（如 App autoload）
```

## 数据驱动架构

### 角色定义 (`data/characters/`)
每个角色由 JSON 定义，包含：
- 视觉模型路径（GLB）
- 骨骼类型
- 动画映射（idle, run, jump, airborne, fall, land, roll, dash, pounce, hit, victory, fail）
- 材质定义（body, scarf, boots 等）
- 碰撞配置（高度、半径、偏移）
- Asset Contract（版本、高度、朝向 -Z、原点在脚部）

**角色标准**：
- 格式：GLB / glTF 2.0
- 原点：feet（脚部）
- 朝向：-Z
- 高度：1.40–1.70 m

### 关卡定义 (`data/levels/`)
每个关卡由 JSON 定义，包含：
- 照明配置引用
- 出生点坐标和朝向
- 段落列表（segments），每段定义：角色（start_hall, main_lane, challenge, shortcut, recovery, finish_hall）、尺寸、高度、特殊属性（如 ice）

### 资产规范 (`data/contracts/`)
定义照明、材质等全局配置，确保 AI 生成的资产符合标准。

## Autoload

- **App** (`res://scripts/core/app.gd`) — 路由层，不包含游戏逻辑

## 开发阶段

| 阶段 | 状态 |
|---|---|
| 0 工厂地基 | 已指定 |
| 1 Yolk Hero v1 美术锁定 | 预览版已锁定 |
| 2 Snow Island Golden Scene | 预览版可玩 |
| 3 Visual / Performance QA | 下一步 |
| iOS Xcode 导出 | 仅限 Mac |

## iOS 导出

Godot iOS 导出**需要 macOS + Xcode**。Linux 预览环境无法生成 IPA。准备发布时在 Mac 上安装 Godot 4.7.2。

导出配置位于 `export_presets.cfg`：
- **iOS 预设**: bundle identifier `com.bingooyong.yolkrush`, 最低 iOS 16.0, arm64, 目标设备为 iPad (family=2)
- **Dedicated Server 预设**: Linux x86_64

## 许可与原创性

这是原创作品。**不要从其他游戏复制角色、地图、UI 或音频**。所有资产必须原创或符合授权。

## 工作流程

1. **架构优先** — 遇到架构冲突时：停止、报告、最小修改、等待决策
2. **数据驱动** — 新角色、关卡、规则通过 JSON 数据文件定义
3. **视觉与逻辑分离** — 游戏逻辑在 GDScript 中实现，视觉通过场景和资产表达
4. **AI Skill 覆盖** — 每个新增能力需要对应的 AI Skill 用于验证和生成
5. **Benchmark 强制** — 视觉和性能改动必须通过 Benchmark 才能合并

## 代码风格

- 使用 GDScript 静态类型（`: Type`）
- Autoload 节点仅用于路由和全局状态，不包含游戏逻辑
- Scene 脚本仅处理视觉和输入，游戏规则在独立的逻辑层
- 注释使用 `##` 用于文档注释，`#` 用于行内注释
