# NOT THE SAME STORY / مش نفس القصة

Godot **4.7.2** source project for the first offline single-player investigation slice. This is **not** a completed commercial game, Android APK, or tested multiplayer release.

## Run

1. Install Godot 4.7.2 Standard (not .NET). Import `project.godot`.
2. Run with F6/F5 or: `godot --path .`.
3. New investigation → WASD/arrow keys or four touch arrows → approach one of the seven different diorama areas, approach a gold clue marker (each clue is inspected individually), then INSPECT / TALK (or E).
4. Gather clues at entrance, caretaker's office, maintenance room, street witness, rooftop, and shop; select two relevant clues on the board to connect them.
5. In `RECONSTRUCT`, challenge the clock and blackout assumptions, then test the roof route and the final narrative.
6. SAVE, return to menu, RESUME to reload. Language changes are immediate from the main menu; both locale resources are in `data/translations.json`.

## Test (requires Godot)

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/core_tests.gd
```

## Android export (requires Godot plus matching templates)

1. Editor → **Manage Export Templates**: install **4.7.2.stable** export templates.
2. Install JDK 17 and the Android SDK packages required by the Godot **4.7** Android export docs; set the Java SDK and Android SDK paths in Editor Settings.
3. Project → Export → Add **Android** preset; package `com.obieda.notsamestory`; orientation **landscape**. In this first single-player slice no INTERNET permission is necessary; **enable it when the real LAN transport is implemented**.
4. Export debug APK and test on the Infinix X689, Android 11. Check GPU, input, Arabic shaping, save/load and memory usage. Do not assume 60 FPS without measured results.

If the included tentative `export_presets.cfg` is rejected by your exact editor build, recreate the preset from the editor instead of guessing names. No Android toolchain, Godot binary, export templates, or device were available in the authoring runtime; an APK could not be produced here.

## Development limits

This first slice represents the scenario through 7 labeled physical areas and 8 clues, with 3 useful graph connections and hypothesis evaluation; each clue now has its own proximity interaction and original temporary floor marker. Rooftop and interior spaces are laid out as a readable flattened low-poly diorama, not yet 3D-connected floors or complete apartment interiors. The evidence board has draggable cards and verified connecting lines; zoom/pan and rich typed relationships are still outstanding; NPCs do not yet run schedules. LAN, QR, role secrecy and reconnection are future milestones and should not be described as existing features.

See `docs/CANONICAL_CASE.md`, `docs/ARCHITECTURE.md`, `docs/ART_DIRECTION.md`, and `docs/ASSET_MANIFEST.md`.

## CI

`.github/workflows/validate.yml` checks authored data, imports the project in **Godot 4.7.2**, executes Godot logic tests and a headless startup smoke test. Its dependent `android` job installs the matching official export templates and uploads a **debug-signed** Android APK as a workflow artifact if export succeeds. CI artifacts are not evidence of on-device frame rate or hotspot multiplayer. The first Android export must be verified in Actions before telling users an APK exists.
