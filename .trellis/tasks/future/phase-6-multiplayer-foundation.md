# Phase 6: Multiplayer Foundation

**Status**: 📋 Planning  
**Priority**: P2  
**Dependencies**: Phase 5 完成  
**Estimated Effort**: 6-8 weeks  
**Target Date**: TBD

---

## 概述

实现基础多人游戏能力，包括客户端-服务器架构、网络同步、匹配系统、基础反作弊。

## 前置条件

- ✅ Phase 1-5 已完成
- ⚠️ 需要服务器基础设施（AWS/GCP）
- ⚠️ 需要 Dedicated Server 导出配置
- ⚠️ 需要网络协议设计

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Rush 添加多人游戏能力：
1. 客户端-服务器架构（Authoritative Server）
2. 实时网络同步（位置、动画、战斗）
3. 匹配系统（房间/大厅）
4. 基础反作弊（服务器验证）
5. 网络优化（插值、预测）

### 用户故事

**作为玩家**：
- 我希望快速匹配到其他玩家
- 我希望看到其他玩家的实时动作
- 我希望网络延迟不影响体验
- 我希望游戏公平（无外挂）

**作为开发者**：
- 我希望网络代码易于维护
- 我希望服务器可横向扩展
- 我希望调试网络问题有工具
- 我希望带宽成本可控

### 非目标（本 Phase 不做）

- ❌ 大型 MMO（单房间限 8-16 人）
- ❌ 跨平台语音
- ❌ 复杂排名系统
- ❌ 战队/公会系统
- ❌ 云存档同步（Phase 7）

---

## Design (设计方案)

### 架构设计

```
Client (移动端)
    ↓ WebSocket / ENet
Game Server (Godot Dedicated Server)
    ↓ 权威逻辑
    ├── 位置同步
    ├── 战斗判定
    ├── 状态管理
    └── 反作弊
    ↓
Match Server (Go/Rust 微服务)
    ├── 房间管理
    ├── 匹配队列
    └── 玩家会话
    ↓
Database (PostgreSQL)
    ├── 玩家数据
    ├── 战绩记录
    └── 房间历史
```

### 网络拓扑

**Authority Model** - 服务器权威：

```
Client A → Input → Server → Validate → Broadcast
                      ↓
Client B ← State Update ← Server
```

**优势**：
- 服务器是唯一真相源
- 天然反作弊
- 易于实现

**劣势**：
- 服务器负载高
- 需要预测/插值优化

### 核心组件

#### 1. NetworkManager.gd (客户端)

```gdscript
class_name NetworkManager extends Node

signal connected_to_server()
signal disconnected_from_server()
signal player_joined(peer_id: int, player_name: String)
signal player_left(peer_id: int)

var peer: ENetMultiplayerPeer
var server_address: String = "127.0.0.1"
var server_port: int = 7777

func connect_to_server() -> Error
func disconnect_from_server() -> void
func send_input(input_data: Dictionary) -> void
func get_server_time() -> float  # 同步时间
```

#### 2. ServerNetworkManager.gd (服务器)

```gdscript
class_name ServerNetworkManager extends Node

signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)

var peer: ENetMultiplayerPeer
var port: int = 7777
var max_clients: int = 16

var connected_players: Dictionary = {}  # peer_id -> PlayerData

func start_server() -> Error
func stop_server() -> void
func broadcast_state_update(state: Dictionary) -> void
func kick_player(peer_id: int, reason: String) -> void
```

#### 3. StateReplicator.gd

```gdscript
class_name StateReplicator extends Node

# 服务器端：收集状态 → 序列化 → 广播
func capture_state() -> Dictionary:
    return {
        "tick": current_tick,
        "timestamp": Time.get_ticks_msec(),
        "players": _capture_players_state(),
        "projectiles": _capture_projectiles_state(),
    }

func broadcast_state() -> void:
    var state = capture_state()
    rpc("receive_state_update", state)

# 客户端：接收状态 → 插值 → 应用
@rpc("any_peer", "unreliable")
func receive_state_update(state: Dictionary) -> void:
    _apply_state_with_interpolation(state)
```

#### 4. ClientPrediction.gd

```gdscript
class_name ClientPrediction extends Node

# 客户端预测：立即响应本地输入，等服务器校正
var pending_inputs: Array[Dictionary] = []
var last_acked_tick: int = 0

func predict_movement(input: Dictionary) -> void:
    # 立即移动（乐观预测）
    apply_movement_locally(input)
    # 记录输入，等待服务器确认
    pending_inputs.append({
        "tick": current_tick,
        "input": input
    })
    # 发送到服务器
    NetworkManager.send_input(input)

func reconcile_with_server(server_state: Dictionary) -> void:
    # 服务器返回权威状态
    last_acked_tick = server_state.tick
    # 回滚到服务器位置
    apply_server_position(server_state.position)
    # 重放未确认的输入
    for input in pending_inputs:
        if input.tick > last_acked_tick:
            apply_movement_locally(input.input)
```

#### 5. InterpolationBuffer.gd

```gdscript
class_name InterpolationBuffer extends Node

# 缓冲区：存储最近 N 个状态快照
const BUFFER_SIZE = 3  # ~100ms @ 30 tick/s
var snapshots: Array[Dictionary] = []

func add_snapshot(state: Dictionary) -> void:
    snapshots.append(state)
    if snapshots.size() > BUFFER_SIZE:
        snapshots.pop_front()

func interpolate(render_time: float) -> Dictionary:
    # 在两个快照之间插值
    if snapshots.size() < 2:
        return snapshots[-1] if snapshots.size() > 0 else {}
    
    var from = snapshots[-2]
    var to = snapshots[-1]
    var t = (render_time - from.timestamp) / (to.timestamp - from.timestamp)
    t = clamp(t, 0.0, 1.0)
    
    return {
        "position": from.position.lerp(to.position, t),
        "rotation": from.rotation.slerp(to.rotation, t),
    }
```

### 数据同步策略

#### 同步频率

| 数据类型 | 频率 | 方式 | 优先级 |
|---------|------|-----|--------|
| 玩家位置 | 30 Hz | Unreliable | 高 |
| 玩家动画 | 15 Hz | Unreliable | 中 |
| 生命值 | Event | Reliable | 高 |
| 技能释放 | Event | Reliable | 高 |
| 聊天消息 | Event | Reliable | 低 |

#### 带宽优化

**压缩技术**：
1. **Delta Encoding** - 只发送变化的部分
2. **Quantization** - 降低浮点精度（位置 16-bit, 旋转 9-bit）
3. **Interest Management** - 只同步可见范围
4. **State Pruning** - 跳过静止对象

**示例**：

```gdscript
func quantize_position(pos: Vector3) -> PackedInt32Array:
    # 将 Vector3 压缩到 3 个 16-bit 整数
    return PackedInt32Array([
        int(pos.x * 100),  # 精度 0.01m
        int(pos.y * 100),
        int(pos.z * 100)
    ])

func dequantize_position(data: PackedInt32Array) -> Vector3:
    return Vector3(
        data[0] / 100.0,
        data[1] / 100.0,
        data[2] / 100.0
    )
```

**带宽估算**：

```
玩家位置: 12 bytes * 30 Hz * 8 players = 2.88 KB/s
玩家动画: 4 bytes * 15 Hz * 8 players = 0.48 KB/s
总计: ~3.4 KB/s 下行（客户端接收）
      ~0.4 KB/s 上行（客户端发送）
```

### 匹配系统

#### 房间模式

1. **快速匹配**
   - 自动分配房间
   - ELO 匹配（可选）
   - 超时进入 Bot 房间

2. **自定义房间**
   - 玩家创建房间
   - 房间码邀请
   - 可设置规则（地图、人数）

3. **好友房间**
   - 从好友列表邀请
   - 私密房间

#### 匹配流程

```
Client → Match Server: FindMatch(mode, region)
  ↓
Match Server: 查找可用房间
  ├─ 找到 → 返回 Game Server IP:Port
  └─ 未找到 → 创建新房间 → 启动 Game Server
  ↓
Client → Game Server: Connect(room_id, auth_token)
  ↓
Game Server: 验证 token → 加入房间
  ↓
Client: 开始游戏
```

#### Match Server API (REST)

```json
POST /api/v1/match/find
{
  "player_id": "uuid",
  "mode": "quick_match",
  "region": "us-west"
}

Response:
{
  "room_id": "room-12345",
  "server_address": "35.123.45.67",
  "server_port": 7777,
  "auth_token": "jwt-token"
}
```

### 反作弊策略

#### 服务器验证

1. **移动速度检测**
   ```gdscript
   func validate_movement(player_id: int, old_pos: Vector3, new_pos: Vector3, delta: float) -> bool:
       var distance = old_pos.distance_to(new_pos)
       var max_distance = player_stats.move_speed * delta * 1.1  # 10% 容错
       if distance > max_distance:
           kick_player(player_id, "Suspected speedhack")
           return false
       return true
   ```

2. **技能冷却验证**
   ```gdscript
   func validate_skill_cast(player_id: int, skill_id: String) -> bool:
       var last_cast = player_skill_cooldowns[player_id][skill_id]
       var cooldown = skill_data[skill_id].cooldown
       var elapsed = Time.get_ticks_msec() - last_cast
       if elapsed < cooldown * 1000:
           kick_player(player_id, "Skill cooldown violation")
           return false
       return true
   ```

3. **伤害来源验证**
   ```gdscript
   func validate_damage(attacker_id: int, target_id: int, damage: float) -> bool:
       var distance = get_distance_between_players(attacker_id, target_id)
       var weapon_range = player_weapons[attacker_id].range
       if distance > weapon_range * 1.2:
           log_suspicious_activity(attacker_id, "Damage out of range")
           return false
       return true
   ```

#### 客户端保护

1. **代码混淆** - GDScript 编译为 bytecode
2. **资源加密** - PCK 文件加密
3. **完整性检查** - 启动时校验文件哈希

---

## Implementation Plan

### Task 1: Network Foundation (5 days)

**文件**：
- `scripts/network/network_manager.gd`
- `scripts/network/server_network_manager.gd`
- `scenes/network/network_test.tscn`

**实现**：
1. ENet 连接建立
2. 心跳/超时检测
3. 重连机制
4. 基础 RPC 测试

**验证**：
- [ ] 客户端成功连接服务器
- [ ] 断线后自动重连
- [ ] RPC 消息正确收发

### Task 2: State Synchronization (5 days)

**文件**：
- `scripts/network/state_replicator.gd`
- `scripts/network/sync_component.gd`

**实现**：
1. 状态快照系统
2. 增量编码
3. 优先级队列（可靠/不可靠）
4. 序列化/反序列化

**验证**：
- [ ] 位置同步延迟 < 100ms
- [ ] 动画状态正确同步
- [ ] 带宽 < 5 KB/s per client

### Task 3: Client Prediction (4 days)

**文件**：
- `scripts/network/client_prediction.gd`
- `scripts/network/input_buffer.gd`

**实现**：
1. 输入缓冲
2. 本地预测
3. 服务器校正
4. 输入重放

**验证**：
- [ ] 本地移动无延迟感
- [ ] 服务器校正平滑
- [ ] 预测误差 < 10cm

### Task 4: Interpolation & Smoothing (4 days)

**文件**：
- `scripts/network/interpolation_buffer.gd`
- `scripts/network/lag_compensation.gd`

**实现**：
1. 插值缓冲区
2. 时间同步（NTP-like）
3. 延迟补偿（Lag Compensation）
4. 平滑算法

**验证**：
- [ ] 其他玩家移动流畅
- [ ] 200ms 延迟下仍可玩
- [ ] 无明显瞬移

### Task 5: Combat Synchronization (5 days)

**实现**：
1. 攻击命中判定（服务器权威）
2. 技能释放同步
3. 伤害计算同步
4. 生命值同步

**验证**：
- [ ] 攻击命中与视觉一致
- [ ] 伤害数字准确
- [ ] 无双杀 Bug（两边都以为赢了）

### Task 6: Dedicated Server Setup (3 days)

**文件**：
- `export_presets.cfg` (Dedicated Server preset)
- `scripts/server/server_main.gd`

**配置**：
1. Headless 模式导出
2. 命令行参数解析（--port, --max-players）
3. 日志系统
4. 崩溃恢复

**验证**：
- [ ] 服务器可 Headless 运行
- [ ] 命令行参数生效
- [ ] 崩溃日志记录

### Task 7: Match Server (Microservice) (7 days)

**技术栈**: Go / Rust  
**文件**：
- `server/match-server/main.go`
- `server/match-server/matchmaking.go`
- `server/match-server/room_manager.go`

**实现**：
1. REST API（FindMatch, CreateRoom）
2. WebSocket（房间状态推送）
3. Game Server 生命周期管理
4. 数据库集成（PostgreSQL）

**验证**：
- [ ] API 响应时间 < 100ms
- [ ] 匹配成功率 > 95%
- [ ] 支持 100 并发匹配请求

### Task 8: Anti-Cheat (4 days)

**实现**：
1. 移动验证
2. 技能冷却验证
3. 伤害来源验证
4. 异常行为日志

**验证**：
- [ ] Speedhack 被检测并踢出
- [ ] 技能 CD 作弊被拦截
- [ ] 正常玩家不误判

### Task 9: Network Debugging Tools (3 days)

**工具**：
- Network Profiler（显示带宽、延迟、丢包）
- Packet Logger（记录所有网络消息）
- Latency Simulator（模拟延迟/丢包）

**验证**：
- [ ] 实时显示网络统计
- [ ] 可回放网络事件
- [ ] 可模拟糟糕网络

### Task 10: Testing & Optimization (6 days)

**测试场景**：
- 2 玩家对战
- 8 玩家混战
- 高延迟测试（500ms）
- 丢包测试（5% packet loss）

**压力测试**：
- 单服务器最大玩家数
- Match Server 并发能力
- 长时间运行稳定性

**优化**：
- 减少带宽
- 降低服务器 CPU
- 优化内存占用

**验证**：
- [ ] 8 玩家同屏稳定
- [ ] 500ms 延迟可玩
- [ ] 服务器可运行 24h+

---

## Acceptance Criteria

### 功能验收

- [ ] 客户端-服务器连接稳定
- [ ] 玩家位置/动画正确同步
- [ ] 战斗系统网络化
- [ ] 匹配系统可用
- [ ] 基础反作弊生效

### 技术验收

- [ ] 客户端预测 + 服务器校正
- [ ] 插值缓冲平滑移动
- [ ] 带宽 < 5 KB/s per client
- [ ] 服务器 tick rate ≥ 30 Hz
- [ ] 延迟补偿误差 < 50ms

### 性能验收

- [ ] 单服务器支持 16 玩家
- [ ] 服务器 CPU < 50%（16 玩家）
- [ ] 服务器内存 < 500MB
- [ ] Match Server 支持 1000 并发

### 用户体验验收

- [ ] 匹配时间 < 30 秒
- [ ] 游戏无卡顿（< 200ms 延迟）
- [ ] 重连后状态恢复
- [ ] 作弊行为被检测

---

## Infrastructure

### Game Server (Godot Dedicated Server)

**部署方式**：
- Docker 容器化
- Kubernetes 编排
- Auto-scaling（根据房间数）

**资源需求**（单实例）：
- CPU: 1 Core
- RAM: 512 MB
- 网络: 1 Mbps
- 支持: 16 玩家

### Match Server (Microservice)

**技术栈**: Go 1.21 + PostgreSQL 15  
**部署**: AWS ECS / Google Cloud Run

**资源需求**：
- CPU: 2 Cores
- RAM: 1 GB
- 数据库: RDS (PostgreSQL)

### 数据库 Schema

```sql
CREATE TABLE players (
    id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    elo INT DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rooms (
    id VARCHAR(20) PRIMARY KEY,
    mode VARCHAR(20) NOT NULL,
    server_address VARCHAR(45) NOT NULL,
    server_port INT NOT NULL,
    max_players INT NOT NULL,
    current_players INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'waiting',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE match_history (
    id UUID PRIMARY KEY,
    room_id VARCHAR(20) REFERENCES rooms(id),
    players JSONB NOT NULL,
    winner_id UUID,
    duration_seconds INT,
    ended_at TIMESTAMP DEFAULT NOW()
);
```

---

## Risks & Mitigations

### Risk 1: 网络复杂度高

**影响**: 高（开发周期延长）  
**缓解**:
- 使用成熟方案（ENet, Godot MultiplayerAPI）
- 参考开源项目（Netcode for GameObjects）
- 充分测试网络边缘情况

### Risk 2: 服务器成本

**影响**: 中（运营成本）  
**缓解**:
- 使用按需实例（AWS Fargate）
- 自动缩放（闲时关闭服务器）
- 区域化部署（降低跨区流量）

### Risk 3: 作弊猖獗

**影响**: 高（用户流失）  
**缓解**:
- 服务器权威架构（天然防御）
- 行为分析（异常检测）
- 社区举报系统

### Risk 4: 延迟体验差

**影响**: 高（用户体验）  
**缓解**:
- 区域化服务器（降低物理延迟）
- 客户端预测 + 插值
- 延迟补偿技术

---

## Out of Scope (Phase 7+)

- ❌ 语音聊天
- ❌ 观战系统
- ❌ 录像回放
- ❌ 排行榜系统
- ❌ 赛季/段位系统

---

## Estimated Timeline

```
Week 1-2: Network Foundation + State Sync
Week 3: Client Prediction + Interpolation
Week 4: Combat Sync + Dedicated Server
Week 5-6: Match Server (Microservice)
Week 7: Anti-Cheat + Tools
Week 8: Testing & Optimization
```

**Total**: 6-8 weeks

---

## References

- Godot High-Level Multiplayer
- ENet Protocol
- Source Engine Networking
- Overwatch Netcode GDC Talk
- Rocket League Networking

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 依赖 Phase 5 完成
