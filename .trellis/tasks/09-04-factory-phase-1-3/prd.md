# PRD — Game Factory Phase 1–3

## Goal

在 Godot 4.7.2 上建成可重复生产的 **Game Factory Foundation 的第一份可玩产物**：
锁定 Yolk Hero v1，跑通一张雪岛黄金关，并用视觉/性能门禁拦住不合格资产。

产品价值：之后每张图、每个角色都走同一条流水线，而不是再手搓一个 Demo。

## Background（已确认）

- 引擎冻结：Godot 4.7.2 stable，禁止 4.8。
- 语言冻结：GDScript。C# 不进本阶段。
- 渲染：Mobile Renderer。目标 iPhone / iPad。
- 资产：glTF 2.0 / GLB。角色身高 1.46 m，脚底原点，朝向 −Z。
- 仓库已有：`project.godot`、`yolk_hero.json`、`snow_island_01.json`、`lighting_profile.json`、空 `boot.tscn`。
- 三条原则文件：`docs/architecture/ARCHITECTURE_PRINCIPLES.md`。
- 旧 Three.js 仓库 `bingooyong/yolk` 只作历史参考，禁止复制版权资产。
- iOS 真机导出只在 Mac + Xcode 上发生；本阶段不强制出 IPA。

## User value

玩家（内部试玩）能在雪岛上用第三人称操纵蛋黄英雄：走、转、跳、落水恢复、到达终点。
制作侧能用 JSON + validator 拒绝坏资产，而不是靠肉眼偶然发现。

## Requirements

- **R1** 角色玩法与视觉解耦：`CharacterGameplay`（胶囊）与 `CharacterVisual`（网格/动画）分节点。
- **R2** `yolk_hero.json` 是角色唯一权威；缺动画名或碰撞字段则不能进 Runtime。
- **R3** 未到合规 GLB 前，必须有走同一接口的程序化占位体，禁止临时把胶囊当角色。
- **R4** 雪岛只表达 `snow_island_01.json` 的 11 个 segment；灯光冻结 `game_lighting_v1`。
- **R5** 输入：键盘 WASD + 空格；触屏摇杆 + 跳。A 左转（逆时针），D 右转。
- **R6** 摄像机第三人称追尾，展示镜头与游戏镜头配置分开（`data/contracts/`）。
- **R7** Gameplay Layer（碰撞线框）可开关，默认关。
- **R8** 截图机位：T-pose 3/4、正面、侧面、背面、开场厅、航拍，路径固定。
- **R9** 视觉分：轮廓/比例/材质/灯光/动画，加权总分。<70 reject，70–84 NI，≥85 pass。黄金关未 pass 不得开第二张图。
- **R10** 性能基线文档：目标机 iPhone 12 级，60 fps 为 pass 线（模拟器/文档先立，真机后补）。
- **R11** 每新增能力必须落一个 Skill 文件到 `.agents/skills/`。
- **R12** 架构冲突先停。禁止为赶进度把规则写进 tscn。

## Acceptance Criteria

- [ ] Godot 4.7.2 打开本仓库，F5 进入雪岛，角色可见、可走、可跳。
- [ ] 关掉 Visual 节点后，胶囊仍能完成跑图（证明解耦）。
- [ ] `tools/validate_character.gd` 与 `tools/validate_level.gd` 对当前 JSON 返回 0。
- [ ] 故意删 `idle` 动画字段后 validator ≠ 0。
- [ ] 固定机位截图目录存在且非空。
- [ ] 视觉记分卡填过一轮（即使占位体 <85，也必须有分数和 NI 列表）。
- [ ] iOS Export Preset 仍在且 bundle id = `com.bingooyong.yolkrush`。
- [ ] 仓库无 C# 工程、无商城/抽卡/第二张图。

## Out of scope

- 商城、抽卡、皮肤经济、账号
- 多人联机 / 权威服务器实现（只保留 export preset）
- Bear / Knight 等第二角色量产
- 第二张地图
- 完整 GLB 生产（Blender 成品可后补；本阶段允许占位网格）
- App Store / TestFlight 提交
- C++ 扩展

## Key decisions

| 决策 | 选择 | 不选 |
|---|---|---|
| 引擎 | 4.7.2 stable | 4.8 / Unity / Three.js 当 Runtime |
| 语言 | GDScript | C# |
| 第一角色 | 只锁 Yolk Hero | 多角色并行 |
| 第一关 | 只做 Snow Island | 地图工厂先铺很多 JSON |
| 视觉未达标 | 记 NI，继续打磨同一关 | 开新图掩盖 |
| 预览 vs 真 Runtime | Godot 是 Runtime | Grok 网页只是沟通面 |

## Risks / Deferred

- 本环境不能跑 Godot；实现必须在用户 Mac 的 4.7.2 上验证。
- 占位网格视觉分可能 <85。允许 Phase 1–2 带着 NI 前进，**Phase 3 必须列出缺口，不得假装 pass**。
- iOS 真机性能数字 Phase 3 只建框架，真机采样标为 deferred。
