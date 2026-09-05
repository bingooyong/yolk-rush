# Trellis — Yolk Rush

本目录是 **Godot 4.7.2 Game Factory** 的规划与执行合同。
Agent 先读这里，再改产品代码。

```
.trellis/
  README.md                 ← 你在这里
  spec/                     ← 长期规范（怎么写代码）
  tasks/                    ← 当前与后续任务（做什么）
```

## 当前父任务

[tasks/09-04-factory-phase-1-3/](tasks/09-04-factory-phase-1-3/) — Phase 1–3

子任务（必须按依赖顺序执行）：

1. [09-04-hero-pipeline](tasks/09-04-hero-pipeline/) — 角色合同 + 占位视觉
2. [09-04-snow-island](tasks/09-04-snow-island/) — 雪岛黄金关可玩
3. [09-04-visual-perf-qa](tasks/09-04-visual-perf-qa/) — 视觉 / 性能门禁

## 使用方式

1. 读父任务 `prd.md` → `design.md` → `implement.md`
2. 只启动一个子任务
3. 子任务未通过验收，禁止开始下一个
4. 架构冲突：停、报、最小修改、等决策

引擎锁定：Godot **4.7.2 stable** · GDScript · Mobile Renderer。
