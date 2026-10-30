# 07 — Prose: `vein_raid` item approach rows and outcomes

**What to build:** Replace the placeholder prose added by tickets 03–06 in `vein_raid`: item approach row labels, toggle labels, success/failure outcome text for Powder, Wormhole, Pan's Rapture, Panic, Pandemonium and Time Pearl approaches, plus the fight-log lines for `enemyFirstStrike` and the fight-start effects (afraid, infighting, start hurt, guards fled). Must match the voice of the existing approach/route/caught beats. Follow `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`.

**Blocked by:** 04 — Wormhole / Pan's Rapture; 05 — Panic / Pandemonium; 06 — Time Pearl.

**Relevant files:** `data/events/vein_raid.json`, `systems/combat.gd` (`SITUATIONAL_MODS` lines), `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (prose quarry only).

**Status:** deprecated

> **DEPRECATED (2026-10-30):** The one-shot item approach rows this prose targets are replaced by the stage-tree rebuild (19). Prose lands as per-beat tickets written after 08's proposal is approved. Do not implement.

- [ ] Every placeholder line from 03–06 replaced
- [ ] Self-audit against the writing guide's audit checklist
- [ ] Report lists every new line under `PROSE-REVIEW:`
- [ ] `tests/test_event_content_lint.gd` passes
