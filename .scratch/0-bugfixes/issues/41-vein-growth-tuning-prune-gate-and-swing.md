# 41 — Vein growth tuning: always-prune + gentler swings

**What to build:** Two related growth-economy changes, both in `systems/cultivating.gd` / `data/vein_growth.json`:

1. **Always-prune.** `Cultivating.prune_gate()` (`cultivating.gd:279-284`) currently disables the prune button whenever `prune_yield(vein, depth) <= 0` (i.e. pruning at/below neutral growth), showing "Nothing to take at or below neutral." Confirmed by the human as the exact restriction they want gone. Remove this yield-based disable — the button stays enabled whenever the player can otherwise afford the action (the existing `Travel.can_afford(district, 1)` / "No blocks left today" gate stays). Pruning at/below neutral still correctly yields 0 ore; the player can just choose to spend the action anyway.
2. **Gentler swings.** Cultivate gain and prune depth currently move growth a lot per action: `cultivate_gain = max(cultivateMinGain, round((cultivateBase + cultivatePerSkill*skill) * (1 - growth/ceiling)))` with `cultivateBase: 10, cultivatePerSkill: 4, cultivateMinGain: 2`; prune depths `pruneLightDepth: 15, pruneHardDepth: 40` (all `data/vein_growth.json`, per `docs/REFERENCE.md` §1.2/§3.4). Human wants ~40% gentler across the board. Target: `cultivateBase: 6, cultivatePerSkill: 2, cultivateMinGain: 1, pruneLightDepth: 9, pruneHardDepth: 24` — get sign-off from the human on final numbers before locking them in, don't guess silently if these feel off in testing.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `prune_gate()` no longer disables on zero-yield; only the time-block-affordability check remains.
- [ ] `data/vein_growth.json` constants updated per above (or human-approved alternative), ~40% gentler than current.
- [ ] `docs/REFERENCE.md` §1.2/§3.4 constants table updated to match.
- [ ] Existing cultivate/prune tests updated for new constants; add a test confirming prune is not blocked by a zero-yield vein.
- [ ] Manual check noted for the human: confirm pruning a neutral/low-growth vein is now possible (yields 0, no error), and that a single cultivate/prune action moves growth noticeably less than before.
