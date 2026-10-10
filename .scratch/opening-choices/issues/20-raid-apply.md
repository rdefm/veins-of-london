# 20 — Home raid, debriefs and vein handover: apply

**What to build:** The home raid starts with the player's decision: ambush, bluff or stay still, each with its stated stakes, with an equipped pearl and earlier bravery visibly raising the odds. Debriefs match the player's inventory and Archie's handover makes sense whichever pub question was asked.

**Blocked by:** 19 — Raid proposal (and owner approval); 03 — Item mods; 09 — Raid entry mods + no-fight; 18 — Catch-up apply.

**Relevant files:** `data/events/home_raid_intro.json`, `data/events/home_raid_debrief_win.json`, `data/events/home_raid_debrief_loss.json`, `.scratch/writing-revamp/home-raid-proposal.md`, `systems/combat.gd`, `systems/events.gd`, opening scenario test file, `tests/test_home.gd`.

**Status:** ready-for-agent

- [ ] Event JSON matches the approved proposal.
- [ ] Tests: ambush success → raider HP reduced in started combat; bluff success → win debrief, no combat; bluff fail → enemy acts first; stay still → loss debrief, no combat; equipped pearl raises ambush odds.
- [ ] Debrief ore line only shown when ore held; handover branch on pub choice.
