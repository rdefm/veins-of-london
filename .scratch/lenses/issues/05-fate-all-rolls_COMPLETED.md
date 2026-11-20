# 05 — Fate lens: light bonus to all rolls

**What to build:** Spec `.scratch/lenses/spec.md` "Always": Fate. A loaded Fate lens adds `fateAllRollsBonusByTier` (placeholder `[0,0.01,0.02,0.03,0.04,0.05]`) to every player roll, before that roll's own clamp, labelled wherever a breakdown lists mods: event checks (`Events.odds_for`/`check_odds`), alert cover rolls, observation (every ore), crafting, Dial seeding, site seeding, prospecting, combat crit and Leg it. Stacks with the normal fate-ore attunement on fate rolls. On a contact Dial it applies only to that ally's crit rolls. Lookup lives in `Lenses.fate_all_rolls_bonus(owner_id)`; each call site adds it.

**Blocked by:** 02

**Status:** ready-for-agent

**Relevant files:**
- `systems/lenses.gd`
- `systems/events.gd`
- `systems/observation.gd`
- `systems/crafting.gd`
- `systems/lab.gd`
- `systems/dial.gd`
- `systems/sites.gd`
- `systems/combat_rounds.gd`
- `data/dial.json`
- `tests/test_lenses.gd`
- `tests/test_observation.gd`
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.5, §3.7b, §3.9a, §3.9d

**Acceptance:**
- [ ] Each listed roll's probability rises by the tier value with a Fate lens loaded, and not without.
- [ ] Check `?` modal and observation mod list show a labelled Fate line.
- [ ] Ally crit gets it only from a Fate lens on that contact's Dial.
- [ ] Clamps (incl. `itemBoostedMax`) still bound the result.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
