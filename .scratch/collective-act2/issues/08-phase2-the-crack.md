# 08 — Phase 2: The Crack (T10-T11)

**What to build:** The scripted trap — Hakim's vein taken despite everything,
then a second, precisely-targeted loss that proves the hardening insufficient.
Full detail in `.scratch/collective-act2/spec.md` §5.4, §6.10, §6.11, and §4.2
(why these must land as "despite" not "because of") — read it before starting.
This is the arc's hardest prose to get right per §11.3 items 2-3; Des must
read as genuinely baffled, not performing innocence.

**Blocked by:** 07 (checkpoint must have fired; T11 follows T10 by a short
delay, both timed after T9).

**Status:** ready-for-agent

- [ ] New one-off effect op `col_a2_force_vein_loss`: forced, unconditional,
      story-triggered ownership transfer (same bookkeeping shape as
      `Factions.resolve_rivalry_outcome()`'s transfer branch, but not rolled).
      No-ops safely if the target site has already changed hands.
- [ ] `col_a2_hakim_vein_lost` (T10): Hakim text via `pendingMessages`, timed
      to fire after T9 on the next non-clashing opportunity. Fires
      `col_a2_force_vein_loss` targeting `state.collective.hakimVeinId`.
- [ ] `col_a2_second_loss` (T11): fires `col_a2_force_vein_loss` (reused,
      parameterised) targeting whichever site T8a's `col_a2_nadia_defend`
      mission named — or, if that mission was never started, the Collective's
      current highest-security vein at the time T11 fires. `on_complete` sets
      `colA2SecondLossSeen true`.
- [ ] Both events added to `GameData.EVENT_IDS`; JSON files under
      `data/events/col_a2_{hakim_vein_lost,second_loss}.json`.
- [ ] Unit test: `col_a2_force_vein_loss` ownership transfer is unconditional,
      targets exactly the named site, no-ops safely if already transferred.
- [ ] PROSE-REVIEW flag raised on both, especially T11 card 3 (Des's baffled
      reaction).
