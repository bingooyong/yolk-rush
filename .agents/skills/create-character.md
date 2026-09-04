# create-character

创建新角色的 AI Agent Skill，通过对话式交互生成符合 Yolk Rush 角色规范的 JSON 定义。

## 触发条件

当用户说以下任何内容时，触发此 skill：
- "创建新角色"
- "create a character"
- "添加角色"
- "生成角色 JSON"
- "make a new character"

## 角色规范（Contract Schema）

根据 `data/contracts/character_schema.json`，一个合法的角色定义必须包含：

```json
{
  "character_id": "unique_lowercase_id",
  "display_name": "Display Name",
  "model_path": "res://assets/models/characters/character_name.glb",
  "collision": {
    "shape": "capsule",
    "radius": 0.4,
    "height": 1.4
  },
  "movement": {
    "base_speed": 5.0,
    "sprint_speed": 8.0,
    "jump_velocity": 7.5
  },
  "visual": {
    "placeholder_color": "#RRGGBB",
    "scale": 1.0
  },
  "metadata": {
    "description": "Character description",
    "tags": ["tag1", "tag2"]
  }
}
```

## 工作流程

### 1. 信息收集（对话式）

询问用户以下信息：

**必需字段：**
- **角色 ID**：小写、下划线分隔（例如：`snow_knight`, `fire_mage`）
- **显示名称**：游戏内显示的名字（例如："雪地骑士"）
- **描述**：一句话描述角色特点
- **占位符颜色**：十六进制颜色代码（例如：`#FFD700` 金色）

**可选字段（提供默认值）：**
- 碰撞半径（默认：0.4）
- 碰撞高度（默认：1.4）
- 移动速度（默认：5.0）
- 冲刺速度（默认：8.0）
- 跳跃速度（默认：7.5）
- 缩放比例（默认：1.0）
- 标签（默认：["hero"]）

### 2. 生成 JSON

根据用户提供的信息，生成完整的角色定义 JSON：

```json
{
  "character_id": "用户输入",
  "display_name": "用户输入",
  "model_path": "res://assets/models/characters/[character_id].glb",
  "collision": {
    "shape": "capsule",
    "radius": 用户输入或默认0.4,
    "height": 用户输入或默认1.4
  },
  "movement": {
    "base_speed": 用户输入或默认5.0,
    "sprint_speed": 用户输入或默认8.0,
    "jump_velocity": 用户输入或默认7.5
  },
  "visual": {
    "placeholder_color": "用户输入",
    "scale": 用户输入或默认1.0
  },
  "metadata": {
    "description": "用户输入",
    "tags": 用户输入或默认["hero"]
  }
}
```

### 3. 保存文件

将生成的 JSON 保存到：
```
data/characters/[character_id].json
```

### 4. 验证

使用验证工具检查生成的 JSON：

```bash
# GDScript 验证
godot --headless --path . --script tools/validate_character.gd -- data/characters/[character_id].json

# Python 验证
python tools/validate_character.py data/characters/[character_id].json
```

### 5. 确认

告知用户：
- JSON 文件已保存到哪里
- 验证结果（通过/失败）
- 如何在游戏中使用这个角色：
  ```gdscript
  var char_def := CharacterDefinition.new()
  char_def.load_from_file("res://data/characters/[character_id].json")
  ```

## 示例对话流程

**User**: "创建一个火焰法师角色"

**Assistant**:
```
好的，让我帮你创建一个新角色。我需要一些信息：

1. **角色 ID**（小写，下划线分隔）：建议使用 `fire_mage`
2. **显示名称**：例如 "火焰法师"
3. **描述**：一句话描述这个角色
4. **占位符颜色**：十六进制颜色（例如 #FF4500 橙红色）

其他参数我会使用默认值，稍后你可以调整。请提供上面的信息。
```

**User**: "ID 用 fire_mage，名字叫'烈焰术士'，是个专精火系魔法的远程角色，颜色用 #FF6347"

**Assistant**:
```
收到！正在生成角色定义...

[生成并保存 JSON 到 data/characters/fire_mage.json]

✅ 角色创建成功！

文件位置: data/characters/fire_mage.json
验证状态: 通过所有合规检查

你现在可以在代码中使用：
```gdscript
var fire_mage := CharacterDefinition.new()
fire_mage.load_from_file("res://data/characters/fire_mage.json")
```

需要调整移动速度或碰撞参数吗？
```

## 错误处理

### 无效的角色 ID
- 如果包含大写字母或空格，自动转换为小写+下划线
- 如果包含特殊字符，拒绝并要求重新输入

### 无效的颜色代码
- 如果不是 `#RRGGBB` 格式，提示正确格式
- 提供常用颜色示例：
  - 金色：`#FFD700`
  - 红色：`#FF0000`
  - 蓝色：`#0080FF`
  - 绿色：`#00FF00`

### 文件已存在
- 检查 `data/characters/[character_id].json` 是否存在
- 如果存在，询问是否覆盖或使用不同的 ID

### 验证失败
- 显示具体的验证错误
- 询问是否要修正错误

## 约束

### 必须遵守的规范

1. **GLB 模型规范**（即使暂时不存在 GLB 文件）：
   - Feet origin：角色脚底在 Y=0
   - Forward facing：角色面向 -Z 轴
   - Height：1.40 - 1.70 米（人形角色）

2. **碰撞体规范**：
   - 形状固定为 `capsule`（胶囊体）
   - 半径：0.3 - 0.6 米
   - 高度：1.0 - 2.0 米
   - 高度应略小于模型高度

3. **移动参数合理范围**：
   - base_speed: 3.0 - 8.0
   - sprint_speed: 6.0 - 12.0
   - jump_velocity: 5.0 - 10.0

4. **文件命名**：
   - JSON 文件名必须与 character_id 一致
   - 路径固定为 `data/characters/`

## 完整示例

### 输入
```
角色 ID: yolk_hero
显示名称: 蛋黄英雄
描述: Yolk Rush 的第一个可玩角色，勇敢的蛋黄战士
颜色: #FFD700
```

### 输出 JSON
```json
{
  "character_id": "yolk_hero",
  "display_name": "蛋黄英雄",
  "model_path": "res://assets/models/characters/yolk_hero.glb",
  "collision": {
    "shape": "capsule",
    "radius": 0.4,
    "height": 1.4
  },
  "movement": {
    "base_speed": 5.0,
    "sprint_speed": 8.0,
    "jump_velocity": 7.5
  },
  "visual": {
    "placeholder_color": "#FFD700",
    "scale": 1.0
  },
  "metadata": {
    "description": "Yolk Rush 的第一个可玩角色，勇敢的蛋黄战士",
    "tags": ["hero", "yolk"]
  }
}
```

### 验证输出
```
✅ Character definition is valid
✅ All required fields present
✅ Collision parameters within range
✅ Movement parameters reasonable
✅ Color format correct (#RRGGBB)
✅ Model path follows convention
```

## 高级功能（可选）

### 批量创建
如果用户提供多个角色名称，询问是否批量创建：
```
检测到多个角色名称，是否要批量创建？
1. yolk_hero
2. fire_mage
3. ice_knight

每个角色将使用默认参数，你可以稍后单独调整。
```

### 从模板复制
如果用户说"基于 yolk_hero 创建新角色"：
1. 读取 `data/characters/yolk_hero.json`
2. 复制所有参数
3. 只修改 character_id、display_name、描述
4. 保留移动参数和碰撞参数

### 生成配套文件
创建角色后，可选生成：
- `README_[character_id].md` - 角色设计文档
- `assets/models/characters/[character_id]_placeholder.txt` - 提醒需要添加 GLB 模型

## 注意事项

1. **不创建 GLB 模型**：此 skill 只生成 JSON 定义，不处理 3D 模型
2. **占位符视觉**：生成的角色会使用 `character_visual.gd` 的占位符渲染（彩色胶囊）
3. **数据驱动**：生成的 JSON 会被 `character_definition.gd` 和 `character_gameplay.gd` 自动读取
4. **验证强制**：每次生成后必须运行验证，确保符合 schema

## 相关文件

- `data/contracts/character_schema.json` - 角色定义规范
- `scripts/character/character_definition.gd` - 角色数据加载器
- `tools/validate_character.gd` - GDScript 验证器
- `tools/validate_character.py` - Python 验证器
- `data/characters/yolk_hero.json` - 参考示例

## 权限

此 skill 会：
- ✅ 读取现有角色 JSON（用于参考和检查重复）
- ✅ 写入新的角色 JSON 到 `data/characters/`
- ✅ 运行验证工具（只读操作）
- ❌ 不修改引擎代码
- ❌ 不创建或修改 3D 模型文件

---

**Skill 版本**: 1.0  
**Trellis Phase**: Phase 1 - Hero Pipeline  
**最后更新**: 2026-09-04
