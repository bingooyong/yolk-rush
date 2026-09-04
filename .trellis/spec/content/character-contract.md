# Character Asset Contract

权威文件：`data/characters/yolk_hero.json`

## 硬约束

- 格式：glTF 2.0 / GLB
- 原点：脚底
- 朝向：−Z
- 身高：1.40–1.70 m（Yolk Hero 锁定 1.46 m）
- 碰撞：胶囊来自 JSON，不来自 mesh
- 动画必须可独立作为 AnimationLibrary
- 材质走 library 名（soft_plastic / cloth / rubber），禁止贴图路径写死玩法

## 必带动画

`idle` `run` `jump_start` `airborne` `fall` `land` `roll` `dash` `pounce` `hit` `victory` `fail`

缺任一 → validator 失败，禁止进 Runtime。

## 视觉锁定（Yolk Hero v1）

- 软塑料蛋黄身体，无缝无布料褶皱
- 赤陶红围巾
- 橡胶靴
- 比例：头大、四肢短、可识别剪影
- 未提供合规 GLB 之前，用程序化占位网格，但必须走同一 CharacterVisual 接口
