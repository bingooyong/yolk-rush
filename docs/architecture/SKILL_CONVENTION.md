# Skill Convention

**Skill** = 给 agent / factory 使用的**具名能力**：固定输入、输出、成功标准，以及 recipe 存放位置。  
原则 7：**New capability ⇒ Skill** — 先登记 Skill，再实现；禁止无登记的「顺手脚本」进入 Runtime。

原则索引：[ARCHITECTURE_PRINCIPLES.md](./ARCHITECTURE_PRINCIPLES.md)  
Skill 索引（仅 planned）：[../skills/README.md](../skills/README.md)

---

## Skill 条目必备字段

| 字段 | 说明 |
|------|------|
| `id` | kebab-case 唯一名，如 `validate-asset-contract` |
| `status` | `planned` \| `draft` \| `active`（当前索引多为 **planned**） |
| `inputs` | 输入工件 / 路径 / 参数 |
| `outputs` | 产出（报告、exit code、artifact 路径） |
| `success_criteria` | 可判定的通过条件 |
| `recipe` | 步骤或脚本所在路径（未实现时写目标路径并标 planned） |
| `phase` | 目标阶段（Phase 3 QA 相关见下） |

可选：`depends_on`（其它 Skill id）、`non_goals`。

---

## 流程

1. 需要新能力 → 在 `docs/skills/README.md` **先加条目**（可先 `status: planned`）。
2. 实现 recipe（脚本 / agent prompt / CI step）→ 更新 `status` 与 `recipe` 路径。
3. Runtime 只消费 Skill 的稳定输出；**不**把 Skill 临时逻辑拷进 `scripts/core` 或 boot。
4. 与原则冲突 → 停、报、最小改、等决策（原则 10）。

---

## Phase 3 计划 Skills（未实现）

以下均为 **planned**，勿当作已落地工具：

### `validate-asset-contract`
- **inputs**: 角色 JSON（如 `data/characters/yolk_hero.json`）+ schema `data/contracts/character_asset_contract.json`；可选 GLB 路径探活
- **outputs**: pass/fail 报告；失败项清单（origin / facing / height_m / collision_profile / materials …）
- **success_criteria**: schema 校验通过且清单全部勾选（见 [ASSET_CONTRACT.md](./ASSET_CONTRACT.md)）
- **recipe**: `docs/skills/validate-asset-contract/`（目标；尚未创建）
- **phase**: 3（亦为合入 Runtime 门禁）

### `run-visual-benchmark`
- **inputs**: golden scene（Snow Island）、角色 visual、lighting profile id（`game_lighting_v1`）
- **outputs**: 维度分 + 总分（0–100）；截图 / 笔记 artifact
- **success_criteria**: 总分 **≥ 85** 为 pass；阈值见 [BENCHMARKS.md](./BENCHMARKS.md)
- **recipe**: `docs/skills/run-visual-benchmark/`（目标；尚未创建）
- **phase**: 3

### `run-performance-benchmark`
- **inputs**: Mobile / iOS 构建设置；golden 或代表关；设备或 profiling 会话
- **outputs**: fps / hitch / memory 记录；对照 **DRAFT** 预算的 checklist
- **success_criteria**: DRAFT checklist 已填写并归档（预算未在真机标定前不作硬门禁数字）
- **recipe**: `docs/skills/run-performance-benchmark/`（目标；尚未创建）
- **phase**: 3

---

## 非目标

- Skill 不是 Runtime 子系统名；不替代 Domain / Presentation 分层。
- 不为 shop / gacha 预留 Skill（boot 明确无商店、无 gacha）。
- 不把未实现 Skill 写成 CI 已绿。
