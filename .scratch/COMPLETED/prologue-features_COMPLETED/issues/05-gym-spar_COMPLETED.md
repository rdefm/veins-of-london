# 05 — Gym location + Spar

**What to build:** A calc gym (Archie's mate, under a railway arch) becomes a location once a story flag unlocks it. Its **Spar** action costs 1 time block. The player picks an easy/even/hard sparring partner scaled to their Combat Skill and fights in the real engine with **free, unlimited Rewinds**. A spar gives Combat XP (more for a win) and normal move XP. No HP loss is carried out, and there's no cash or loot. The first 3 sessions are free, used whenever; after that each costs a small £ fee (placeholder). Home `train()` stays as the cheap fallback. Source: `docs/story-restructure.md` Prologue step 5, "Features to build" item 3.

**Blocked by:** 01 — Rewind tiers.

**Relevant files:** `systems/combat.gd` (`train` ~L1515, `award_xp`, XP consts ~L95, open_fight/exit), `systems/combat_prep.gd`, `scenes/components/hq_gym_modal.gd`, `systems/districts.gd`, `systems/map_events.gd`, `scenes/screens/map.gd`, `data/constants.json`. REFERENCE §3.7a Combat Skill, §3.7b. Update `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] A flag-gated gym location with a Spar action. Refused when no time blocks are left.
- [ ] 3 partners whose stats/levels scale off the player's Combat Skill (easy/even/hard), from data.
- [ ] In a spar the Rewind costs nothing and is unlimited (house rules, labelled in the UI). No inventory units are spent.
- [ ] XP: a base amount plus a win bonus (data). Move XP accrues normally. Player HP after the spar equals HP before it.
- [ ] Free-session counter in state (3), then the £ fee. Refused if the player can't pay.
- [ ] Tests cover the counter, fee, XP split, HP restore and free Rewind. The human checks the gym screen on device.
