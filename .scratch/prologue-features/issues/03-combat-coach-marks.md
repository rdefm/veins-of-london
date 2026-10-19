# 03 — Combat coach marks

**What to build:** Fights can show one-line coaching hints, so the cold open and the gym's guided spar can teach without walls of text. Every move/item has a default hint line. A fight can supply per-round lesson lines (e.g. R1 "Read the intent. Guard the Strike.") and restrict which actions are highlighted/selectable that round. Source: `docs/story-restructure.md` Prologue steps 1 and 5, "Features to build" item 2.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_command_dock.gd`, `scenes/screens/combat.gd`, `systems/combat.gd` (fight dict fields), `data/constants.json` (hint lines). REFERENCE §3.7b. Prose rules: `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`.

**Status:** ready-for-agent

- [ ] Default per-move/item hint lines live in data, not code.
- [ ] A fight's data can set per-round lesson lines and an allowed/highlighted action set. Disallowed actions are shown but not selectable.
- [ ] Ordinary fights show no coach marks unless the fight asks for them (or a setting enables them).
- [ ] Coach-mark state is pure data in the fight dict and survives Rewind/save/load.
- [ ] Tests cover allowed-set enforcement. `PROSE-REVIEW:` is flagged for the hint lines.
