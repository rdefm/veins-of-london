# Spec — Security Officer

Status: ready-for-agent

## Problem Statement

Guards are interchangeable £500/week units. Once the player has hired a few, the only lever left is "hire more". Nothing in the business handles security, and no person on LodedInnit makes the guards better at their job. The player can't build a security operation the way they build a cultivation or production one: they can't pick a specialist, watch them improve, or bring them along into a fight.

## Solution

A new staff role, **Security Officer**. The business can employ at most one. The player hires one from LodedInnit into a new one-seat HQ room, the **Security Office**, or gives the role to a founder (Archie or James). While on duty, the officer's two skills improve every guard the player has, on veins and at HQ:

- **`security`** (the role skill) makes the player harder to target and harder to raid: deterrence.
- **`combat`** (the officer's own fighting skill) sets the officer's own fight stats.
- How much the officer lifts the guards' fighting is set by **`min(security, combat)`**. A brawler with no security sense can't direct guards, and a planner who can't fight can't train them.

The officer also joins the player in fights as a normal recruit, and speeds up the player's own Train sessions. The officer shows in BizBrief's Staff tab. Guard Costs shows the active modifiers, and the Morning Brief says when they're off.

## User Stories

1. As a player, I want security candidates listed on LodedInnit, so that I can compare officers like any other hire.
2. As a player, I want every security candidate to show both a `security` level and a `combat` level with their caps, so that I can tell a deterrence specialist from a fighter.
3. As a player, I want a candidate's hire button to say they need a Security Office when I don't have one, so that I know what to build.
4. As a player, I want to build a Security Office in a free floorplan slot through the existing room flow, so that security fits the HQ I already manage.
5. As a player, I want the Security Office to have exactly one seat and no seat upgrade, so that it's clear I can only have one officer.
6. As a player, I want hiring an officer to use the same first-week prepay, pot/float and top-up flow as other hires, so that there's nothing new to learn.
7. As a player, I want the officer's wage to rise as either skill grows, so that a better officer costs more.
8. As a player, I want the officer's wage to go through payroll as a staff wage, so that my guard bill and staff bill stay separate in Stats.
9. As a player, I want my officer's `security` level to add raid resistance to every guard I have, so that a good officer makes each guard worth more.
10. As a player, I want my officer's `security` level to cut HQ raid chance per HQ guard, so that HQ benefits as well as veins.
11. As a player, I want a high-`security` officer to lengthen the alarm window, so that I have more time to respond to a raid.
12. As a player, I want lower faction raid success odds against my guarded veins from a good officer, so that factions find me a worse target.
13. As a player, I want my officer's combat-bonus level (`min(security, combat)`) to raise guard repel chance, so that guards drive off more raids unaided.
14. As a player, I want a high combat-bonus level to lift the repel cap slightly, so that a top officer is worth having even with many guards.
15. As a player, I want guard allies in fights to get HP/attack/speed bonuses from the combat-bonus level, so that a trained guard fights better.
16. As a player, I want my Train action to give more combat XP when I have an officer, scaled by the combat-bonus level, so that the officer trains me as well.
17. As a player, I want the officer in the CombatPrep recruit picker for planned raids and vein/HQ defences, so that I can bring them along.
18. As a player, I want the officer to have two item slots and no Dial, so that they fight with kit, not casting.
19. As a player, I want each candidate to have their own authored base stats, so that officers feel distinct in a fight.
20. As a player, I want an officer's own HP and attack to grow with their `combat` level using the same curves as my Combat Skill, so that their growth is readable.
21. As a player, I want the officer's speed to rise by one per `combat` level, so that experienced fighters act earlier.
22. As a player, I want a KO'd officer to go on the normal KO cooldown, so that losing them in a fight has a cost.
23. As a player, I want the officer's guard and Train modifiers to switch off while they're KO'd, so that the KO cost reaches my guards too.
24. As a player, I want the modifiers to switch off while I owe the officer wages, so that not paying them has a consequence.
25. As a player, I want the modifiers to end at once if the officer is poached or let go, so that the state is never stale.
26. As a player, I want the officer's `security` to gain XP when my guards deter or repel a raid, plus a small daily on-duty trickle, so that they improve even in a quiet week.
27. As a player, I want the officer's `combat` to gain XP per turn they take in a fight and per defence my guards win, so that fighting makes them better.
28. As a player, I want the `eager` trait to speed up both skills' XP, so that traits mean the same thing across roles.
29. As a player, I want a notification when either officer skill levels up, so that I see the growth.
30. As a player, I want to give Archie the security role (security cap 2, combat 2 → cap 4), so that a founder can cover the role before I can afford a hire.
31. As a player, I want to give James the security role (security cap 1, combat 1 → cap 2), so that the option exists, even if he's weak at it.
32. As a player, I want a founder officer to keep their authored fight stats (and James his Dial), so that putting them in the role doesn't change how they fight.
33. As a player, I want the officer listed in BizBrief's Staff tab with role, both skill levels, wage and owed/working state, so that I manage them with the rest of the staff.
34. As a player, I want Guard Costs to show a line of the officer's live modifiers, so that I can see what they're worth against what my guards cost.
35. As a player, I want Guard Costs to say "No officer — hire on LodedInnit" when I have none, so that the feature can be found.
36. As a player, I want the Morning Brief to say when the officer's modifiers are off and why (unpaid or KO'd), so that I don't miss a lapse.
37. As a player, I want faction poach offers on my officer, like any hire, so that a good officer is something rivals want.
38. As a player, I want LodedInnit feed status posts when an officer is hired, let go or poached, so that the feed reflects my security staff.
39. As a player, I want a save made before this feature to load with no officer and no Security Office, so that old saves keep working.
40. As a player, I want Rewind and save/load to bring back the officer's skills, XP and KO state exactly, so that the flagship feature stays intact.
41. As a designer, I want every officer number (curves, XP awards, room cost, candidate stats) in JSON, so that balance never needs a code change.
42. As a designer, I want every level-indexed curve's length to set its own cap, so that the pending level-10 skill extension carries over.

## Implementation Decisions

**Seam: one new system module, `SecurityOfficer`.** Every consumer asks it for the current modifiers and never reads officer state directly. Pure static reads over `GameState.state`, no state of its own:
- `officer_id()` → the contact id holding the `security` role, or null. At most one.
- `is_active()` → officer exists and is working (`Payroll.is_working`) and not KO'd (`koCooldownUntilDay`).
- `security_level()`, `combat_level()`, `combat_bonus_level()` = `min(security, combat)`. All return 0 when inactive.
- Modifier reads, each returning the neutral value when inactive: `guard_raid_resist_bonus()` (per guard), `hq_guard_raid_reduction_mult()`, `alarm_extra_days()`, `repel_bonus_per_guard()`, `repel_cap_bonus()`, `guard_ally_bonus()` → `{hpMax, attack, speed}`, `train_xp_mult()`.
- `modifiers_summary()` → display model for Guard Costs and the Morning Brief (active / off reason / none).
- XP hooks: `on_raid_deterred()`, `on_guard_defence_won()`, `daily_on_duty_tick()`.

**Role and room**
- `hiring.json` `roles.security` is enabled, `room: "securityOffice"`, `skill: "security"`.
- New `home.json` room `securityOffice`: 1 seat, no `seatUpgrades`, `minTier` the lowest tier that has room slots, cost a *placeholder*.
- Hiring into it uses the existing free-seat check, so a cap of one officer follows from the single seat.
- `set_role(founder, "security")` is also refused when another contact already holds the role.

**Skills on contacts**
- Contacts gain `securitySkill`/`securityXP` and `combatSkill`/`combatXP` (backfilled 0/0 on load for every contact; founders get their authored starts on load if missing).
- `Contacts.xp_levels()` learns `"security"` (new `securityXpLevels`, *placeholder*, same shape as the other ladders) and `"combat"` (reuses `COMBAT_XP_LEVELS`).
- `skill_cap` is unchanged: it reads `skillCaps`, else the ladder top.
- `award_contact_xp` applies the trait XP multiplier to **both** officer skills, not just the role skill.

**Candidate schema** (security candidates only, alongside the existing fields):
- `startLevel` stays the `security` start.
- New `combatStartLevel`.
- `skillCaps` holds both `security` and `combat`.
- New `combatKit {hpMax, attackMin, attackMax, speed}` is the authored base block.
- Four candidates: a deterrence specialist (high security cap, low combat), a combat specialist (high combat cap, low security), a cheap balanced rookie, and a premium veteran with a trait. Base wages £350–600, `wagePerLevel` 60.

**Officer fight stats**
- `combatHpMax` = kit hpMax + `COMBAT_HP_BONUS_BY_LEVEL[combat]`.
- attackMin/Max = kit + `COMBAT_ATTACK_BONUS_BY_LEVEL[combat]`.
- speed = kit speed + (combat − 1).
- These are written to the contact's existing `combat*` fields on hire and on each `combat` level-up, so `build_combat_ally`, the recruit picker, KO and replenish all work unchanged.
- No Dial is granted.
- **Founders are excluded:** their `combat*` fields stay authored, and their `combatSkill` feeds only `min()`.

**Founder values** (in `constants.json` contacts, `skillCaps` plus starts):

| Founder | security (start / cap) | combat (start / cap) |
|---|---|---|
| Archie | 1 / 2 | 2 / 4 |
| James | 1 / 1 | 1 / 2 |

**Wage**
- Same formula as other hires, extended over both skills: `baseWage + wagePerLevel × ((security − startLevel) + (combat − combatStartLevel))`, × the existing wage multiplier.
- `refresh_wage` fires on either skill's level-up.

**Effects wired through the seam**
- `Cultivating.vein_raid_resist` adds `vein_guard_count × guard_raid_resist_bonus()` for **player** veins only. This flows into stealth, raid and rivalry odds unchanged.
- `Home.get_home_raid_chance`: the per-guard HQ `raidReduction` is multiplied by `hq_guard_raid_reduction_mult()`.
- Alarm windows: vein and HQ pending raids survive `alarm_extra_days()` additional daily ticks before expiring.
- `guard_repel_chance` takes the player-side bonus: `min(count × (chancePerGuard + repel_bonus_per_guard()), cap + repel_cap_bonus())`. Faction-side calls pass no bonus.
- `Combat.build_guard_ally` adds `guard_ally_bonus()` when the guard fights on the player's side. Partner fighters are not buffed.
- The HQ Train action multiplies its XP by `train_xp_mult()`.

**Placeholder data** (a `security` block in `hiring.json`, all *placeholder*, needs a balance pass with `sim_combat_balance.gd`). Each is indexed by level, and its length is its cap:

| Curve | Indexed by | Values |
|---|---|---|
| `guardRaidResistBonusByLevel` | security | [0,0,3,6,10,15] |
| `hqGuardRaidReductionMultByLevel` | security | [1,1,1.15,1.3,1.5,1.75] |
| `alarmExtraDaysByLevel` | security | [0,0,0,0,1,1] |
| `repelBonusPerGuardByLevel` | combat-bonus | [0,0,0.02,0.04,0.06,0.08] |
| `repelCapBonusByLevel` | combat-bonus | [0,0,0,0.05,0.05,0.10] |
| `guardAllyBonusByLevel.hpMax` | combat-bonus | [0,0,5,10,18,28] |
| `guardAllyBonusByLevel.attack` | combat-bonus | [0,0,1,2,3,5] |
| `guardAllyBonusByLevel.speed` | combat-bonus | [0,0,0,1,1,2] |
| `trainXpMultByLevel` | combat-bonus | [1,1,1.25,1.5,1.75,2.0] |

XP awards: `xp.deter` 20, `xp.dailyOnDuty` 2, `xp.defenceWon` 10. Officer fight-turn XP reuses `COMBAT_XP_PER_ATTACK_TURN`. Lookups clamp to the last index.

**XP triggers**
- `security`: a player guard repel (vein missed-defend or HQ) and a faction raid on the player that fails its odds both call `on_raid_deterred()`. The daily tick calls `daily_on_duty_tick()`.
- `combat`: each turn the officer takes in combat, and `on_guard_defence_won()` on a won vein/HQ defence fight with guard allies.
- XP is earned only while `is_active()`, except fight turns, which count whenever they fight.

**Screens** (read-only over the seam): the LodedInnit profile and directory show both skills; BizBrief Staff shows the officer row; Guard Costs adds the modifiers line or hire prompt; the Morning Brief adds an `officerOff {reason}` line. The Security filter in the LodedInnit directory comes for free from the role registry.

**State purity:** nothing new holds an object. All officer state is primitive fields on the existing contact dict plus the existing hiring/business entries, so save, snapshot and Rewind need no special handling beyond load backfill.

## Testing Decisions

- Good tests drive public system calls against a seeded `GameState.state` and assert on observable results (odds, stats, wages, state fields). They never assert on private helpers or call order.
- **Primary: a new `tests/test_security_officer.gd`** at the `SecurityOfficer` seam:
  - no officer / inactive (unpaid, KO'd) → neutral values;
  - `combat_bonus_level` = min;
  - each curve lookup at representative levels, plus clamping past the curve's end;
  - founder officer uses authored stats but a skill-based `min()`;
  - only one officer can hold the role.
- **Integration through existing suites:**
  - `test_hiring.gd`: hire refused without a Security Office; second officer refused; wage over both skills; poach.
  - `test_contacts.gd`: dual-skill XP and trait, level-up rewrites fight stats for hires but not founders, `set_role` refusal.
  - `test_raiding.gd`: vein raid resist and repel with and without an officer; faction-side unaffected.
  - `test_home.gd`: HQ raid chance; alarm extra day.
  - `test_combat_prep.gd`: officer listed as a recruit, no Dial; guard ally bonus.
  - `test_guard_upkeep.gd` / Guard Costs projection: modifiers line.
  - Save backfill test for pre-feature saves.
- Prior art: `test_hiring.gd` (hire/seat/wage flows), `test_guard_upkeep.gd` (guard math), `test_raiding.gd` (seeded-Rng odds), `test_combat_prep.gd` (recruit listing).
- One targeted run per change, then one full suite plus `check_all.sh` at the end.

## Out of Scope

- Any officer equivalent for factions; faction veins and guards never get these bonuses.
- More than one officer, Security Office seat upgrades, or assigning the officer to specific veins.
- A dedicated BizBrief Security tab.
- Officer Dials or casting.
- Changing anonymous guards' wage, hire flow or kit rules.
- Final balance numbers (placeholders only, signed off later).
- Extending officer curves to level 10 (handled by the skill-level-cap-10 effort; this spec only requires length-derived caps).

## Further Notes

- **Decided:** a founder officer needs no Security Office (the existing `roomFreeRoles` rule). `set_role` still enforces the one-officer cap.
- **Decided:** the security role has no `roleFlags` story gate for founders.
- **Decided:** the seams are confirmed. `SecurityOfficer` is the primary test seam, with integration covered through the existing suites.
- PROSE-REVIEW: candidate names, headlines, about text, feed posts, Guard Costs / Morning Brief strings and the Security Office description are drafted against CONTENT-GUIDE.md and flagged in the implementing ticket.
- REFERENCE.md needs a new subsection (hiring/§1.6 guards/§3.10), CONTEXT.md needs "Security Officer" / "Security Office" / "combat-bonus level", and CODEMAP.md needs the new system. All are updated in the implementing commits.
