# add-glb-model

**Purpose**: 帮助将 GLB 3D 模型集成到 Yolk Rush 角色系统中

**Triggers**:
- "add glb model"
- "import character model"
- "添加 GLB"
- "导入角色模型"
- "集成 3D 模型"

**Context**: Yolk Rush 使用数据驱动的角色系统，支持在任何时候将占位符替换为真实 GLB 模型，无需修改 Gameplay 代码。

---

## Skill Workflow

### 1. 验证输入

**检查项**:
```bash
# 用户应提供 GLB 文件路径
ls -lh /path/to/model.glb

# 或者用户想为某个现有角色添加模型
cat data/characters/{character_id}.json | jq .character_id
```

**询问用户**:
- GLB 文件在哪里？（本地路径）
- 这是为哪个角色？（character_id）
- 是新角色还是替换现有占位符？

### 2. 验证 GLB 文件

```bash
# 使用项目验证工具
python3 tools/validate_glb.py /path/to/model.glb
```

**检查规范**:
- ✅ 文件格式正确（GLB binary GLTF）
- ✅ 文件大小合理（< 10MB mobile, < 50MB desktop）
- ✅ 命名规范（alphanumeric + _ or -）

**如果验证失败**:
- 提供修复建议（重新导出、优化、重命名）
- 推荐工具（Blender, Godot 编辑器）

### 3. 放置 GLB 文件

```bash
# 创建目标目录
mkdir -p assets/characters/

# 复制或移动文件
cp /path/to/model.glb assets/characters/{character_id}.glb

# 或让用户手动移动
echo "Please move your GLB file to: assets/characters/{character_id}.glb"
```

**路径规范**:
- 所有角色 GLB 放在 `assets/characters/`
- 文件名与 character_id 一致
- 使用 Godot 资源路径: `res://assets/characters/{character_id}.glb`

### 4. 更新角色 JSON

**读取现有数据**:
```bash
cat data/characters/{character_id}.json | jq .
```

**更新 visual_model 字段**:
```json
{
  "character_id": "yolk_hero",
  "display_name": "Yolk Hero",
  "visual_model": "res://assets/characters/yolk_hero.glb",  // 添加此行
  "skeleton": "Armature",  // 可选，根据 GLB 内部骨架名称
  "gameplay": { ... },
  "materials": [  // 可选，自定义材质
    {
      "mesh": "Body",
      "albedo_color": [1.0, 0.9, 0.3],
      "roughness": 0.42,
      "metallic": 0.0
    }
  ],
  "placeholder_color": [1.0, 0.9, 0.3]
}
```

**如果是新角色**:
- 从模板复制完整 JSON 结构
- 填充 gameplay 参数（height, radius, mass）
- 参考 `data/characters/yolk_hero.json`

### 5. 检查 GLB 内部结构

**在 Godot 编辑器中**:
```bash
# 打开 Godot 编辑器
open -a Godot

# 或使用项目脚本
./tools/open_godot.sh
```

**检查项**:
1. 在 FileSystem 面板找到 `assets/characters/{character_id}.glb`
2. 双击打开预览
3. 查看场景树：
   - 记录骨架名称（如 "Armature", "Skeleton"）
   - 记录 MeshInstance3D 名称（用于材质配置）
   - 检查模型朝向（-Z 应为前方）
   - 检查原点位置（脚底应在 Y=0）

**如果发现问题**:
- 朝向错误 → 在 Blender 中旋转并重新导出
- 原点偏移 → 在 Blender 中调整原点到脚底
- 尺寸不对 → 缩放到 1.4-1.7m 高度

### 6. 配置材质（可选）

**基础配置**:
```json
{
  "materials": [
    {
      "mesh": "Body",              // 从 Godot 场景树获取准确名称
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
  ]
}
```

**高级配置（未来）**:
- 纹理贴图（albedo_texture, normal_texture, etc.）
- 发光材质（emission_enabled, emission_color）
- 透明度（transparency, alpha_scissor）

### 7. 验证集成

```bash
# 验证角色数据完整性
python3 tools/validate_character.py data/characters/{character_id}.json

# 验证 GLB 引用
python3 tools/validate_glb.py data/characters/{character_id}.json
```

**预期输出**:
```
✅ Status: PASS
Character: yolk_hero
Visual Model: res://assets/characters/yolk_hero.glb

GLB Model Validation:
  ✅ extension: Extension: .glb
  ✅ size: Size: 1234.56 KB
  ✅ format: GLB version 2, length: 1263820 bytes
  ✅ naming: Name: yolk_hero (valid)
```

### 8. 运行时测试

```bash
# 在 Hero Studio 中查看角色
./tools/open_godot.sh scenes/studio/hero_studio.tscn

# 在雪岛场景中测试
./tools/open_godot.sh scenes/game/snow_island.tscn
```

**测试检查点**:
- ✅ GLB 模型正确加载（不再显示占位符）
- ✅ 模型位置正确（站在地面，不飘浮/下陷）
- ✅ 模型朝向正确（-Z 轴向前）
- ✅ 材质正确应用（颜色、粗糙度符合预期）
- ✅ 碰撞正常（Gameplay 层胶囊体独立工作）
- ✅ 移动流畅（WASD 控制无异常）

**如果模型不显示**:
```bash
# 检查控制台输出
# 查找 [CharacterVisual] 开头的日志
# 常见错误：
# - "GLB model not found" → 路径错误
# - "Failed to load GLB" → 文件损坏或格式错误
# - "Failed to generate scene" → GLB 内部结构问题
```

### 9. 性能检查

```bash
# 运行 QA 性能测试
godot --headless --script scripts/qa/qa_runner.gd
```

**性能指标**:
- FPS: ≥ 60 (目标)
- 内存: < 100MB (mobile 预算)
- Draw Calls: 尽可能少

**如果性能下降**:
- 检查多边形数量（< 10k triangles for mobile）
- 检查纹理大小（建议 1024x1024 或 2048x2048）
- 考虑 LOD（Level of Detail）优化

### 10. 文档更新

**更新清单**:
- [ ] 更新 `PHASE_1_3_REPORT.md` - 记录 GLB 集成
- [ ] 更新 `README.md` - 如果是主要角色
- [ ] 添加截图 - 在 `docs/screenshots/` 保存模型预览
- [ ] 更新 Git - 提交所有变更

```bash
git add assets/characters/{character_id}.glb
git add data/characters/{character_id}.json
git commit -m "feat: 添加 {character_id} GLB 模型

- 导入 GLB 模型到 assets/characters/
- 更新角色 JSON 的 visual_model 路径
- 配置自定义材质
- 性能测试通过: {fps} FPS, {memory} MB

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Error Handling

### GLB 加载失败 → 自动回退

系统设计确保**永不阻塞开发**:
```gdscript
if not visual_model_path.is_empty() and FileAccess.file_exists(visual_model_path):
    load_visual_model()  # 尝试加载 GLB
else:
    _spawn_placeholder()  # 回退到占位符
```

**用户体验**:
- 开发阶段：占位符让逻辑先行
- 有 GLB 时：自动升级视觉效果
- GLB 缺失时：游戏仍可运行

### 常见问题解决

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 模型不显示 | 路径错误 | 检查 JSON 中 `visual_model` 路径 |
| 模型飘浮 | 原点不在脚底 | Blender 中调整原点 |
| 模型朝向错误 | 导出设置问题 | 重新导出，确保 `-Z` 朝前 |
| 材质全黑 | 缺少光照 | 检查场景中的灯光节点 |
| 性能下降 | 多边形过多 | 优化模型，使用 LOD |
| 碰撞异常 | Gameplay 层依赖问题 | 确认 CharacterGameplay 仅使用胶囊体 |

---

## Reference Files

阅读这些文件以深入理解集成流程：

1. **`docs/GLB_INTEGRATION.md`** - 完整集成指南
2. **`scripts/visual/character_visual.gd`** - GLB 加载逻辑
3. **`data/characters/yolk_hero.json`** - 角色数据模板
4. **`data/contracts/character_schema.json`** - 数据规范
5. **`tools/validate_glb.py`** - GLB 验证工具
6. **`tools/validate_character.py`** - 角色数据验证

---

## Tips

### Blender 导出最佳实践

```
File → Export → glTF 2.0 (.glb)

Settings:
  Format: glTF Binary (.glb)  ✓
  +Y Up                       ✓
  Apply Modifiers             ✓
  Apply Transform             ✓
  
  Include:
    Cameras                   ✗
    Punctual Lights           ✗
    
  Geometry:
    UVs                       ✓
    Normals                   ✓
    Tangents                  ✓ (如果有法线贴图)
    Vertex Colors             ✓ (可选)
    
  Compression:
    Draco (optional for smaller files)
```

### Godot 导入最佳实践

在 Godot 编辑器中选择 GLB 文件 → Import 面板：

```
Root Type: Node3D
Root Name: (保持默认)

Meshes:
  Ensure Tangents: On (如果有法线贴图)
  Generate LODs: Off (手动控制)
  Create Shadow Meshes: On
  Light Baking: Disabled
  Lightmap Texel Size: 0.2

Skins:
  Use Named Skins: On

Animation:
  Import: On (如果有动画)
  FPS: 30
  Trimming: Off
```

### 性能优化 Checklist

- [ ] 多边形数 < 10,000 (mobile) 或 < 50,000 (desktop)
- [ ] 纹理尺寸 1024x1024 或 2048x2048
- [ ] 材质数量尽可能少（合并相同材质）
- [ ] 移除不可见面（内部几何体）
- [ ] 使用 VRAM 压缩（Godot 自动处理）
- [ ] 考虑 LOD（距离分级）
- [ ] 骨骼数量 < 75（如果有骨骼动画）

---

## Success Criteria

集成成功的标志：

✅ **数据层**:
- character JSON 包含正确的 `visual_model` 路径
- GLB 文件存在于 `assets/characters/`
- 通过 `validate_character.py` 和 `validate_glb.py` 验证

✅ **运行时**:
- 游戏启动时加载 GLB 模型，不显示占位符
- 控制台输出: `[CharacterVisual] GLB model loaded: res://...`
- 模型位置、朝向、尺寸正确

✅ **性能**:
- FPS ≥ 60
- 内存增加 < 50MB
- 无警告或错误日志

✅ **体验**:
- WASD 移动流畅
- 碰撞检测正常
- 视觉效果符合预期

当所有标准满足时，GLB 集成完成！🎉
