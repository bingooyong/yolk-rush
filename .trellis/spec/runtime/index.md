# Runtime Spec

## 何时适用

任何 `scenes/`、`scripts/`、Autoload、Export 改动。

## 本地模式

- 主场景只做路由：`scenes/bootstrap/boot.tscn` + `boot.gd`
- 全局路由 Autoload：`scripts/core/app.gd`（禁止 gameplay）
- 角色玩法：`CharacterBody3D` 读 `data/characters/*.json` 的 `collision_profile`
- 角色视觉：独立 `Node3D` 子节点，读 `visual_model` + AnimationLibrary
- 关卡：JSON DSL → 生成/填充 Scene，Scene 不持有规则

## 证据

- `project.godot` — Mobile renderer, Jolt, 4.7 features
- `export_presets.cfg` — iOS + Dedicated Server
- `docs/architecture/ARCHITECTURE_PRINCIPLES.md`

## 禁止

- C# / .NET Godot
- 在 Visual 节点里改速度、重力、胜负
- 把 `boot.tscn` 做成完整关卡
