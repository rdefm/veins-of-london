# Spec: Observation (reading people and places) — MVP

**Status:** ready-for-agent

Source: grilling session on `.scratch/observation/issues/01-grill-observation-system.md`.

## Problem Statement

Events are read-and-pick: the player has no way to *look closer* at a scene — to notice the nervous man, the half-hidden exit, the guard about to turn his back — and have that noticing matter. Raids are the sharpest case: the player's only lever is "Go slow / Go fast" in front of a bare stealth roll they can't see into, and the stealth skill behind it has no real use outside raids and no way to train it.

## Solution

Any event card can carry one **observation** of the scene. When there's something new to see, the event screen's **Action** button pulses; inside it, **Observe** rolls once per ore type (physics, life, emotion, time, fate) and reveals a block of insight per ore — better rolls land better tiers, a miss still says something. Rolls are shown D&D-style (d100, high is good, bonuses lower the number needed). What you saw can unlock new options, add bonuses to later checks (in this event or future ones), and set up the fight if it comes to one. A new skill, **Sense**, makes you better at it.

The MVP proves this on one event: `vein_raid` becomes an observation raid — read the place, then pick a route (quiet routes unlocked by what you spotted, or go in hard with combat bonuses from what you spotted).

## User Stories

1. As a player, I want the Action button to pulse when the current card has something I haven't observed, so that I know there's more to see.
2. As a player, I want the Observe row inside the Action popup to pulse too, so that I know which action the pulse is about.
3. As a player with reduced motion on, I want a static badge instead of a pulse, so that the signal doesn't animate.
4. As a player, I want one Observe tap to read the whole scene (place and people together), so that looking around is one gesture.
5. As a player, I want to see a die roll per ore, so that each insight feels earned.
6. As a player, I want rolls shown as "Rolled 73 · needed 40+", where higher is better, so that it reads like the dice games I know.
7. As a player, I want to see which bonuses lowered the number I needed (Sense, attunement, Lady, intel…), so that I understand why I'm good or bad at this read.
8. As a player, I want each ore's text to animate in after its roll, so that the reveal has rhythm.
9. As a player, I want to tap to skip the animation, so that repeat reads don't slow me down.
10. As a player, I want tier pips (e.g. ●●○) and muted text on a miss, so that I can tell at a glance what landed.
11. As a player, I want a miss to still give me a line of text, so that observing never shows a blank.
12. As a player, I want some reads to have more than pass/fail (a sharp read vs. a rough read), so that a great roll tells me more.
13. As a player, I want to reopen an observation I've already made and see the same results instantly, so that I can check what I noticed before deciding.
14. As a player, I want consecutive cards in the same scene to share one observation, so that I don't re-read the same alley.
15. As a player, I want the pulse to come back when the scene changes to something new, so that I don't miss new things to notice.
16. As a player, I want observing to be free, so that I'm never punished for looking.
17. As a player who rewinds, I want to keep what I already observed, so that a Rewind never makes me forget.
18. As a player who rewinds, I want one fresh roll per observation that keeps my best tier per ore, so that a Rewind can sharpen a read but never worsen it.
19. As a player, I want a re-armed observation to pulse again after a Rewind, so that I know I can look again.
20. As a player, I want re-roll rows to show "Rolled 31 · kept 73", so that I see the second roll didn't cost me anything.
21. As a player, I want options unlocked by a read to appear (fade in) after I close the sheet, so that I feel observing opened new doors.
22. As a player, I want unlocked or boosted options to carry the glyph of the ore that earned them, so that I can connect cause and effect.
23. As a player, I want the ? modal of a boosted check to list the read as a labelled modifier, so that I see exactly what my observation was worth.
24. As a player, I want a read I made in an earlier event to matter later (a bonus or a new option), so that paying attention pays off over time.
25. As a player going into a fight, I want what I spotted to change the fight (easier Leg It, one enemy at a time, first strike, seeing their plans), so that reading the room matters even when it goes loud.
26. As a player, I want those fight bonuses shown when the fight starts, so that I know why the fight is shaped this way.
27. As a player, I want a Sense skill that levels up, so that I get better at reading people and places.
28. As a player, I want every block rolled and every tier landed to give Sense XP, re-rolls included, so that observing trains Sense.
29. As a player, I want prospecting to give Sense XP on top of its cultivating XP, so that scouting land also sharpens my eye.
30. As a player with a seated Movement, I want reads of its attuned ore to be easier, so that my Dial shapes what I notice.
31. As a player under Be A Lady, I want all reads to be easier, so that the item behaves as it does for checks.
32. As a player under Prophet's Breath, I want time reads to be easier, so that the item's foresight theme carries over.
33. As a raider, I want to read the vein site before committing, so that I can find a smarter way in.
34. As a raider, I want my intel on the owning faction to improve my reads, so that groundwork pays off.
35. As a raider being fed disinformation, I want my reads to suffer, so that bad intel bites.
36. As a raider, I want the site's security and value to make it harder to read, so that well-defended veins feel well defended.
37. As a raider, I want the Network handler's tip, grudge and Muscle perk bonuses to still help, so that existing systems keep their effect.
38. As a raider, I want "Just go in" and "Go in loud" always available, so that I'm never forced to observe.
39. As a raider, I want quiet routes (a window on the latch, timing the patrol gap, waiting out a tired guard, distracting him, moving when he's about to turn) unlocked by specific reads, so that each ore gives me a different way in.
40. As a raider, I want some routes to take guards out of the fight, so that a good read can avoid or shrink the fight.
41. As a raider, I want a better tier on an ore to make its route more likely to work, so that a sharp read beats a rough one.
42. As a raider, I want getting caught to come only from a failed route, not from observing, so that looking is always safe.
43. As a raider who reads the same vein on another night, or a different vein, I want a fresh roll, so that raids don't read identically every time.
44. As a player who reloads a save, I want the same rolls to replay, so that save-scumming doesn't reroll fate.
45. As an author, I want to define each observation once per event and reference it by id from cards, so that authoring is compact.
46. As an author, I want a card without `observe` to inherit the scene's observation and `observe: null` to clear it, so that scene changes are explicit only where they happen.
47. As an author, I want to give each ore 1–n tiers, each with its own base chance and text, plus a miss text, so that I control difficulty and depth per ore per situation.
48. As an author, I want to list only the ores that have something to say (1–5), so that I'm not forced to pad.
49. As an author, I want to add my own mods to an observation's rolls using the normal condition vocabulary, so that earlier choices can make a read easier.
50. As an author, I want an `{observed: {event?, id, ore, atLeast}}` condition in `requires`, `mods` and conditional `goto`, so that reads gate and boost content.
51. As an author, I want per-tier `effects` that run once when that tier is first reached, so that a read can set flags, intel or similar side effects.
52. As an author, I want a fight op's `situational` list of conditional mods, so that reads shape a fight without new prep state.
53. As an author, I want the content lint to reject malformed observations, so that broken data fails tests rather than play.
54. As the human designer, I want the MVP to leave stealth and the stockpile raids untouched, so that I can back out if the feel is wrong.
55. As the human designer, I want all numbers in data and flagged as placeholders, so that playtesting tunes them without code changes.

## Implementation Decisions

### Modules
- **New system `Observation`** (static funcs, pure state, no Nodes): resolves the observation in effect for the current card, reports whether it is unread/re-armed, performs a read (rolls, tiers, best-of, XP, tier effects), returns display rows for the screen (per ore: shown roll, needed, mod breakdown, tier landed, text, whether this roll improved), writes observation memory on event completion, and answers the `observed` condition.
- **Events**: card `observe` field and inheritance; `condition_met()` gains `observed`; observation state lives under `state.event` (snapshotted); the re-roll arm and roll counts carry forward through `Events.rewind()` like `rolled`; checks in repeatable events include `runKey` in their roll key.
- **Event items / Action menu**: the event footer's Item button becomes the **Action** button, shown when any action exists (observation in effect, or a usable item). The popup lists Observe first, then items.
- **Combat**: fight-start ops (`start_scripted_fight`, `start_raid_combat`) accept `situational: [{if: <condition>, <mod>}]`, evaluated once at fight start with the shared condition vocabulary. MVP mods: `fleeBoost` (Leg It chance), `oneAtATime` (enemies enter via the reinforcement queue), `firstStrike` (overrides `enemyFirst`), `sight: N` (rounds of sight). Active mods are recorded on `state.combat` and shown at fight start.
- **Sense skill**: `player.senseSkill` / `player.senseXP`, curve `senseXpLevels` (shared shape, follows the level-10 extension), awarded via `Progression.award_xp` with a level-up notify. Prospecting awards Sense XP alongside its cultivating XP.
- **Raiding**: a raid-factor mod source for observation rolls (security / raid resist, value, intel on owning faction via `Intel.raid_odds_shift`, Network handler `claim_bonus`, grudge bonus, Muscle perk), each a labelled mod applied to every ore. Raid guard count can be reduced by an event op from an incapacitate route; zero guards left skips the fight.
- **Stealth is not touched** in the MVP: `stealth_check`, `stealthSkill`, and the stockpile raids keep working as today.

### Schema (event JSON)
```
"observations": {
  "<id>": {
    "mods": [ <mod> ],                      // optional, normal mod vocabulary
    "blocks": {
      "<ore>": {                            // 1–5 of physics/life/emotion/time/fate
        "tiers": [                          // best first; nested thresholds
          { "base": 0.2, "text": "...", "effects": [ ... ], "min"?: , "max"?: },
          { "base": 0.6, "text": "..." }
        ],
        "miss": "..."
      }
    }
  }
}
card: "observe": "<id>" | null             // absent = inherit
condition: { "observed": { "event"?: "<eventId>", "id": "<obsId>", "ore": "<ore>", "atLeast": <tier 1..n, 1 = lowest hit> } }
fight op: "situational": [ { "if": <condition>, "fleeBoost"|"oneAtATime"|"firstStrike"|"sight": <value> } ]
```
Leave room for future per-block/tier `variants` (not implemented).

### Roll rules
- One independent roll per listed ore. Tier k lands iff `roll < clamp(tier.base + Σmods, min, max)` (defaults `eventChecks.defaultMin`/`defaultMax`); the best landed tier wins; none = miss. The same Σmods applies to every tier of that ore.
- Mods per ore: Sense `sensePerLevel × (level − 1)` (all ores); seated Movement attunement (matching ore, flat, scaled by Movement tier); Be A Lady (`ladyBonusPerLevel × level`, all); Prophet's Breath active (time, flat); the observation's own `mods`; raid factors (raid observations only). Item `observeBonus: {ore|"all": delta}` is the data hook for future items. All numbers live in data and are placeholders.
- **Display (presentation only)**: shown roll = `100 − roll×100`, needed = `100 − p×100` for the landed or next tier. The engine stays as `roll < p`.
- **Seeding**: `Rng.stable_unit("rollSeed|eventId|observationId|ore|runKey|rollCount")`, where `runKey` = current day plus the event's context site id when present. Reload replays; another night or vein differs. No global RNG draws.
- **Once per id per run**: the first Observe rolls; later Observes reopen results. Each event Rewind re-arms one extra roll for each observation already read (`rollCount` + 1); the best tier per ore is kept across rolls. No extra advantage hash.
- **XP**: per block rolled + per tier landed, on every roll including re-rolls. No raid-specific Sense XP.
- **Tier effects** run once, when that tier (or the first time any tier ≥ it) is first reached; an improvement runs only the newly reached tiers' effects.
- **Memory**: on event completion, the best tier per ore per observation is written to a persistent record keyed by event id + observation id (pure data, saved, survives Rewind); `observed` with `event` reads it, without `event` reads the current run.
- Observing costs nothing and can never trigger detection.

### Event screen
- Action button: new icon (to be picked in the visual pass); pulses (glow/scale tween) while an unread or re-armed observation is in effect; reduced motion shows a static badge. The popup's Observe row pulses likewise. The popup always opens, even when Observe is the only entry.
- Observation sheet: a bottom sheet titled with the scene; one row per listed ore in fixed order physics, life, emotion, time, fate, using the ore glyph and colour. Per row: a d100 tick/spin (~0.5s), then the roll line, the tier pips, then the text fades in; rows play in sequence. Tap skips to the end state. Tap a roll line for the mod breakdown. Reopen = instant end state. Re-roll shows "Rolled X · kept Y" and animates only improved rows. Reduced motion = no spin, quick fade.
- Options gated by `observed` stay hidden until met (the default `requires` display), then fade in when the sheet closes; options unlocked or boosted by a read show that ore's glyph on the button. Boost mods appear in the ? modal with their author label.
- The screen only reads `Observation`/`Events` outputs and calls their functions. No state mutation in the screen.

### MVP content: `vein_raid`
- **Approach beat**: the tension card + a raid observation (aim for all 5 ores, tiers + miss text, card-label tokens for faction/district/ore where useful).
- **Route beat**: always-on "Just go in" (a check with a low base and raid factor mods, `runKey`-seeded) and "Go in loud" (straight to the fight); read-unlocked quiet routes (one per ore as the writing permits), each a check with a good base plus `observed atLeast: 2` mods; some routes incapacitate guards. A failed route → `start_raid_combat` with `situational` mods from the reads.
- **Caught beat**: fight intro lines, including the situational lines.
- Claim / Loot are unchanged. The old Go slow / Go fast and their `stealth_check` are removed from `vein_raid` only.
- Prose: one ticket per beat, drafted against `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`, flagged `PROSE-REVIEW:`. Engine/UI tickets may use placeholder prose.

### Docs
- REFERENCE.md gains an Observation section (schema, roll rules, mods, memory, seeding) and the Sense skill; the §3.9a roll key notes `runKey` for repeatable events. CONTEXT.md gains *observation*, *read*, *tier*, *Sense*. CODEMAP updated for new and changed files.

## Testing Decisions

- Good tests drive public behaviour and assert on resulting state/outputs, never on internals or animation timing. Rolls are stable-seeded, so tests either pick seeds/bases that force outcomes (base 0.95/0.05 with clamps) or compute the expected stable roll via the public roll helper.
- **Seam 1, Events (main)**: synthetic events installed into `GameData.EVENTS` (prior art: `test_events.gd`). Covers inheritance/`null`, unread/re-armed state, per-ore independent rolls, nested tiers and miss, the mod sum and clamps per source, display conversion, once per run, Rewind keep + one re-roll + best-of, `runKey` variation and replay, XP awards (including re-rolls), tier effects firing once, `observed` in `requires`/`mods`/`goto`, memory after completion and cross-event reads, raid factor mods, and checks in repeatable events varying by `runKey`.
- **Seam 2, combat start**: event-op fight start with `situational` entries, asserting on `state.combat` (prior art: `test_raiding.gd`, combat tests).
- **Seam 3, event screen** (live tree, prior art: `test_event_screen.gd`): Action button visibility rules, popup order, pulse/badge state flag, sheet rows (pips, hit/miss styling, text), skip, reopen, ore glyph on unlocked/boosted options.
- **Seam 4, content**: `test_event_content_lint.gd` validates the observation schema (known ores, tiers best-first, miss present, ids referenced exist); a `vein_raid` playthrough via seam 1 (observe → unlocked route → success/fail → combat with situational mods → claim/loot).
- Sense XP from prospecting: covered alongside the existing prospecting XP tests.

## Out of Scope

Post-MVP. No tickets are to be written or implemented for these until the human has playtested the MVP and approved the full feature:
- **Intro event** that introduces Sense and observing: Sherlock Holmes-style deduction, alluding to the player's Gift letting them sense orichalchum.
- **Stealth → Sense merge**: migrate stealth XP, remove `stealth_check` / `stealthSkill` / `stealthXpLevels` and `Raiding.stealth_success_chance()`, convert `stockpile_raid` and `stockpile_raid_stash` to observation raids.
- Observation in ordinary (non-raid) events.
- Prose `variants` per block/tier.
- Further item `observeBonus` entries beyond Lady and Breath; the `enemyStartsHurt` combat mod.
- D&D-style d100 display for ordinary event checks.
- Number tuning (placeholders until playtest).

## Further Notes

- Pure-state rule: all observation results, roll counts, re-arm marks and memory are Dictionaries/Arrays/primitives under `GameState.state`, so save, snapshot and Rewind keep working.
- Existing roll-key gap: `Events.check_roll()` keys carry nothing per run, so repeatable events roll identically every run; this spec fixes it for checks in repeatable events via `runKey`.
- Writing load: authors aim for all 5 ores per observation, but the schema allows 1–5. writing-guide.md should gain a guideline: at least one non-physics block per observation.
