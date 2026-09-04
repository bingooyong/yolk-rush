# Phase 9: Social & Guild System

**Status**: 📋 Planning  
**Priority**: P3  
**Dependencies**: Phase 6, Phase 8 完成  
**Estimated Effort**: 5-7 weeks  
**Target Date**: TBD

---

## 概述

实现社交系统和公会系统，包括好友、聊天、公会、团队副本、PvP 排位赛。

## 前置条件

- ✅ Phase 1-8 已完成
- ✅ 多人游戏稳定（Phase 6）
- ✅ 经济系统健康（Phase 8）
- ⚠️ 需要聊天内容审核（敏感词过滤）
- ⚠️ 需要服务器集群（公会数据）
- ⚠️ 需要运营团队（社区管理）

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Rush 建立活跃的玩家社区：
1. 好友系统（添加、删除、黑名单）
2. 聊天系统（世界、公会、私聊）
3. 公会系统（创建、管理、活动）
4. 团队副本（4 人协作）
5. PvP 排位赛（1v1/3v3）
6. 排行榜系统

### 用户故事

**作为玩家**：
- 我希望和朋友一起玩
- 我希望加入公会找到组织
- 我希望在聊天中交流
- 我希望组队挑战副本
- 我希望和其他玩家竞技

**作为公会会长**：
- 我希望管理成员
- 我希望组织公会活动
- 我希望公会有专属奖励

### 非目标（本 Phase 不做）

- ❌ 语音聊天
- ❌ 跨服匹配（Phase 10）
- ❌ 公会战（Phase 10）
- ❌ 结婚系统

---

## Design (设计方案)

### 架构设计

```
SocialSystem
    ├── FriendSystem (好友系统)
    │   ├── FriendList (好友列表)
    │   ├── FriendRequest (好友申请)
    │   └── Blacklist (黑名单)
    ├── ChatSystem (聊天系统)
    │   ├── WorldChat (世界频道)
    │   ├── GuildChat (公会频道)
    │   ├── PrivateChat (私聊)
    │   ├── MessageFilter (内容过滤)
    │   └── MessageHistory (历史记录)
    ├── GuildSystem (公会系统)
    │   ├── GuildManager (公会管理)
    │   ├── GuildRanks (职位系统)
    │   ├── GuildTech (公会科技)
    │   ├── GuildWarehouse (公会仓库)
    │   └── GuildActivities (公会活动)
    ├── TeamSystem (组队系统)
    │   ├── TeamLobby (队伍大厅)
    │   ├── TeamDungeon (团队副本)
    │   └── LootDistribution (战利品分配)
    ├── PvPSystem (竞技场)
    │   ├── RankedQueue (排位匹配)
    │   ├── EloRating (天梯积分)
    │   └── SeasonRewards (赛季奖励)
    └── LeaderboardSystem (排行榜)
        ├── PowerRanking (战力榜)
        ├── PvPRanking (竞技榜)
        └── GuildRanking (公会榜)
```

### 核心组件

#### 1. FriendSystem.gd

```gdscript
class_name FriendSystem extends Node

enum FriendStatus {
    OFFLINE,
    ONLINE,
    IN_GAME,
    AWAY,
}

class Friend:
    var user_id: String
    var username: String
    var level: int
    var status: FriendStatus
    var last_online: int
    var avatar_icon: String

var friends: Array[Friend] = []
var pending_requests: Array[Friend] = []
var blacklist: Array[String] = []  # user_ids

signal friend_added(friend: Friend)
signal friend_removed(user_id: String)
signal friend_request_received(friend: Friend)
signal friend_status_changed(user_id: String, new_status: FriendStatus)

func send_friend_request(user_id: String) -> bool:
    if is_friend(user_id) or is_blocked(user_id):
        return false
    
    var request = {
        "from_user_id": PlayerProfile.user_id,
        "to_user_id": user_id,
        "timestamp": Time.get_unix_time_from_system()
    }
    
    NetworkManager.send_rpc("friend_request", request)
    return true

func accept_friend_request(user_id: String) -> void:
    # 从待处理中移除
    for i in range(pending_requests.size()):
        if pending_requests[i].user_id == user_id:
            var friend = pending_requests[i]
            pending_requests.remove_at(i)
            friends.append(friend)
            friend_added.emit(friend)
            
            # 通知服务器
            NetworkManager.send_rpc("accept_friend", {"user_id": user_id})
            break

func remove_friend(user_id: String) -> void:
    for i in range(friends.size()):
        if friends[i].user_id == user_id:
            friends.remove_at(i)
            friend_removed.emit(user_id)
            NetworkManager.send_rpc("remove_friend", {"user_id": user_id})
            break

func block_user(user_id: String) -> void:
    if not is_blocked(user_id):
        blacklist.append(user_id)
        remove_friend(user_id)
        NetworkManager.send_rpc("block_user", {"user_id": user_id})

func is_friend(user_id: String) -> bool:
    return friends.any(func(f): return f.user_id == user_id)

func is_blocked(user_id: String) -> bool:
    return blacklist.has(user_id)

func get_online_friends() -> Array[Friend]:
    return friends.filter(func(f): return f.status != FriendStatus.OFFLINE)
```

#### 2. ChatSystem.gd

```gdscript
class_name ChatSystem extends Node

enum ChatChannel {
    WORLD,
    GUILD,
    TEAM,
    PRIVATE,
    SYSTEM,
}

class ChatMessage:
    var message_id: String
    var sender_id: String
    var sender_name: String
    var channel: ChatChannel
    var content: String
    var timestamp: int
    var receiver_id: String = ""  # 私聊目标

var message_history: Dictionary = {}  # channel -> Array[ChatMessage]
var max_history_per_channel: int = 100
var spam_prevention: Dictionary = {}  # user_id -> last_message_time

signal message_received(message: ChatMessage)
signal message_blocked(reason: String)

func send_message(channel: ChatChannel, content: String, receiver_id: String = "") -> bool:
    # 反垃圾检查
    if not can_send_message():
        message_blocked.emit("spam_prevention")
        return false
    
    # 内容过滤
    var filtered_content = MessageFilter.filter_message(content)
    if filtered_content != content:
        content = filtered_content
    
    # 检测违禁内容
    if MessageFilter.contains_prohibited_content(content):
        message_blocked.emit("prohibited_content")
        return false
    
    var message = ChatMessage.new()
    message.message_id = generate_message_id()
    message.sender_id = PlayerProfile.user_id
    message.sender_name = PlayerProfile.username
    message.channel = channel
    message.content = content
    message.timestamp = Time.get_unix_time_from_system()
    message.receiver_id = receiver_id
    
    # 本地添加
    add_message_to_history(message)
    
    # 发送到服务器
    NetworkManager.send_rpc("chat_message", {
        "channel": channel,
        "content": content,
        "receiver_id": receiver_id
    })
    
    # 更新反垃圾时间戳
    spam_prevention[PlayerProfile.user_id] = Time.get_unix_time_from_system()
    return true

func can_send_message() -> bool:
    var now = Time.get_unix_time_from_system()
    var last_time = spam_prevention.get(PlayerProfile.user_id, 0)
    return now - last_time >= 1.0  # 1 秒冷却

func add_message_to_history(message: ChatMessage) -> void:
    var channel_key = message.channel
    if message.channel == ChatChannel.PRIVATE:
        # 私聊以对方 ID 为 key
        channel_key = message.receiver_id if message.sender_id == PlayerProfile.user_id else message.sender_id
    
    if not message_history.has(channel_key):
        message_history[channel_key] = []
    
    message_history[channel_key].append(message)
    
    # 限制历史记录长度
    if message_history[channel_key].size() > max_history_per_channel:
        message_history[channel_key].remove_at(0)
    
    message_received.emit(message)
```

#### 3. MessageFilter.gd

```gdscript
class_name MessageFilter extends Node

var prohibited_words: Array[String] = []
var sensitive_pattern: RegEx

func _ready() -> void:
    load_prohibited_words()
    compile_patterns()

func load_prohibited_words() -> void:
    var file = FileAccess.open("res://data/chat/prohibited_words.txt", FileAccess.READ)
    if file:
        while not file.eof_reached():
            var line = file.get_line().strip_edges()
            if line and not line.begins_with("#"):
                prohibited_words.append(line)
        file.close()

func filter_message(content: String) -> String:
    var filtered = content
    
    # 替换敏感词为 ***
    for word in prohibited_words:
        var regex = RegEx.new()
        regex.compile("(?i)" + word)
        filtered = regex.sub(filtered, "***", true)
    
    return filtered

func contains_prohibited_content(content: String) -> bool:
    # 严重违禁内容（政治、色情、欺诈）
    var severe_patterns = [
        "advertising_pattern",
        "fraud_pattern",
        "illegal_content"
    ]
    
    for pattern_name in severe_patterns:
        if check_pattern(content, pattern_name):
            # 记录日志，上报服务器
            report_violation(content, pattern_name)
            return true
    
    return false

func report_violation(content: String, violation_type: String) -> void:
    NetworkManager.send_rpc("report_chat_violation", {
        "user_id": PlayerProfile.user_id,
        "content": content,
        "violation_type": violation_type,
        "timestamp": Time.get_unix_time_from_system()
    })
```

#### 4. GuildSystem.gd

```gdscript
class_name GuildSystem extends Node

enum GuildRank {
    LEADER,      # 会长
    OFFICER,     # 副会长
    ELITE,       # 精英
    MEMBER,      # 成员
    RECRUIT,     # 新兵
}

class Guild:
    var guild_id: String
    var name: String
    var tag: String  # 公会标签 [TAG]
    var icon: Texture2D
    var level: int = 1
    var exp: int = 0
    var member_count: int = 0
    var max_members: int = 50
    var created_at: int
    var notice: String = ""
    var leader_id: String

class GuildMember:
    var user_id: String
    var username: String
    var rank: GuildRank
    var contribution: int  # 公会贡献度
    var joined_at: int

var current_guild: Guild = null
var guild_members: Array[GuildMember] = []

signal guild_joined(guild: Guild)
signal guild_left()
signal member_joined(member: GuildMember)
signal member_left(user_id: String)
signal guild_notice_updated(notice: String)

func create_guild(name: String, tag: String) -> bool:
    # 检查名称可用性
    if name.length() < 2 or name.length() > 20:
        return false
    
    if tag.length() < 2 or tag.length() > 6:
        return false
    
    # 检查创建条件
    if not can_create_guild():
        return false
    
    # 消耗货币
    CurrencyManager.spend_currency(CurrencyManager.CurrencyType.GOLD, 10000, "guild_creation")
    
    # 发送创建请求
    var result = await NetworkManager.send_rpc_async("create_guild", {
        "name": name,
        "tag": tag,
        "leader_id": PlayerProfile.user_id
    })
    
    if result.success:
        current_guild = result.guild
        guild_joined.emit(current_guild)
        return true
    
    return false

func can_create_guild() -> bool:
    # 不在公会中
    if current_guild != null:
        return false
    
    # 等级要求
    if PlayerProfile.level < 10:
        return false
    
    # 货币要求
    if CurrencyManager.balances[CurrencyManager.CurrencyType.GOLD] < 10000:
        return false
    
    return true

func join_guild(guild_id: String) -> bool:
    if current_guild != null:
        return false
    
    var result = await NetworkManager.send_rpc_async("join_guild", {
        "guild_id": guild_id,
        "user_id": PlayerProfile.user_id
    })
    
    if result.success:
        current_guild = result.guild
        guild_joined.emit(current_guild)
        return true
    
    return false

func leave_guild() -> bool:
    if current_guild == null:
        return false
    
    # 会长不能直接退出，需要先转让或解散
    if is_guild_leader():
        return false
    
    var result = await NetworkManager.send_rpc_async("leave_guild", {
        "guild_id": current_guild.guild_id,
        "user_id": PlayerProfile.user_id
    })
    
    if result.success:
        current_guild = null
        guild_members.clear()
        guild_left.emit()
        return true
    
    return false

func promote_member(user_id: String, new_rank: GuildRank) -> bool:
    if not can_manage_members():
        return false
    
    var member = get_member(user_id)
    if member == null or member.rank <= GuildRank.OFFICER:
        return false
    
    NetworkManager.send_rpc("promote_member", {
        "guild_id": current_guild.guild_id,
        "user_id": user_id,
        "new_rank": new_rank
    })
    
    member.rank = new_rank
    return true

func kick_member(user_id: String) -> bool:
    if not can_manage_members():
        return false
    
    NetworkManager.send_rpc("kick_member", {
        "guild_id": current_guild.guild_id,
        "user_id": user_id
    })
    
    for i in range(guild_members.size()):
        if guild_members[i].user_id == user_id:
            guild_members.remove_at(i)
            member_left.emit(user_id)
            break
    
    return true

func can_manage_members() -> bool:
    if current_guild == null:
        return false
    
    var my_member = get_member(PlayerProfile.user_id)
    return my_member != null and my_member.rank <= GuildRank.OFFICER

func is_guild_leader() -> bool:
    return current_guild != null and current_guild.leader_id == PlayerProfile.user_id
```

#### 5. TeamSystem.gd

```gdscript
class_name TeamSystem extends Node

const MAX_TEAM_SIZE = 4

class Team:
    var team_id: String
    var leader_id: String
    var members: Array[String]  # user_ids
    var target_dungeon: String
    var min_level: int = 1
    var locked: bool = false

var current_team: Team = null
var team_invites: Array[String] = []  # 收到的组队邀请

signal team_created(team: Team)
signal team_joined(team: Team)
signal team_left()
signal member_joined(user_id: String)
signal member_left(user_id: String)
signal team_ready()

func create_team(dungeon_id: String, min_level: int = 1) -> bool:
    if current_team != null:
        return false
    
    var team = Team.new()
    team.team_id = generate_team_id()
    team.leader_id = PlayerProfile.user_id
    team.members = [PlayerProfile.user_id]
    team.target_dungeon = dungeon_id
    team.min_level = min_level
    
    current_team = team
    team_created.emit(team)
    
    # 通知服务器
    NetworkManager.send_rpc("create_team", {
        "team_id": team.team_id,
        "dungeon_id": dungeon_id,
        "min_level": min_level
    })
    
    return true

func invite_to_team(user_id: String) -> bool:
    if current_team == null or not is_team_leader():
        return false
    
    if current_team.members.size() >= MAX_TEAM_SIZE:
        return false
    
    NetworkManager.send_rpc("team_invite", {
        "team_id": current_team.team_id,
        "from_user_id": PlayerProfile.user_id,
        "to_user_id": user_id
    })
    
    return true

func accept_team_invite(team_id: String) -> bool:
    if current_team != null:
        return false
    
    var result = await NetworkManager.send_rpc_async("accept_team_invite", {
        "team_id": team_id,
        "user_id": PlayerProfile.user_id
    })
    
    if result.success:
        current_team = result.team
        team_joined.emit(current_team)
        return true
    
    return false

func leave_team() -> bool:
    if current_team == null:
        return false
    
    NetworkManager.send_rpc("leave_team", {
        "team_id": current_team.team_id,
        "user_id": PlayerProfile.user_id
    })
    
    current_team = null
    team_left.emit()
    return true

func start_dungeon() -> bool:
    if not is_team_leader():
        return false
    
    if current_team.members.size() < 1:
        return false
    
    # 检查所有成员是否准备
    if not all_members_ready():
        return false
    
    # 锁定队伍
    current_team.locked = true
    
    # 加载副本
    NetworkManager.send_rpc("start_team_dungeon", {
        "team_id": current_team.team_id,
        "dungeon_id": current_team.target_dungeon
    })
    
    team_ready.emit()
    return true
```

#### 6. PvPSystem.gd

```gdscript
class_name PvPSystem extends Node

enum MatchMode {
    DUEL_1V1,
    ARENA_3V3,
}

class PlayerRating:
    var user_id: String
    var username: String
    var rating: int = 1500  # ELO rating
    var wins: int = 0
    var losses: int = 0
    var win_streak: int = 0
    var season_rank: int = 0

var my_rating: PlayerRating
var matchmaking_queue: MatchMode = -1
var current_match: Dictionary = {}

signal match_found(opponent: PlayerRating)
signal match_started()
signal match_ended(victory: bool, rating_change: int)

func queue_for_match(mode: MatchMode) -> void:
    if matchmaking_queue != -1:
        return
    
    matchmaking_queue = mode
    
    NetworkManager.send_rpc("queue_pvp", {
        "user_id": PlayerProfile.user_id,
        "mode": mode,
        "rating": my_rating.rating
    })

func cancel_queue() -> void:
    if matchmaking_queue == -1:
        return
    
    NetworkManager.send_rpc("cancel_pvp_queue", {
        "user_id": PlayerProfile.user_id
    })
    
    matchmaking_queue = -1

func on_match_found(match_data: Dictionary) -> void:
    matchmaking_queue = -1
    current_match = match_data
    
    match_found.emit(match_data.opponent)

func end_match(victory: bool) -> void:
    var rating_change = calculate_rating_change(victory, current_match.opponent.rating)
    
    if victory:
        my_rating.wins += 1
        my_rating.win_streak += 1
    else:
        my_rating.losses += 1
        my_rating.win_streak = 0
    
    my_rating.rating += rating_change
    
    # 上报服务器
    NetworkManager.send_rpc("pvp_match_result", {
        "match_id": current_match.match_id,
        "winner_id": PlayerProfile.user_id if victory else current_match.opponent.user_id,
        "rating_change": rating_change
    })
    
    match_ended.emit(victory, rating_change)
    current_match = {}

func calculate_rating_change(victory: bool, opponent_rating: int) -> int:
    # ELO 算法
    var K = 32  # K-factor
    var expected = 1.0 / (1.0 + pow(10.0, (opponent_rating - my_rating.rating) / 400.0))
    var actual = 1.0 if victory else 0.0
    var change = K * (actual - expected)
    
    return int(round(change))
```

### 数据驱动配置

**data/social/guild_levels.json**：

```json
{
  "$schema": "../schemas/guild_level_schema.json",
  "levels": [
    {
      "level": 1,
      "exp_required": 0,
      "max_members": 30,
      "benefits": {
        "warehouse_slots": 50
      }
    },
    {
      "level": 2,
      "exp_required": 10000,
      "max_members": 40,
      "benefits": {
        "warehouse_slots": 75,
        "guild_buff_attack": 0.02
      }
    },
    {
      "level": 5,
      "exp_required": 100000,
      "max_members": 50,
      "benefits": {
        "warehouse_slots": 100,
        "guild_buff_attack": 0.05,
        "guild_buff_defense": 0.05
      }
    },
    {
      "level": 10,
      "exp_required": 500000,
      "max_members": 80,
      "benefits": {
        "warehouse_slots": 150,
        "guild_buff_attack": 0.1,
        "guild_buff_defense": 0.1,
        "guild_exclusive_dungeon": true
      }
    }
  ]
}
```

**data/social/team_dungeons.json**：

```json
{
  "$schema": "../schemas/team_dungeon_schema.json",
  "dungeons": [
    {
      "id": "frozen_cave",
      "name": "冰封洞窟",
      "description": "4 人团队副本",
      "min_level": 15,
      "max_players": 4,
      "duration_minutes": 20,
      "difficulty": "normal",
      "rewards": {
        "guaranteed": [
          {"type": "currency", "currency_type": "GOLD", "amount": 5000}
        ],
        "loot_table": [
          {"item_id": "rare_weapon", "chance": 0.3},
          {"item_id": "epic_weapon", "chance": 0.1}
        ]
      },
      "bosses": [
        {
          "id": "ice_guardian",
          "name": "冰霜守卫",
          "health": 50000,
          "mechanics": ["freeze_aoe", "ice_wall"]
        }
      ]
    }
  ]
}
```

**data/social/pvp_seasons.json**：

```json
{
  "$schema": "../schemas/pvp_season_schema.json",
  "seasons": [
    {
      "season_id": "season_1_pvp",
      "season_name": "竞技赛季 1",
      "start_date": 1717228800,
      "end_date": 1722470400,
      "ranks": [
        {
          "rank_name": "青铜",
          "min_rating": 0,
          "max_rating": 1199,
          "icon": "res://assets/icons/ranks/bronze.png"
        },
        {
          "rank_name": "白银",
          "min_rating": 1200,
          "max_rating": 1499,
          "icon": "res://assets/icons/ranks/silver.png"
        },
        {
          "rank_name": "黄金",
          "min_rating": 1500,
          "max_rating": 1799,
          "icon": "res://assets/icons/ranks/gold.png"
        },
        {
          "rank_name": "铂金",
          "min_rating": 1800,
          "max_rating": 2099,
          "icon": "res://assets/icons/ranks/platinum.png"
        },
        {
          "rank_name": "钻石",
          "min_rating": 2100,
          "max_rating": 2399,
          "icon": "res://assets/icons/ranks/diamond.png"
        },
        {
          "rank_name": "大师",
          "min_rating": 2400,
          "max_rating": 9999,
          "icon": "res://assets/icons/ranks/master.png"
        }
      ],
      "rewards": {
        "bronze": {
          "currency": {"GOLD": 5000}
        },
        "silver": {
          "currency": {"GOLD": 10000, "GEM": 200}
        },
        "gold": {
          "currency": {"GOLD": 20000, "GEM": 500},
          "items": ["rare_pvp_weapon"]
        },
        "platinum": {
          "currency": {"GOLD": 50000, "GEM": 1000},
          "items": ["epic_pvp_weapon", "epic_pvp_armor"]
        },
        "diamond": {
          "currency": {"GOLD": 100000, "GEM": 2000},
          "items": ["legendary_pvp_weapon"],
          "title": "钻石斗士"
        },
        "master": {
          "currency": {"GOLD": 200000, "GEM": 5000},
          "items": ["legendary_pvp_set"],
          "title": "竞技大师",
          "avatar_frame": "master_frame"
        }
      }
    }
  ]
}
```

---

## Implementation Plan

### Task 1: Friend System (3 days)

**文件**：
- `scripts/social/friend_system.gd`
- `scenes/ui/friend_list_panel.tscn`

**验收**：
- [ ] 添加/删除好友正常
- [ ] 好友请求流程完整
- [ ] 黑名单功能正常
- [ ] 在线状态同步

### Task 2: Chat System (5 days)

**文件**：
- `scripts/social/chat_system.gd`
- `scripts/social/message_filter.gd`
- `scenes/ui/chat_panel.tscn`
- `data/chat/prohibited_words.txt`

**验收**：
- [ ] 世界/公会/私聊频道正常
- [ ] 敏感词过滤生效
- [ ] 反垃圾机制有效
- [ ] 历史记录保存

### Task 3: Guild System Core (7 days)

**文件**：
- `scripts/social/guild_system.gd`
- `scripts/social/guild_manager.gd`
- `scenes/ui/guild_panel.tscn`
- `data/social/guild_levels.json`

**验收**：
- [ ] 创建公会功能正常
- [ ] 加入/退出公会正常
- [ ] 职位管理功能完整
- [ ] 公会升级系统正常

### Task 4: Guild Advanced Features (5 days)

**功能**：
1. 公会仓库
2. 公会科技
3. 公会活动
4. 公会商店

**验收**：
- [ ] 仓库存取功能正常
- [ ] 科技升级生效
- [ ] 活动定时触发
- [ ] 商店货币流通

### Task 5: Team System (5 days)

**文件**：
- `scripts/social/team_system.gd`
- `scenes/ui/team_lobby.tscn`
- `data/social/team_dungeons.json`

**验收**：
- [ ] 组队功能正常
- [ ] 邀请/加入流程完整
- [ ] 队伍匹配正常
- [ ] 副本进入正常

### Task 6: Team Dungeon Content (6 days)

**实现**：
1. 4 人副本设计（3 个）
2. Boss 机制
3. 战利品分配
4. 协作玩法

**验收**：
- [ ] 至少 3 个团队副本可玩
- [ ] Boss 机制有趣
- [ ] 战利品分配公平
- [ ] 需要协作才能通关

### Task 7: PvP System (6 days)

**文件**：
- `scripts/social/pvp_system.gd`
- `scripts/social/matchmaking.gd`
- `data/social/pvp_seasons.json`

**验收**：
- [ ] 1v1 匹配正常
- [ ] ELO 算法正确
- [ ] 排位赛功能完整
- [ ] 赛季奖励正确发放

### Task 8: PvP Arena Content (5 days)

**实现**：
1. 竞技场地图（3 个）
2. 平衡性调整
3. 反作弊机制
4. 观战功能

**验收**：
- [ ] 3 个竞技场地图可用
- [ ] 职业平衡
- [ ] 作弊检测生效
- [ ] 观战功能正常

### Task 9: Leaderboard System (4 days)

**实现**：
1. 战力榜
2. PvP 榜
3. 公会榜
4. 每日/每周重置

**验收**：
- [ ] 排行榜实时更新
- [ ] 排名计算正确
- [ ] 定时重置正常
- [ ] 奖励正确发放

### Task 10: Social Features Polish (5 days)

**优化**：
1. UI/UX 优化
2. 社交推荐算法
3. 新手引导
4. 社区活动工具

**验收**：
- [ ] UI 流畅美观
- [ ] 推荐算法有效
- [ ] 新手引导清晰
- [ ] 运营工具完备

---

## Acceptance Criteria

### 功能验收

- [ ] 好友系统完整（添加、删除、黑名单）
- [ ] 聊天系统可用（3 个频道）
- [ ] 公会系统完整（创建、管理、活动）
- [ ] 团队副本可玩（至少 3 个）
- [ ] PvP 排位赛运行（1v1）
- [ ] 排行榜实时更新

### 技术验收

- [ ] 聊天内容审核完备
- [ ] 服务器负载均衡
- [ ] 数据一致性保证
- [ ] 防作弊机制有效

### 社区验收

- [ ] 公会活跃度 ≥ 60%
- [ ] 聊天日活 ≥ 40%
- [ ] PvP 参与率 ≥ 20%
- [ ] 举报响应 < 24h

---

## Risks & Mitigations

### Risk 1: 聊天内容违规

**影响**: 高（法律风险）  
**缓解**:
- AI + 人工审核
- 敏感词库及时更新
- 玩家举报机制

### Risk 2: 公会管理混乱

**影响**: 中（用户体验）  
**缓解**:
- 清晰的权限系统
- 操作日志
- GM 工具干预

### Risk 3: PvP 平衡性问题

**影响**: 中（游戏体验）  
**缓解**:
- 数据追踪
- 快速热更新
- 赛季机制重置

---

## Out of Scope (Phase 10+)

- ❌ 语音聊天
- ❌ 跨服匹配
- ❌ 公会战
- ❌ 大型 GvG

---

## Estimated Timeline

```
Week 1: Friend + Chat System
Week 2-3: Guild System Core + Advanced
Week 3-4: Team System + Dungeons
Week 5-6: PvP System + Arena
Week 7: Leaderboard + Polish
```

**Total**: 5-7 weeks

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 依赖 Phase 6, 8 完成
**警告**: ⚠️ 需要内容审核系统，必须符合当地法规
