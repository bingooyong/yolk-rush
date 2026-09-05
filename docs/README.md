# 文档索引

欢迎查看 Yolk Rush 游戏系统文档！

## 📚 文档列表

### 🎯 核心文档

1. **[系统总览](SYSTEMS_SUMMARY.md)**
   - 项目概述
   - 系统列表
   - 快速开始
   - 技术栈

2. **[系统集成文档](SYSTEMS_INTEGRATION.md)**
   - 详细的系统架构
   - 系统交互流程
   - 扩展指南
   - 性能考虑

3. **[快速参考](QUICK_REFERENCE.md)**
   - 常用操作速查
   - 代码示例
   - 信号参考
   - 调试命令

4. **[使用教程](TUTORIAL.md)**
   - 从入门到精通
   - 每个系统的详细使用说明
   - 综合应用示例
   - 常见问题解答

### 📊 项目报告

5. **[Phase 1-7 完成报告](PHASE_1-7_COMPLETION_REPORT.md)**
   - 完整的开发总结
   - 测试结果
   - 问题修复记录
   - 性能指标

6. **[Phase 7 测试总结](phase7_test_summary.md)**
   - 集成测试详情
   - 测试覆盖范围
   - 已知问题

## 🚀 快速导航

### 我想...

- **开始使用系统** → [使用教程](TUTORIAL.md)
- **查询 API** → [快速参考](QUICK_REFERENCE.md)
- **了解架构** → [系统集成文档](SYSTEMS_INTEGRATION.md)
- **查看进度** → [完成报告](PHASE_1-7_COMPLETION_REPORT.md)

### 按系统查找

- **等级和属性** → [教程 - 等级和属性系统](TUTORIAL.md#等级和属性系统)
- **装备** → [教程 - 装备系统](TUTORIAL.md#装备系统)
- **背包** → [教程 - 背包和快捷栏](TUTORIAL.md#背包和快捷栏)
- **技能树** → [教程 - 技能树系统](TUTORIAL.md#技能树系统)
- **成就** → [教程 - 成就系统](TUTORIAL.md#成就系统)
- **商店** → [教程 - 商店系统](TUTORIAL.md#商店系统)
- **掉落** → [教程 - 掉落系统](TUTORIAL.md#掉落系统)
- **存档** → [教程 - 存档系统](TUTORIAL.md#存档系统)

## 📖 推荐阅读顺序

### 新手入门
1. [系统总览](SYSTEMS_SUMMARY.md) - 了解项目整体
2. [使用教程 - 基础入门](TUTORIAL.md#基础入门) - 学习基本概念
3. [快速参考](QUICK_REFERENCE.md) - 开始编码

### 深入学习
1. [系统集成文档](SYSTEMS_INTEGRATION.md) - 理解架构
2. [使用教程](TUTORIAL.md) - 掌握每个系统
3. [完成报告](PHASE_1-7_COMPLETION_REPORT.md) - 了解实现细节

## 🔍 快速查找

### 常见操作

```gdscript
# 添加经验
GameManager.level_system.add_exp(100)

# 添加物品
var item = GameManager.item_database.get_item_by_id("health_potion_small")
GameManager.inventory_system.add_item(item, 5)

# 装备武器
var weapon = GameManager.equipment_database.get_equipment_by_id("iron_sword")
GameManager.equipment_system.equip_item(weapon)

# 保存游戏
GameManager.save_manager.save_game("slot_1")
```

详见 [快速参考](QUICK_REFERENCE.md)

## 📊 项目状态

✅ **Phase 1-7 全部完成**

- 等级和属性系统
- 装备系统
- 背包和快捷栏系统
- 技能树系统
- 成就系统
- 商店和掉落系统
- 存档系统

**所有集成测试通过** ✅

## 🛠️ 技术支持

遇到问题？

1. 查看 [使用教程 - 常见问题](TUTORIAL.md#常见问题)
2. 参考 [快速参考](QUICK_REFERENCE.md)
3. 查阅 [系统集成文档](SYSTEMS_INTEGRATION.md)

## 📝 文档更新

- **创建日期：** 2025
- **最后更新：** Phase 1-7 完成
- **文档版本：** 1.0
- **项目版本：** Phase 1-7

## 🎯 下一步

- [ ] UI 系统集成
- [ ] 战斗系统优化
- [ ] 关卡设计

查看完整计划：[系统总览 - 下一步计划](SYSTEMS_SUMMARY.md#下一步计划)
