# Skill: create-character

- **id**: `create-character`
- **status**: `draft`
- **phase**: 1
- **inputs**: character brief; optional reference board; must target `data/characters/<id>.json`
- **outputs**: character JSON conforming to Asset Contract; optional placeholder-ready studio check
- **success_criteria**:
  - `tools/validate_character.gd` (or `tools/validate_data.py`) exits 0
  - `contract.origin == feet`, `facing == -Z`, `height_m` in [1.40, 1.70]
  - all required `*_animation` fields present
  - `collision_profile` present and not derived from mesh
  - materials use library names (`soft_plastic` / `cloth` / `rubber` …)
- **recipe**:
  1. Write / update `data/characters/<id>.json` (do not invent mesh collision).
  2. Run validator.
  3. Open `scenes/studio/hero_studio.tscn` (boot routes here in Phase 1).
  4. Confirm Gameplay + Visual siblings; silhouette readable on Z/X/C/V cameras.
  5. Until GLB passes contract, keep `PlaceholderYolk` via `CharacterVisual`.
- **non_goals**: level geometry, movement, wardrobe, gacha, second map
- **depends_on**: `validate-asset-contract` (draft via `tools/validate_character.gd`)
