# Architecture Docs — Yolk Rush

AI-native 3D party obstacle race（原作 IP；非蛋仔派对克隆）。  
引擎冻结：Godot **4.7.2 stable** · GDScript · Mobile renderer · Jolt Physics。

本目录为架构约定索引。实现以仓库代码与 `data/**` 为准；文档描述**目标分层**并标明与当前骨架的差距。

---

## 文档

| 文档 | 内容 |
|------|------|
| [ARCHITECTURE_PRINCIPLES.md](./ARCHITECTURE_PRINCIPLES.md) | 十条架构原则（权威；勿在未决策时改写） |
| [RUNTIME_LAYERS.md](./RUNTIME_LAYERS.md) | Data → Domain → Presentation → Scene → Bootstrap/App |
| [ASSET_CONTRACT.md](./ASSET_CONTRACT.md) | 角色资产契约；进 Runtime 前门禁 |
| [SKILL_CONVENTION.md](./SKILL_CONVENTION.md) | Skill 定义与登记流程（新能力先 Skill） |
| [BENCHMARKS.md](./BENCHMARKS.md) | Visual 阈值与 Mobile/iOS Perf **DRAFT** 预算 |

相关：

- Skill 索引（planned only）：[../skills/README.md](../skills/README.md)
- Character schema：[`../../data/contracts/character_asset_contract.json`](../../data/contracts/character_asset_contract.json)
- Lighting（独立契约族）：`data/contracts/lighting_profile.json`

---

## 阅读顺序（建议）

1. `ARCHITECTURE_PRINCIPLES.md`
2. `RUNTIME_LAYERS.md`（含 GitHub vs preview gap）
3. `ASSET_CONTRACT.md` + schema JSON
4. `SKILL_CONVENTION.md` → `docs/skills/README.md`
5. `BENCHMARKS.md`（Phase 3 入口条件）
