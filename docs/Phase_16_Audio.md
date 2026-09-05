# Phase 16 - 音效系统

## 概述

音效系统为游戏提供完整的音频支持，包括音乐播放、音效管理、音量控制和3D空间音效。

## 核心组件

### 1. AudioManager (音效管理器)

主要的音频管理系统，负责所有音频资源的加载、播放和控制。

**位置**: `scripts/audio/audio_manager.gd`

#### 主要功能

- **音乐管理**: 背景音乐播放、淡入淡出、暂停恢复
- **音效管理**: 2D/3D音效播放、音效池管理
- **音量控制**: 分总线音量控制（Master、Music、SFX、UI）
- **资源缓存**: 音频资源预加载和缓存
- **设置持久化**: 与存档系统集成

#### 音频总线

```gdscript
Master (主音量)
├── Music (音乐)
├── SFX (游戏音效)
└── UI (界面音效)
```

#### 使用示例

```gdscript
# 获取音效管理器（自动加载）
var audio = get_node("/root/AudioManager")

# 播放音乐
audio.play_music("menu_theme", true)  # 带淡入
audio.play_music("battle_theme", false)  # 不淡入

# 停止音乐
audio.stop_music(true)  # 带淡出

# 暂停/恢复音乐
audio.pause_music()
audio.resume_music()

# 播放音效
audio.play_sfx("jump", 0.0, 1.0)  # 名称、音量、音高
audio.play_sfx("explosion", 5.0, 1.2)  # 提高音量和音高

# 播放3D音效
audio.play_sfx_3d("footstep", Vector3(10, 0, 5), 0.0)

# 播放UI音效
audio.play_ui_sfx("button_click")

# 便捷方法
audio.play_powerup_collect()
audio.play_obstacle_hit()
audio.play_button_click()
audio.play_level_complete()

# 音量控制
audio.set_master_volume(0.8)
audio.set_music_volume(0.6)
audio.set_sfx_volume(1.0)
audio.set_ui_volume(0.9)

# 查询
var volume = audio.get_master_volume()
var is_playing = audio.is_music_playing()
var current = audio.get_current_music()

# 预加载资源
audio.preload_sfx(["jump", "land", "hurt"])
audio.preload_music(["menu", "game", "boss"])
```

### 2. SoundEmitter (音效发射器)

用于游戏对象的音效播放组件，可以作为子节点添加到任何游戏对象。

**位置**: `scripts/audio/sound_emitter.gd`

#### 功能

- 为游戏对象提供音效播放能力
- 支持2D和3D音效
- 音高随机化
- 预定义音效类型

#### 使用示例

```gdscript
# 添加到玩家节点
var emitter = SoundEmitter.new()
player.add_child(emitter)

# 配置
emitter.use_3d_sound = true
emitter.volume_offset = -5.0
emitter.pitch_randomness = 0.2

# 播放音效
emitter.play_jump()
emitter.play_land()
emitter.play_hurt()
emitter.play_powerup_collect()

# 或使用通用方法
emitter.play(SoundEmitter.SoundType.PLAYER_JUMP)
```

#### 音效类型

```gdscript
enum SoundType {
    PLAYER_JUMP,
    PLAYER_LAND,
    PLAYER_HURT,
    PLAYER_DIE,
    POWERUP_COLLECT,
    OBSTACLE_HIT,
    CHECKPOINT_REACH,
    BUTTON_CLICK,
    BUTTON_HOVER,
    LEVEL_START,
    LEVEL_COMPLETE,
    LEVEL_FAILED,
    COUNTDOWN,
    GO,
}
```

## 音频资源结构

```
audio/
├── music/
│   ├── menu_theme.ogg
│   ├── game_theme.ogg
│   ├── boss_theme.ogg
│   └── victory.ogg
└── sfx/
    ├── player_jump.wav
    ├── player_land.wav
    ├── player_hurt.wav
    ├── powerup_collect.wav
    ├── obstacle_hit.wav
    ├── button_click.wav
    ├── countdown.wav
    └── level_complete.wav
```

## 音效池系统

AudioManager 使用音效池来高效管理同时播放的音效：

- 每种音效维护一个播放器池（默认5个）
- 自动复用空闲的播放器
- 避免频繁创建/销毁音频节点
- 支持同时播放多个相同音效

```gdscript
# 配置池大小
audio_manager.sfx_pool_size = 10

# 即使快速连续调用，也能正确播放
for i in range(10):
    audio.play_sfx("gunshot")
```

## 音量系统

### 线性到分贝转换

音量值使用线性 0.0-1.0 范围，内部自动转换为分贝：

```gdscript
# 用户友好的线性值
audio.set_master_volume(0.5)  # 50%

# 自动转换为分贝
# 0.0 → -80dB (静音)
# 0.5 → -6dB
# 1.0 → 0dB (最大)
```

### 音量层级

```
Master Volume (影响所有)
  ├── Music Volume (只影响音乐)
  ├── SFX Volume (只影响游戏音效)
  └── UI Volume (只影响界面音效)
```

## 与其他系统集成

### 与 GameFlowManager 集成

```gdscript
# GameFlowManager 控制音乐切换
func _on_state_changed(new_state):
    match new_state:
        GameState.MAIN_MENU:
            audio.play_music("menu_theme")
        GameState.PLAYING:
            audio.play_music("game_theme")
        GameState.LEVEL_COMPLETE:
            audio.play_sfx("level_complete")
```

### 与 SaveSystem 集成

```gdscript
# 音量设置自动保存和加载
audio.set_master_volume(0.8)  # 自动保存到存档

# 启动时自动加载
# AudioManager._ready() 会从存档加载音量设置
```

### 与游戏对象集成

```gdscript
# 玩家
extends CharacterBody3D

var sound_emitter: SoundEmitter

func _ready():
    sound_emitter = $SoundEmitter

func jump():
    velocity.y = jump_speed
    sound_emitter.play_jump()

func _on_hit():
    sound_emitter.play_hurt()

# 道具
extends Area3D

func _on_body_entered(body):
    if body.name == "Player":
        get_node("/root/AudioManager").play_powerup_collect()
        queue_free()

# 障碍物
extends StaticBody3D

func _on_collision(body):
    var audio = get_node("/root/AudioManager")
    audio.play_sfx_3d("obstacle_hit", global_position)
```

## 性能优化

1. **资源预加载**: 在场景加载时预加载常用音效
2. **音效池**: 复用播放器，避免频繁创建
3. **缓存系统**: 已加载的音频资源保持在内存中
4. **3D音效优化**: 只在需要空间音效时使用3D播放器

```gdscript
# 场景加载时预加载
func _ready():
    var audio = get_node("/root/AudioManager")
    
    # 预加载当前关卡需要的音效
    audio.preload_sfx([
        "jump", "land", "hurt",
        "powerup_collect", "obstacle_hit"
    ])
    
    # 预加载音乐
    audio.preload_music(["game_theme", "boss_theme"])
```

## 调试和测试

### 测试脚本

运行完整测试：

```bash
godot --headless --script scripts/tests/phase_16_audio_test.gd
```

### 测试覆盖

- AudioManager 初始化
- 音量控制
- 音效播放
- 音乐播放
- SoundEmitter 功能
- 音效池系统

## 最佳实践

### 1. 使用便捷方法

```gdscript
# 推荐
audio.play_powerup_collect()

# 而不是
audio.play_sfx("powerup_collect", 0.0, randf_range(0.9, 1.1))
```

### 2. UI音效使用UI总线

```gdscript
# UI元素应该使用 play_ui_sfx
button.pressed.connect(func():
    audio.play_ui_sfx("button_click")
)
```

### 3. 3D音效用于空间定位

```gdscript
# 需要空间感的音效使用3D
audio.play_sfx_3d("explosion", bomb_position)

# 不需要空间感的使用2D
audio.play_sfx("ui_confirm")
```

### 4. 音乐淡入淡出

```gdscript
# 平滑过渡
audio.play_music("new_track", true)  # 淡入

# 快速切换（如死亡）
audio.play_music("death_music", false)
```

### 5. 音高随机化

```gdscript
# 避免重复感
audio.play_sfx("footstep", 0.0, randf_range(0.95, 1.05))

# 或使用 SoundEmitter 的自动随机化
emitter.pitch_randomness = 0.1
```

## API 参考

### AudioManager

#### 音乐方法

- `play_music(track_name: String, fade_in: bool = true)`
- `stop_music(fade_out: bool = true)`
- `pause_music()`
- `resume_music()`
- `is_music_playing() -> bool`
- `get_current_music() -> String`

#### 音效方法

- `play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0)`
- `play_ui_sfx(sfx_name: String)`
- `play_sfx_3d(sfx_name: String, world_position: Vector3, volume_db: float = 0.0)`

#### 音量方法

- `set_master_volume(volume: float)`
- `set_music_volume(volume: float)`
- `set_sfx_volume(volume: float)`
- `set_ui_volume(volume: float)`
- `get_master_volume() -> float`
- `get_music_volume() -> float`
- `get_sfx_volume() -> float`
- `get_ui_volume() -> float`

#### 资源方法

- `preload_sfx(sfx_names: Array)`
- `preload_music(track_names: Array)`
- `clear_cache()`

#### 便捷方法

- `play_powerup_collect()`
- `play_obstacle_hit()`
- `play_button_click()`
- `play_button_hover()`
- `play_level_complete()`
- `play_level_failed()`
- `play_countdown()`
- `play_go()`

### SoundEmitter

#### 方法

- `play(sound_type: SoundType)`
- `play_jump()`
- `play_land()`
- `play_hurt()`
- `play_die()`
- `play_powerup_collect()`
- `play_obstacle_hit()`
- `play_checkpoint_reach()`

#### 属性

- `use_3d_sound: bool` - 是否使用3D音效
- `volume_offset: float` - 音量偏移（分贝）
- `pitch_randomness: float` - 音高随机范围

## 信号

### AudioManager

- `music_changed(track_name: String)` - 音乐切换时发出
- `sfx_played(sfx_name: String)` - 音效播放时发出
- `volume_changed(bus: String, volume: float)` - 音量改变时发出

## 下一步

音效系统已完成，建议继续：

1. **Phase 17 - 关卡编辑器**: 可视化关卡设计工具
2. **Phase 20 - 粒子效果系统**: 增强视觉反馈
3. **Phase 18 - 多人系统**: 实现多人对战

详见 `docs/NEXT_STEPS.md`
