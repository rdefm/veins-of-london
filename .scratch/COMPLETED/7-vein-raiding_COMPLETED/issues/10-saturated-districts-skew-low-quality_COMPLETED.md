# 10 — Saturated districts skew prospecting toward low quality

**What to build:** When a district is at its `siteCap` (`data/districts.json`), `Sites.prospect()`'s existing at-cap behaviour (today: reroll the worst unclaimed site, using the same tier-roll table a fresh, below-cap prospect uses) should weight the rolled tier heavily toward poor/barren, leaving only a small residual chance of a better tier — the same "mostly the expected outcome, occasionally not" shape other probabilistic systems in this codebase already use (e.g. `Factions.pick_claimant`'s presence-vs-rival-encroachment split). No new UI or action: `prospect()` remains the single entry point regardless of whether the district is under or at cap; only the tier-weighting changes once at cap. Exact curve/weighting is the implementer's call, documented in code, mirroring the signed-tilt convention this codebase already uses elsewhere (e.g. `Factions._security_opulence`, `Raiding.raid_success_chance`).

**Blocked by:** None — can start immediately (orthogonal to ticket 09; can land in either order)

**Status:** ready-for-agent

- [ ] `Sites.prospect()`'s at-`siteCap` path (today: `_reroll_worst_unclaimed`) rolls tier from a table skewed toward poor/barren, distinct from the below-cap tier-roll table
- [ ] A small, non-zero chance of a better (rich/saturated) tier still exists once at cap — not a hard floor
- [ ] Below-cap prospecting is completely unaffected — same tier-roll behaviour as today
- [ ] Tests cover: at-cap prospecting rolls poor/barren markedly more often than below-cap prospecting for the same district/skill (statistical, many-seed style, matching this codebase's existing convention for weighted-pick assertions); at-cap prospecting can still occasionally roll a better tier (non-zero, not asserted-impossible); below-cap prospecting's existing tier-weight tests are untouched and still pass
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
