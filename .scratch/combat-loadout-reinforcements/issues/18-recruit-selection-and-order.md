# 18 — Choose and order recruits for raids and defences

**What to build:** On planned raids and defences (now including HQ defence), preparation lets the player select and order any currently eligible combat recruits. Selected recruits come before automatic partner helpers, then hired guards; everyone past the two friendly places beside the player enters the reinforcement queue in that order. Surprise/scripted encounters keep their established participants and cannot summon absent recruits.

**Blocked by:** 07, 17

**Relevant files:** preparation screen (from 17), `systems/combat.gd` (roster build), `systems/partners.gd`, `systems/contacts.gd` (eligibility, KO cooldown), `systems/raiding.gd`, `systems/home.gd`, `tests/test_combat.gd`, `tests/test_raiding.gd`. Update REFERENCE §3.7a with the change.

**Status:** ready-for-agent

- [ ] Eligible recruits selectable and reorderable for planned raids and vein/HQ defences
- [ ] Ineligible (KO cooldown, noncombat) recruits not offered
- [ ] Active/queue order: player, recruits in chosen order, partners, guards
- [ ] Muggings and scripted fights keep their roster unchanged
- [ ] On-device QA block in report
