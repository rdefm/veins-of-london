# 04 — Security spend: affordability-gated upgrades

**What to build:** Two changes, both about a faction's resource balance gating its vein security:

1. **Claim-time roll goes dynamic.** `Factions.roll_security_tier()` / `_security_opulence()` (`systems/factions.gd`) currently consult the static placeholder `resourceLevel` (`data/factions.json`) as an explicit stand-in for "the real dynamic faction-resource stat is Chunk 1b, not built yet" (see the comment above `_security_opulence()`). Swap that input for the real balance from ticket 01 — a resource-strapped faction now genuinely rolls toward cheaper security tiers when it claims a new vein, not a fixed per-faction constant.
2. **New spend: security upgrades over time.** A new daily-tick step lets a faction spend from its balance to upgrade a held vein's security tier, gated by whether it can afford that tier's `cost` (`data/vein_security.json` — already has `none`/`basic`/`warded`/`guarded` costs, no new cost table needed). This is the only spend category in this PRD's near-term scope. Whether a faction always upgrades everything it can afford, or applies some restraint/priority logic (e.g. one upgrade per faction per tick, or biased toward its highest-value veins) is left to the implementer, documented in code — the PRD explicitly leaves this open.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `_security_opulence()`'s resource input reads the faction's real dynamic balance (ticket 01) instead of the static `resourceLevel` placeholder; the placeholder comment block is updated/removed to reflect this is no longer a stand-in.
- [ ] New daily-tick step: for each faction, for each held vein below max security tier, if the faction's balance covers that tier's `vein_security.json` cost, spend it and upgrade the vein's security — documented affordability/priority rule (see above).
- [ ] A faction's balance decreases by the upgrade's cost when an upgrade happens; a faction that can't afford any upgrade this tick is a no-op, not an error.
- [ ] Tick step ordered sensibly relative to the other daily-tick steps (claim, abandonment, growth, income) — document the ordering.
- [ ] Tests cover: claim-time security roll responds to a faction's current balance (not just its static `resourceLevel`), a faction with enough balance upgrades an eligible vein and its balance drops by the tier cost, a faction without enough balance doesn't upgrade and isn't charged, a vein already at max security (`guarded`) is never targeted.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.

Demoable by advancing the game clock in a test/debug save with a well-funded faction and observing one of its held veins' security tier increase without player action.
