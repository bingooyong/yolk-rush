# PRD — Phase 1 Hero Pipeline

## Goal

把 `yolk_hero.json` 变成可运行的角色：玩法胶囊 + 视觉节点 + validator + 占位网格。不进关卡玩法。

## Requirements

- **H1** `scripts/character/character_definition.gd` 加载并校验 JSON。
- **H2** `character_gameplay.gd` extends CharacterBody3D，胶囊来自 `collision_profile`。
- **H3** `character_visual.gd` 只表现 pose，不读 Input。
- **H4** `placeholder_yolk.gd`：蛋黄体 + 围巾 + 靴，比例符合 1.46 m。
- **H5** `tools/validate_character.gd` 覆盖全部必带动画字段。
- **H6** `.agents/skills/create-character/SKILL.md` 存在。
- **H7** 审片场景 `scenes/studio/hero_studio.tscn`：能切 3/4、front、side、back 机位。

## Acceptance

- [ ] validator 对当前 JSON 退出 0；删 `idle` 后退出非 0。
- [ ] F5 打开 studio：占位英雄可见，idle 呼吸，转一圈剪影可辨。
- [ ] 场景树同时存在 Gameplay 与 Visual 两个节点。
- [ ] 无关卡几何、无 HUD 摇杆（那是 Phase 2）。

## Out of scope

雪岛、移动、跳跃、截图批量、GLB 实模（接口预留即可）。

## Depends

无。阻塞 Phase 2。
