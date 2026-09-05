# PRD — Phase 3 Visual / Performance QA

## Goal

给工厂装上门：固定机位截图、视觉记分卡、性能日志。不靠聊天里“看起来还行”。

## Depends

Phase 2 可玩。

## Requirements

- **Q1** `tools/screenshot_rig.gd` 输出到 `qa/screenshots/`：hero_34、hero_front、hero_side、hero_back、start_hall、overview。
- **Q2** `qa/visual_scorecard.md` 模板：轮廓 20、比例 20、材质 20、灯光 20、动画 20。阈值 <70 reject / 70–84 NI / ≥85 pass。
- **Q3** 本轮必须填一版分数。占位体未达 85 时写 NI 列表，禁止改阈值。
- **Q4** `tools/perf_counters.gd` 记录 FPS、Draw Calls、FPS 最低值到 `qa/perf/latest.json`。
- **Q5** 目标：iPhone 12 级 60 fps。无真机则标记 `sampled: editor`，不得写成设备 pass。
- **Q6** Skills：`review-visual` `optimize-mobile` `screenshot-qa`。
- **Q7** `qa/PHASE_1_3_REPORT.md` 汇总：通过项、NI、禁止项。

## Acceptance

- [ ] 六张截图文件存在。
- [ ] scorecard 有数字，不是空表。
- [ ] perf JSON 有 fps 字段。
- [ ] 三个 Skill 文件存在。
- [ ] 报告明确写：是否允许开第二张图（默认否，除非视觉 ≥85 且无 P0 NI）。

## Out of scope

自动视觉打分模型、CI 上的 Mac runner、真机 TestFlight。
