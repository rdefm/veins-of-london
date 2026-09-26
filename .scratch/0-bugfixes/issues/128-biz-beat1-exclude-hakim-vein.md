# 128 — Business Beat 1 vein count leaves out Hakim's vein

**Status:** ready-for-agent

**Blocked by:** None. Can start immediately.

**What to build:** Business Empire Beat 1 (`BusinessQuest.maybe_trigger_proposition()`, `systems/business_quest.gd:48`) fires once `player.veins.size() >= MIN_VEINS` (2) and Archie is recruited. Hakim's vein is granted into `player.veins` by `grant_contact_vein` in `data/events/col_a1_hakim_meet.json:35`, with its id stored at `collective.hakimVeinId`, and the player only manages it temporarily. So a player with 1 vein of their own plus Hakim's triggers Archie's "Two veins" proposition too early.

Human decision: **always** leave out the vein whose id equals `collective.hakimVeinId` from this count. That covers the Act 1 management window and any time it's back in `player.veins` later (e.g. after the Act 2 retake, `col_a2_hakim_retake.json`). It's Hakim's yard, never the player's supply.

- Count = `player.veins` minus any entry whose `id == collective.hakimVeinId` (null-safe: when `hakimVeinId` is null, nothing is left out).
- Change only this gate. Other vein-count consumers stay as they are.
- Update the REFERENCE.md §3 Business Empire "Beat 1" line (currently "`player.veins.size() ≥ 2`") to say Hakim's vein is left out. This rule is human-confirmed on 2026-09-26.
- `bizA1Proposed` already set on existing saves: no migration, it stays fired.

**Relevant files:**
- `systems/business_quest.gd`: `maybe_trigger_proposition()` :48, `MIN_VEINS`
- `systems/collective.gd`: Hakim vein handling :571-620 (`force_vein_loss`, retake, `hakimVeinId`)
- `data/events/col_a1_hakim_meet.json` :35 (grant), `data/events/col_a1_hakim_done.json` :11 (handback), `data/events/col_a2_hakim_retake.json`
- `autoload/GameState.gd` :355 (`collective.hakimVeinId` default)
- `tests/test_business_quest.gd`
- REFERENCE.md §3 "Business Empire questline (Beats 1–8)", Beat 1

- [ ] 1 own vein + Hakim's vein + Archie recruited → no proposition, `bizA1Proposed` stays false.
- [ ] 2 own veins + Hakim's vein → proposition fires.
- [ ] `hakimVeinId` null → same behaviour as now.
- [ ] REFERENCE.md Beat 1 line updated.
- [ ] Tests added to `tests/test_business_quest.gd`.
