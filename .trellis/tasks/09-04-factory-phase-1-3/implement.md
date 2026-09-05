# Implement — Phase 1–3 总计划

按子任务执行。父任务本身不写业务代码。

## 顺序

```
09-04-hero-pipeline     ──►  09-04-snow-island     ──►  09-04-visual-perf-qa
     (阻塞)                      (阻塞)                      (本轮终点)
```

## 全局验证（每个子任务结束都跑）

```
godot --headless --script tools/validate_character.gd
godot --headless --script tools/validate_level.gd
```

Mac 上 F5 手测：角色可见；W 前进；A 左转；D 右转；空格跳。

## 禁止在本父任务里做的事

- 开第二张图、第二角色
- 商城 / 抽卡 / 网络同步
- 升级引擎到 4.8
- 引入 C#

## 子任务入口

1. [../09-04-hero-pipeline/implement.md](../09-04-hero-pipeline/implement.md)
2. [../09-04-snow-island/implement.md](../09-04-snow-island/implement.md)
3. [../09-04-visual-perf-qa/implement.md](../09-04-visual-perf-qa/implement.md)

## 完成后

更新本父任务 `task.json` status → `review`，写 `qa/PHASE_1_3_REPORT.md`。
未获视觉 ≥85 时 status 仍为 `review`（带 NI），不得标 `completed`。
