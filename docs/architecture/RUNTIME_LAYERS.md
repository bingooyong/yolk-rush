# Runtime Layers — Yolk Rush

目标分层（自上而下依赖方向：**上层依赖下层，不得反向污染**）。当前仓库骨架与目标之间仍有缺口，下文如实标注。

引擎冻结：Godot **4.7.2 stable** · GDScript only · Mobile renderer · Jolt Physics  
入口：`scenes/bootstrap/boot.tscn` · `App` autoload：`scripts/core/app.gd`（仅路由）

原则索引见 [ARCHITECTURE_PRINCIPLES.md](./ARCHITECTURE_PRINCIPLES.md)（尤其 1–5、7、10）。

---

## 1. Data（`data/**` JSON）

**Owns**
- 角色、关卡、光照等可序列化事实：id、数值、槽位、segment 角色、flags。
- Asset Contract / Lighting Profile 等契约声明。
- 碰撞尺寸等来自 `collision_profile` 的权威数值（非 mesh 派生）。

**Must not own**
- 节点树、场景布局、脚本逻辑、渲染调用。
- 「临时」硬编码路径当正式 API 用（见原则 10）。

**Example paths**
- `data/characters/yolk_hero.json` — `visual_model`、`skeleton: humanoid_v1`、`animations`、`materials` slots、`collision_profile`、`contract`
- `data/levels/snow_island_01.json` — segments（`start_hall` / `main_lane` / `challenge` / `shortcut` / `recovery` / `finish_hall`）、ice flags、`lighting: game_lighting_v1`
- `data/contracts/lighting_profile.json`
- `data/contracts/character_asset_contract.json`（本仓库文档侧 schema；Runtime 校验以仓库内同路径为准）

**Current gap**  
GitHub 侧已有 **data + print-only bootstrap**；Domain 加载器尚未落地。Data 是目前最完整的一层。

---

## 2. Domain / Gameplay systems（目标层）

**Owns（目标）**
- JSON loader / 校验（含 Asset Contract）。
- 规则与状态：比赛流程、障碍交互、胜负条件等。
- 从 `collision_profile` 构建/配置碰撞体（height / radius / offset_y），**禁止**从 mesh 推断碰撞。

**Must not own**
- Mesh / material / lighting 资源选择（属 Presentation）。
- 关卡节点摆放（属 Scene）。
- 路由与 boot 编排（属 Bootstrap / App）。

**Example paths（目标，多数尚未实现）**
- `scripts/domain/**` 或等价目录：character loader、level segment resolver、collision factory
- 读取 `yolk_hero.json` → 产出 gameplay capsule，而非 `MeshInstance3D` 形状

**Current status**  
最小加载层已落地：`scripts/character/character_definition.gd`、`scripts/level/level_definition.gd`、`scripts/character/character_gameplay.gd`（仅胶囊）、`tools/validate_*.gd`。仍无完整 match / 移动 / Visual；新能力先登记 Skill（原则 7）。

---

## 3. Presentation / Visual

**Owns**
- GLB/glTF mesh、材料槽填充、动画绑定到 visual skeleton。
- Lighting profile 应用（如 `game_lighting_v1`）。
- 与 Gameplay 解耦的展示参数（原则 1：Gameplay ≠ Visual）。

**Must not own**
- 碰撞权威数据、胜负规则、segment 角色判定。
- 「mesh 自带 collision」进入 Runtime（原则 4、6）。

**Example paths**
- `assets/characters/**`（visual_model 指向的 GLB）
- 材料 / lighting 资源；profile 数据仍在 `data/contracts/lighting_profile.json`

**Current gap**  
Yolk Hero v1 art 与 Snow Island golden 主要在 **Grok preview** 锁定/可玩；GitHub 上 Presentation 资源与 Domain 绑定仍不完整。资产进 Runtime 前必须过 Asset Contract（原则 6）。

---

## 4. Scene（布局 only）

**Owns**
- 节点树与空间布局：spawn、segment 占位、相机挂点、灯光节点位置。
- 引用 Data id / visual 资源路径，不内嵌业务公式。

**Must not own**
- 业务规则、胜负、数值表、碰撞尺寸计算（原则 2、5）。
- 临时 `print` 冒充系统行为（原则 10：冲突则停、报、最小改、等决策）。

**Example paths**
- `scenes/levels/**` — Snow Island 布局
- `scenes/bootstrap/boot.tscn` — 启动场景（无 shop / 无 gacha）
- Level JSON 描述 roles；Scene 只摆对应节点

**Current gap**  
Golden scene（Snow Island）**主要仍在 Grok preview** 可玩；GitHub 侧 scene 可能仅为骨架或缺失完整布局。以 preview 为视觉金标，合入前走 Visual / Perf QA（Phase 3）。

---

## 5. Bootstrap / App

**Owns**
- `App` autoload（`scripts/core/app.gd`）：**仅路由**（场景切换、启动序），不承载玩法规则。
- `boot.tscn`：冷启动入口；当前产品声明：**无商店、无 gacha**。

**Must not own**
- Domain 规则、资产校验细节、关卡 segment 逻辑。
- 临时调试代码长期留在 Runtime（原则 10）。

**Example paths**
- `scenes/bootstrap/boot.tscn`
- `scripts/core/app.gd`

**Current gap**  
GitHub：**print-only bootstrap**（验证引擎/autoload 可跑）。完整路由到 Domain + golden level 仍待 Phase 推进。GitHub 是相对 Grok preview 休眠的 **durable copy**；iOS 导出仅 Mac + Xcode。

---

## 依赖与合入规则（摘要）

| 层 | 可依赖 | 不可被依赖方写入 |
|----|--------|------------------|
| Data | — | Scene / Presentation 不得改写契约数值当本地真理 |
| Domain | Data | Scene 不得内嵌 Domain 规则 |
| Presentation | Data（visual 引用） | Domain 不持有 mesh 所有权 |
| Scene | Data id、Presentation 资源、Domain 入口信号 | 无业务规则 |
| Bootstrap | 路由到 Scene / 未来 Domain | 无玩法 |

**冲突处理（原则 10）**：Runtime 出现临时代码或与原则冲突 → **停止 → 报告 → 最小改动 → 等待决策**。不发明未实现系统并写成「已存在」。
