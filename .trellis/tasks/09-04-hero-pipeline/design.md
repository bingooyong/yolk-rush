# Design — Phase 1 Hero Pipeline

## Files

```
scripts/character/character_definition.gd
scripts/character/character_gameplay.gd
scripts/character/character_visual.gd
scripts/character/placeholder_yolk.gd
scenes/studio/hero_studio.tscn
scenes/studio/hero_studio.gd
tools/validate_character.gd
.agents/skills/create-character/SKILL.md
data/contracts/camera_profiles.json   # hero_lock 四机位
```

## Pose contract

```
enum Pose { IDLE, RUN, JUMP_START, AIRBORNE, FALL, LAND, HIT, FAIL }
```

Studio 用键盘 1–8 切 pose（仅调试）。正式输入在 Phase 2 才接。

## Placeholder metrics

- 身体球半径 ~0.42，中心 y≈0.95
- 胶囊 collision：height 1.48, radius 0.34, offset_y 0.74（与 JSON 一致）
- 围巾 torus 在颈
- 靴两条短胶囊

材质：albedo 蛋黄 `#F2C14E`，围巾 `#C45C26`，靴 `#3D2A1A`。roughness 对齐 JSON。
