# Skills Index — Yolk Rush

本目录为 agent / factory **Skill** 索引。约定见 [../architecture/SKILL_CONVENTION.md](../architecture/SKILL_CONVENTION.md)。

当前仅登记 **Phase 3 planned** 条目；**无已实现 recipe**。状态一律 `planned`。

---

## Planned (Phase 3)

| id | status | 一句话 | 成功标准（摘要） |
|----|--------|--------|------------------|
| `validate-asset-contract` | planned | 用 Character Asset Contract 校验角色 JSON + 资源 | schema + 清单全过；方可进 Runtime |
| `run-visual-benchmark` | planned | 在 Snow Island golden 上打 Visual 分 | 总分 ≥ 85 pass；&lt;70 reject；70–84 NI |
| `run-performance-benchmark` | planned | Mobile/iOS 性能采样并对 DRAFT 预算填 checklist | checklist 归档；预算数字标 DRAFT |

### validate-asset-contract
- **inputs**: `data/characters/*.json`、`data/contracts/character_asset_contract.json`
- **outputs**: pass/fail + 失败字段列表
- **recipe**: `docs/skills/validate-asset-contract/`（未创建）
- **depends_on**: —

### run-visual-benchmark
- **inputs**: Snow Island golden scene、`game_lighting_v1`、受试角色 visual
- **outputs**: 维度分、总分、截图笔记
- **recipe**: `docs/skills/run-visual-benchmark/`（未创建）
- **depends_on**: `validate-asset-contract`（建议先过契约）

### run-performance-benchmark
- **inputs**: Mobile renderer 构建；代表关卡；设备或 profiler
- **outputs**: fps / hitch / memory 记录 + DRAFT 预算对照表
- **recipe**: `docs/skills/run-performance-benchmark/`（未创建）
- **depends_on**: —

---

## 添加新 Skill

1. 在本表增加一行，`status: planned`。
2. 在 [SKILL_CONVENTION.md](../architecture/SKILL_CONVENTION.md) 字段齐全后再写 recipe。
3. 实现后改 `status`，并链到实际路径；**禁止**无索引直接改 Runtime。
