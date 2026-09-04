# Phase 7: Meta Systems & Progression - PLAN

**状态**: 📋 Ready to Start  
**优先级**: P1 🔴  
**预计工期**: 5-6 weeks  
**创建日期**: 2026-09-05

---

## 📅 实施计划

### 工作分解结构 (WBS)

本 Phase 分为 10 个主要任务，按依赖关系排序。

---

### Task 1: 经验值与等级系统

**目标**: 实现完整的经验值累加和升级机制

**工期**: 3-4 天

**文件清单**:
```
scripts/progression/
├── level_system.gd              (核心系统)
└── level_component.gd           (玩家组件)

data/progression/
└── level_curve.json             (经验曲线配置)

tests/
└── test_level_system.gd         (单元测试)
```

**实现步骤**:
1. 创建 `LevelSystem` autoload
2. 实现 `add_exp()` 和 `_level_up()` 方法
3. 配置经验曲线 JSON（Level 1-50）
4. 集成升级奖励（属性点/技能点）
5. 添加升级特效和音效
6. 编写单元测试

**验收标准**:
- [ ] 玩家可以通过击败敌人获得经验值
- [ ] 经验条实时更新并平滑动画
- [ ] 升级时正确发放 5 属性点 + 1 技能点
- [ ] 升级时播放金色闪光特效和音效
- [ ] 升级时恢复满血满蓝
- [ ] 达到 Level 50 后经验不再增长
- [ ] 单元测试覆盖率 > 80%

**依赖**: 无

---

### Task 2: 属性系统

**目标**: 实现 5 大属性和属性点分配

**工期**: 3-4 天

**文件清单**:
```
scripts/progression/
├── stats_system.gd              (核心系统)
└── stats_component.gd           (玩家组件)

data/progression/
└── stats_formula.json           (属性公式配置)

scenes/ui/
└── stats_panel.tscn             (属性面板 UI)
└── stats_panel.gd               (面板脚本)

tests/
└── test_stats_system.gd         (单元测试)
```

**实现步骤**:
1. 创建 `StatsSystem` autoload
2. 实现 5 大属性字典和加成计算
3. 实现 `allocate_stat()` 和 `reset_stats()` 方法
4. 创建属性面板 UI（显示属性和分配按钮）
5. 实现 `_apply_stats_to_player()` 应用到组件
6. 添加 Tooltip 显示属性加成详情
7. 编写单元测试

**验收标准**:
- [ ] 5 大属性（STR/AGI/VIT/INT/LUK）正确影响角色数值
- [ ] 属性面板显示当前属性值和待分配点数
- [ ] 点击 + 按钮正确分配属性点
- [ ] Tooltip 显示属性加成详情
- [ ] 重置属性功能正常（消耗金币）
- [ ] 属性加成实时应用到 HealthComponent/CombatComponent
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 1 (等级系统)

---

### Task 3: 装备系统核心

**目标**: 实现装备槽位和装备数据库

**工期**: 4-5 天

**文件清单**:
```
scripts/progression/
├── equipment_system.gd          (核心系统)
└── equipment_component.gd       (玩家组件)

data/progression/
├── equipment_database.json      (装备数据库)
└── equipment_schema.json        (装备数据结构)

scenes/ui/
└── equipment_panel.tscn         (装备面板 UI)
└── equipment_panel.gd           (面板脚本)

tests/
└── test_equipment_system.gd     (单元测试)
```

**实现步骤**:
1. 创建 `EquipmentSystem` autoload
2. 定义 7 个装备槽位枚举和字典
3. 创建装备数据库 JSON（20+ 件装备）
4. 实现 `equip_item()` 和 `unequip_item()` 方法
5. 实现 `_recalculate_equipment_stats()` 属性计算
6. 创建装备面板 UI（7 个槽位 + 装备图标）
7. 实现装备 Tooltip（属性/词条/特效）
8. 编写单元测试

**验收标准**:
- [ ] 7 个装备槽位正常装备/卸下
- [ ] 装备数据库包含 4 种品质装备
- [ ] 装备属性正确应用到角色
- [ ] 装备 Tooltip 显示完整信息
- [ ] 装备等级需求正确检查
- [ ] 装备品质用不同颜色边框区分
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 2 (属性系统)

---

### Task 4: 背包系统

**目标**: 实现背包存储和物品管理

**工期**: 3-4 天

**文件清单**:
```
scripts/progression/
└── inventory_system.gd          (背包系统，集成到 EquipmentSystem)

scenes/ui/
└── inventory_panel.tscn         (背包 UI)
└── inventory_panel.gd           (背包脚本)
└── item_slot.tscn               (物品格子)
└── item_slot.gd                 (格子脚本)

tests/
└── test_inventory_system.gd     (单元测试)
```

**实现步骤**:
1. 扩展 `EquipmentSystem` 添加背包功能
2. 实现 `add_to_inventory()` 和 `remove_from_inventory()`
3. 创建背包 UI（30 格网格布局）
4. 实现物品格子组件（支持拖拽）
5. 实现拖拽装备到槽位功能
6. 实现右键快捷菜单（装备/出售/丢弃）
7. 实现背包扩容功能
8. 编写单元测试

**验收标准**:
- [ ] 背包支持 30 格起始容量
- [ ] 拖拽装备到槽位正常装备
- [ ] 拖拽槽位装备到背包正常卸下
- [ ] 右键装备显示快捷菜单
- [ ] 背包满时无法拾取新物品
- [ ] 背包扩容功能正常
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 3 (装备系统核心)

---

### Task 5: 装备对比与拾取

**目标**: 实现装备对比界面和战利品拾取

**工期**: 2-3 天

**文件清单**:
```
scripts/progression/
└── loot_system.gd               (掉落系统)

scenes/ui/
└── equipment_compare_tooltip.tscn  (对比 Tooltip)
└── equipment_compare_tooltip.gd    (对比脚本)

scenes/game/
└── loot_drop.tscn               (掉落物场景)
└── loot_drop.gd                 (掉落物脚本)

tests/
└── test_loot_system.gd          (单元测试)
```

**实现步骤**:
1. 创建 `LootSystem` 管理敌人掉落
2. 实现掉落概率算法（基于品质）
3. 创建装备对比 Tooltip（当前 vs 新装备）
4. 实现属性差异显示（绿色↑/红色↓）
5. 创建掉落物 3D 场景（悬浮旋转）
6. 实现拾取交互（靠近自动拾取）
7. 编写单元测试

**验收标准**:
- [ ] 敌人死亡后正确掉落装备
- [ ] 掉落物在地面悬浮旋转
- [ ] 鼠标悬停装备显示对比 Tooltip
- [ ] 对比 Tooltip 显示属性差异（↑↓）
- [ ] 靠近掉落物自动拾取到背包
- [ ] 背包满时掉落物不消失
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 4 (背包系统)

---

### Task 6: 技能树系统

**目标**: 实现 3 分支技能树和技能点分配

**工期**: 5-6 天

**文件清单**:
```
scripts/progression/
├── skill_tree_system.gd         (核心系统)
└── skill_node.gd                (技能节点数据)

data/progression/
├── skill_tree.json              (技能树配置)
└── skill_tree_warrior.json      (战士分支)
└── skill_tree_assassin.json     (刺客分支)
└── skill_tree_mage.json         (法师分支)

scenes/ui/
└── skill_tree_panel.tscn        (技能树 UI)
└── skill_tree_panel.gd          (面板脚本)
└── skill_node_ui.tscn           (技能节点 UI)
└── skill_node_ui.gd             (节点脚本)

tests/
└── test_skill_tree_system.gd    (单元测试)
```

**实现步骤**:
1. 创建 `SkillTreeSystem` autoload
2. 设计 3 分支技能树结构（各 20 个节点）
3. 配置技能树 JSON（技能名称/效果/前置）
4. 实现 `learn_skill()` 和 `reset_skill_tree()` 方法
5. 创建技能树可视化 UI（树状图布局）
6. 实现技能节点 UI（未学习/已学习/可学习状态）
7. 实现 `_apply_skill_effect()` 应用技能效果
8. 实现技能 Tooltip 和前置技能高亮
9. 编写单元测试

**验收标准**:
- [ ] 3 个技能分支共 60 个技能节点
- [ ] 技能树 UI 清晰显示节点连接关系
- [ ] 前置技能未学习时无法学习后续技能
- [ ] 技能点投入正确增强技能效果
- [ ] 技能 Tooltip 显示完整效果描述
- [ ] 重置技能树正确返还技能点
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 1 (等级系统)

---

### Task 7: 成就系统

**目标**: 实现成就追踪和奖励发放

**工期**: 4-5 天

**文件清单**:
```
scripts/progression/
├── achievement_system.gd        (核心系统)
└── achievement_tracker.gd       (进度追踪器)

data/progression/
└── achievements.json            (成就配置)

scenes/ui/
└── achievement_panel.tscn       (成就列表 UI)
└── achievement_panel.gd         (面板脚本)
└── achievement_notification.tscn (解锁通知)
└── achievement_notification.gd   (通知脚本)

tests/
└── test_achievement_system.gd   (单元测试)
```

**实现步骤**:
1. 创建 `AchievementSystem` autoload
2. 配置成就 JSON（50+ 个成就）
3. 实现 `track_progress()` 进度追踪方法
4. 连接游戏信号（敌人死亡/升级/装备等）
5. 实现 `_unlock_achievement()` 解锁和奖励发放
6. 创建成就列表 UI（按分类显示）
7. 创建成就解锁横幅通知
8. 实现成就进度条和完成状态
9. 编写单元测试

**验收标准**:
- [ ] 成就系统正确追踪游戏事件
- [ ] 成就进度条实时更新
- [ ] 成就解锁时播放横幅动画和音效
- [ ] 成就奖励正确发放（经验/金币/装备）
- [ ] 成就列表按分类显示（战斗/探索/成长）
- [ ] 已完成成就显示完成标记
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 1, 3, 6 (等级/装备/技能系统)

---

### Task 8: 本地存档系统

**目标**: 实现本地存档保存和加载

**工期**: 3-4 天

**文件清单**:
```
scripts/core/
└── save_manager.gd              (存档管理器)

data/
└── save_data/                   (存档目录，运行时生成)
    └── player_data.cfg          (存档文件)

scenes/ui/
└── save_load_menu.tscn          (存档菜单 UI)
└── save_load_menu.gd            (菜单脚本)

tests/
└── test_save_manager.gd         (单元测试)
```

**实现步骤**:
1. 创建 `SaveManager` autoload
2. 实现 `save_game()` 收集所有系统数据
3. 实现 `load_game()` 恢复所有系统数据
4. 使用 `ConfigFile` 保存到 `user://`
5. 实现自动存档功能（每 5 分钟）
6. 实现存档版本管理和迁移
7. 创建存档/读档菜单 UI
8. 实现存档加密（防修改器）
9. 编写单元测试

**验收标准**:
- [ ] 存档正确保存所有系统数据
- [ ] 读档后数据完整无丢失
- [ ] 存档加载时间 < 1 秒
- [ ] 自动存档功能正常（每 5 分钟）
- [ ] 存档版本号正确管理
- [ ] 旧版本存档可正常加载
- [ ] 单元测试覆盖率 > 80%

**依赖**: Task 1-7 (所有系统)

---

### Task 9: UI 完善与动画

**目标**: 完善所有 UI 界面和动画效果

**工期**: 4-5 天

**文件清单**:
```
scenes/ui/
├── character_panel.tscn         (角色主面板)
├── character_panel.gd           (主面板脚本)
├── ui_animations.gd             (UI 动画库)
└── ui_theme.tres                (UI 主题资源)

assets/ui/
├── fonts/                       (字体文件)
├── icons/                       (图标文件)
└── stylebox/                    (UI 样式)

tests/
└── test_ui_integration.gd       (UI 集成测试)
```

**实现步骤**:
1. 创建角色面板主界面（4 个标签页）
2. 统一 UI 主题（字体/颜色/样式）
3. 实现标签页切换动画
4. 实现升级金色闪光特效
5. 实现成就解锁横幅动画
6. 实现装备切换过渡动画
7. 实现技能学习反馈动画
8. 优化 Tooltip 显示逻辑
9. 编写 UI 集成测试

**验收标准**:
- [ ] 角色面板 4 个标签页流畅切换
- [ ] 所有 UI 遵循统一主题
- [ ] 升级特效显眼且流畅
- [ ] 成就解锁动画吸引注意
- [ ] 装备/技能切换有平滑过渡
- [ ] Tooltip 自动跟随鼠标
- [ ] UI 界面保持 60 FPS

**依赖**: Task 1-7 (所有系统)

---

### Task 10: 集成测试与优化

**目标**: 全面测试并优化性能

**工期**: 3-4 天

**文件清单**:
```
tests/integration/
├── test_progression_flow.gd     (成长流程测试)
├── test_save_load_cycle.gd      (存档循环测试)
└── test_performance.gd          (性能测试)

tools/
├── progression_stress_test.gd   (压力测试脚本)
└── generate_test_data.gd        (测试数据生成)

docs/
└── PHASE_7_TEST_REPORT.md       (测试报告)
```

**实现步骤**:
1. 编写完整成长流程集成测试
2. 测试存档/读档循环 100 次
3. 压力测试（1000+ 物品背包）
4. 性能分析（帧率/内存/存档时间）
5. 修复发现的 Bug
6. 优化性能瓶颈
7. 编写测试报告
8. 生成演示存档

**验收标准**:
- [ ] 所有集成测试通过
- [ ] 存档/读档循环 100 次无错误
- [ ] 1000 物品背包性能正常
- [ ] 游戏保持 60 FPS
- [ ] 存档加载 < 1 秒
- [ ] 内存占用 < 500MB
- [ ] 无已知严重 Bug

**依赖**: Task 1-9 (所有任务)

---

## 📊 时间线甘特图

```
Week 1:
  Mon-Thu: Task 1 (等级系统)
  Fri:     Task 2 开始 (属性系统)

Week 2:
  Mon-Wed: Task 2 完成
  Thu-Fri: Task 3 开始 (装备系统)

Week 3:
  Mon-Wed: Task 3 完成
  Thu-Fri: Task 4 (背包系统)

Week 4:
  Mon-Tue: Task 4 完成
  Wed-Thu: Task 5 (装备对比)
  Fri:     Task 6 开始 (技能树)

Week 5:
  Mon-Thu: Task 6 完成
  Fri:     Task 7 开始 (成就系统)

Week 6:
  Mon-Wed: Task 7 完成
  Thu:     Task 8 (存档系统)
  Fri:     Task 9 开始 (UI 完善)

Week 7 (可选缓冲):
  Mon-Wed: Task 9 完成
  Thu-Fri: Task 10 (集成测试)
```

---

## ⚠️ 风险管理

### 风险 1: 数值平衡失调
**影响**: 高  
**缓解措施**:
- 提前设计数值模型
- 多轮内部测试
- 保留热更新能力

### 风险 2: 存档兼容性问题
**影响**: 中  
**缓解措施**:
- 存档版本号管理
- 存档迁移脚本
- 测试覆盖旧版本

### 风险 3: 技能树 UI 复杂度
**影响**: 中  
**缓解措施**:
- 简化初版设计
- 参考成熟游戏
- 用户测试反馈

### 风险 4: 开发周期延期
**影响**: 中  
**缓解措施**:
- MVP 优先（等级/装备先行）
- 技能树和成就可后置
- 每周评审进度

---

## ✅ 总验收标准

### 功能完整性
- [ ] 经验值和等级系统完整
- [ ] 5 大属性分配正常
- [ ] 7 槽位装备系统完整
- [ ] 30 格背包系统完整
- [ ] 3 分支技能树可用
- [ ] 成就系统正常追踪
- [ ] 本地存档保存/加载正常

### 性能指标
- [ ] 游戏保持 60 FPS
- [ ] 存档加载 < 1 秒
- [ ] 内存占用 < 500MB
- [ ] UI 响应 < 100ms

### 用户体验
- [ ] UI 界面美观统一
- [ ] 动画流畅自然
- [ ] Tooltip 信息完整
- [ ] 无明显 Bug

### 代码质量
- [ ] 单元测试覆盖率 > 80%
- [ ] 所有集成测试通过
- [ ] 代码符合项目规范
- [ ] 文档完整

---

## 📝 交付物清单

1. **代码**
   - 7 个核心系统脚本
   - 10+ UI 场景和脚本
   - 20+ 单元测试和集成测试

2. **数据配置**
   - 经验曲线 JSON
   - 装备数据库 JSON (20+ 件装备)
   - 技能树 JSON (60 个技能节点)
   - 成就配置 JSON (50+ 个成就)

3. **UI 资源**
   - 角色面板场景
   - 装备面板场景
   - 技能树面板场景
   - 成就列表场景
   - 各类 Tooltip 场景

4. **文档**
   - 测试报告
   - 数值策划文档
   - 用户操作指南

5. **演示存档**
   - Level 25 角色
   - 部分装备和技能
   - 部分成就解锁

---

## 🚀 启动 Checklist

开始 Phase 7 前确认：

- [ ] Phase 6 (UI/Audio/Camera) 已完成 ✅
- [ ] 战斗系统稳定可用 ✅
- [ ] 敌人 AI 正常工作 ✅
- [ ] 技术负责人已审阅 PRD 和 Design
- [ ] 数值策划已审阅经验曲线和属性公式
- [ ] UI 设计师已审阅界面布局
- [ ] 测试环境已搭建

---

**总结**: Phase 7 实施计划已完整制定，包含 10 个详细任务、清晰的时间线、风险管理和验收标准。按此计划执行，预计 5-6 周完成完整的 Meta Systems。

**下一步**: 创建 Git 分支 `feature/phase-7-meta-systems`，开始 Task 1（等级系统）的实现。
