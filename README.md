# gomFlip

Platformer 2D Android (landscape) — gominola elástica, lengua, caramelos y mundos dulces.

**Motor:** Godot 4.3+  
**GDD:** ver Project store `docs/game-design.md`

## Cómo jugar

1. Abrir la carpeta en Godot 4.3+
2. Ejecutar `scenes/main.tscn`
3. Demo captura: `godot --path . --rendering-driver opengl3 -- --demo`

**Controles:** A/D mover · S agachar/tubo · Space salto · J lengua · pad táctil + A/B

## Contenido

- 3 dificultades (Fácil / Medio / Difícil)
- 3 mundos × 4 stages (fábrica, jardín, alcantarillas)
- Stretch jelly unificado, doble salto, lengua, enemigos E1–E3
- Caramelos / engordantes / gotas / estrellas / score
- Colores + cosméticos de 8 temporadas (siempre disponibles)
- Menús: título, dificultad, mapa, cosméticos, pausa, resultados
- Preset export Android (`export_presets.cfg`)

## Build Android

Requiere Android SDK + plantillas de export Godot. Preset: **Android** → `build/gomFlip.apk`, orientation landscape vía `project.godot` (`window/handheld/orientation=4`).
