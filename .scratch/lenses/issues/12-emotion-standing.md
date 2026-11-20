# 12 — Emotion lens: exact standing

**What to build:** Spec `.scratch/lenses/spec.md` "Emotion: standing". With an Emotion lens and Sense >= world gate, faction screens show the exact Threat toward the player and any grudge's days remaining. Contact cards already show `Rel. N`: check what relation info is currently hidden or banded and expose only that; if nothing is hidden, say so in the report and skip that part. Strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/faction_ai.gd`
- `systems/grudges.gd`
- `scenes/screens/factions.gd`
- `scenes/components/contact_cards.gd`
- `systems/lenses.gd`
- `docs/REFERENCE.md` §3.1c

**Acceptance:**
- [ ] Threat number and grudge countdown visible only with lens + gate, values read from systems.
- [ ] Human QA: faction screen lines.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
