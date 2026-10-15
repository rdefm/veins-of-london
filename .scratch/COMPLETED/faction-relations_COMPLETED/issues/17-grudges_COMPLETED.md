# 17 — Grudges

**What to build:** A successful faction raid on the player (vein, stockpile, shortfall steal) records a "score to settle" grudge: `state.grudges[factionId] = { sinceDay, siteId?, district }`. The grudge is answered by a player raid on that faction, or by a security upgrade on a vein in the grudge district, within `grudgeWindowDays` (TBD). Answering gives a raid-odds bonus on the lost site and a reputation gain. Unanswered grudges that expire make the player look soft: a decaying pressure term against the player from every faction. The grudge shows on the faction/district UI.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/raiding.gd` (raid resolution, player raids), `systems/faction_sim.gd` (shortfall steals), `systems/cultivating.gd` (security upgrade), `systems/faction_ai.gd` (pressure term), `autoload/SaveManager.gd` (backfill `grudges`), faction/district UI readers, tests: `test_raiding`, `test_faction_ai`, new `test_grudges`. REFERENCE.md new Grudges §, §3.12. CONTEXT.md: Grudge.

**Status:** ready-for-agent

- [ ] Each successful faction raid type records or refreshes a grudge
- [ ] A player raid on the faction or a security upgrade in the district within the window answers it
- [ ] Answering applies the odds bonus on the lost site and the reputation gain
- [ ] An expired, unanswered grudge adds the decaying "looks soft" pressure for all factions
- [ ] Backfill + Rewind safe; an answer hook other systems can call (for 18, 19)
