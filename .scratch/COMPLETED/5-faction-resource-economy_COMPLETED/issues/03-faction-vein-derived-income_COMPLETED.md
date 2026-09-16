# 03 — Daily vein-derived income

**What to build:** Each daily tick, every faction also converts value from its held veins into resource balance — the same shape as the player's own cultivate-then-sell loop (`systems/economy.gd`'s `execute_sale`, ore `basePrice` per `data/ore_types.json` / `GameData.ORE_TYPES`), just automated and without the player's mugging/district-price-mod mechanics (those are player-facing friction, not relevant to a faction's internal books). Faction veins currently only grow (`Sites.roll_faction_vein_growth`, ticket 02 of chunk 1) — they have no charge/harvest cycle of their own; this ticket doesn't need to bolt player-style `charged`/`chargeBlocks` fields onto faction veins, a simpler periodic conversion of vein value (ore type × level) into balance is sufficient, as long as it's recognisably the same shape (ore value in, resources out) and scales with what the vein is actually worth (higher level / higher-value ore → more income).

Exact conversion formula is left to the implementer, documented in code.

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] New (or extended) daily-tick step converts each faction-held vein's value into resource income for its owning faction, scaling with the vein's ore type value and level.
- [ ] A faction holding more/higher-value veins earns more vein-derived income than one holding few/low-value veins — differentiation is visible in a debug save over several days.
- [ ] Tick step ordering documented relative to the existing claim/abandonment/growth/passive-income steps (e.g. a vein abandoned or claimed the same tick doesn't double-count or get skipped inconsistently — pick and document one rule).
- [ ] Tests cover: a faction with high-value veins earns more than one with low-value veins, a faction with zero veins earns zero from this source (passive income from ticket 02 still applies), income scales with vein level.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.

Demoable by advancing the game clock in a test/debug save with factions holding veins of varying value and observing balances diverge accordingly.
