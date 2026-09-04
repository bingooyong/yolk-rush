# Implement — Phase 1

有序清单（一次一项 commit）：

1. `character_definition.gd` + 从 JSON 加载
2. `tools/validate_character.gd` 与失败用例说明写进 Skill
3. `character_gameplay.gd` 只建胶囊，不移动
4. `placeholder_yolk.gd` + `character_visual.gd`
5. `hero_studio.tscn`：灯光读 `lighting_profile.json`，四机位
6. `camera_profiles.json` 的 `hero_lock`
7. `.agents/skills/create-character/SKILL.md`
8. 改 `boot.tscn` 临时进 studio（Phase 2 再改去岛屿）
9. Mac 上 F5 目视 + validator

## Validation

```
godot --headless --script tools/validate_character.gd
```

手测：studio 里角色不是黑的；A/D 不要求（还没有移动）。

## Rollback

只回滚 `scripts/character/*` 与 studio 场景。不改 `yolk_hero.json` 字段名。
