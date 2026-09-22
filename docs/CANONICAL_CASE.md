# Internal story bible — The 11:42 Disappearance

**Spoilers. Never display or transmit this file wholesale to network clients.**

## Truth

Mariam notices electrical-bypass risks in her building. Fared, who authorized the bypass, alters a maintenance log at 23:31 to conceal earlier warnings. Hossam isolates the supply after an overheating incident, causing power loss from 23:32 to 23:50. The DVR/entrance camera has a small UPS; its internal clock is seven minutes fast. It shows Mariam entering at displayed 23:42, actual 23:35.

Mariam confronts Fared in the caretaker's office at 23:36. Fared knocks over a glass cup at 23:37; its break is audible, but there is no physical proof of violence. At 23:40 he leaves via the side service passage in a dark jacket. Amina sees only the garment from across the street and cannot identify his face. Someone stationed at the *main entrance* could sincerely report that no one passed it.

Mariam takes photos of the electrical records, uses the roof passage at 23:45, crosses the connected landing to Nabil's shop storage room, and seeks safety at 23:47. Nabil records her arrival. She isn't murdered or abducted. Fared's altered record remains relevant wrongdoing, but it is not proof of an assault.

## Epistemic taxonomy

- `truth.timeline[*]`: authored actual incident event; local authority only.
- `evidence[*].observed`: physical trace or attributed report, **not** actual event.
- `evidence[*].claim_time`: claimed/displayed time, possibly wrong.
- `evidence[*].reliability`: reason to verify / caution, **not** a numerical truth score.
- `found`: discovered by single-player. In LAN milestone, replace with per-role discoveries and shared discovery events.
- `links`: deduplicated verified relationships; their presence does not magically prove unrelated claims.

## Epistemic pitfalls covered

1. **Timestamp vs actual time:** CCTV overlay + independent clock note.
2. **Blackout vs camera operation:** power record + physical UPS.
3. **Clothing vs identity:** Amina's limited-visibility testimony.
4. **Breaking glass vs injury:** the cup without blood or other corroboration.
5. **Physical route vs whereabouts:** roof traces + shop record.

## First slice's evidence graph

`camera_frame ↔ clock_note`; `power_log ↔ ups`; `roof_marks ↔ shop_receipt`.

The full interpretation also requires the broken cup and witness's careful statement. A hypothesis is supported by specified discovered evidence and graph edges rather than clicking one arbitrary suspect.

## Later case-depth enhancements

- Split each location into multiple subobjects, avoid discovering every clue in the room on one interaction.
- Replay authentic camera video with inspectable clock, UPS, and lighting; add interrogation branches and visual contradictions.
- Distinguish direct observations, witness claims, player inferences, and communicated summaries in typed event schemas.
- Add multiple consistent conclusions, alternative investigative paths, nonbinary confidence statements.
- Simulate NPC schedules and create story state *from* events rather than loading a fixed mystery file as a simple list.
