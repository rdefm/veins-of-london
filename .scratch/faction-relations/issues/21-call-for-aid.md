# 21 — Call for aid

**What to build:** At war, the player can ask another faction to join: `Diplomacy.ask_aid(factionId, enemyId)`. The accept chance comes from the player's relation with the asked faction, that faction's pair relation with the enemy, its weariness, and the warmonger score (TBD formula). On acceptance, the faction enters war with the enemy under the existing war rules, and the player owes it a favour; refusing that owed favour later costs relation. Cooldown per faction.

**Blocked by:** 20 — Warmonger meter

**Relevant files:** `systems/diplomacy.gd`, `systems/faction_ai.gd` (war entry, weariness, pair relations), `scenes/screens/factions.gd` / `scenes/components/contact_cards.gd` (ask action), diplomacy config in `data/factions.json`, tests: `test_diplomacy`, `test_faction_war`. REFERENCE.md Warmonger/aid §, §3.10 "Favours".

**Status:** ready-for-agent

- [ ] `ask_aid` is available only while the player is at war with the enemy; cooldown enforced
- [ ] Accept chance follows the data formula (seeded tests at the extremes)
- [ ] Acceptance starts the faction-vs-enemy war and records an owed favour
- [ ] Refusing the owed favour later costs relation
- [ ] UI QA list; strings `PROSE-REVIEW`
