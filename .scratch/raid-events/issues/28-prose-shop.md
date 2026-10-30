# 28 — Prose: the Shop

**What to build:** Real prose for the Shop, replacing every placeholder line from its build ticket (11 — The Shop). Drafted against `docs/writing-guide.md` (structure, humour, characters, audit checklist) and `docs/CONTENT-GUIDE.md` (tone bible), in the voice of the existing `vein_raid` intro and claim/loot beats. Staff and customers are witnesses with their own evening going on, not obstacles; the till worker is a person. One section per beat (proposal §1.11); each beat is drafted, self-audited and listed under `PROSE-REVIEW:` in the report before the next starts:

1. **Intro + observations**: the opening card, and every observation tier, miss and security-profile variant line (§5).
2. **Perimeter**: the perimeter card's options and results.
3. **Route 1**: customer: past the till, the back room, the cellar stairs.
4. **Route 2**: yard door: the back yard, the yard door.
5. **Route 3**: cellar flap: the flap on the pavement, the drop into the cellar.
6. **Detection**: window cards (outside, inside), alarm/searching, guard post, reinforcements arriving, Back out / Run for it results.
7. **Security set pieces + ending**: ward, camera, vein room, claim/loot, getaway.

Rules that bite here: one dry line per threat (CONTENT-GUIDE); observation lines describe what is there, never what to do about it; the ore types read as their subject (physics = fabric, life = people, fate = systems and chance, time = cycles, emotion = mood).

**Blocked by:** 11 — The Shop.

**Relevant files:** `data/events/raid_shop.json`, `.scratch/raid-events/raid-variants-proposal.md` §5, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (prose quarry only), `tests/test_event_content_lint.gd`.

**Status:** ready-for-agent

- [ ] All 7 beats written; no placeholder line left in the event
- [ ] Each beat self-audited against the writing guide's audit checklist
- [ ] Report lists every new line under `PROSE-REVIEW:`, grouped by beat
- [ ] `tests/test_event_content_lint.gd` and the event's tests pass
