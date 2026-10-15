# 07 — Perks core

**What to build:** Each faction offers three perk tiers (Friendly, Partner, Sworn/joined), defined in data and marked global or turf-scoped. One query layer answers which perks are active for the player globally, which turf perks apply to a given vein/district (full at Control, reduced at Foothold), and the full per-tier list for a preview. In the district panel, each active perk shows as a benefit with its source faction, and tapping a faction opens a preview of the player's current tier and the perks at every tier, with turf-scoped ones marked. This ticket ships no effect hooks; tickets 08–12 wire them.

**Blocked by:** 06 — District panel Turf section

**Relevant files:** new `data/faction_perks.json`, new `systems/perks.gd`, `autoload/GameData.gd` (load + validate), `systems/factions.gd` (joined), `systems/faction_ai.gd` (stance/relation bands), `systems/turf.gd`, `scenes/screens/map.gd`, the decision layer from 06, new `tests/test_perks.gd`. REFERENCE.md new Perks §, §3.10. Spec "Perks (new system)".

**Status:** ready-for-agent

- [ ] `faction_perks.json` schema: per faction, tiers `friendly`/`partner`/`sworn`, entries `{ id, scope, effect params, label, description }` for all 15 perks in the spec (labels `PROSE-REVIEW`)
- [ ] Tier mapping: Friendly/Partner from relation/stance band (Friendly cut TBD in data), Sworn = joined
- [ ] Queries: active global perks, active turf perks for a vein/district with control/foothold scale, per-tier preview list
- [ ] Panel benefit rows and faction preview are backed by a pure decision layer, with tests
- [ ] No faction-specific effect code outside the perk query consumers
- [ ] On-device QA list in the report
