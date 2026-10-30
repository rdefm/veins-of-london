# 26 — Prose: the Yard (`vein_raid`)

**What to build:** Real prose for the Yard (`vein_raid`), replacing every placeholder line from its build ticket (19 — Rebuild `vein_raid` as the Yard stage tree). Drafted against `docs/writing-guide.md` (structure, humour, characters, audit checklist) and `docs/CONTENT-GUIDE.md` (tone bible), in the voice of the existing `vein_raid` intro and claim/loot beats. Existing prose the proposal keeps (intro, observation texts, claim/loot) stays unless a beat needs a seam patched. One section per beat (proposal §1.11); each beat is drafted, self-audited and listed under `PROSE-REVIEW:` in the report before the next starts:

1. **Intro + observations**: the opening card, and every observation tier, miss and security-profile variant line (§3).
2. **Perimeter**: the perimeter card's options and results.
3. **Route 1**: front gate: across the yard, the depot door.
4. **Route 2**: back window: the window, the back corridor.
5. **Route 3**: roof: the fire escape, the skylight, the drop into the vein room.
6. **Detection**: window cards (outside, inside), alarm/searching, guard post, reinforcements arriving, Back out / Run for it results.
7. **Security set pieces + ending**: ward, camera, vein room, claim/loot, getaway.

Rules that bite here: one dry line per threat (CONTENT-GUIDE); observation lines describe what is there, never what to do about it; the ore types read as their subject (physics = fabric, life = people, fate = systems and chance, time = cycles, emotion = mood).

**Blocked by:** 19 — Rebuild `vein_raid` as the Yard stage tree.

**Relevant files:** `data/events/vein_raid.json`, `.scratch/raid-events/raid-variants-proposal.md` §3, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (prose quarry only), `tests/test_event_content_lint.gd`.

**Status:** ready-for-agent

- [ ] All 7 beats written; no placeholder line left in the event
- [ ] Each beat self-audited against the writing guide's audit checklist
- [ ] Report lists every new line under `PROSE-REVIEW:`, grouped by beat
- [ ] `tests/test_event_content_lint.gd` and the event's tests pass
