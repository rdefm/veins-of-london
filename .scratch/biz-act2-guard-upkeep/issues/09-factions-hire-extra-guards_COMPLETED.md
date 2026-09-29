# 09 — Factions hire extra guards

**What to build:** The faction daily security spend continues past `guarded` into hiring extra guards.

- **Targeting:**
  1. First, bring veins up the tier ladder (up to `guarded`), highest-value vein first.
  2. Only once no vein below `guarded` is eligible or affordable, hire extra guards, highest-value vein first, capped at `maxExtraGuardsPerVein` per vein.
  - Still one upgrade per faction per tick, and a security freeze still blocks.
- **Cost:** moving to `guarded` and each extra guard cost only the prorated advance, from `resources`.
- **Wage reserve:** any guard hire (tier or extra) needs `resources ≥ advance + wageReserveWeeks × the faction's weekly guard bill after the hire`.
- **Unchanged:**
  - Lock and ward upgrades keep their prices and aren't reserve-gated.
  - Claim and day-1 security rolls stay as they are.
- Faction extras feed raid resist and guard repel the same way the player's do.

**Blocked by:** 02 — Guards are hired; 08 — Faction Monday guard bill.

**Relevant files:**
- `systems/factions.gd` (`apply_security_upgrades`, `rivalry_success_chance`), `systems/network_handler.gd` (`is_security_frozen`)
- `systems/cultivating.gd` (`vein_raid_resist`), `systems/raiding.gd`
- guardUpkeep data block from 01
- `tests/test_factions.gd`, `tests/test_raiding.gd`
- Spec §Faction guard upkeep (Hiring); REFERENCE.md §1.8, §3.12

**Status:** ready-for-agent

- [ ] Tier upgrades across veins take priority over extras
- [ ] Extras are hired on the highest-value vein first and never beyond the cap
- [ ] A guard hire is refused without the wage reserve; an affordable hire pays the prorated advance (seeded weekday cases)
- [ ] One upgrade per faction per tick; frozen veins are skipped
- [ ] Faction extras raise raid resist and repel on raids against them
- [ ] Rng seeded in tests; REFERENCE §1.8 and §3.12 updated
