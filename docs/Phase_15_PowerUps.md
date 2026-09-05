# Phase 15 - 道具系统

## ✅ 完成内容

### 核心类
1. **PowerUpBase** - 道具基类
   - 收集系统
   - 激活/过期机制
   - 持续时间管理
   - 稀有度系统
   - 视觉反馈

2. **PowerUpManager** - 道具管理器
   - 道具生成
   - 自动生成系统
   - 稀有度权重
   - 统计追踪

### 道具类型

#### 1. SpeedBoost（加速道具）
临时提升移动速度
- **稀有度**: 常见
- **持续时间**: 5秒
- **效果**: 1.5倍速度
- **可叠加**: 是

**特点**:
- 黄色胶囊外观
- 速度线条效果
- 拖尾视觉反馈

#### 2. Invincibility（无敌道具）
免疫所有伤害
- **稀有度**: 稀有
- **持续时间**: 6秒
- **效果**: 完全无敌
- **可叠加**: 否

**特点**:
- 金色星星外观
- 光环效果
- 最后2秒闪烁警告

#### 3. Shield（护盾道具）
吸收固定次数伤害
- **稀有度**: 不常见
- **持续时间**: 15秒
- **效果**: 吸收3次伤害
- **可叠加**: 否

**特点**:
- 蓝色半透明气泡
- 每次受击闪烁
- 根据剩余次数调整透明度

#### 4. Magnet（磁铁道具）
自动吸引附近道具
- **稀有度**: 常见
- **持续时间**: 8秒
- **效果**: 10米吸引范围
- **可叠加**: 否

**特点**:
- U型磁铁外观（红蓝双色）
- 紫色磁场圆环
- 自动吸引效果

---

## 🎮 使用指南

### 基础用法

```gdscript
# 创建道具管理器
var manager = PowerUpManager.new()
add_child(manager)

# 生成随机道具
var power_up = manager.spawn_random_power_up(Vector3(0, 2, 0))

# 生成指定类型道具
var speed_boost = manager.spawn_power_up(
    PowerUpBase.PowerUpType.SPEED_BOOST,
    Vector3(5, 2, 0)
)
```

### 自动生成系统

```gdscript
# 启用自动生成
manager.set_auto_spawn(true)
manager.set_spawn_interval(5.0)  # 每5秒生成一个
manager.set_max_power_ups(10)    # 最多10个

# 添加生成点
manager.add_spawn_point(Vector3(10, 2, 0))
manager.add_spawn_point(Vector3(-10, 2, 5))
manager.add_spawn_points([
    Vector3(0, 2, 10),
    Vector3(0, 2, -10)
])
```

### 调整稀有度

```gdscript
# 自定义稀有度权重
manager.set_rarity_weight(PowerUpBase.PowerUpRarity.COMMON, 40)
manager.set_rarity_weight(PowerUpBase.PowerUpRarity.RARE, 20)
manager.set_rarity_weight(PowerUpBase.PowerUpRarity.LEGENDARY, 5)
```

### 手动激活道具

```gdscript
# 创建不自动激活的道具
var power_up = SpeedBoostPowerUp.new()
power_up.auto_activate = false
add_child(power_up)

# 玩家拾取后手动激活
power_up._collect(player)
# 稍后激活
power_up.activate(player)
```

---

## 🔧 自定义道具

继承 `PowerUpBase` 创建自定义道具：

```gdscript
extends PowerUpBase
class_name CustomPowerUp

func _initialize_power_up() -> void:
    power_up_name = "My PowerUp"
    power_up_type = PowerUpType.CUSTOM
    rarity = PowerUpRarity.EPIC
    duration = 10.0
    can_stack = true
    
    _customize_visual()

func _customize_visual() -> void:
    # 自定义外观
    pass

func _apply_effect(player: Node) -> void:
    # 应用效果到玩家
    print("Custom effect applied!")

func _remove_effect(player: Node) -> void:
    # 移除效果
    print("Custom effect removed!")
```

---

## 🎯 关卡设计建议

### 1. 道具放置策略

```gdscript
# 困难区域前放置加速/无敌
manager.spawn_power_up(
    PowerUpBase.PowerUpType.INVINCIBILITY,
    obstacle_zone_entrance
)

# 长距离路段放置加速
manager.spawn_power_up(
    PowerUpBase.PowerUpType.SPEED_BOOST,
    long_corridor_start
)

# 多道具区域放置磁铁
manager.spawn_power_up(
    PowerUpBase.PowerUpType.MAGNET,
    power_up_cluster_center
)
```

### 2. 动态难度调整

```gdscript
# 根据玩家表现调整道具生成
func adjust_difficulty(player_health: float):
    if player_health < 30:
        # 玩家血量低，增加护盾生成
        manager.set_rarity_weight(PowerUpBase.PowerUpRarity.UNCOMMON, 50)
    else:
        # 恢复正常权重
        manager.set_rarity_weight(PowerUpBase.PowerUpRarity.UNCOMMON, 30)
```

### 3. 竞技模式设计

```gdscript
# 多人竞速中的道具争夺
func setup_race_power_ups():
    # 在关键位置放置强力道具
    var key_positions = [
        checkpoint_1_position,
        shortcut_entrance,
        final_stretch_start
    ]
    
    for pos in key_positions:
        manager.spawn_power_up(
            PowerUpBase.PowerUpType.INVINCIBILITY,
            pos
        )
```

---

## 🔗 系统集成

### 与战斗系统集成

```gdscript
# 护盾吸收伤害
func take_damage(amount: float):
    if has_meta("shield"):
        var shield = get_meta("shield")
        shield._on_player_damaged(amount, false)
        return  # 伤害被护盾吸收
    
    # 无敌检查
    if has_meta("invincible") and get_meta("invincible"):
        return  # 无敌，不受伤
    
    # 正常受伤
    health -= amount
```

### 与UI系统集成

```gdscript
# 显示激活的道具
func _on_power_up_activated(power_up, player):
    var hud = get_node("/root/GameHUD")
    hud.show_power_up_icon(
        power_up.power_up_name,
        power_up.duration
    )
```

### 与障碍系统集成

```gdscript
# 障碍检测无敌状态
func _apply_effect(player: Node) -> void:
    if player.has_meta("invincible") and player.get_meta("invincible"):
        return  # 玩家无敌，障碍无效
    
    # 应用伤害
    player.take_damage(damage_amount)
```

---

## 📊 道具平衡

### 稀有度建议
- **Common** (50%): 基础增益（加速、磁铁）
- **Uncommon** (30%): 防御型（护盾）
- **Rare** (15%): 强力增益（无敌）
- **Epic** (4%): 特殊能力
- **Legendary** (1%): 超强效果

### 持续时间建议
- **短期** (3-5秒): 高强度效果（无敌、巨大化）
- **中期** (6-10秒): 平衡效果（加速、磁铁）
- **长期** (10-15秒): 弱化效果或次数限制（护盾）

---

## 🚀 性能优化

### 对象池

```gdscript
# 使用对象池减少频繁创建
var power_up_pool: Dictionary = {}

func get_pooled_power_up(type: PowerUpBase.PowerUpType):
    if not power_up_pool.has(type):
        power_up_pool[type] = []
    
    if power_up_pool[type].is_empty():
        return _create_new_power_up(type)
    else:
        return power_up_pool[type].pop_back()
```

### 视距剔除

```gdscript
# 远距离道具暂停动画
func _process(delta):
    for power_up in spawned_power_ups:
        var distance = player.global_position.distance_to(power_up.global_position)
        
        if distance > 50.0:
            power_up.process_mode = Node.PROCESS_MODE_DISABLED
        else:
            power_up.process_mode = Node.PROCESS_MODE_INHERIT
```

---

## ✅ 测试

运行测试: `godot --headless --script scripts/tests/phase_15_powerup_test.gd`

测试覆盖:
- ✓ PowerUpManager 基础功能
- ✓ 道具生成和注册
- ✓ SpeedBoost 加速效果
- ✓ Invincibility 无敌机制
- ✓ Shield 护盾吸收
- ✓ Magnet 磁铁吸引

---

## 🎨 扩展道具建议

### 未实现的道具类型
1. **DoubleJump** - 双倍跳跃能力
2. **Teleport** - 传送到检查点
3. **SlowTime** - 减缓时间流速
4. **GiantSize** - 巨大化（碾压障碍）
5. **Ghost** - 穿墙模式
6. **Rocket** - 火箭加速
7. **Freeze** - 冻结障碍

每种道具只需继承 `PowerUpBase` 并实现：
- `_initialize_power_up()` - 设置属性
- `_apply_effect()` - 应用效果
- `_remove_effect()` - 移除效果
- `_customize_visual()` - 自定义外观

---

## 🚀 下一步

**Phase 15 道具系统已完成！**

推荐继续:
- **Phase 16**: 音效系统（道具拾取音效、背景音乐）
- **Phase 17**: 关卡编辑器（可视化设计工具）
- **Phase 18**: 多人系统（网络同步、排行榜）
