# 视觉升级资源获取指南

## 免费 3D 资源推荐

### 1. 角色模型 - Mixamo
**网址**: https://www.mixamo.com/

**步骤**:
1. 注册/登录（免费）
2. 选择角色（推荐: "Y Bot" - 简单干净的人形）
3. 下载格式: FBX for Unity (.fbx)
4. 将 .fbx 转换为 .glb（使用在线工具: https://products.aspose.app/3d/conversion/fbx-to-glb）
5. 放到 `assets/models/yolk_hero.glb`

**动画**（同样在 Mixamo）:
- Idle
- Walking
- Running
- Jump
- Punching (攻击)
- Hit Reaction (受击)
- Dying

### 2. 敌人模型 - Quaternius
**网址**: https://quaternius.com/packs/ultimatemonsterpack.html

**推荐模型**:
- Simple Enemy (任意怪物)
- 下载格式: .glb
- 放到 `assets/models/enemy_01.glb`

### 3. VFX 粒子 - Kenney
**网址**: https://kenney.nl/assets/particle-pack

**需要的贴图**:
- Spark (攻击特效)
- Circle (受击闪光)
- Star (Combo 星星)

### 4. 音效 - Freesound
**网址**: https://freesound.org/

**搜索关键词**:
- "punch impact" (攻击音效)
- "hit hurt" (受击音效)
- "action music loop" (背景音乐)

---

## 快速方案：使用 Godot 内置资源

如果不想下载外部资源，我可以先用 Godot 内置的 CSG 几何体创建简单但好看的视觉：

### 方案 A: 立即可用（无需下载）
1. **角色**: CSG 组合体（头+身体+四肢）+ 平滑着色器
2. **敌人**: CSG 球体 + 尖刺 + 发光材质
3. **VFX**: CPUParticles3D + 内置贴图
4. **音效**: AudioStreamGenerator（程序化音效）

### 方案 B: 等待资源下载
需要你手动下载上述免费资源后，我再集成。

---

## 我的建议

**立即执行方案 A**（无需等待）:
- 30 分钟内完成所有视觉升级
- 效果已经比红色胶囊好 10 倍
- 之后随时可以替换为真实模型

你想要哪个方案？
1. **方案 A** - 立即用 CSG 几何体升级（我马上开始）
2. **方案 B** - 等你下载外部资源后集成
