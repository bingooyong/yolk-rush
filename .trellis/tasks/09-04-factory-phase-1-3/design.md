# Design — Game Factory Phase 1–3

## Architecture

```
YOLK RUSH
    │
    ├── GAME RUNTIME          Godot 4.7.2 / GDScript / Mobile
    ├── CONTENT PIPELINE      JSON contracts + GLB + validators
    └── AI FACTORY            Skills + Trellis tasks + screenshot QA
```

Godot 是底座，不是全部架构。Scene 不是业务层。

## Runtime node graph

```
Boot (boot.tscn)
 └── App (autoload, routing only)
      └── Match
           ├── World (static from Level DSL)
           ├── LightingProfile (game_lighting_v1)
           ├── YolkHero
           │    ├── CharacterGameplay : CharacterBody3D
           │    └── CharacterVisual    : Node3D
           ├── ChaseCamera : Camera3D
           └── HUD (touch + debug overlay)
```

### CharacterGameplay

- 只读 `collision_profile` 与移动参数（速度 5.5–7.5，跳跃 9.5，重力 24）。
- 转向：A 增加 yaw（逆时针），D 减少 yaw。禁止摄像机左右反。
- 地面检测 + 冰面摩擦倍率（segment.ice）。
- 掉入 recovery 区后重置到最近安全点（lane 中心）。

### CharacterVisual

- 不读输入，不改速度。
- 订阅 gameplay 的 `pose`：`idle|run|jump_start|airborne|fall|land`。
- 有 GLB 则实例化 `visual_model`；否则实例化 `PlaceholderYolk`（球体身体 + 围巾环 + 靴）。

## Data flow

```
data/characters/yolk_hero.json  ──validate──► CharacterDefinition
data/levels/snow_island_01.json ──validate──► LevelDefinition
data/contracts/lighting_profile.json ──────► WorldEnvironment + 3 lights
```

Level 编译器（`scripts/level/level_builder.gd`）按 segment 数组沿 +Z 或约定轴向铺盒子：
start 20m → lane → 三块冰 → lane → ramp/shortcut → recovery 在下方 → finish。
坐标一旦写进 JSON，禁止在编辑器里拖完不回写。

## Camera / lighting contracts

新增：

- `data/contracts/camera_profiles.json`
  - `chase`：游戏
  - `hero_lock`：角色审片（3/4、front、side、back）
  - `island_overview` / `start_hall`
- 灯光禁止场景里手调 energy；改 JSON 或走 NI。

## Tools

| 工具 | 作用 | 退出码 |
|---|---|---|
| `tools/validate_character.gd` | 合同字段 + 动画全集 | 0/1 |
| `tools/validate_level.gd` | 角色枚举、正宽度、spawn | 0/1 |
| `tools/screenshot_rig.gd` | 固定机位 PNG → `qa/screenshots/` | 0/1 |
| `tools/perf_counters.gd` | FPS / drawcalls 日志 → `qa/perf/` | 0 |

Headless：`godot --headless --script tools/validate_character.gd`

## Skills to add

```
.agents/skills/create-character/SKILL.md
.agents/skills/create-level/SKILL.md
.agents/skills/review-visual/SKILL.md
.agents/skills/optimize-mobile/SKILL.md
.agents/skills/screenshot-qa/SKILL.md
```

没有 Skill 的能力，视为未完成（原则 7）。

## Compatibility

- 不迁移 Three.js 代码。只迁移已冻结的 JSON 语义。
- `export_presets.cfg` 本阶段只读校验，不改 bundle id。
- 占位网格与未来 GLB 必须共用 `CharacterVisual` 接口，避免二次接线。

## Trade-offs

- **占位 vs 等 GLB**：先占位可玩，视觉 NI 明示。等模型会堵住工厂。
- **Jolt vs Godot Physics**：已在 `project.godot` 选 Jolt，本阶段不换。
- **JSON 手写 vs 编辑器插件**：Phase 1–3 手写 + builder；编辑器插件 deferred。

## Rollback

每个子任务一个 git commit。视觉回归立即回退该 commit，不在其上叠新图。
