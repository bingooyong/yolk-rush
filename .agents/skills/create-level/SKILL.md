# Skill: create-level

- **id**: `create-level`
- **status**: `draft`
- **phase**: 2
- **inputs**: Level DSL JSON under `data/levels/<id>.json` (roles only from DSL six)
- **outputs**: valid JSON + `LevelBuilder` world with all non-recovery segments + recovery catcher
- **success_criteria**:
  - `tools/validate_level.gd` / `tools/validate_data.py` exit 0
  - roles ⊆ `start_hall|main_lane|challenge|shortcut|recovery|finish_hall`
  - lighting id matches `data/contracts/lighting_profile.json`
  - builder lays geometry along −Z; ice uses low friction; recovery catches falls
  - Phase 1–3: only `snow_island_01` may be the golden playable level
- **recipe**:
  1. Author / edit level JSON (no business rules in `.tscn`).
  2. Run validators.
  3. Open `scenes/match/match.tscn` (boot routes here in Phase 2).
  4. Confirm W/A/D/Space, recovery respawn, finish print.
  5. Do not open a second map until Visual QA ≥ 85.
- **non_goals**: shop, gacha, multiplayer, second map, CSG dependency
- **depends_on**: `validate-asset-contract` (character still required for match)
