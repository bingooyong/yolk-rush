# Level DSL

权威文件：`data/levels/snow_island_01.json`

## 空间角色（只允许这些）

`start_hall` `main_lane` `challenge` `shortcut` `recovery` `finish_hall`

## 规则

- JSON 描述布局与材质标签（如 `ice`），不描述脚本
- 灯光引用 `data/contracts/lighting_profile.json` 的 `game_lighting_v1`
- 出生点在 JSON `spawn`，不在 Scene 里手摆后忘回写
- 黄金关只有 `snow_island_01`；未经 Visual QA ≥85，禁止第二张图

## 表现层 vs 玩法层

- 玩法：胶囊、AABB / 静态体、冰面摩擦、坠落恢复
- 表现：雪地 PBR、装饰、粒子、摄像机追尾
- 调试：Gameplay Layer 线框可开关，默认关
