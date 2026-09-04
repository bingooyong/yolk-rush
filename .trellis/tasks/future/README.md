# Trellis 长期规划索引

**项目**: Yolk Rush  
**规划周期**: Phase 4-6+  
**状态**: 📋 Planning  
**更新日期**: 2026-09-04

---

## 📊 规划概览

### 已完成 Phase (Phase 0-3)

| Phase | 名称 | 状态 | 完成度 | 文档 |
|-------|------|------|--------|------|
| **Phase 0** | 工厂地基 | ✅ 完成 | 100% | README.md |
| **Phase 1** | Hero Pipeline | ✅ 完成 | 100% | PHASE_1_3_REPORT.md |
| **Phase 2** | Snow Island | ✅ 完成 | 100% | PHASE_1_3_REPORT.md |
| **Phase 3** | Visual/Perf QA | ✅ 完成 | 100% | PHASE_1_3_REPORT.md |

**交付物**: 
- 35+ 文件
- 4,500+ 行代码
- 完整工具链
- 本地运行验证 ✅

---

## 🚀 未来 Phase (Phase 4-6)

### Phase 4: Animation System

**优先级**: P1  
**依赖**: Phase 1-3 ✅  
**预计工期**: 3-4 weeks  
**状态**: 📋 Planning

**核心目标**:
- 角色动画系统（Idle/Walk/Run/Jump/Fall/Land）
- AnimationTree + 状态机
- 动画混合与过渡
- Root Motion 支持（可选）
- 动画事件系统

**关键成果**:
- [ ] 6 个动画状态完整实现
- [ ] 状态机转换流畅
- [ ] 配置完全数据驱动
- [ ] 性能满足基准（≥60 FPS）

**文档**: [phase-4-animation-system.md](./phase-4-animation-system.md)

---

### Phase 5: Combat System & Skills

**优先级**: P1  
**依赖**: Phase 4  
**预计工期**: 4-5 weeks  
**状态**: 📋 Planning

**核心目标**:
- 基础战斗系统（普攻 + 技能）
- 伤害计算与生命值
- HitBox/HurtBox 碰撞检测
- 战斗特效与音效
- 简单 AI 敌人

**关键成果**:
- [ ] 攻击系统完整（普攻 + 连击）
- [ ] 技能系统支持 4 种类型
- [ ] 至少 3 个可用技能
- [ ] 简单 AI 敌人可战斗
- [ ] 战斗手感流畅

**文档**: [phase-5-combat-system.md](./phase-5-combat-system.md)

---

### Phase 6: Multiplayer Foundation

**优先级**: P2  
**依赖**: Phase 5  
**预计工期**: 6-8 weeks  
**状态**: 📋 Planning

**核心目标**:
- 客户端-服务器架构
- 实时网络同步（位置、动画、战斗）
- 匹配系统（房间/大厅）
- 基础反作弊（服务器验证）
- 网络优化（插值、预测）

**关键成果**:
- [ ] 客户端-服务器连接稳定
- [ ] 玩家状态正确同步
- [ ] 匹配系统可用
- [ ] 支持 8-16 人同屏
- [ ] 基础反作弊生效

**文档**: [phase-6-multiplayer-foundation.md](./phase-6-multiplayer-foundation.md)

---

## 📅 时间线规划

```
2026 Q3 (7-9月)
├─ Phase 1-3: 完成 ✅
└─ Phase 4: Animation System 📋

2026 Q4 (10-12月)
├─ Phase 4: 完成 + 测试
└─ Phase 5: Combat System (开始)

2027 Q1 (1-3月)
├─ Phase 5: 完成 + 测试
└─ Phase 6: Multiplayer (开始)

2027 Q2 (4-6月)
├─ Phase 6: 完成 + 测试
└─ Beta 测试准备
```

**里程碑**:
- ✅ **2026-09-04**: Phase 1-3 完成，本地可玩
- 🎯 **2026-12**: Phase 4 完成，动画系统就绪
- 🎯 **2027-03**: Phase 5 完成，战斗系统就绪
- 🎯 **2027-06**: Phase 6 完成，多人游戏就绪
- 🎯 **2027-09**: Beta 测试启动

---

## 🎯 技术栈演进

### Phase 1-3 (已完成)
```
Godot 4.7.2 (GDScript)
├─ 数据驱动架构 (JSON + Schema)
├─ Gameplay ⊥ Visual 解耦
├─ GLB 3D 模型支持
├─ QA 自动化 (Headless 测试)
└─ AI Agent Skills (6 个)
```

### Phase 4-5 (计划中)
```
+ AnimationTree + 状态机
+ HitBox/HurtBox 系统
+ 粒子特效 (GPUParticles3D)
+ 伤害计算框架
+ NavigationAgent3D (AI)
```

### Phase 6 (计划中)
```
+ ENet 多人网络
+ 客户端预测 + 插值
+ Dedicated Server (Docker)
+ Match Server (Go 微服务)
+ PostgreSQL 数据库
```

---

## 📁 Trellis 文档结构

```
.trellis/
├─ README.md                    # Trellis 使用说明
├─ spec/                        # 长期规范
│  ├─ runtime/
│  ├─ character-contract/
│  └─ level-dsl/
├─ tasks/                       # 任务分解
│  ├─ 09-04-factory-phase-1-3/  # Phase 1-3 (已完成)
│  │  ├─ task.json
│  │  ├─ PRD.md
│  │  ├─ DESIGN.md
│  │  └─ IMPLEMENT.md
│  └─ future/                   # 未来 Phase
│     ├─ phase-4-animation-system.md
│     ├─ phase-5-combat-system.md
│     └─ phase-6-multiplayer-foundation.md
└─ research/
   └─ phase-4-plus.md          # Phase 4+ 原始规划
```

---

## 🚫 Phase 4+ 明确不做的功能

根据 Trellis 原始规划（`research/phase-4-plus.md`），以下功能**明确延期**：

### 商业化功能（Phase 7+）
- ❌ 商城系统
- ❌ 抽卡/Gacha 系统
- ❌ 内购/IAP 集成
- ❌ 广告系统

### 社交功能（Phase 7+）
- ❌ 好友系统
- ❌ 战队/公会
- ❌ 聊天系统（文字/语音）
- ❌ 社交分享

### 进阶玩法（Phase 8+）
- ❌ 第二角色
- ❌ 第二张地图
- ❌ 副本系统
- ❌ Boss 战
- ❌ PvP 排位赛

### 技术扩展（按需）
- ❌ C# 绑定
- ❌ 模组系统
- ❌ 关卡编辑器
- ❌ 强制出 IPA（iOS 真机）

---

## ⚠️ 风险与依赖

### 技术风险

| Phase | 风险 | 影响 | 缓解措施 |
|-------|------|------|----------|
| Phase 4 | 美术资源缺失 | 高 | 使用 Mixamo 占位符 |
| Phase 4 | Root Motion 与物理冲突 | 中 | 设为可选配置 |
| Phase 5 | 战斗手感调整耗时 | 高 | 提供丰富调试工具 |
| Phase 5 | 特效性能问题 | 中 | GPU Particles + 池化 |
| Phase 6 | 网络复杂度高 | 高 | 使用成熟方案 (ENet) |
| Phase 6 | 服务器成本 | 中 | 按需实例 + 自动缩放 |

### 资源依赖

**Phase 4 需求**:
- [ ] 动画资源（6 个基础动画）
- [ ] Mixamo 账号（免费）
- [ ] Blender（动画编辑）

**Phase 5 需求**:
- [ ] 战斗动画（Attack/Cast/Hit/Die）
- [ ] 特效资源（粒子、光效）
- [ ] 音效资源（攻击/受击/技能）

**Phase 6 需求**:
- [ ] 服务器基础设施（AWS/GCP）
- [ ] 数据库服务（PostgreSQL）
- [ ] 后端开发资源（Go/Rust）

---

## 📈 成功指标

### 技术指标

| 指标 | Phase 1-3 | Phase 4 | Phase 5 | Phase 6 |
|------|-----------|---------|---------|---------|
| **FPS** | ≥60 | ≥60 | ≥60 | ≥60 (8人) |
| **内存** | ≤100MB | ≤120MB | ≤150MB | ≤200MB |
| **启动时间** | <3s | <3s | <3s | <5s |
| **构建时间** | <1min | <1min | <2min | <3min |

### 用户体验指标

| 指标 | Phase 4 | Phase 5 | Phase 6 |
|------|---------|---------|---------|
| **学习曲线** | <5min | <10min | <2min (匹配) |
| **操作延迟** | <50ms | <50ms | <100ms |
| **崩溃率** | <0.1% | <0.1% | <0.5% |
| **匹配成功率** | - | - | >95% |

### 开发效率指标

| 指标 | 目标 |
|------|------|
| **添加新角色** | <1 天 |
| **添加新技能** | <2 小时 |
| **添加新地图** | <3 天 |
| **修复 Bug** | <1 天（P0）|

---

## 🔄 迭代策略

### Alpha → Beta → Release

**Alpha 阶段** (Phase 1-3 完成):
- ✅ 核心玩法可玩
- ✅ 单机体验完整
- ✅ 技术框架稳定

**Beta 阶段** (Phase 4-5 完成):
- 动画系统完整
- 战斗系统可玩
- AI 敌人有挑战
- 内测招募开始

**Pre-Release** (Phase 6 完成):
- 多人游戏稳定
- 匹配系统流畅
- 性能优化完成
- 公测准备就绪

**Release** (Phase 7+):
- 商业化功能
- 社交功能
- 内容扩展（新角色/地图）

---

## 📚 参考文档

### 已完成 Phase 文档

- `README.md` - 项目概述和十条原则
- `CLAUDE.md` - 架构说明
- `PHASE_1_3_REPORT.md` - Phase 1-3 技术实现细节
- `TRELLIS_COMPLETION_SUMMARY.md` - 任务完成总结
- `docs/GLB_INTEGRATION.md` - GLB 模型集成指南
- `docs/architecture/` - 架构设计文档

### 未来 Phase 文档

- `.trellis/tasks/future/phase-4-animation-system.md`
- `.trellis/tasks/future/phase-5-combat-system.md`
- `.trellis/tasks/future/phase-6-multiplayer-foundation.md`

### 外部资源

- [Godot 文档](https://docs.godotengine.org/en/stable/)
- [Mixamo](https://www.mixamo.com/) - 免费角色动画
- [OpenGameArt](https://opengameart.org/) - 免费游戏资源
- [Kenney](https://kenney.nl/) - 免费资源包

---

## 🎯 下一步行动

### 立即可做（Phase 1-3 后续）

1. **优化当前系统**
   - [ ] 改进占位符视觉
   - [ ] 优化性能瓶颈
   - [ ] 补充单元测试

2. **准备 Phase 4**
   - [ ] 调研 Mixamo 动画
   - [ ] 学习 AnimationTree
   - [ ] 准备测试场景

3. **文档完善**
   - [ ] 更新 CLAUDE.md
   - [ ] 补充架构图
   - [ ] 录制演示视频

### Phase 4 启动前置

- [ ] 确认美术资源来源
- [ ] 安装 Blender
- [ ] 阅读 Godot AnimationTree 文档
- [ ] 创建 Phase 4 任务分支

---

## 📞 联系方式

如有问题或建议，请查阅：

- **项目文档**: `README.md`, `CLAUDE.md`
- **技术细节**: `PHASE_1_3_REPORT.md`
- **架构设计**: `docs/architecture/`
- **Trellis 规划**: `.trellis/tasks/future/`

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Active Planning

---

## 🎉 当前成就

✅ **Phase 1-3: 100% 完成**  
✅ **30+ 任务交付**  
✅ **4,500+ 行代码**  
✅ **完整工具链**  
✅ **本地运行验证**  

🎯 **未来目标**: Phase 4-6 规划完成  
🚀 **长期愿景**: 打造数据驱动的多人在线游戏

**Yolk Rush - 数据驱动的游戏工厂已就绪！** 🥚🎮
