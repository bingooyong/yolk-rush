# Benchmarks — Visual & Performance

原则 8（Visual Benchmark）与原则 9（Mobile Performance Benchmark）。  
原则索引：[ARCHITECTURE_PRINCIPLES.md](./ARCHITECTURE_PRINCIPLES.md)  
相关 Skill（planned）：[../skills/README.md](../skills/README.md)

Golden 场景：**Snow Island**（`data/levels/snow_island_01.json` + preview 可玩布局）。  
Lighting 参照：`game_lighting_v1`（`data/contracts/lighting_profile.json`）。

---

## Visual Benchmark

### 分数阈值（原则 8）

| 总分 | 判定 |
|------|------|
| **&lt; 70** | **reject** — 不得合入 Runtime / 不得标 golden |
| **70–84** | **needs improvement (NI)** — 可迭代，不作为 Phase 3 通过 |
| **≥ 85** | **pass** |

### 评分维度（可加权，总分 0–100）

1. **Silhouette readability** — 远中近距离轮廓可辨；与障碍/雪地背景不糊成一团。
2. **Lighting match (`game_lighting_v1`)** — 受光、阴影方向与强度符合 lighting profile；无「预览灯乱加」破坏统一。
3. **Material soft_plastic feel** — 蛋壳/软塑胶质感；高光与粗糙度符合材料槽意图（非金属脏污乱反射）。
4. **No mesh-driven collision leaks** — 视觉与碰撞分离：无导入 mesh collision 顶替 `collision_profile`；capsule 与脚底原点关系正确（原则 4、6）。

建议流程：先 `validate-asset-contract` → 再在 Snow Island golden 下跑 `run-visual-benchmark`。

### 金标语境

- Phase 2：Snow Island golden 在 **Grok preview** 可玩。
- 截图 / 笔记应对齐同一 lighting profile 与同一角色合同身高（1.40–1.70 m，yolk_hero height_m 1.46）。

---

## Performance Benchmark（Mobile / iOS）

引擎：Godot 4.7.2 · **Mobile renderer** · Jolt Physics。  
iOS 导出：**仅 Mac + Xcode**。

### DRAFT 预算（未在真机标定前不作硬门禁）

> 以下全部标记为 **DRAFT**。Phase 3 要求「对照本表完成记录」，不要求数字已最终冻结。

| 指标 | DRAFT 目标 | DRAFT 底线 | 备注 |
|------|------------|------------|------|
| 帧率 | **60 fps** 目标 | **30 fps** sustained 底线 | golden / 代表段；注明机型 |
| Hitch | 无明显长卡顿 | 单帧尖峰记录并标注 | 记录 p95/最长 hitch（ms） |
| 内存 | 记录峰值 RSS / 引擎统计 | 超预期增长需备注 | DRAFT：尚无绝对 MB 上限 |
| 加载 | 冷启动到可操作可玩 | 超时需备注 | boot 无 shop / 无 gacha |

测量输出应归档（路径由 Skill `run-performance-benchmark` 约定），并写明：设备、Godot 版本、renderer、关卡、是否 preview 资源。

---

## Phase 3 入口条件

同时满足才可宣称 Visual/Perf QA 入口通过：

1. **Asset Contract pass**（角色进 Runtime 前门禁）
2. **Visual ≥ 85** on Snow Island golden（同 lighting / 合同约束）
3. **Perf DRAFT checklist recorded**（上表逐项有测量记录；预算数字仍为 DRAFT）

未满足 → 不宣称 Phase 3 QA 完成；不把 preview 临时通过当成 GitHub Runtime 已达标。

---

## 诚实边界

- GitHub 侧多为 data + print-only bootstrap；完整 golden 与测量环境可能仍在 preview。
- 勿将 DRAFT 预算写成已批准的 ship gate。
- 冲突或临时刷分脚本 → 原则 10：停、报、最小改、等决策。
