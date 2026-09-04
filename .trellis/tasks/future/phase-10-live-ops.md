# Phase 10: Live Operations & Endgame

**Status**: 📋 Planning  
**Priority**: P4  
**Dependencies**: Phase 1-9 完成  
**Estimated Effort**: 持续运营  
**Target Date**: 游戏上线后

---

## 概述

实现游戏的长期运营系统，包括赛季系统、跨服匹配、公会战、世界 Boss、限时活动、数据分析、运营工具。

## 前置条件

- ✅ Phase 1-9 全部完成
- ✅ 游戏正式上线
- ✅ 玩家基数稳定（DAU > 10,000）
- ⚠️ 需要运营团队（24/7）
- ⚠️ 需要数据分析师
- ⚠️ 需要活动策划

---

## PRD (Product Requirements Document)

### 目标

保持游戏长期活力和玩家留存：
1. 赛季系统（Season System）
2. 跨服匹配（Cross-Server）
3. 公会战（Guild vs Guild）
4. 世界 Boss（World Boss）
5. 限时活动（Events）
6. 数据驱动运营（Analytics）
7. 运营工具（GM Tools）

### 核心指标

**留存指标**：
- 次日留存 > 40%
- 7 日留存 > 20%
- 30 日留存 > 10%

**活跃指标**：
- DAU (Daily Active Users)
- MAU (Monthly Active Users)
- 平均在线时长 > 45 分钟

**收入指标**：
- ARPU (Average Revenue Per User)
- ARPPU (Average Revenue Per Paying User)
- 付费转化率 > 2%

**社交指标**：
- 公会活跃度 > 60%
- 好友互动率 > 30%
- 聊天活跃度 > 40%

### 非目标

- ❌ 真实货币交易市场
- ❌ 区块链/NFT
- ❌ 第三方广告联盟

---

## Design (设计方案)

### 架构设计

```
LiveOpsSystem
    ├── SeasonSystem (赛季系统)
    │   ├── SeasonManager (赛季管理)
    │   ├── SeasonPass (赛季通行证)
    │   ├── SeasonReset (赛季重置)
    │   └── SeasonRewards (赛季奖励)
    ├── CrossServerSystem (跨服系统)
    │   ├── ServerCluster (服务器集群)
    │   ├── CrossServerMatch (跨服匹配)
    │   └── DataSync (数据同步)
    ├── GuildWarSystem (公会战)
    │   ├── GuildWarScheduler (战斗调度)
    │   ├── TerritoryControl (领地控制)
    │   └── GuildRanking (公会排名)
    ├── WorldBossSystem (世界 Boss)
    │   ├── BossSpawner (Boss 生成)
    │   ├── DamageTracker (伤害统计)
    │   └── RewardDistributor (奖励分发)
    ├── EventSystem (活动系统)
    │   ├── EventScheduler (活动调度)
    │   ├── EventTypes (活动类型)
    │   └── EventRewards (活动奖励)
    ├── AnalyticsSystem (数据分析)
    │   ├── EventTracking (事件追踪)
    │   ├── FunnelAnalysis (漏斗分析)
    │   ├── ABTesting (A/B 测试)
    │   └── Dashboard (数据看板)
    └── GMToolsSystem (GM 工具)
        ├── PlayerManagement (玩家管理)
        ├── ItemDistribution (物品发放)
        ├── BanSystem (封禁系统)
        └── LiveConfig (热更新配置)
```

### 核心组件

#### 1. SeasonSystem.gd

```gdscript
class_name SeasonSystem extends Node

class Season:
    var season_id: String
    var season_number: int
    var start_date: int
    var end_date: int
    var theme: String
    var reset_rankings: bool = true
    var reset_gear: bool = false  # 是否重置装备
    var rewards: Dictionary

var current_season: Season
var season_history: Array[Season] = []

signal season_started(season: Season)
signal season_ending_soon(days_left: int)
signal season_ended(season: Season)
signal season_rewards_distributed()

func start_new_season(season: Season) -> void:
    # 结算上一赛季
    if current_season:
        finalize_previous_season()
    
    current_season = season
    
    # 重置系统
    if season.reset_rankings:
        reset_rankings()
    
    if season.reset_gear:
        reset_player_gear()
    
    # 通知玩家
    season_started.emit(season)
    
    # 开启赛季监控
    start_season_countdown()

func finalize_previous_season() -> void:
    # 快照最终排名
    var final_rankings = LeaderboardSystem.snapshot_all_rankings()
    
    # 计算并发放赛季奖励
    distribute_season_rewards(final_rankings)
    
    # 归档
    season_history.append(current_season)
    season_ended.emit(current_season)

func distribute_season_rewards(rankings: Dictionary) -> void:
    for leaderboard_type in rankings:
        var top_players = rankings[leaderboard_type]
        
        for i in range(top_players.size()):
            var player = top_players[i]
            var rank = i + 1
            var rewards = calculate_season_rewards(leaderboard_type, rank)
            
            # 发放奖励（邮件）
            MailSystem.send_mail(
                player.user_id,
                "赛季奖励",
                "恭喜你在赛季结束时排名第 %d！" % rank,
                rewards
            )
    
    season_rewards_distributed.emit()

func reset_rankings() -> void:
    # 软重置：降低 20%，保留基础实力
    PvPSystem.soft_reset_ratings(0.8)
    
    # 清空赛季专属排行榜
    LeaderboardSystem.clear_seasonal_rankings()

func reset_player_gear() -> void:
    # 硬重置：所有装备转为赛季积分
    # 用于"新赛季，新开始"模式
    pass
```

#### 2. CrossServerSystem.gd

```gdscript
class_name CrossServerSystem extends Node

enum ServerRegion {
    NA_WEST,
    NA_EAST,
    EU,
    ASIA,
    CN,
}

class ServerInfo:
    var server_id: String
    var region: ServerRegion
    var name: String
    var player_count: int
    var status: String  # "online", "maintenance"
    var latency_ms: int

var current_server: ServerInfo
var available_servers: Array[ServerInfo] = []
var cross_server_enabled: bool = false

signal cross_server_match_found(server: ServerInfo)

func enable_cross_server() -> void:
    cross_server_enabled = true
    discover_servers()

func discover_servers() -> void:
    # 向调度服务器查询可用服务器列表
    var response = await NetworkManager.send_rpc_async("discover_servers", {
        "region": current_server.region,
        "max_latency_ms": 150
    })
    
    available_servers = response.servers

func queue_cross_server_match(mode: String) -> void:
    if not cross_server_enabled:
        return
    
    # 扩大匹配池到跨服
    NetworkManager.send_rpc("queue_cross_server", {
        "user_id": PlayerProfile.user_id,
        "mode": mode,
        "preferred_servers": available_servers.map(func(s): return s.server_id)
    })

func transfer_to_server(server_id: String) -> void:
    # 玩家数据打包
    var player_data = PlayerProfile.serialize_for_transfer()
    
    # 请求转服
    var response = await NetworkManager.send_rpc_async("transfer_server", {
        "from_server": current_server.server_id,
        "to_server": server_id,
        "player_data": player_data
    })
    
    if response.success:
        # 重连到新服务器
        NetworkManager.reconnect(response.new_connection_url)
```

#### 3. GuildWarSystem.gd

```gdscript
class_name GuildWarSystem extends Node

enum WarPhase {
    PREPARATION,   # 准备阶段（报名）
    MATCHMAKING,   # 匹配阶段
    BATTLE,        # 战斗阶段
    ENDED,         # 结算阶段
}

class GuildWar:
    var war_id: String
    var guild_a: String
    var guild_b: String
    var start_time: int
    var end_time: int
    var phase: WarPhase
    var score_a: int = 0
    var score_b: int = 0
    var territories: Array[Territory]

class Territory:
    var territory_id: String
    var name: String
    var position: Vector2
    var controlling_guild: String = ""
    var capture_progress: float = 0.0
    var resource_bonus: Dictionary

var active_wars: Array[GuildWar] = []
var guild_war_schedule: Array[int] = []  # 每周固定时间

signal war_started(war: GuildWar)
signal territory_captured(territory: Territory, guild_id: String)
signal war_ended(war: GuildWar, winner: String)

func schedule_guild_war() -> void:
    # 每周六 20:00-22:00
    var now = Time.get_datetime_dict_from_system()
    if now.weekday == 6 and now.hour == 20:
        start_matchmaking_phase()

func start_matchmaking_phase() -> void:
    # 按公会等级匹配
    var eligible_guilds = get_eligible_guilds()
    var matched_pairs = match_guilds_by_level(eligible_guilds)
    
    for pair in matched_pairs:
        create_guild_war(pair[0], pair[1])

func create_guild_war(guild_a_id: String, guild_b_id: String) -> GuildWar:
    var war = GuildWar.new()
    war.war_id = generate_war_id()
    war.guild_a = guild_a_id
    war.guild_b = guild_b_id
    war.start_time = Time.get_unix_time_from_system() + 300  # 5 分钟准备
    war.end_time = war.start_time + 7200  # 2 小时战斗
    war.phase = WarPhase.PREPARATION
    war.territories = generate_territories()
    
    active_wars.append(war)
    war_started.emit(war)
    
    return war

func capture_territory(war: GuildWar, territory_id: String, guild_id: String) -> void:
    var territory = war.territories.filter(func(t): return t.territory_id == territory_id)[0]
    
    if not territory:
        return
    
    # 捕获逻辑
    territory.controlling_guild = guild_id
    territory.capture_progress = 1.0
    
    # 加分
    if guild_id == war.guild_a:
        war.score_a += 100
    else:
        war.score_b += 100
    
    territory_captured.emit(territory, guild_id)

func end_guild_war(war: GuildWar) -> void:
    war.phase = WarPhase.ENDED
    
    var winner = war.score_a > war.score_b ? war.guild_a : war.guild_b
    
    # 发放奖励
    distribute_war_rewards(war, winner)
    
    war_ended.emit(war, winner)
    active_wars.erase(war)
```

#### 4. WorldBossSystem.gd

```gdscript
class_name WorldBossSystem extends Node

class WorldBoss:
    var boss_id: String
    var name: String
    var level: int
    var max_health: int
    var current_health: int
    var spawn_time: int
    var despawn_time: int
    var participants: Dictionary  # user_id -> damage_dealt
    var top_guild: String = ""

var active_bosses: Array[WorldBoss] = []
var boss_spawn_schedule: Dictionary = {}

signal boss_spawned(boss: WorldBoss)
signal boss_damaged(boss: WorldBoss, damage: int, by_user: String)
signal boss_defeated(boss: WorldBoss, mvp: String)

func schedule_world_boss() -> void:
    # 每天固定时间生成 Boss
    boss_spawn_schedule = {
        12: "ancient_dragon",    # 中午 12:00
        20: "ice_titan",         # 晚上 20:00
    }

func spawn_world_boss(boss_id: String) -> void:
    var boss_data = load_boss_data(boss_id)
    
    var boss = WorldBoss.new()
    boss.boss_id = boss_id
    boss.name = boss_data.name
    boss.level = boss_data.level
    boss.max_health = boss_data.health
    boss.current_health = boss_data.health
    boss.spawn_time = Time.get_unix_time_from_system()
    boss.despawn_time = boss.spawn_time + 3600  # 1 小时后消失
    
    active_bosses.append(boss)
    boss_spawned.emit(boss)
    
    # 全服公告
    announce_to_all_players("世界 Boss [%s] 已出现！" % boss.name)

func deal_damage_to_boss(boss: WorldBoss, user_id: String, damage: int) -> void:
    boss.current_health -= damage
    
    if not boss.participants.has(user_id):
        boss.participants[user_id] = 0
    
    boss.participants[user_id] += damage
    boss_damaged.emit(boss, damage, user_id)
    
    if boss.current_health <= 0:
        defeat_boss(boss)

func defeat_boss(boss: WorldBoss) -> void:
    # 找出 MVP
    var mvp = ""
    var max_damage = 0
    
    for user_id in boss.participants:
        if boss.participants[user_id] > max_damage:
            max_damage = boss.participants[user_id]
            mvp = user_id
    
    # 分发奖励
    distribute_boss_rewards(boss, mvp)
    
    boss_defeated.emit(boss, mvp)
    active_bosses.erase(boss)

func distribute_boss_rewards(boss: WorldBoss, mvp: String) -> void:
    # MVP 奖励
    var mvp_rewards = {
        "currency": {"GEM": 500},
        "items": ["legendary_boss_weapon"]
    }
    MailSystem.send_mail(mvp, "世界 Boss MVP", "恭喜成为 MVP！", mvp_rewards)
    
    # 参与奖励（按伤害排名）
    var sorted_participants = boss.participants.keys()
    sorted_participants.sort_custom(func(a, b): return boss.participants[a] > boss.participants[b])
    
    for i in range(min(10, sorted_participants.size())):
        var user_id = sorted_participants[i]
        var rank = i + 1
        var rewards = calculate_rank_rewards(rank)
        MailSystem.send_mail(user_id, "世界 Boss 奖励", "排名第 %d" % rank, rewards)
```

#### 5. EventSystem.gd

```gdscript
class_name EventSystem extends Node

enum EventType {
    DOUBLE_EXP,
    DOUBLE_DROP,
    LIMITED_DUNGEON,
    LOGIN_BONUS,
    FESTIVAL,
    CHALLENGE,
}

class GameEvent:
    var event_id: String
    var name: String
    var description: String
    var type: EventType
    var start_time: int
    var end_time: int
    var rewards: Dictionary
    var conditions: Dictionary
    var active: bool = false

var active_events: Array[GameEvent] = []
var event_calendar: Array[GameEvent] = []

signal event_started(event: GameEvent)
signal event_progress_updated(event: GameEvent, progress: float)
signal event_ended(event: GameEvent)

func schedule_event(event: GameEvent) -> void:
    event_calendar.append(event)
    
    # 到时间自动启动
    var delay = event.start_time - Time.get_unix_time_from_system()
    if delay > 0:
        await get_tree().create_timer(delay).timeout
        start_event(event)

func start_event(event: GameEvent) -> void:
    event.active = true
    active_events.append(event)
    event_started.emit(event)
    
    # 应用活动效果
    apply_event_effects(event)
    
    # 全服公告
    announce_to_all_players("活动开始：%s" % event.name)
    
    # 定时结束
    var duration = event.end_time - event.start_time
    await get_tree().create_timer(duration).timeout
    end_event(event)

func apply_event_effects(event: GameEvent) -> void:
    match event.type:
        EventType.DOUBLE_EXP:
            ExperienceManager.set_multiplier(2.0)
        EventType.DOUBLE_DROP:
            LootSystem.set_multiplier(2.0)
        EventType.LIMITED_DUNGEON:
            unlock_limited_dungeon(event.conditions.dungeon_id)

func end_event(event: GameEvent) -> void:
    event.active = false
    active_events.erase(event)
    
    # 移除活动效果
    remove_event_effects(event)
    
    event_ended.emit(event)
    announce_to_all_players("活动结束：%s" % event.name)

func create_festival_event(name: String, start: int, duration: int) -> GameEvent:
    var event = GameEvent.new()
    event.event_id = generate_event_id()
    event.name = name
    event.type = EventType.FESTIVAL
    event.start_time = start
    event.end_time = start + duration
    event.rewards = {
        "login_daily": {"GEM": 100},
        "complete_missions": {"currency": {"GOLD": 5000}}
    }
    return event
```

#### 6. AnalyticsSystem.gd

```gdscript
class_name AnalyticsSystem extends Node

enum EventCategory {
    USER,
    ECONOMY,
    GAMEPLAY,
    SOCIAL,
    MONETIZATION,
}

class AnalyticsEvent:
    var event_name: String
    var category: EventCategory
    var timestamp: int
    var user_id: String
    var properties: Dictionary

var event_buffer: Array[AnalyticsEvent] = []
var buffer_size_limit: int = 100

signal analytics_event_tracked(event: AnalyticsEvent)

func track_event(event_name: String, category: EventCategory, properties: Dictionary = {}) -> void:
    var event = AnalyticsEvent.new()
    event.event_name = event_name
    event.category = category
    event.timestamp = Time.get_unix_time_from_system()
    event.user_id = PlayerProfile.user_id
    event.properties = properties
    
    event_buffer.append(event)
    analytics_event_tracked.emit(event)
    
    if event_buffer.size() >= buffer_size_limit:
        flush_events()

func flush_events() -> void:
    if event_buffer.is_empty():
        return
    
    # 批量发送到分析服务器
    NetworkManager.send_rpc("analytics_batch", {
        "events": event_buffer
    })
    
    event_buffer.clear()

# 便捷方法
func track_level_up(new_level: int) -> void:
    track_event("level_up", EventCategory.GAMEPLAY, {
        "new_level": new_level,
        "play_time_seconds": PlayerProfile.total_play_time
    })

func track_purchase(item_id: String, amount: float, currency: String) -> void:
    track_event("purchase", EventCategory.MONETIZATION, {
        "item_id": item_id,
        "amount": amount,
        "currency": currency
    })

func track_retention(day: int) -> void:
    track_event("retention_day_%d" % day, EventCategory.USER, {
        "install_date": PlayerProfile.created_at
    })

func track_funnel_step(funnel_name: String, step: int) -> void:
    track_event("funnel_%s_step_%d" % [funnel_name, step], EventCategory.USER, {
        "funnel": funnel_name,
        "step": step
    })
```

#### 7. GMToolsSystem.gd

```gdscript
class_name GMToolsSystem extends Node

enum GMPermissionLevel {
    NONE,
    SUPPORT,      # 客服
    MODERATOR,    # 版主
    ADMIN,        # 管理员
    SUPER_ADMIN,  # 超级管理员
}

var current_gm_level: GMPermissionLevel = GMPermissionLevel.NONE

signal gm_action_executed(action: String, target: String)

func has_permission(required_level: GMPermissionLevel) -> bool:
    return current_gm_level >= required_level

func give_items_to_player(user_id: String, items: Array[Dictionary]) -> bool:
    if not has_permission(GMPermissionLevel.SUPPORT):
        return false
    
    NetworkManager.send_rpc("gm_give_items", {
        "gm_id": PlayerProfile.user_id,
        "target_user_id": user_id,
        "items": items
    })
    
    gm_action_executed.emit("give_items", user_id)
    return true

func ban_player(user_id: String, duration_hours: int, reason: String) -> bool:
    if not has_permission(GMPermissionLevel.MODERATOR):
        return false
    
    NetworkManager.send_rpc("gm_ban_player", {
        "gm_id": PlayerProfile.user_id,
        "target_user_id": user_id,
        "duration_hours": duration_hours,
        "reason": reason
    })
    
    gm_action_executed.emit("ban_player", user_id)
    return true

func broadcast_message(message: String, level: String = "info") -> bool:
    if not has_permission(GMPermissionLevel.ADMIN):
        return false
    
    NetworkManager.send_rpc("gm_broadcast", {
        "gm_id": PlayerProfile.user_id,
        "message": message,
        "level": level
    })
    
    return true

func hot_update_config(config_name: String, new_data: Dictionary) -> bool:
    if not has_permission(GMPermissionLevel.SUPER_ADMIN):
        return false
    
    # 热更新游戏配置（无需重启服务器）
    NetworkManager.send_rpc("gm_hot_update", {
        "gm_id": PlayerProfile.user_id,
        "config_name": config_name,
        "data": new_data
    })
    
    gm_action_executed.emit("hot_update", config_name)
    return true

func rollback_player_state(user_id: String, timestamp: int) -> bool:
    if not has_permission(GMPermissionLevel.SUPER_ADMIN):
        return false
    
    # 回滚玩家数据到指定时间点
    NetworkManager.send_rpc("gm_rollback", {
        "gm_id": PlayerProfile.user_id,
        "target_user_id": user_id,
        "rollback_to": timestamp
    })
    
    gm_action_executed.emit("rollback", user_id)
    return true
```

### 数据驱动配置

**data/live_ops/season_schedule.json**：

```json
{
  "$schema": "../schemas/season_schema.json",
  "seasons": [
    {
      "season_id": "season_1",
      "season_number": 1,
      "theme": "黎明之章",
      "start_date": 1717228800,
      "end_date": 1725091200,
      "duration_days": 90,
      "reset_rankings": true,
      "reset_gear": false,
      "new_content": [
        "5 new characters",
        "2 new dungeons",
        "1 new PvP map",
        "50-level Battle Pass"
      ],
      "top_rewards": {
        "rank_1": {
          "currency": {"GEM": 10000},
          "items": ["season_1_champion_skin"],
          "title": "S1 冠军"
        },
        "rank_2_10": {
          "currency": {"GEM": 5000},
          "items": ["season_1_legend_frame"]
        }
      }
    }
  ]
}
```

**data/live_ops/event_calendar.json**：

```json
{
  "$schema": "../schemas/event_calendar_schema.json",
  "recurring_events": [
    {
      "name": "周末双倍经验",
      "type": "DOUBLE_EXP",
      "schedule": "weekly",
      "day_of_week": [6, 0],
      "start_hour": 0,
      "duration_hours": 48
    },
    {
      "name": "每日签到",
      "type": "LOGIN_BONUS",
      "schedule": "daily",
      "rewards": {
        "day_1": {"GOLD": 1000},
        "day_7": {"GEM": 100},
        "day_30": {"TICKET": 10}
      }
    }
  ],
  "one_time_events": [
    {
      "event_id": "lunar_new_year_2027",
      "name": "春节活动",
      "type": "FESTIVAL",
      "start_date": 1738166400,
      "end_date": 1739376000,
      "duration_days": 14,
      "special_content": [
        "限定副本：年兽来袭",
        "限定皮肤：新春套装",
        "红包雨活动"
      ]
    }
  ]
}
```

---

## Implementation Plan

### Task 1: Season System (5 days)
### Task 2: Cross-Server Infrastructure (7 days)
### Task 3: Guild War System (8 days)
### Task 4: World Boss System (5 days)
### Task 5: Event System Framework (5 days)
### Task 6: Event Content Creation (持续)
### Task 7: Analytics Integration (5 days)
### Task 8: GM Tools (6 days)
### Task 9: Live Dashboard (4 days)
### Task 10: 24/7 Operations Setup (持续)

---

## Acceptance Criteria

### 功能验收
- [ ] 赛季系统完整运行
- [ ] 跨服匹配正常
- [ ] 公会战可玩
- [ ] 世界 Boss 定时生成
- [ ] 活动系统灵活配置
- [ ] 数据分析完备
- [ ] GM 工具齐全

### 运营指标
- [ ] 次日留存 > 40%
- [ ] 7 日留存 > 20%
- [ ] DAU 稳定增长
- [ ] 付费转化率 > 2%
- [ ] 服务器稳定性 > 99.5%

---

## Estimated Timeline

**持续运营** - 游戏生命周期

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 游戏上线后执行
