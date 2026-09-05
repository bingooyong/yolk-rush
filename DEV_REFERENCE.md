# Yolk Rush - 快速开发参考

**当前状态**: Milestone 1.1 - 75% 完成  
**最后更新**: 2025-09-05

---

## 🚀 快速启动

### 运行测试
```bash
# 所有测试套件
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/phase_17_save_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/phase_19_game_loop_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/phase_22_alpha_integration_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/phase_24_level_config_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/level_01_playtest.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --script scripts/tests/level_flow_integration_test.gd

# 快速批量测试
/tmp/run_all_phase_tests.sh
```

### 启动关卡1
```bash
# 在Godot编辑器中：
# 1. 打开 scenes/levels/level_01_grassland.tscn
# 2. 按 F6 运行当前场景
# 或者设置为主场景后按 F5
```

---

## 📁 核心文件位置

### 关卡系统
- **关卡场景**: `scenes/levels/level_01_grassland.tscn`
- **关卡初始化**: `scripts/levels/level_01_init.gd`
- **关卡生成器**: `scripts/levels/level_generator.gd`
- **关卡配置**: `scripts/levels/level_config.gd`
- **关卡模板**: `scripts/levels/level_templates.gd`
- **关卡流程**: `scripts/core/level_flow_controller.gd`

### 实体系统
- **玩家**: `scenes/player/player.tscn` + `scripts/player/player.gd`
- **基础敌人**: `scenes/entities/basic_enemy.tscn` + `scripts/entities/basic_enemy.gd`

### 道具和障碍
- **障碍基类**: `scripts/objects/obstacle_base.gd`
- **尖刺**: `scenes/objects/spike_obstacle.tscn` + `scripts/objects/spike_obstacle.gd`
- **道具基类**: `scripts/objects/item_base.gd`
- **金币**: `scenes/objects/coin_item.tscn` + `scripts/objects/coin_item.gd`
- **药水**: `scenes/objects/health_potion.tscn` + `scripts/objects/health_potion.gd`

### 核心系统
- **战斗系统**: `scripts/systems/combat_system.gd`
- **游戏状态**: `scripts/core/game_state_manager.gd`
- **保存系统**: `scripts/core/save_manager.gd`

### 测试
- **关卡1测试**: `scripts/tests/level_01_playtest.gd`
- **流程测试**: `scripts/tests/level_flow_integration_test.gd`

---

## 🎮 游戏玩法参考

### 玩家控制
- **移动**: WASD 或方向键
- **跳跃**: Space
- **攻击**: 鼠标左键（近战，2m范围，90°扇形）
- **暂停**: ESC

### 玩家属性
```gdscript
max_hp = 100
current_hp = 100
damage = 20
attack_range = 2.0
attack_angle = 90.0  # 度
score = 0
```

### 敌人属性（基础敌人）
```gdscript
max_hp = 50
damage = 10
speed = 3.0
detection_range = 15.0
attack_range = 2.0
```

### 道具效果
- **金币**: +10分
- **生命药水**: +30 HP（最大100）

### 障碍
- **尖刺**: 15点伤害，1秒冷却

---

## 🎯 关卡1配置

```gdscript
level_id = 0
level_name = "草原初章"
theme = "grassland"
difficulty = 1
time_limit = 180.0s
player_lives = 3

# 目标
objectives = [
    {"type": "defeat_all", "target": 2}  # 击败2个敌人
]

# 敌人 (2个)
enemies = [
    {"type": "basic", "position": Vector3(10, 0, 10), "level": 1},
    {"type": "basic", "position": Vector3(-10, 0, 10), "level": 1}
]

# 障碍 (4个尖刺)
obstacles = [
    {"type": "spike", "position": Vector3(5, 0, 5)},
    {"type": "spike", "position": Vector3(-5, 0, 5)},
    {"type": "spike", "position": Vector3(5, 0, -5)},
    {"type": "spike", "position": Vector3(-5, 0, -5)}
]

# 道具 (5个)
items = [
    {"type": "health_potion", "position": Vector3(0, 0, 8)},
    {"type": "coin", "position": Vector3(3, 0, 3)},
    {"type": "coin", "position": Vector3(-3, 0, 3)},
    {"type": "coin", "position": Vector3(0, 0, -3)},
    {"type": "coin", "position": Vector3(8, 0, 0)}
]

# 位置
spawn_point = Vector3(0, 0, -15)
exit_point = Vector3(0, 0, 20)
```

---

## 🔧 常用代码片段

### 创建新敌人
```gdscript
const ENEMY_SCENE = preload("res://scenes/entities/basic_enemy.tscn")

var enemy = ENEMY_SCENE.instantiate()
add_child(enemy)
enemy.global_position = Vector3(10, 0, 10)
enemy.set_level(2)  # 可选：设置等级
```

### 创建新道具
```gdscript
const COIN_SCENE = preload("res://scenes/objects/coin_item.tscn")

var coin = COIN_SCENE.instantiate()
add_child(coin)
coin.global_position = Vector3(5, 1, 5)
```

### 应用伤害
```gdscript
const CombatSystem = preload("res://scripts/systems/combat_system.gd")

# 直接伤害
CombatSystem.apply_damage(target, 20)

# 近战攻击（带判定）
var targets = CombatSystem.melee_attack(
    attacker_position,
    attacker_forward,
    damage,
    range,
    angle
)
```

### 连接信号
```gdscript
# 敌人死亡
enemy.died.connect(func(e):
    print("Enemy died: ", e.name)
)

# 玩家死亡
player.player_died.connect(func():
    print("Game Over!")
)

# 目标完成
level_flow.objective_completed.connect(func(obj_id):
    print("Objective completed: ", obj_id)
)

# 关卡胜利
level_flow.all_objectives_completed.connect(func():
    print("Victory!")
)
```

---

## 📝 下一步任务清单

### Task 1.1.7: 粒子特效 (当前任务)
- [ ] 攻击命中粒子 (CPUParticles3D)
  - 白色火花
  - 生命周期0.3s
  - 爆发式发射
- [ ] 敌人死亡粒子
  - 红色消散
  - 生命周期0.5s
  - 向上飘散
- [ ] 道具拾取粒子
  - 黄色（金币）/绿色（药水）
  - 生命周期0.4s
  - 向上爆发
- [ ] 性能测试
  - 每个粒子<1ms
  - 多个粒子同时<5ms

### Task 1.1.8: 最终验证
- [ ] 完整通关测试
- [ ] 性能基准（60fps）
- [ ] Bug修复
- [ ] 平衡调整

---

## 🐛 已知问题

### 轻微问题
1. **死亡动画警告**
   - 敌人死亡时缩放到零会产生物理引擎警告
   - 不影响功能
   - 优先级：低

2. **视觉占位符**
   - 所有实体使用基础几何体
   - 功能完整，但需美化
   - 优先级：中（Phase 4视觉升级）

### 待实现
1. **音效系统**
   - AudioManager已有框架
   - 需要音频资源
   - 优先级：中

2. **粒子特效**
   - Task 1.1.7正在实现
   - 优先级：高

---

## 📊 测试覆盖

| 系统 | 测试套件 | 覆盖率 |
|------|----------|--------|
| 保存系统 | phase_17_save_test.gd | ✅ 100% |
| 游戏循环 | phase_19_game_loop_test.gd | ✅ 100% |
| Alpha集成 | phase_22_alpha_integration_test.gd | ✅ 100% |
| 关卡配置 | phase_24_level_config_test.gd | ✅ 100% |
| 关卡1功能 | level_01_playtest.gd | ✅ 100% |
| 关卡流程 | level_flow_integration_test.gd | ✅ 100% |

---

## 🎯 性能目标

### 当前性能（开发机）
- FPS: 稳定60+ (估计)
- 敌人数量: 2个（测试通过）
- 道具数量: 5个（测试通过）
- 障碍数量: 4个（测试通过）

### 移动端目标（iPhone）
- FPS: 稳定60
- 最大敌人: 10-15个
- 最大道具: 20-30个
- 最大障碍: 30-50个
- Draw calls: <100

---

## 📚 相关文档

- **架构文档**: `docs/architecture/`
- **项目状态**: `PROJECT_STATUS.md`
- **Milestone进度**: `MILESTONE_1_1_PROGRESS.md`
- **完成总结**: `MILESTONE_1_1_SUMMARY.md`
- **快速启动**: `QUICK_START.md`
- **测试报告**: `test_report.md`
- **Phase 24计划**: `docs/Phase_24_Content_Expansion.md`

---

**最后更新**: 2025-09-05  
**下一次更新**: Task 1.1.7 完成后
