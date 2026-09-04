# Architecture Principles

1. Gameplay 与 Visual 完全解耦。
2. Scene 不承担业务规则。
3. 游戏规则优先 Data Driven。
4. 角色模型永远不能决定碰撞。
5. Level Scene 只表达布局。
6. AI 生成资产必须通过 Asset Contract。
7. 所有新增能力必须有 Skill。
8. 视觉改动必须经过 Visual Benchmark（<70 reject, 70–84 NI, ≥85 pass）。
9. 移动端改动必须经过 Performance Benchmark。
10. 临时代码不得进入 Runtime。架构冲突：停、报、最小修改、等决策。

Engine freeze: Godot 4.7.2 stable. GDScript only. Mobile renderer.
Character standard: GLB / glTF 2.0, feet origin, facing −Z, height 1.40–1.70 m.
