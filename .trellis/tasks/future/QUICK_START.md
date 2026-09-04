# Yolk Rush - Phase 4-10 快速启动指南

**适用人群**: 刚接触本项目的开发者、项目经理、产品经理  
**阅读时间**: 10 分钟  
**最后更新**: 2026-09-04

---

## 🚀 5 分钟快速了解

### 项目现状（2026-09-04）

✅ **Phase 0-3 已完成**:
- 完整的数据驱动架构
- GLB 3D 模型集成
- 角色控制器 + 场景系统
- 本地可运行的游戏原型

📋 **Phase 4-10 待实现**:
- 7 个大型 Phase
- 预计 15-18 个月开发周期
- 从动画系统到正式上线运营

### 核心文档（必读）

| 优先级 | 文档 | 阅读时间 | 用途 |
|--------|------|----------|------|
| ⭐⭐⭐ | [INDEX.md](./INDEX.md) | 5 min | 了解文档结构 |
| ⭐⭐⭐ | [COMPLETE_ROADMAP.md](./COMPLETE_ROADMAP.md) | 10 min | 完整路线图 |
| ⭐⭐ | phase-4-animation-system.md | 15 min | 下一个 Phase |
| ⭐ | 其他 phase-*.md | 按需 | 具体 Phase 细节 |

---

## 👥 按角色快速入门

### 🧑‍💻 开发工程师

**第一天要做的 3 件事**:
1. 阅读 `../../CLAUDE.md` 了解架构
2. 运行 `godot --path . --headless` 验证环境
3. 阅读 [phase-4-animation-system.md](./phase-4-animation-system.md)

**技术栈**:
- Godot 4.7.2 (GDScript only)
- JSON 数据驱动
- Git + GitHub Actions CI

**关键代码位置**:
```
scripts/           # 所有 GDScript 代码
data/              # JSON 配置
scenes/            # .tscn 场景文件
assets/            # 3D 模型、材质等
```

**开发流程**:
```bash
# 1. 创建功能分支
git checkout -b feature/animation-system

# 2. 实现代码（参考 phase-4 文档）
# 3. 运行测试
godot --headless --script tests/run_tests.gd

# 4. 提交代码
git add .
git commit -m "feat: implement animation system"
git push
```

---

### 📊 项目经理

**第一天要做的 3 件事**:
1. 阅读 [COMPLETE_ROADMAP.md](./COMPLETE_ROADMAP.md) 了解时间线
2. 查看每个 Phase 的"Implementation Plan"章节
3. 评估团队规模和资源需求

**关键里程碑**:
- 2026 Q4: Phase 4 完成（动画系统）
- 2027 Q2: Phase 6 完成（多人游戏 + Alpha）
- 2027 Q3: Beta 测试启动
- 2028 Q2: 正式上线

**风险点**:
- Phase 6（多人游戏）- 技术复杂度高
- Phase 8（商业化）- 需要法务审核
- Phase 9（社交）- 需要内容审核系统

**资源需求**:
- 2-3 名 Godot 工程师
- 1 名后端工程师（Phase 6+）
- 1 名 UI/UX 设计师
- 1 名数值策划（Phase 7+）
- 0.5 名运营（Phase 10）

---

### 🎨 产品经理

**第一天要做的 3 件事**:
1. 阅读每个 Phase 的"PRD"章节
2. 查看 `data/` 目录下的 JSON 配置示例
3. 了解"非目标"清单，控制范围蔓延

**核心玩法**:
- 快节奏多人竞技（类似 Brawl Stars）
- 角色成长系统（装备/技能树）
- 社交系统（公会/好友/聊天）
- 长期运营（赛季/活动/排行榜）

**商业模式**:
- IAP 直购（礼包、钻石）: 40%
- 抽卡（角色、武器、皮肤）: 30%
- 战令（Battle Pass）: 20%
- 广告（可选激励视频）: 10%

**数据指标**:
- 次日留存 > 40%
- 7 日留存 > 20%
- 付费转化率 > 2%
- ARPU > $0.50

**配置工具**:
- 所有游戏内容都是 JSON 配置
- 支持热更新（无需发版）
- Schema 验证防止配置错误

---

### 🎮 游戏策划

**第一天要做的 3 件事**:
1. 阅读 Phase 7（成长系统）和 Phase 8（商业化）
2. 查看 `data/` 目录下的数值配置
3. 了解经济系统的"水龙头-水池"模型

**关键数值系统**:
- 经验曲线（指数增长）
- 装备稀有度（白 60% / 绿 30% / 蓝 9% / 紫 1%）
- 抽卡概率（0.6% 传说 / 5.1% 史诗）
- 货币产出/消耗平衡

**配置示例位置**:
```
data/progression/level_curve.json       # 等级曲线
data/items/weapons.json                 # 装备数据
data/monetization/gacha_pools.json      # 抽卡池
data/monetization/shop_catalog.json     # 商城商品
```

**数值平衡工具**:
- 经济模拟器（Excel/Python）
- 数据分析看板（Phase 10）
- A/B 测试系统（Phase 10）

---

### 🏗️ 技术负责人

**第一天要做的 3 件事**:
1. 阅读 `../../CLAUDE.md` 了解架构决策
2. 审查 Phase 6（多人游戏）的技术方案
3. 评估基础设施需求（服务器/数据库）

**架构演进**:
```
Phase 1-3: 单机原型
    └─ Godot 4.7.2 (GDScript)

Phase 4-5: 核心玩法
    └─ + AnimationTree + Combat System

Phase 6: 多人游戏 ⚠️ 关键里程碑
    └─ + ENet + Dedicated Server + PostgreSQL

Phase 7-9: 深度系统
    └─ + 装备/技能树/社交/商城

Phase 10: 运营系统
    └─ + Analytics + GM Tools + Cross-Server
```

**技术选型**:
- 客户端: Godot 4.7.2 (GDScript only)
- 网络协议: ENet (UDP)
- 服务器: Go/Rust (Dedicated Server)
- 数据库: PostgreSQL + Redis
- 云平台: AWS/GCP/阿里云

**性能目标**:
- FPS ≥ 60
- 内存 ≤ 200MB
- 网络延迟 < 100ms
- 服务器可用性 > 99.5%

**风险评估**:
- Phase 6 网络同步是最大技术风险
- 需要提前验证 ENet 性能
- 考虑自建 vs 云游戏方案

---

## 📋 开发检查清单

### Phase 4（动画系统）启动前

- [ ] 团队成员已读 phase-4-animation-system.md
- [ ] Mixamo 账号准备（角色动画资源）
- [ ] AnimationTree 技术预研完成
- [ ] Git 分支策略确定
- [ ] 验收标准已确认

### Phase 5（战斗系统）启动前

- [ ] Phase 4 已完成并验收
- [ ] 战斗手感原型已测试
- [ ] HitBox/HurtBox 碰撞层已规划
- [ ] 技能配置表已设计
- [ ] AI 行为树已预研

### Phase 6（多人游戏）启动前 ⚠️

- [ ] Phase 5 已完成并验收
- [ ] 服务器架构已确定
- [ ] ENet 网络测试完成
- [ ] 数据库设计完成
- [ ] 运维方案已确定
- [ ] 后端工程师已到位

### Phase 7（成长系统）启动前

- [ ] Phase 6 已完成并验收
- [ ] 数值策划已到位
- [ ] 经济模型已建立
- [ ] 装备系统设计已确认
- [ ] 技能树已设计

### Phase 8（商业化）启动前 ⚠️

- [ ] Phase 7 已完成并验收
- [ ] 法务审核已通过
- [ ] Apple/Google 开发者账号已准备
- [ ] 支付接入已完成
- [ ] 防沉迷系统已实现
- [ ] 隐私政策已更新

---

## 🎯 常见问题 FAQ

### Q1: 为什么不用 C#？
A: 项目十条原则第 1 条明确规定"GDScript only"，保持技术栈简单统一。

### Q2: Phase 4-10 可以并行开发吗？
A: Phase 4-6 必须顺序完成（核心玩法链），Phase 7-9 可以部分并行。

### Q3: 预算需要多少？
A: 
- 人力成本: 2-3 工程师 × 18 个月 ≈ $300K-500K
- 基础设施: 服务器 + CDN + 云存储 ≈ $50K/年
- 第三方服务: Analytics + 支付接入 ≈ $20K/年
- **总计**: ~$400K-600K

### Q4: 多人游戏服务器用什么技术？
A: 推荐 Go 或 Rust，具体见 phase-6-multiplayer-foundation.md

### Q5: 抽卡系统合法吗？
A: 必须符合当地法规，Phase 8 文档有详细合规说明，需要法务审核。

### Q6: 可以跳过某个 Phase 吗？
A: Phase 4-6 不可跳过（核心玩法），Phase 7-9 可根据商业目标调整优先级。

### Q7: 文档会更新吗？
A: 每个 Phase 开始前应 review 并更新对应文档，根据实际情况调整。

---

## 📞 获取帮助

### 文档问题
- 阅读 [INDEX.md](./INDEX.md) 了解文档结构
- 阅读 `../../README.md` 了解项目原则

### 技术问题
- 阅读 `../../CLAUDE.md` 了解架构
- 查看 `../../docs/` 目录下的技术文档
- 阅读对应 Phase 文档的"Design"章节

### 流程问题
- 查看对应 Phase 文档的"Implementation Plan"
- 查看"Acceptance Criteria"了解验收标准

---

## 🎉 开始你的第一个任务

根据你的角色，选择下一步：

**🧑‍💻 工程师**: 
```bash
git checkout -b feature/animation-idle-state
# 实现 phase-4 的 Task 1: Idle State
```

**📊 项目经理**: 
- 创建 Phase 4 的任务看板
- 分配 10 个子任务给团队

**🎨 产品经理**: 
- Review phase-4 的 PRD
- 准备角色动画需求文档

**🎮 策划**: 
- Review `data/` 目录结构
- 准备技能配置表模板

---

**🥚 Good luck with Yolk Rush!** 🎮
