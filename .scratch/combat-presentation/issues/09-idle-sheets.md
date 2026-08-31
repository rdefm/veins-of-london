# 09 — Idle sheets (7 subjects)

**What to build:** Per §3/§4, swap ticket 01's placeholder boxes for real
idle-loop art, driven entirely through `data/combat_visuals.json` (ticket
08) — no changes to the fan-layout, glow, or strip logic ticket 01/02 built,
since those were already written against template-id-keyed placeholders.

Each subject gets a 2–3 frame ping-pong idle loop at ~6fps:

| Subject | Source |
|---|---|
| Player | `state.player` |
| Archie | `data/constants.json` → `contacts.archie` |
| Territorial Scrapper | `data/enemies.json` |
| Vein Guard | `data/enemies.json` |
| Orichalchum Dealer | `data/enemies.json` |
| The Raider | `data/enemies.json` (`GameData.ENEMY_HOME_RAID_RAIDER`) |
| Mugger | `Combat._spawn_mugger_instance()` — one sprite, mirrored/offset
  for the 2×/3× fan cases, no new art per extra Mugger instance |

Pipeline discipline from ticket 07 applies: generate one canonical sprite
per subject, never re-prompt per frame (produce every other pose by editing
that same image, or generate all keyposes as a single strip in one
generation), run every asset through `tools/pixelize.py` before import.

Ally roster is generic per `docs/combat-animation-vision.md` §3's note:
`Contacts.can_join_combat()` allows any recruited contact with a combat kit,
so the manifest entry is per ally-template, not hardcoded to Archie — today
only Archie exists (`data/constants.json`'s flagged content gap), so only
his sheet is produced now; a future 2nd/3rd combat ally slots into the same
manifest shape with no code change.

**Blocked by:** 01 (fan layout must exist to render into), 07 (palette +
pixelize.py pipeline)

**Assets needed:** **7 idle sheets**, ~64×104 native per §6.1, 2–3 frames
each: player, Archie, Territorial Scrapper, Vein Guard, Orichalchum Dealer,
The Raider, Mugger. Each generated as a single canonical image, quantised
through `tools/pixelize.py` against `data/palette.json`.

**Status:** ready-for-agent

- [ ] All 7 idle sheets exist, native ~64×104, imported Lossless/Nearest per
      ticket 08's locked settings, referenced from
      `data/combat_visuals.json` by template key
- [ ] Stage (ticket 01) renders the real idle loop for every subject that
      has one, falling back to the ticket 01 placeholder box for any
      subject whose sheet isn't in the manifest yet — the fallback path
      must still work cleanly, not error
- [ ] Idle loop plays ping-pong at ~6fps, matching §4's frame-budget table
- [ ] Multiple concurrent Mugger instances (2×/3× roster) reuse the single
      Mugger sheet, mirrored/offset per fan slot — no per-instance art
- [ ] No change was needed to ticket 01's fan-layout/glow code or ticket
      02's strip code to land this — confirms the placeholder-first
      architecture actually decouples art from layout as intended
