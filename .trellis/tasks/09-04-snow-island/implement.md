# Implement — Phase 2

1. level_definition + validate_level
2. level_builder 生成 11 个 segment（含 ice / recovery）
3. player_input（键盘 + 触屏信号）
4. gameplay 接入移动/跳跃/冰面/重生
5. chase_camera
6. match.tscn 组装 World + Hero + Camera + HUD
7. boot 改主路径
8. create-level Skill
9. 控制验收：A 左 D 右 W 进 空格跳
10. 解耦验收：隐藏 Visual 再跑 10 秒

## 控制回归（必须）

在追尾镜头下：按 A，角色向屏幕左侧转（逆时针）。反了就改 yaw 符号，不改摄像机。

## Rollback

关卡 JSON 坐标若被手改，以 git 中 `snow_island_01.json` 为准回滚。
