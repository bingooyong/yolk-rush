# Phase 20 - 粒子效果系统使用文档

## 📖 概述

Phase 20 实现了完整的粒子效果系统，为游戏提供丰富的视觉反馈。

## 🎨 系统架构

### 核心组件

```
ParticleEffectManager (粒子效果管理器)
├── 粒子池系统
├── 效果模板库
└── 自动回收机制

VFXEmitter (VFX发射器)
├── 效果触发接口
├── 持续效果管理
└── 便捷方法
```

## 🚀 快速开始

### 1. 添加粒子管理器到场景

```gdscript
# 在主场景中添加
var particle_manager = ParticleEffectManager.new()
particle_manager.name = "ParticleEffectManager"
add_child(particle_manager)
```

### 2. 使用 VFXEmitter

```gdscript
# 附加到游戏对象
var emitter = VFXEmitter.new()
add_child(emitter)

# 触发效果
emitter.trigger_effect("pickup_flash", Vector3.UP, 1.0)
```

## 📚 可用粒子效果

### 道具拾取特效

| 效果名称 | 说明 | 粒子数 | 持续时间 |
|---------|------|--------|----------|
| `pickup_sparkle` | 闪光粒子 | 20 | 0.8s |
| `pickup_flash` | 爆发闪光 | 10 | 0.3s |
| `pickup_trail` | 拾取轨迹 | 15 | 持续 |

### 碰撞特效

| 效果名称 | 说明 | 粒子数 | 持续时间 |
|---------|------|--------|----------|
| `collision_spark` | 碰撞火花 | 25 | 0.6s |
| `collision_debris` | 碰撞碎片 | 15 | 1.0s |
| `impact_wave` | 冲击波 | 8 | 0.4s |

### 技能特效

| 效果名称 | 说明 | 粒子数 | 持续时间 |
|---------|------|--------|----------|
| `skill_charge` | 技能充能 | 30 | 持续 |
| `skill_explosion` | 技能爆炸 | 40 | 0.8s |
| `skill_trail` | 技能轨迹 | 20 | 持续 |

### 环境粒子

| 效果名称 | 说明 | 粒子数 | 持续时间 |
|---------|------|--------|----------|
| `ambient_dust` | 环境灰尘 | 50 | 持续 |
| `snow_fall` | 飘雪 | 100 | 持续 |
| `rain_drop` | 雨滴 | 200 | 持续 |

## 💡 使用示例

### 道具拾取

```gdscript
# 方式 1: 使用便捷方法
emitter.play_pickup_effect()

# 方式 2: 手动组合
emitter.trigger_effect("pickup_flash")
emitter.trigger_effect("pickup_sparkle")
```

### 障碍碰撞

```gdscript
# 碰撞时触发
func _on_collision(impact_normal: Vector3):
    emitter.play_collision_effect(impact_normal)
```

### 技能释放

```gdscript
# 开始充能
func start_charging():
    var charge_effect = emitter.play_skill_charge()

# 释放技能
func release_skill():
    emitter.play_skill_release(skill_direction)
```

### 技能轨迹

```gdscript
# 移动时显示轨迹
func _physics_process(delta):
    if is_dashing:
        if not trail_effect:
            trail_effect = emitter.play_skill_trail()
    else:
        if trail_effect:
            emitter.stop_continuous_effect(trail_effect)
            trail_effect = null
```

## 🔧 高级用法

### 自定义粒子生成

```gdscript
var manager = get_node("ParticleEffectManager")

# 生成粒子并自定义参数
var effect = manager.spawn_effect(
    "skill_explosion",
    global_position,
    Vector3.UP,
    2.0  # 缩放为2倍
)
```

### 持续效果管理

```gdscript
# 启动持续效果
var continuous_effect = emitter.start_continuous_effect("ambient_dust")

# 稍后停止
emitter.stop_continuous_effect(continuous_effect)

# 或停止所有持续效果
emitter.stop_all_continuous_effects()
```

### 监控池使用情况

```gdscript
var manager = get_node("ParticleEffectManager")

# 获取池统计信息
var stats = manager.get_pool_stats()
for effect_name in stats.keys():
    var info = stats[effect_name]
    print("%s: %d/%d active" % [effect_name, info.active, info.total])

# 获取活跃粒子数
var active_count = manager.get_active_count()
print("Active effects: %d" % active_count)
```

## 🎯 最佳实践

### 1. 性能优化

```gdscript
# ✓ 好：使用池化系统
emitter.trigger_effect("pickup_sparkle")

# ✗ 差：手动创建粒子（绕过池）
var particle = GPUParticles3D.new()  # 不推荐
```

### 2. 持续效果管理

```gdscript
# ✓ 好：记得停止持续效果
var trail = emitter.play_skill_trail()
# ... 使用后
emitter.stop_continuous_effect(trail)

# ✗ 差：忘记停止会导致内存泄漏
var trail = emitter.play_skill_trail()
# 忘记停止！
```

### 3. 组合使用

```gdscript
# ✓ 好：组合多个效果增强视觉表现
func play_super_explosion():
    emitter.trigger_effect("skill_explosion", Vector3.UP, 2.0)
    emitter.trigger_effect("impact_wave", Vector3.UP, 1.5)
    emitter.trigger_effect("collision_spark", Vector3.UP)
```

## 🔗 与其他系统集成

### 与音效系统配合

```gdscript
func play_pickup_feedback():
    # 视觉
    emitter.play_pickup_effect()
    
    # 音效
    AudioManager.play_sfx("pickup_coin", global_position)
```

### 与道具系统集成

```gdscript
# 在 PickupItem 中
func _on_picked_up():
    # 触发粒子效果
    if vfx_emitter:
        vfx_emitter.play_pickup_effect()
```

### 与障碍系统集成

```gdscript
# 在 Obstacle 中
func _on_player_collision(impact_point: Vector3, impact_normal: Vector3):
    # 触发碰撞粒子
    if vfx_emitter:
        vfx_emitter.global_position = impact_point
        vfx_emitter.play_collision_effect(impact_normal)
```

## ⚙️ 配置参数

### ParticleEffectManager 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `max_pool_size` | 50 | 每类效果的最大池大小 |
| `initial_pool_size` | 10 | 初始预创建数量 |
| `auto_cleanup_interval` | 5.0 | 自动清理间隔（秒） |

### VFXEmitter 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `auto_trigger_on_ready` | false | 准备完成时自动触发 |
| `default_effect` | "" | 默认效果名称 |
| `trigger_on_collision` | false | 碰撞时触发 |
| `trigger_on_pickup` | false | 拾取时触发 |

## 📊 性能指标

### 粒子池优势

- **内存复用**: 避免频繁创建销毁
- **性能稳定**: 预分配减少运行时开销
- **自动管理**: 自动回收已完成的效果

### 移动端优化

- 单次并发最大 50 个粒子效果
- 自动清理未使用的粒子
- 池化系统减少 GC 压力

## 🐛 故障排除

### 粒子不显示

```gdscript
# 检查管理器是否存在
var manager = get_tree().root.find_child("ParticleEffectManager", true, false)
if not manager:
    print("ParticleEffectManager not found!")
```

### 效果名称错误

```gdscript
# 检查可用效果
var manager = get_node("ParticleEffectManager")
print("Available effects: ", manager.effect_templates.keys())
```

### 持续效果不停止

```gdscript
# 确保调用停止方法
emitter.stop_all_continuous_effects()

# 或在退出时自动清理
func _exit_tree():
    emitter.stop_all_continuous_effects()
```

## 📝 完整示例

```gdscript
extends CharacterBody3D

@onready var vfx_emitter = VFXEmitter.new()
var dash_trail = null

func _ready():
    add_child(vfx_emitter)

func pickup_item():
    # 道具拾取反馈
    vfx_emitter.play_pickup_effect()
    AudioManager.play_sfx("pickup")

func start_dash():
    # 开始冲刺轨迹
    dash_trail = vfx_emitter.play_skill_trail()

func end_dash():
    # 停止冲刺轨迹
    if dash_trail:
        vfx_emitter.stop_continuous_effect(dash_trail)
        dash_trail = null

func on_hit_obstacle(impact_point, impact_normal):
    # 碰撞反馈
    vfx_emitter.global_position = impact_point
    vfx_emitter.play_collision_effect(impact_normal)
    AudioManager.play_sfx("collision", impact_point)

func _exit_tree():
    vfx_emitter.stop_all_continuous_effects()
```

## 🎓 相关文档

- Phase 16: 音效系统
- Phase 14: 障碍系统
- Phase 15: 道具系统
- Phase 10: 技能系统
