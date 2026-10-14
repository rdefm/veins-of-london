# 01 — Benefit rows read (shared pure system)

**What to build:** A pure, headless-testable read that gives, per faction, the benefit rows both screens render. Each row: tier + tier label, requirement text (Friendly "Relation ≥25", Partner "Partner stance", Sworn "Joined"), unlocked, scope (global/turf), and active-now. Global perks are active when unlocked. Turf perks are active when the faction holds control (full strength) or a foothold (reduced strength) in a district; the row lists those districts and strength. Also a district-scoped variant telling whether each perk is active in that district (full / reduced / inactive). No mechanics change; perk data and rules untouched.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/perks.gd` (`preview`, `active_turf`, `turf_scale`, `player_tier`), `systems/turf_panel.gd` (`faction_preview`), `data/faction_perks.json` (read only; `friendlyAtOrAbove`), `tests/test_perks.gd`, `tests/test_turf_panel.gd`, `CODEMAP.md`. REFERENCE.md R§3.10 perks, turf tiers (`GameData.TURF` footholdFactor).

**Status:** ready-for-agent

- [ ] Faction-level rows include requirement text, unlocked, scope, active-now, active districts + strength
- [ ] District-level rows report active here: full / reduced / inactive
- [ ] Requirement text derives from `friendlyAtOrAbove` config, not hardcoded numbers
- [ ] Tests cover each tier, global vs turf, control vs foothold vs none
- [ ] Existing perk behaviour unchanged; check_all and tests pass
