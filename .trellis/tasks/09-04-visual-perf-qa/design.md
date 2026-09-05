# Design — Phase 3 QA

## Screenshot rig

切到 `camera_profiles.json` 命名机位，隐藏 HUD 与 Gameplay Layer，等 2 帧再 `get_viewport().get_texture()`。
文件名冻结，CI 以后做 pixel diff 才有基线。

## Scorecard 权重

| 项 | 权重 | 看什么 |
|---|---|---|
| 轮廓 | 20 | 剪影能否在雪地里立刻认出蛋+围巾 |
| 比例 | 20 | 头/身/肢与 1.46 m 胶囊一致，无脚陷 |
| 材质 | 20 | 软塑料 vs 布 vs 橡胶可分，无金属蛋 |
| 灯光 | 20 | 三灯比例，无死黑无过曝 |
| 动画 | 20 | idle 呼吸、run 摆臂不过度 |

打分人可以是人眼或后续视觉模型；本阶段人眼填表合法。

## Perf

Editor 窗口 1280×720，Mobile renderer。记录 10s 平均值。
真机采样表留空字段：`device`, `ios`, `fps_avg`, `thermal`。
