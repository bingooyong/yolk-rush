# Design — Phase 2 Snow Island

## Files

```
scripts/level/level_definition.gd
scripts/level/level_builder.gd
scripts/match/match.gd
scripts/match/chase_camera.gd
scripts/input/player_input.gd
scenes/levels/snow_island.tscn      # 空壳，几何由 builder 生成
scenes/match/match.tscn
scenes/ui/touch_hud.tscn
tools/validate_level.gd
.agents/skills/create-level/SKILL.md
```

## Movement

- 前进沿角色 −Z（Godot 前向）。
- yaw 速率约 3.6 rad/s × 速度因子，使低速也能转身。
- 触屏摇杆：x → yaw，y → 油门。不使用摄像机相对 Strafe 作为默认（避免 A/D 语义分裂）。键盘与摇杆同一套 yaw-throttle。

## World build

Builder 从 spawn 起沿关卡轴铺盒子。`width`×`length`，`y` 为顶面高度。
shortcut 的 ramp 用斜盒或台阶近似，不引入 CSG 依赖。
recovery 宽 30 × 长 48 于 y=-3.4，必须接得住主路跌落。

## Lighting

实例化三灯 + ambient，数值只来自 `lighting_profile.json`。
