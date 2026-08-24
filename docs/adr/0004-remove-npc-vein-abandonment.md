# Remove NPC-vein abandonment; retune claim rate and prune-back target

adr/0002 gave faction-claimed sites two independent daily ways to die: the
growth-collapse-at-zero roll every vein (player or faction) already faces,
plus a second, separate roll — NPC-abandonment — that could delete a
faction-claimed site outright regardless of its vein's growth. Ticket 22
already retuned that second roll once (0.05/0.01/0.15 → 0.02/0.005/0.08)
because it was visibly emptying the map; by ticket 73, factions were still
losing veins fast enough to trend toward vanishing rather than holding a
readable presence. Retuning the same independent roll a third time was
judged unlikely to hold — two stacked death rolls compound in a way that's
hard to reason about or tune predictably, and one of them (abandonment) was
never load-bearing for anything else in the design.

**Decision:** remove `Sites.roll_npc_abandonment()` / `Sites.
npc_abandonment_chance()` entirely (ticket 40). A faction vein now dies
**only** via `Cultivating.collapse_vein()` — the same growth-collapse-at-
zero roll (`collapseChancePerDay`, 0.15/day once pinned at 0) a player vein
already faces, branching only on which owner's site gets deleted vs.
reverted. `TimeSystem.daily_tick()`'s old step ⑤c (NPC-abandonment) is gone;
every step from the old ⑤d onward shifted up one letter.

This changes what actually keeps a faction vein population in check, so two
follow-on numbers needed retuning in the same pass (ticket 73):

- **NPC-claim rate** (`Sites.npc_claim_chance()`): removing abandonment
  roughly extends a freshly-claimed vein's expected lifespan (a fresh claim
  starts at `seedGrowth` (20), below neutral, so absent any upward force it
  decays to 0 on a fixed schedule — 8 daily-tick steps under the drift
  table — then rolls `collapseChancePerDay` each day it sits there,
  expectation ~6.7 more days: ~10 days average lifespan before this ticket,
  once abandonment's extra early-death pressure is layered in, to ~14 days
  without it). Retuned down from `clamp(0.03 + 0.02×tierIndex +
  0.01×ageDays, 0, 0.25)` to `clamp(0.02 + 0.01×tierIndex + 0.005×ageDays,
  0, 0.15)` — base and cap down roughly a third, tier/age sensitivity
  halved — to track that slower turnover rather than compound it.
- **Faction-vein growth prune-back target** (`Sites.
  FACTION_PRUNE_BACK_TARGET`): this was the more serious of the two. The
  prune-back mechanic (faction-vein-ownership T02/vein-growth-state T04)
  resets a faction vein's growth once it drifts to the ceiling (≥85), since
  growth has 0 drift at the ceiling and would otherwise park there forever.
  Its reset target was 55 — inside the "dormant" band (45–55, drift 0).
  While abandonment existed, a vein parked at 55 could still die via that
  independent roll; once abandonment is gone, a vein reset to 55 never
  drifts again at all (direction only flips at neutral (50), and dormant's
  own drift is 0) — a de facto immortal vein, silently accumulating without
  bound over a long game. Retuned to 40 ("thinning" band, 30–44, drift 1
  leftward), so a prune-backed vein resumes its walk toward 0 and
  eventually reaches the same collapse-at-zero fate as any other vein. This
  is what makes a steady faction-vein population possible at all now that
  abandonment is gone, not merely a nice-to-have tuning pass. Threshold
  (85) and chance (0.40) are unrelated to this bug and were left as-is.

Both retuned numbers are drafts pending human balance sign-off after
playtesting, same as the ticket's own framing — they're derived from the
drift-model math above, not from a hard target vein count.

**Superseded:** this decision replaces adr/0002's NPC-abandonment
half only — adr/0002's `siteCap`/claim-state/reroll-eligibility decisions
are unaffected and still stand.

**Status:** accepted (2026-08-24, bugfixes-73/`.scratch/0-bugfixes/issues/73-faction-vein-churn-balance.md`, executing the previously-unactioned bugfixes-40).
