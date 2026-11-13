# 27 — Prose: the Arches

**What to build:** Real prose for the Arches, replacing every placeholder line from its build ticket (10 — The Arches). Drafted against `docs/writing-guide.md` (structure, humour, characters, audit checklist) and `docs/CONTENT-GUIDE.md` (tone bible), in the voice of the existing `vein_raid` intro and claim/loot beats. The trains overhead are the event's signature: keep them a fact of the place, not a running joke. One section per beat (proposal §1.11); each beat is drafted, self-audited and listed under `PROSE-REVIEW:` in the report before the next starts:

1. **Intro + observations**: the opening card, and every observation tier, miss and security-profile variant line (§4).
2. **Perimeter**: the perimeter card's options and results.
3. **Route 1**: shutter: past the bench, the partition door.
4. **Route 2**: neighbour arch: the mechanic next door, the shared wall.
5. **Route 3**: trackside: along the line, the back vent, the drop into the arch.
6. **Detection**: window cards (outside, inside), alarm/searching, guard post, reinforcements arriving, Back out / Run for it results.
7. **Security set pieces + ending**: ward, camera, vein room, claim/loot, getaway.

Rules that bite here: one dry line per threat (CONTENT-GUIDE); observation lines describe what is there, never what to do about it; the ore types read as their subject (physics = fabric, life = people, fate = systems and chance, time = cycles, emotion = mood).

**Blocked by:** 10 — The Arches.

**Relevant files:** `data/events/raid_arches.json`, `.scratch/raid-events/raid-variants-proposal.md` §4, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (prose quarry only), `tests/test_event_content_lint.gd`.

**Status:** ready-for-agent

- [ ] All 7 beats written; no placeholder line left in the event
- [ ] Each beat self-audited against the writing guide's audit checklist
- [ ] Report lists every new line under `PROSE-REVIEW:`, grouped by beat
- [ ] `tests/test_event_content_lint.gd` and the event's tests pass
