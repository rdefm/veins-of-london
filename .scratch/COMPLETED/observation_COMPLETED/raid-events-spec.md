# Raid events + item effects — spec

Status: ready-for-agent (first task is a grilling session, see Further Notes)

## Problem Statement

Vein raids are thin: one approach beat, a route, a caught beat. Observation (Sense rolls) informs them but opens few real choices. Items (Wormhole, Panic, Pandemonium, Pan's Rapture, Enhancement Powder, Time Pearl) are combat-only or give flat observe bonuses, so they add no tactical variety to a raid. The player can't plan a raid around what they noticed and what they carry.

## Solution

Vein raids become fuller events with many cards, several variants, and many approaches. Observation results (kept as is) unlock or boost specific approaches. Items are optional enhancements: consuming an item (or casting its dial effect) at the right approach adds a roll bonus, unlocks an option, bypasses or reshapes the fight, or sets how the fight starts. Approaches the player can't use yet show greyed with a `?` icon that opens a modal explaining what is missing. Items never replace observation; they sit on top of it.

## User Stories

1. As a player, I want vein raids to come in several different events, so that no two raids feel the same.
2. As a player, I want what I observe to change which approaches are open, so that Sense and attention matter.
3. As a player, I want a high physics roll to reveal exactly where the vein is, so that I can choose a direct way in.
4. As a player, I want to consume Wormhole after such a reveal, so that I teleport in and bypass the guards.
5. As a player, I want Wormhole to still roll, so that using it isn't an automatic win.
6. As a player, I want Panic to make guards flee or start the fight afraid, so that I can soften a fight.
7. As a player, I want Pandemonium to make guards attack each other before the fight, so that I enter against fewer or weaker enemies.
8. As a player, I want Pan's Rapture to make guards docile so I can walk straight in, so that a fight can be skipped entirely.
9. As a player, I want Enhancement Powder to boost specific physical approaches (a weak-lock window, a fire escape, a skylight), so that I can break in quickly and silently.
10. As a player, I want Time Pearl to let me sneak past a guard whose patrol I timed, so that observation of routes pays off.
11. As a player, I want the Time Pearl sneak to carry a low roll when I try to get in afterwards, so that the trade-off is felt.
12. As a player, I want item bonuses to apply only when I actually consume the item or cast the dial effect, so that carrying items is not a free buff.
13. As a player, I want a used item to always do what it says, so that failure comes from the roll or threshold, not the item.
14. As a player, I want a consumed item to stay consumed even if the roll fails, so that choices carry weight.
15. As a player, I want some approaches to injure or incapacitate guards before the fight, so that preparation shows up as an advantage.
16. As a player, I want some choices to remove some combatants outright, so that a raid can shrink before a blow is struck.
17. As a player, I want some choices to bypass combat altogether, so that stealth and persuasion are real routes.
18. As a player, I want enemies' start-of-fight state shown in the fight (hurt, afraid, fewer), so that I see my earlier choices paying off.
19. As a player, I want greyed-out approaches with a `?` icon, so that I know options exist that I can't yet use.
20. As a player, I want the `?` modal to say why the approach is blocked (which observation tier, which item, or both), so that I learn what to do next time.
21. As a player, I want an enemy to always be left with at least 1 HP when start-hurt applies, so that a fight can't be won before it starts.
22. As a player, I want observation results to remain the main driver, so that items feel like optional extras.
23. As a player, I want a rewind to behave consistently with item use and observation, so that my rewinds aren't undermined.
24. As a writer, I want raid events defined as data with per-approach item effects, so that I can add variants without code.
25. As a writer, I want each raid event to have its own observations, approaches and cards, so that variety is authored per event.
26. As a writer, I want new raid prose flagged for review and held to docs/writing-guide.md, so that tone stays consistent.
27. As a developer, I want one engine path for item effects on approaches, so that new items are data, not code.
28. As a developer, I want the fight to read its start state from the chosen approach's payload, so that combat has no special-casing per event.

## Implementation Decisions

- **Items are optional enhancements, observation is unchanged.** Observation rolls, tiers and display stay as in `spec.md`. Item effects are added per approach and per choice in event data.
- **Effect kinds** on an approach or choice (`itemEffects`, each naming an item):
  - `bonus`: roll delta on that approach's check.
  - `unlock`: makes an approach selectable (with or without an observation requirement).
  - `bypass`: skips the fight and still goes through a roll (high base chance).
  - `remove`: removes N combatants from the fight.
  - `fightStart`: start-of-fight state payload: `enemyStartsHurt`, enemy fear, guards infighting.
- **Observation gating:** approaches may require an observation tier (e.g. physics high), and observation tiers may also grant roll bonuses to named approaches. Gating and item effects combine: an approach can need both.
- **Consumption rule:** effects apply only when the item is consumed, or its dial effect is cast, in that event. No passive hold bonus. Consumption is spent whether or not the following roll succeeds. Items themselves never fail: only the roll or threshold can.
- **`enemyStartsHurt`:** chosen per approach (never global). When it applies, at least one enemy enters the fight with at least 1 HP. Choices may reduce the enemy count first or skip combat entirely; the 1-HP rule only guards fights that actually happen. Applied at fight start and shown in the fight view.
- **Item map (tentative, tuned in the grilling session):**
  - Wormhole: needs a physics-high observation, then bypass guards (still rolls).
  - Panic: guards flee (remove) or start afraid (fightStart).
  - Pandemonium: guards hit each other before the fight (fightStart, reduces HP / count).
  - Pan's Rapture: docile guards, bypass (still rolls).
  - Enhancement Powder: bonus on physical-entry approaches only.
  - Time Pearl: sneak past a timed patrol, low roll on the entry afterwards.
- **UI:** blocked approaches render greyed with a `?` icon. The icon opens a modal listing the missing requirement(s) (observation tier, item, or both). Locked rows should not hide.
- **Scope of events:** vein raids only. Stockpile raids get their own events (their own observations, options and cards) later. Other event types are deferred until raids are defined.
- **Replaces** the old passive `observeBonus` hook (ticket 23 as written); any remaining use is migrated to consumed-item `bonus`.
- **Architecture:** follows the project's one-way flow. Item effect resolution and fight-start payloads live in systems, event data in JSON, state remains a pure data tree (payload stored as plain dictionaries), screens only render and call systems.
- **Seams (proposed; confirm):** one top-level seam: the raid event resolver, driven headless with a seeded state (observation results + inventory in, approach availability, roll mods, fight-start payload, inventory out). Fight start is checked at one second seam: the combat entry from a payload.

## Testing Decisions

- A good test drives external behaviour: given state (observations, inventory, chosen approach), assert availability, modifiers, consumed items and fight-start state. No assertions on internals.
- Modules tested: raid event resolution (availability, gating reasons, item consumption), the effect kinds (bonus / unlock / bypass / remove / fightStart), and combat entry (1-HP rule, start state shown).
- The rules to cover: item consumed on failed roll; no passive hold bonus; bypass still rolls; locked reasons reported for the `?` modal; Rewind interplay.
- Prior art: `tests/test_observation.gd` (seeded rolls, mods) and `tests/test_raiding.gd` (raid flow).

## Out of Scope

- Stockpile raid redesign (own events later).
- Non-raid events and other event types.
- Rebalancing numbers (placeholders until playtest).
- New item art or combat visuals.
- Changing observation rules.

## Further Notes

- **First task for the agent: request a grilling session (the `grilling` skill) with the human before any code or tickets.** Goal: pin down exactly what a vein raid event should look like: how many events and variants, cards per event, approaches per event, which observations unlock what, how items map to approaches, bypass/remove/fightStart payload shapes, and failure paths. Break the result into tickets after the session.
- Other open questions to take into the grilling: Rewind vs consumed items; how many approaches per event; how rolls for `bypass` are tuned; guards-removed counts and fight scaling; whether the same item can be used more than once per event.
- Prose tickets: one per beat, each referencing `docs/writing-guide.md`, flagged `PROSE-REVIEW:`.
