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

## Why GitHub, not only Grok preview

The in-chat preview can hibernate. GitHub is the durable copy.
Clone this repo onto a Mac with Godot 4.7.2 when you are ready to export iOS.

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

## Phase status

| Phase | Status |
|---|---|
| 0 Factory foundation | specified |
| 1 Yolk Hero v1 art lock | locked in preview |
| 2 Snow Island Golden Scene | playable in preview |
| 3 Visual / Performance QA | next |
| iOS Xcode export | Mac only |

## iOS

Godot iOS export requires **macOS + Xcode**. The Grok Linux preview cannot
produce an IPA. Install Godot 4.7.2 on your Mac when you are ready to ship.

## License

Original work. Do not copy characters, maps, UI, or audio from other games.
