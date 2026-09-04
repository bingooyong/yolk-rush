# GLB 模型集成指南

## 概述

Yolk Rush 采用**数据驱动 + 占位符优先**的开发模式。Phase 1 使用彩色胶囊占位符，真实 GLB 模型可以在任何时候无缝替换。

## 架构设计

### Gameplay ⊥ Visual 解耦

```
CharacterGameplay (CharacterBody3D)
    ↑ 零依赖
CharacterVisual (Node3D)
    ├── 占位符（默认）
    └── GLB 模型（可选）
```

- **Gameplay 层**：始终使用胶囊体碰撞，不关心视觉
- **Visual 层**：自动检测 GLB 存在，不存在则回退到占位符

## 添加 GLB 模型

### 1. 准备 GLB 文件

要求：
- **格式**：`.glb` (binary GLTF)
- **原点**：模型脚底对齐世界原点（feet origin）
- **朝向**：-Z 轴为前方（Godot 标准）
- **高度**：1.40m - 1.70m（人形角色标准）
- **单位**：米（Godot 默认）

推荐工具：
- Blender（导出选项：`+Y Up`, `Apply Transform`）
- Godot 编辑器（导入后检查预览）

### 2. 放置 GLB 文件

```bash
# 将 GLB 放入 assets 目录
mkdir -p assets/characters/
cp your_character.glb assets/characters/yolk_hero.glb
```

### 3. 更新角色数据

编辑 `data/characters/yolk_hero.json`：

```json
{
  "character_id": "yolk_hero",
  "display_name": "Yolk Hero",
  "visual_model": "res://assets/characters/yolk_hero.glb",  // 更新此路径
  "skeleton": "Armature",
  "gameplay": {
    "height": 1.48,
    "radius": 0.34,
    "mass": 70.0
  },
  "materials": [
    {
      "mesh": "Body",
      "albedo_color": [1.0, 0.9, 0.3],
      "roughness": 0.42,
      "metallic": 0.0
    },
    {
      "mesh": "Head",
      "albedo_color": [1.0, 0.85, 0.2],
      "roughness": 0.35,
      "metallic": 0.0
    }
  ],
  "placeholder_color": [1.0, 0.9, 0.3]
}
```

### 4. 验证导入

在 Godot 编辑器中：

1. 打开 `assets/characters/yolk_hero.glb`
2. 检查导入设置：
   - **Root Type**: Node3D
   - **Root Name**: 保持默认
   - **Animation**: 根据需要启用
3. 点击 **Reimport**

### 5. 测试

```bash
# 重新运行游戏
./tools/open_godot.sh scenes/game/snow_island.tscn
```

如果 GLB 加载失败，系统会自动回退到占位符，不会影响游戏运行。

## GLB 模型加载流程

```
CharacterVisual._load_character_visual()
    ↓
检查 visual_model_path 是否存在
    ↓ 是
load_visual_model()
    - GLTFDocument.append_from_file()
    - 生成 Scene
    - 清除占位符
    - 应用 materials_config
    ↓ 否
_spawn_placeholder()
    - 生成胶囊体 + 球体
    - 应用 placeholder_color
```

## 材质配置

### 基础材质

```json
{
  "mesh": "Body",              // 目标 Mesh 名称
  "albedo_color": [1.0, 0.9, 0.3],  // RGB (0.0-1.0)
  "roughness": 0.42,           // 0.0 (光滑) - 1.0 (粗糙)
  "metallic": 0.0              // 0.0 (非金属) - 1.0 (金属)
}
```

### 高级材质（未来扩展）

```json
{
  "mesh": "Armor",
  "albedo_texture": "res://assets/textures/armor_albedo.png",
  "normal_texture": "res://assets/textures/armor_normal.png",
  "roughness_texture": "res://assets/textures/armor_roughness.png",
  "metallic": 0.8,
  "emission_enabled": true,
  "emission_color": [0.3, 0.6, 1.0],
  "emission_energy": 2.0
}
```

当前版本仅支持基础材质，纹理支持已规划但未实现。

## 动画集成（未来）

当前 Phase 1 不包含动画，但架构已预留接口：

```json
{
  "animations": {
    "idle": "res://assets/animations/yolk_hero_idle.res",
    "walk": "res://assets/animations/yolk_hero_walk.res",
    "jump": "res://assets/animations/yolk_hero_jump.res"
  }
}
```

动画系统将在后续 Phase 实现。

## 故障排查

### GLB 不显示

**检查控制台输出**：
```
[CharacterVisual] GLB model not found: res://assets/characters/yolk_hero.glb
```
→ 路径错误或文件缺失

**检查 Godot 导入**：
- 在 FileSystem 面板查看 GLB 文件
- 右键 → Reimport
- 查看 Import 面板的错误信息

### 模型朝向错误

如果角色面向错误方向：

1. 在 Blender 中检查模型朝向（-Y 应为前方）
2. 导出时确保 `+Y Up` 已勾选
3. 或在 JSON 中添加 `visual_rotation: [0, 180, 0]`（临时方案）

### 模型偏移

如果模型不在地面：

1. 在 Blender 中将脚底对齐世界原点
2. 应用所有 Transform（Ctrl+A → All Transforms）
3. 导出时勾选 `Apply Transform`

### 材质未应用

检查 `materials_config` 中的 `mesh` 名称是否匹配 GLB 内部的 MeshInstance3D 名称：

```bash
# 在 Godot 编辑器中打开 GLB，查看场景树
# 记录 MeshInstance3D 的确切名称
```

## 性能优化

### LOD（Level of Detail）

未来支持多 LOD：

```json
{
  "visual_model": "res://assets/characters/yolk_hero.glb",
  "lod_levels": [
    {"distance": 0, "mesh": "yolk_hero_high.glb"},
    {"distance": 20, "mesh": "yolk_hero_medium.glb"},
    {"distance": 50, "mesh": "yolk_hero_low.glb"}
  ]
}
```

当前版本不支持，所有距离使用同一模型。

### 顶点预算

建议：
- **Mobile**: < 10,000 triangles
- **Desktop**: < 50,000 triangles
- **Hero (重要角色)**: 可适当放宽

### 纹理预算

建议：
- **Albedo**: 1024x1024 (Mobile), 2048x2048 (Desktop)
- **Normal/Roughness**: 1024x1024
- **Compression**: VRAM Compressed (导入时自动)

## 示例工作流

### 从 Mixamo 导入角色

1. 下载 FBX 格式（带 T-Pose）
2. 在 Blender 中打开：
   - 旋转 -90° X 轴（Mixamo 使用 Y-Up）
   - 缩放到 1.6m 高度
   - 应用所有 Transform
   - 导出为 GLB（`+Y Up`, `Apply Transform`）
3. 放入 `assets/characters/`
4. 更新 JSON `visual_model` 路径
5. 测试运行

### 从 Blender 创建角色

1. 建模时保持脚底在原点
2. 朝向 -Y 轴（前方）
3. 高度 1.4-1.7m
4. 导出设置：
   - Format: glTF 2.0 (.glb)
   - +Y Up: ✓
   - Apply Modifiers: ✓
   - Apply Transform: ✓
5. 导出到 `assets/characters/`

## Contract 验证

GLB 模型会经过 Character Schema 验证：

```bash
# 验证角色数据
python3 tools/validate_character.py data/characters/yolk_hero.json
```

验证项：
- ✅ `visual_model` 路径格式正确
- ✅ `gameplay.height` 在合理范围
- ✅ `materials` 配置格式正确
- ⚠️ GLB 文件存在性（运行时检查）

## 未来扩展

Phase 1 实现了基础 GLB 加载，未来将支持：

- ❌ 动画系统（AnimationPlayer integration）
- ❌ 骨骼绑定（Skeleton IK）
- ❌ 材质纹理（Albedo/Normal/Roughness maps）
- ❌ LOD 系统（距离分级）
- ❌ 实时换装（Material/Mesh swap）
- ❌ 粒子特效（Attachment points）

这些功能已规划在 Phase 4+ 或更远的迭代。

## 总结

Yolk Rush 的 GLB 集成设计确保：

1. **开发不阻塞** - 占位符让逻辑先行
2. **无缝替换** - GLB 有就用，没有就占位
3. **数据驱动** - 一个 JSON 控制所有视觉
4. **性能优先** - Gameplay 层零 GLB 依赖

只需准备好 GLB，更新 JSON 路径，系统自动处理其余。
