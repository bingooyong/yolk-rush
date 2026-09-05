# Task 5: 成就系统设计（精简版）

## 核心类

### Achievement (成就数据)
```gdscript
class_name Achievement extends Resource
- id, title, description, icon
- type: KILL, COLLECT, LEVEL, COMBAT, EXPLORATION
- requirement: int (目标值)
- reward: {exp, gold, skill_points}
- hidden: bool
```

### AchievementSystem (成就管理)
```gdscript
class_name AchievementSystem extends Node
- unlocked_achievements: Dictionary  # id -> unlock_time
- progress: Dictionary  # id -> current_value
- track_event(event_type, data)
- check_achievement(id)
- get_completion_percentage()
```

## 成就分类（15个）

### 等级成就 (3个)
- newcomer: 达到5级
- veteran: 达到20级
- master: 达到50级

### 战斗成就 (4个)
- first_blood: 击败第一个敌人
- slayer: 击败100个敌人
- executioner: 击败1000个敌人
- crit_master: 触发100次暴击

### 收集成就 (3个)
- collector: 收集50种物品
- hoarder: 背包满100次
- wealthy: 拥有10000金币

### 装备成就 (2个)
- well_equipped: 装备全身装备
- legendary_gear: 获得传说装备

### 技能成就 (3个)
- skill_learner: 解锁5个技能
- skill_master: 解锁15个技能
- ultimate_power: 任意技能达到最大等级

## 数据结构
```json
{
  "achievements": [
    {
      "id": "newcomer",
      "title": "新手冒险者",
      "description": "达到5级",
      "type": "LEVEL",
      "requirement": 5,
      "reward": {"exp": 100, "gold": 50},
      "hidden": false
    }
  ]
}
```

## 实现步骤
1. Achievement 资源类
2. AchievementSystem 管理类
3. AchievementDatabase 数据库
4. achievements.json (15个成就)
5. 集成测试

## 文件清单
- scripts/achievement/achievement.gd
- scripts/achievement/achievement_system.gd
- scripts/achievement/achievement_database.gd
- data/achievement/achievements.json
- tests/achievement/test_achievements.gd
