# Phase 6: UI/音效/相机系统 - PRD

**版本**: 1.0  
**状态**: Planning  
**负责人**: AI Coding Team  
**预计时间**: 2周  
**依赖**: Phase 4.5 视觉升级

---

## 🎯 目标

将"可展示的原型"升级为"可录制演示视频的版本"：
- 专业级UI界面
- 完整音效反馈
- 电影级相机体验
- 可发布到社交媒体展示

---

## 📋 功能需求

### 1. UI系统

#### 1.1 战斗HUD
**优先级**: P0

**功能点**:
- 血条显示（平滑过渡动画）
- 护盾条显示（有护盾时显示）
- 血量数字（当前/最大）
- 技能UI（4个技能按钮）
- 技能冷却指示器（圆形填充）
- Combo计数器（连击显示）
- 伤害飘字（受伤时）
- 治疗飘字（恢复时）

**用户体验**:
- 血条变化平滑过渡（0.2秒）
- 技能可用/不可用清晰区分
- Combo数字放大动画
- 飘字向上漂浮后淡出

**技术实现**:
```gdscript
# scripts/ui/game_hud.gd
extends CanvasLayer
class_name GameHUD

func update_health(current, max_value, shield, max_shield)
func update_skill_cooldown(skill_key, remaining, total)
func add_combo()
func show_damage_number(amount, position, is_crit)
```

#### 1.2 菜单系统
**优先级**: P1

**功能点**:
- 主菜单（开始/设置/退出）
- 暂停菜单（继续/重新开始/返回主菜单）
- 设置菜单（音量/画质/控制）

**UI风格**:
- 派对游戏风格（Fall Guys参考）
- 圆润按钮
- 明亮颜色
- 动画过渡

---

### 2. 音效系统

#### 2.1 音效管理器
**优先级**: P0

**功能点**:
- 音效池（避免重复创建AudioStreamPlayer）
- 2D音效（UI、系统）
- 3D音效（战斗、环境，空间化）
- 音量控制（分离SFX/Music）
- 音效变调（增加真实感）

**音效类型**:
```gdscript
enum SFXType {
    FOOTSTEP,      # 脚步声
    JUMP,          # 跳跃
    LAND,          # 落地
    ATTACK_LIGHT,  # 轻攻击
    ATTACK_HEAVY,  # 重攻击
    SKILL_CAST,    # 技能释放
    HIT_RECEIVED,  # 受击
    DEATH,         # 死亡
    UI_CLICK,      # UI点击
    UI_HOVER,      # UI悬停
}
```

#### 2.2 音乐系统
**优先级**: P1

**功能点**:
- 背景音乐循环
- 音乐淡入淡出（场景切换）
- 动态音乐（可选，战斗强度响应）

**音乐类型**:
- 主菜单音乐（轻松愉快）
- 战斗音乐（激烈紧张）
- 胜利音乐（欢快庆祝）
- 失败音乐（低沉遗憾）

**资源获取**:
- Freesound.org（免费音效）
- OpenGameArt.org（免费游戏音乐）
- 付费音效包（如需高质量）

---

### 3. 相机系统

#### 3.1 相机控制
**优先级**: P0

**功能点**:
- 平滑跟随（SpringArm3D）
- 延迟跟随（不晃动）
- 碰撞检测（不穿墙）
- 高度调整（战斗时拉远）
- 前瞻跟随（朝向方向）

**技术参数**:
```gdscript
@export var follow_speed: float = 10.0
@export var look_ahead_distance: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 15.0
@export var height_offset: float = 3.0
```

#### 3.2 相机震动
**优先级**: P1

**功能点**:
- 攻击震动（小幅度0.1）
- 受击震动（中等幅度0.3）
- 技能震动（大幅度0.5）
- Boss震动（超大幅度1.0）

**实现方式**:
- 随机偏移Camera3D.position
- 强度衰减（shake_decay）
- 自动归位

#### 3.3 相机特效
**优先级**: P2

**功能点**:
- FOV变化（冲刺时增大，速度感）
- 慢动作（终结技，Engine.time_scale）
- 受击闪红（边缘红光，需后处理）
- 死亡黑白（生命结束，需后处理）

---

## 🏗️ 架构设计

### 系统集成

```
GameManager (scripts/core/game_manager.gd)
├── GameHUD (scripts/ui/game_hud.gd)
├── AudioManager (scripts/audio/audio_manager.gd)
└── CameraController (scripts/camera/camera_controller.gd)

游戏逻辑通过 GameManager 统一调度
```

### 回调机制

```gdscript
# GameManager 接收游戏事件，分发到各系统

func on_player_damaged(damage, current_hp, max_hp):
    hud.update_health(...)
    audio.play_sfx(SFXType.HIT_RECEIVED)
    camera.add_shake(0.3)

func on_player_attack(combo_count):
    audio.play_sfx(SFXType.ATTACK_LIGHT)
    camera.add_shake(0.1)
    hud.add_combo()

func on_player_skill_cast(skill_id):
    audio.play_sfx(SFXType.SKILL_CAST)
    camera.add_shake(0.5)
```

---

## 📂 文件结构

```
yolk-rush/
├── scripts/
│   ├── ui/
│   │   ├── game_hud.gd          ✅ 已完成
│   │   ├── main_menu.gd         ⏳ TODO
│   │   ├── pause_menu.gd        ⏳ TODO
│   │   └── settings_menu.gd     ⏳ TODO
│   ├── audio/
│   │   └── audio_manager.gd     ✅ 已完成
│   ├── camera/
│   │   └── camera_controller.gd ✅ 已完成
│   └── core/
│       └── game_manager.gd      ✅ 已完成
│
├── scenes/
│   └── ui/
│       ├── game_hud.tscn        ⏳ TODO
│       ├── main_menu.tscn       ⏳ TODO
│       ├── pause_menu.tscn      ⏳ TODO
│       └── settings_menu.tscn   ⏳ TODO
│
├── audio/
│   ├── sfx/
│   │   ├── combat/              ⏳ TODO（音效文件）
│   │   ├── movement/            ⏳ TODO
│   │   └── ui/                  ⏳ TODO
│   └── music/
│       ├── menu.ogg             ⏳ TODO
│       ├── battle.ogg           ⏳ TODO
│       ├── victory.ogg          ⏳ TODO
│       └── defeat.ogg           ⏳ TODO
```

---

## 🧪 测试计划

### 自动化测试
✅ `tools/test_phase_6_systems.py`
- 脚本存在性检查
- 架构检查（继承关系）
- 9/9 测试通过

### 人工测试
⏳ TODO
- [ ] UI显示测试（血条、技能、Combo）
- [ ] 音效播放测试（所有SFX类型）
- [ ] 相机跟随测试（平滑性、不穿墙）
- [ ] 相机震动测试（不同强度）
- [ ] 完整战斗循环（UI + Audio + Camera）

---

## 🎯 验收标准

### P0（必须完成）
- [x] GameHUD脚本完成
- [x] AudioManager脚本完成
- [x] CameraController脚本完成
- [x] GameManager集成完成
- [ ] HUD场景文件（game_hud.tscn）
- [ ] 基础音效资源（至少5个）
- [ ] 相机跟随实际测试

### P1（应该完成）
- [ ] 菜单系统（主菜单、暂停菜单）
- [ ] 环境音效（风声、脚步声）
- [ ] 相机震动效果
- [ ] Combo显示

### P2（可以完成）
- [ ] 动态音乐系统
- [ ] 后处理特效（黑白、闪红）
- [ ] 慢动作效果
- [ ] 小地图

---

## 📊 当前状态

### 已完成 ✅
- 核心脚本框架（4个）
- VFX系统（Phase 4.5）
- 装饰系统（Phase 4.5）
- 自动化测试（9/9通过）

### 进行中 🔄
- 无

### 待开始 ⏳
- UI场景文件
- 音频资源收集
- 实际测试集成

---

## 🚀 下一步行动

1. **立即开始**（本周）
   - 创建UI场景文件（.tscn）
   - 收集免费音效资源
   - 集成到现有游戏场景

2. **短期目标**（1周内）
   - 完成P0验收标准
   - 实际测试所有系统
   - 录制第一版演示视频

3. **中期目标**（2周内）
   - 完成P1验收标准
   - 菜单系统完整
   - 可发布演示视频

---

**更新**: 2026-09-05  
**下一次审查**: 实现完成时
