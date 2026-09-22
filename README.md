# NOT THE SAME STORY / مش نفس القصة

Godot **4.7.2** Android-first offline investigation. **Debug APKs are built by GitHub Actions** on successful commits; this is still a first playable slice, not a finished commercial title or a tested multiplayer game.

## Android touch controls

- **Left thumb:** analogue joystick; move and strafe into actual obstacles. Physics prevents walking through walls, closed doors, lamp posts, trees, furniture and the witness.
- **Right thumb:** swipe open scenery to look around. No keyboard or mouse gameplay bindings.
- **INSPECT / TALK:** collect one nearby clue or toggle a nearby door. Four room doors physically open/close and update collision.
- **CAMERA:** cycle first-person → behind-the-shoulder → entrance surveillance camera → first-person. The surveillance view stays fixed and pauses player motion; switch back to walk.
- **EVIDENCE BOARD:** touch cards to choose two clues; drag cards to arrange them; open RECONSTRUCT to test hypotheses.
- **SAVE** saves evidence, board positions, case result and location. The language toggle in the menu immediately rebuilds the layout without changing the investigation.

## Run and test

Import `project.godot` into **Godot 4.7.2 Standard** and use F5 **in the editor for development only**. The product's gameplay bindings target Android touch.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/core_tests.gd
godot --headless --path . --script tests/mobile_tests.gd
```

CI (`.github/workflows/validate.yml`) validates translated evidence keys and chronology, executes logic, geometry, camera and Arabic-panel tests, checks headless startup, then exports a debug APK for arm64 and armeabi-v7a and uploads it under **Actions → successful workflow → Artifacts**. Do not confuse the ZIP artifact with a directly hosted APK.

## Current artwork and performance scope

The user-provided detective-board screenshot is a **mood reference only**; its people/layout are not copied or included. Four original SVG headshots and four original SVG evidence illustrations are imported by Godot and shown in the mobile dialogue / board. Street architecture, four interior rooms, street furniture and NPCs are stylized original low-poly procedural meshes with collision, not final licensed high-quality character models. Missing: final GLB models/rigged animation, ambient audio, full vertically connected building, zoomable board, advanced NPC schedules, offline LAN, QR joining and reconnection.

The case remains authored and the canonical answer is packaged in this **single-player** APK. Do not ship multiplayer until secret host truth is separated from client resources. Frame rate, Arabic glyph coverage and aspect-ratio touch targets **still require physical testing on the target Infinix X689**, even with passing headless CI. The font uses the installed OS fallbacks; a properly licensed, packaged Arabic font is still a production task.

See `docs/CANONICAL_CASE.md`, `docs/ARCHITECTURE.md`, `docs/ART_DIRECTION.md` and `docs/ASSET_MANIFEST.md`.
