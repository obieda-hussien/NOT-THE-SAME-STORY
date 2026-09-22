# Architecture and development status

## Single-player first-slice implementation

- `scripts/world/neighborhood.gd`: compact Cairo/Alexandria-inspired night block using actual `StaticBody3D` collisions: floors, four doorway frames and interactive door panels, cabinets/desks, street furniture, trees, pole trunks, an NPC. Visual-only decorations remain collision-free.
- `scripts/world/game.gd`: touch first-person controller with gravity/`CharacterBody3D.move_and_slide()`, look swipes and shoulder/surveillance camera switching, mobile HUD, evidence inspection, adaptive panels.
- `scripts/ui/touch_joystick.gd`, `look_pad.gd`: independent touch capture and reset, supporting two thumbs without keyboard controls.
- `scripts/ui/evidence_board.gd`: original portrait-enabled draggable mobile clue graph.
- `scripts/core/case.gd`: canonical timeline, discovered evidence, gated locations, useful graph links, hypothesis checks, versioned game snapshot.
- `scripts/core/saves.gd`: exact-byte SHA-256, tmp-file + backup rollback, restore.
- `scripts/core/loc.gd`: runtime ar_EG and en, data-driven labels, UI rebuilt on change.
- `assets/portraits/` and `assets/evidence/`: original SVG illustrations imported as renderable in-game image assets, **not** GLB models or finished animations.

## Automated verification

`tests/core_tests.gd` tests core truth/evidence/serialization. `tests/mobile_tests.gd` tests physical colliders, doors including collision toggles, camera states and Arabic-panel geometry. `tests/verify_source.py` tests data chronology and localization completeness. GitHub Actions exports an installable Android debug artifact after the logic suite succeeds. Device frame-rate, real touch feel, and Arabic shaping are *not* covered by headless CI.

## Not yet implemented

LAN/Hotspot, host-only truth, player-specific knowledge, QR entry and multiplayer reconnect, authored dialogue trees, meaningful room-by-room narrative, realistic rigged models, physical second floor/roof navigation, interaction raycasts, audio and accessibility settings. No multiplayer claims should be made for current APK.

Important multiplayer security limitation: current offline `data/case_1142.json` includes the authored truth in the APK. Before adding clients, split host-only truth from client-visible observations; never send this case JSON to peers, and document that the host device can access its own files. No internet-permission requirement until LAN transport lands.
