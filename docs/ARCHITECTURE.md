# Architecture and milestones

## Current scope — offline single-player first-slice **source code**

- `scripts/core/case.gd`: stable evidence IDs, location-gated collection, hypothesis checks, graph, snapshot schema.
- `scripts/core/loc.gd`: runtime `en` ↔ `ar_EG`; UI rebuilding without changing state.
- `scripts/core/saves.gd`: SHA-256 checked, temp file + backup restore on interrupted replacement.
- `scripts/world/game.gd`: procedural diorama and mobile-first touch UI. Camera moves with one investigator.
- `scripts/ui/evidence_board.gd`: draggable cards and confirmed graph edges; saved card positions.
- `data/case_1142.json`: authored case truth and clue definitions; **not a production client-safe case bundle**.
- `data/translations.json`: language-independent keys and translations.
- `tests/core_tests.gd`: Godot headless logic tests. **Run in Godot; not executed in the authoring sandbox.**

## Multiplay security plan (NOT IMPLEMENTED in this first slice)

Host is authoritative, validates every interaction against player position and role, and holds secret event state. Messages contain only player-approved observations or public board IDs. Session/player IDs are opaque, reconnect tokens are unguessable and expire, event IDs enforce idempotence, board ops have revision numbers. Never trust client-submitted discoveries/times, nor send the entire case JSON to a client.

Important caveat: the *current offline build* includes `data/case_1142.json` and thus includes authored truth in the exported APK. For true client-memory secrecy, split server-truth and publicly authored observations into separate runtime and export bundles before networking ships; doing so alone cannot protect secrets from the physical host or a user who reverse-engineers a game with publicly distributed identical case content. A dedicated LAN-host-only authored-truth DLC/bundle can improve non-host clients' protection.

ENet UDP for room replication in Milestone 4; optional UDP discovery broadcast and manual IP fallback. Android `INTERNET` export permission required. Android may block/multicast-gate discovery and hotspot traffic; no hardcoded gateway. QR join requires encoding the currently bound local IP, port, and room token—not unverified assumptions.

## Planned milestones

1. M1: Godot project + Android export **source setup** (APK not yet built).
2. M2: mobile camera/touch, evidence interaction, bilingual board and hypothesis evaluation in source (runtime validation outstanding).
3. M3: authored first case with actual explorable interiors, dialogue, sounds, clocks, full timeline renderer.
4. M4: authoritative LAN protocol, role-specific payloads, reconnection, private knowledge, 2–4 device tests.
5. M5: consistent licensed GLB assets + audio, animation, inspection screens, measured low-end Android performance.

## Notes

The initial diorama uses original procedural box meshes so there are no external-asset redistributions. The user-supplied detective image has been inspected for broad visual art direction (see `docs/ART_DIRECTION.md`); it is not an asset licensed for redistribution. SystemFont uses installed Android Noto/Roboto fallbacks; a distributable font with a verified redistribution license must be chosen and tested before shipping. No artwork, generated 3D asset, APK, real multiplayer, or device FPS has been verified yet.
