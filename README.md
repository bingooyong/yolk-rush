# Yolk Rush

AI-native 3D party obstacle race. iOS first. Original IP.

This is **not** “make an Eggy Party clone.” It is a Godot **Game Factory**:
runtime + asset pipeline + AI agents. Yolk Rush is the first product.

## Frozen stack

- Engine: **Godot 4.7.2 stable** (not 4.8)
- Language: **GDScript only**
- Renderer: Mobile
- Assets: glTF 2.0 / GLB
- Multiplayer: server-authoritative (later)
- Target: iPhone / iPad via Xcode on a Mac

## Trellis (do this next)

Planning lives in [`.trellis/`](.trellis/README.md).

Current parent task: [`.trellis/tasks/09-04-factory-phase-1-3/`](.trellis/tasks/09-04-factory-phase-1-3/)

| Order | Task | Artifact |
|---|---|---|
| 1 | Hero pipeline | `prd.md` + `design.md` + `implement.md` |
| 2 | Snow Island golden scene | same |
| 3 | Visual + Performance QA | same |

Do not start Phase 2 until Phase 1 acceptance is green.

## Layout

```
project.godot
export_presets.cfg
docs/architecture/
data/characters/
data/levels/
data/contracts/
scenes/bootstrap/
scripts/core/
.trellis/spec/
.trellis/tasks/
```

## Principles (non-negotiable)

1. Gameplay ≠ Visual
2. Scene does not own business rules
3. Data-driven gameplay
4. Character mesh never owns collision
5. Level scene is layout only
6. AI assets must pass Asset Contract
7. New capability ⇒ Skill
8. Visual change ⇒ Visual Benchmark (≥85 pass)
9. Mobile change ⇒ Performance Benchmark
10. No temp code in Runtime

## iOS

Godot iOS export requires **macOS + Xcode**. Download Godot from
[godotengine.org/download/macos](https://godotengine.org/download/macos/)
(4.7.2 Universal, **not** the .NET build). The Godot Fund site is donations, not a paywall.

## License

Original work. Do not copy characters, maps, UI, or audio from other games.
