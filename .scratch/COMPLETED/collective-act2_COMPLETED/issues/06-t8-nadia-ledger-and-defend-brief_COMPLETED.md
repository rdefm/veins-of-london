# 06 — T8/T8a: Nadia's ledger, supplies, defend brief

**What to build:** Nadia gets the Collective organised — activates the three
new missions (ticket 01's evaluators), funds them, and the crafting checklist
gates the alarm-defend mission via a short follow-up scene. Full detail in
`.scratch/collective-act2/spec.md` §5.1, §6.8 and §6.8a — read it before
starting, especially the sequencing note ("supplies before defend, not
parallel") and the Des card-2 tone note (must read as almost nothing on a
first pass).

**Blocked by:** 01 (objectives evaluators), 02 (Phase 0).

**Status:** ready-for-agent

- [ ] `col_a2_nadia_ledger` (T8): cards per §6.8's beat outline. `on_complete`
      activates `col_a2_nadia_reseed` and `col_a2_nadia_supplies` **only**
      (not `col_a2_nadia_defend`); sets `colA2LedgerStarted true`; unlocks the
      Collective ledger Notes section (ticket 01) by advancing `colA2Stage`
      to `"hardening"`.
- [ ] Nadia hands over resources on T8 completion: enough to attempt the
      first mission immediately, and enough physics + emotion calc to attempt
      one craft each of Blast, Shield, and Pan's Prank.
- [ ] `data/objectives.json` entries for all three: `col_a2_nadia_defend`
      (`alarm_defend_wins`, `minCount`), `col_a2_nadia_reseed`
      (`faction_vein_seeded_count`, `factionId: "collective"`, `minCount`),
      `col_a2_nadia_supplies` (`items_crafted_set`,
      `recipeKeys: ["blast","shield","pansPrank"]`, `minEach: 1`).
- [ ] `col_a2_nadia_defend_brief` (T8a): enabled by `col_a2_nadia_supplies`
      completing. Sets `state.collective.nadiaDefendVeinId` to a chosen
      Collective vein; activates `col_a2_nadia_defend`; sets
      `colA2DefendBriefed true`.
- [ ] Pre-fight reminder card: when the alarm-defend encounter tied to
      `nadiaDefendVeinId` triggers (`Raiding.trigger_defend()`), for that
      specific vein and only once, one extra Nadia-voiced narration card
      prepends the fight's card sequence (§5.1's PROSE-REVIEW line). Generic
      alarm-defend encounters elsewhere are unaffected.
- [ ] If `nadiaDefendVeinId`'s vein is raided and lost before being defended,
      `col_a2_nadia_defend` re-targets a different Collective vein rather than
      dead-ending.
- [ ] `state.collective.nadiaDefendVeinId` (nullable String) added to
      `GameState` schema; `colA2LedgerStarted`, `colA2DefendBriefed` flags added.
- [ ] Test asserts the sequencing itself (supplies completing before defend
      activates), not just end state — crafting each recipe via
      `Crafting.attempt_craft()`.
- [ ] PROSE-REVIEW flag raised, especially T8 card 2 (Des) and T8a card 2.
