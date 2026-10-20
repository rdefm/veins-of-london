# 12 — Flat raid + debrief (deposit goal)

**What to build:** Prologue step 7. Keep `home_raid_intro` (a lone burglar, no Firm link). Make sure it's winnable with the pearls Archie kept back (first raid is forced), so it lands as the first win: "that first fight was brutal, but I won this one with something I made." Rewrite the win (and loss) debrief so Archie says the flat's a liability: you need cash to move somewhere safer, and he'll line up help (Des). The debrief sets the **deposit goal**, showing "Deposit: £X / £Y". Rent stays the immediate goal until it's paid.

**Prose rules:** follow `docs/writing-guide.md` (structure, humour, characters, audit) and `docs/CONTENT-GUIDE.md`. Extract and patch existing debrief prose where it still fits. Run the writing-guide audit before handing in. Flag changed prose with `PROSE-REVIEW:`.

**Blocked by:** 05 — Prologue chain skeleton.

**Relevant files:** `data/events/home_raid_intro.json`, `home_raid_debrief_win.json`, `home_raid_debrief_loss.json`, `systems/home.gd` (`deposit_goal()` ~L299, `depositGoalTier` flag), `systems/combat.gd` (home raid). REFERENCE §3.3, §3.8. `docs/story-restructure.md` Prologue step 7, Early Act 1 beats.

**Status:** ready-for-agent

- [ ] Raid winnable with the kept pearls; debrief sets the deposit goal and names Des.
- [ ] Rent row stays first until rent is paid.
- [ ] Writing-guide audit done; `PROSE-REVIEW:` flagged.
- [ ] Human on-device: the win feels earned by the crafted pearls.
