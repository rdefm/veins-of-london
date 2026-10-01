# 19 — Favours

**What to build:** Factions message the player favour requests: deliver goods by a day, guard a vein, sit out a raid, or sell to them below market. Accepting commits the player. Completing raises relation, ignoring costs nothing, and failing an accepted favour costs a little. A favour for a faction's enemy also raises the player's intel on that enemy. Favours reuse the existing offers/contracts/objectives plumbing for "deliver X by day N". Each faction ships the two sample favours from ticket 01.

**Blocked by:** 03 — Pressure + relation drift.

**Relevant files:** new `systems/diplomacy.gd` (or part of `faction_ai.gd`; the ticket decides), `systems/offers.gd`, `systems/objectives.gd`, `systems/contracts.gd`, pending-message mechanism (`systems/collective.gd`), `systems/intel.gd` (if present; otherwise note the hook), `data/factions.json`, `SaveManager`, `scenes/phone_apps/factions_app.gd`, `tests/test_diplomacy.gd` (new), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 69–70, 75, §Relation levers. REFERENCE.md §3.10.

**Status:** ready-for-agent

- [ ] Rollover test: favour requests are issued as actionable key-member messages and expire.
- [ ] Test: accept + complete raises relation. Ignoring does nothing. Accept + fail lowers relation a little.
- [ ] Pending and accepted favours are saved and backfilled. REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for favour lines.
