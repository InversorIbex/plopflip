# gomFlip (plopflip)

**Fase 0 — feel prototype** for a stretchy gummy 2D platformer (Godot 4, Android landscape).

## Open in Godot

1. Install **Godot 4.3+**.
2. Import this folder as a project (`project.godot` at repo root).
3. Press **F5** / Play. Main scene: `scenes/main.tscn`.

## Controls

| Input | Action |
|-------|--------|
| A / D or ← / → | Move |
| S / ↓ | Crouch; enter pipe when on a tube |
| Space / W | Jump / double jump |
| J / LMB | Tongue attack |
| E | Interact (pipe) |
| On-screen pad + A/B/↓ | Touch landscape HUD |

## Fase 0 contents

- Squash/stretch gummy player (run, jump, crouch, double jump always on)
- Energy (caramelos) drains on move/jump and more on tongue
- Gradual fat stacks + water drop slim
- Short stage with multi-height platforms, pipe warp stub, Masticón enemy
- Landscape HUD + virtual controls

See the approved GDD in the project docs store for locked product rules.

## Demo capture

```bash
godot4 --path . --rendering-driver opengl3 -- --demo
```

Saves PNGs under Godot `user://fase0_demo/` (path printed in the console).

## Out of scope (later phases)

Worlds, difficulties, cosmetics shop, monetization, full enemy roster.
