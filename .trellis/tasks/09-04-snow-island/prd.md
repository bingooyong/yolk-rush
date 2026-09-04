# PRD — Phase 2 Snow Island

## Goal

把 `snow_island_01.json` 变成可玩黄金关：第三人称走、转、跳、冰面、坠落恢复、到达终点。一张图，不再做第二张。

## Depends

Phase 1 验收通过（角色节点存在且 validator 绿）。

## Requirements

- **L1** `scripts/level/level_definition.gd` + `level_builder.gd` 按 segment 生成 StaticBody3D。
- **L2** 空间角色仅限 DSL 六种；未知 role → builder 失败。
- **L3** 冰面降低摩擦；recovery 触发重生到上一个非 recovery 安全点。
- **L4** 输入：WASD + 空格；移动端虚拟摇杆 + JUMP。A = 左转。
- **L5** 追尾相机 `chase`，不与 studio 机位混用。
- **L6** HUD 最小：摇杆、跳、debug 开关（Gameplay Layer）。
- **L7** 到达 `finish_hall` 发 `match_finished` 信号（可只 print）。
- **L8** `.agents/skills/create-level/SKILL.md`。
- **L9** `boot.tscn` 主路径改为岛屿，不再停在 studio（studio 保留可切）。

## Acceptance

- [ ] F5 出生在 start_hall，能看见终点方向的路。
- [ ] W 速度 > 0；A 逆时针转；D 顺时针转；空格离地。
- [ ] 掉下主路进入 recovery，自动救回。
- [ ] 关掉 Visual 只留胶囊仍能跑完（解耦回归）。
- [ ] validator_level 退出 0。
- [ ] 无第二张 JSON 关卡被 builder 引用。

## Out of scope

检查点 UI 美化、对手 AI、道具、计时排行榜、多人。
