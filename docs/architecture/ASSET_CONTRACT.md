# Asset Contract — Character

角色资产进入 **Runtime** 前必须通过本契约（原则 6）。契约以 Data 为准，mesh 不得反向定义碰撞或朝向。

机器可读 schema：[`data/contracts/character_asset_contract.json`](../../data/contracts/character_asset_contract.json)  
参考实例：`data/characters/yolk_hero.json`  
原则索引：[ARCHITECTURE_PRINCIPLES.md](./ARCHITECTURE_PRINCIPLES.md)

光照是 **另一契约族**：`data/contracts/lighting_profile.json`（如 `game_lighting_v1`），不并入本 Character Contract。

---

## Character 标准（硬约束）

| 项 | 要求 | 字段 / 说明 |
|----|------|-------------|
| 格式 | glTF 2.0 / **GLB** | `visual_model` 指向合法资源 |
| Origin | **feet**（脚底原点） | `contract.origin == "feet"` |
| Facing | **−Z** | `contract.facing == "-Z"` |
| 身高 | **1.40–1.70 m** | `contract.height_m`（例：yolk_hero `1.46`） |
| Skeleton | 声明式 id | 例：`skeleton: "humanoid_v1"` |
| Materials | 槽位表，非散落硬编码 | `materials` slots |
| Animations | 分字段 `*_animation`（或可选 `animations` 表） | 至少 idle + run |
| Collision | **独立于 mesh** | `collision_profile`：`height` / `radius` / `offset_y`（例：1.48 / 0.34 / 0.74） |

`collision_profile` 是 Gameplay 权威源；Presentation mesh **不得**携带或覆盖 Runtime 碰撞（原则 4）。

---

## 校验清单（进 Runtime 前）

- [ ] 文件为 glTF 2.0 / GLB，路径与 `visual_model` 一致且可加载
- [ ] Origin = feet（脚底在世界原点附近，无「悬空原点」）
- [ ] Facing = −Z（前向与引擎约定一致）
- [ ] `contract.height_m` ∈ **[1.40, 1.70]**
- [ ] `collision_profile` 存在且完整（`height`, `radius`, `offset_y`）；数值合理、与视觉身高大致匹配但 **不由 mesh 自动生成**
- [ ] `materials` slots 已声明；无未映射的必需槽
- [ ] `skeleton` / `animations` 与工厂约定一致（如 `humanoid_v1`）
- [ ] `contract.version` 已填写，且通过 `character_asset_contract.json` 校验
- [ ] **未**将 mesh 自带 collision 导入为 Runtime 碰撞

全部通过 → 允许进入 Runtime / Domain 加载路径。  
任一失败 → **拒绝合入 Runtime**；退回资产侧修复（可配合 Skill `validate-asset-contract`，见 [SKILL_CONVENTION.md](./SKILL_CONVENTION.md)）。

---

## yolk_hero.json 字段映射（契约锚点）

以下为现有 Data 形状摘要（以仓库 JSON 为准）：

```text
visual_model          → res://…/*.glb
skeleton              → "humanoid_v1"
*_animation           → idle/run/jump/… 分字段（也可用可选的 animations 表）
materials             → [{ slot, library, roughness, metallic }, …]
collision_profile     → { height: 1.48, radius: 0.34, offset_y: 0.74 }
contract              → { version: "1.0.0", height_m: 1.46, facing: "-Z", origin: "feet" }
```

校验器应以 `contract.*` + `collision_profile.*` + `visual_model` + `materials` 为必检；动画至少具备 `idle_animation`/`run_animation`（或 `animations`）。材料/动画缺失策略由 Skill 成功标准写明。

---

## 与 Lighting Profile 的边界

| 契约族 | 路径 | 用途 |
|--------|------|------|
| Character Asset Contract | `data/contracts/character_asset_contract.json` | 角色 mesh / 朝向 / 身高 / 碰撞分离 |
| Lighting Profile | `data/contracts/lighting_profile.json` | 关卡光照（如 `game_lighting_v1`） |

Visual Benchmark 会检查角色在 `game_lighting_v1` 下的观感，但 **光照合规不替代** Character Asset Contract。

---

## Phase 说明

- Phase 1：Yolk Hero v1 art 已在 preview 锁定 → 合入 Runtime 前仍须本契约 pass。
- Phase 3：Asset Contract pass 是 Visual / Perf QA 入口条件之一（见 [BENCHMARKS.md](./BENCHMARKS.md)）。
