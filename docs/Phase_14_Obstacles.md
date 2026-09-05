# Phase 14 - 障碍系统

## ✅ 完成内容

### 核心类
1. **ObstacleBase** - 障碍物基类
   - 碰撞检测
   - 伤害/击退系统
   - 状态管理
   - 玩家触发追踪

2. **ObstacleManager** - 障碍管理器
   - 障碍注册/注销
   - 分组管理
   - 批量激活/禁用
   - 统计系统
   - 状态序列化

### 障碍类型

#### 1. RotatingHammer（旋转锤）
经典的旋转障碍物
- 可配置旋转速度和方向
- 高伤害和击退
- 自动旋转动画
- 木质臂 + 金属锤头

**使用示例**:
```gdscript
var hammer = RotatingHammer.new()
hammer.rotation_speed = 60.0  # 度/秒
hammer.rotation_axis = Vector3.UP
hammer.hammer_length = 3.0
hammer.damage_amount = 30.0
add_child(hammer)
```

#### 2. MovingPlatform（移动平台）
可站立的移动障碍
- 往返移动
- 玩家可站立
- 可配置移动速度/距离
- 自动停顿

**使用示例**:
```gdscript
var platform = MovingPlatform.new()
platform.move_speed = 2.0
platform.move_distance = 5.0
platform.move_direction = Vector3.RIGHT
platform.pause_time = 1.0
add_child(platform)
```

#### 3. RollingLog（滚动圆木）
滚动碾压障碍
- 玩家靠近自动触发
- 滚动动画
- 自动返回起点
- 高伤害

**使用示例**:
```gdscript
var log = RollingLog.new()
log.roll_speed = 5.0
log.roll_distance = 10.0
log.auto_return = true
add_child(log)
```

#### 4. BouncePad（弹跳板）
将玩家弹向空中
- 可配置弹跳力度
- 自定义弹跳方向
- 视觉反馈动画
- 冷却系统

**使用示例**:
```gdscript
var pad = BouncePad.new()
pad.bounce_force = 15.0
pad.bounce_direction = Vector3.UP
pad.cooldown_time = 0.5
add_child(pad)
```

#### 5. FallingPlatform（掉落平台）
站上去会掉落的平台
- 延迟掉落
- 抖动警告
- 自动重生
- 颜色变化提示

**使用示例**:
```gdscript
var platform = FallingPlatform.new()
platform.fall_delay = 0.8
platform.respawn_delay = 3.0
platform.shake_before_fall = true
add_child(platform)
```

---

## 🎮 使用ObstacleManager

### 基础用法
```gdscript
# 创建管理器
var manager = ObstacleManager.new()
add_child(manager)

# 自动发现场景中的障碍
manager.discover_obstacles()

# 或手动注册
var hammer = RotatingHammer.new()
manager.register_obstacle(hammer, "zone1")
```

### 分组管理
```gdscript
# 激活特定区域的障碍
manager.activate_group("zone1")

# 禁用特定区域
manager.deactivate_group("zone2")

# 重置特定区域
manager.reset_group("zone1")
```

### 统计查询
```gdscript
# 获取统计信息
var stats = manager.get_stats()
print("Total obstacles: ", stats.total_obstacles)
print("Total triggers: ", stats.total_triggers)

# 打印详细统计
manager.print_stats()
```

---

## 🔧 自定义障碍

继承 `ObstacleBase` 创建自定义障碍：

```gdscript
extends ObstacleBase
class_name MyCustomObstacle

func _initialize_obstacle() -> void:
    obstacle_name = "My Obstacle"
    damage_type = DamageType.MEDIUM
    damage_amount = 25.0
    knockback_force = 12.0
    
    _create_visual()

func _create_visual() -> void:
    # 创建障碍视觉和碰撞
    pass

func _on_triggered(player: Node) -> void:
    # 触发时的自定义逻辑
    print("Player hit my obstacle!")
```

---

## 🎯 关卡设计建议

### 1. 难度递进
```gdscript
# 简单区域：单一障碍
manager.register_obstacle(bounce_pad, "easy")

# 中等区域：组合障碍
manager.register_obstacle(hammer, "medium")
manager.register_obstacle(moving_platform, "medium")

# 困难区域：多重障碍组合
manager.register_obstacle(hammer1, "hard")
manager.register_obstacle(hammer2, "hard")
manager.register_obstacle(falling_platform, "hard")
manager.register_obstacle(rolling_log, "hard")
```

### 2. 时序控制
```gdscript
# 按顺序激活障碍
manager.activate_group("phase1")
await get_tree().create_timer(5.0).timeout
manager.activate_group("phase2")
await get_tree().create_timer(5.0).timeout
manager.activate_group("phase3")
```

### 3. 动态调整
```gdscript
# 根据玩家表现调整难度
if player_score > 100:
    for obstacle in manager.get_active_obstacles():
        if obstacle is RotatingHammer:
            obstacle.set_rotation_speed(obstacle.rotation_speed * 1.5)
```

---

## 📊 性能优化

### 障碍LOD（细节层次）
```gdscript
# 远距离禁用障碍
func _process(delta):
    for obstacle in manager.active_obstacles:
        var distance = player.global_position.distance_to(obstacle.global_position)
        
        if distance > 50.0:
            obstacle.deactivate()
        elif distance < 40.0:
            obstacle.activate()
```

### 批量更新
```gdscript
# 使用分组批量操作而不是单独操作
manager.activate_group("visible_obstacles")
manager.deactivate_group("hidden_obstacles")
```

---

## 🔗 集成其他系统

### 与地图系统集成
```gdscript
# 在地图生成时放置障碍
func generate_level():
    var map_generator = MapGenerator.new()
    var level = map_generator.generate_level()
    
    # 在特定位置放置障碍
    for spawn_point in level.obstacle_spawn_points:
        var obstacle = _create_random_obstacle()
        obstacle.global_position = spawn_point
        obstacle_manager.register_obstacle(obstacle)
```

### 与战斗系统集成
```gdscript
# 障碍触发时应用状态效果
func _on_obstacle_triggered(obstacle, player):
    if obstacle is RollingLog:
        # 应用击晕效果
        player.status_system.add_effect(
            StatusEffectSystem.create_stun(1.0)
        )
```

---

## ✅ 测试结果

运行 `phase_14_obstacle_test.gd` 验证所有功能。

---

## 🚀 下一步

完成 Phase 14 后，推荐路径：
- **Phase 15**: 道具系统（增强玩家能力）
- **Phase 16**: 关卡编辑器（可视化关卡设计）
- **Phase 17**: 多人系统（网络同步）
