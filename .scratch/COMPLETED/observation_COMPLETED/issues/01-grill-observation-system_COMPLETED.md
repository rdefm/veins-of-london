# 01 — Grill: Observation (reading people and places) in events

**Type:** grilling

**Status:** ready-for-human

**Blocked by:** None — can start immediately.

**Ask:** Human starts a grilling session (`/grilling` or `/grill-with-docs`) on the idea below. Aim: settle the open questions, then the human runs `/to-spec` to turn the result into `.scratch/observation/spec.md`. Nothing here is decided until the grilling confirms it — no code or data from this ticket.

## The idea so far

Inspired by Esoteric Ebb's observation system: pick a target, tap Observe, make one roll (stat + modifiers), and the roll decides how many of a fixed set of insight blocks get revealed. You never get nothing; a better roll shows more.

### Reading people: 5 blocks = 5 ores
Each insight block on a character maps to an ore — you read the calc residue on someone, and each ore shows a different side of them. Blocks unlock in a fixed order, easiest first:

| Ore | Reveals (working framing) |
|---|---|
| physics | what they carry: weapons, kit, cash |
| life | their body: hurt, tired, scared, using |
| emotion | what they feel now and what they want |
| time | where they've been and what they've done |
| fate | what they'll do next: intent |

### Reading places
Observation also works on surroundings, not just characters. Most finds are flavour; some have teeth:
- unlock an event option (`requires {flag}` style)
- add a mod to a later event check
- give a combat bonus going into a fight, e.g. a half-hidden exit → better Leg It odds; a narrow alley → enemies can only come at you one at a time

Open question: do place reads use the same 5-ore lens, or a different set of blocks?

### The stat: Sense (working name; "Perception" also floated)
- A new player skill you level up, like crafting/cultivating/combat. It's an affinity the player develops, not something bought per read.
- Seated Dial / Movement attunement gives a modifier, probably to reads of the matching ore.
- Item effects give targeted bonuses: Be A Lady boosts all reads; Prophet's Breath boosts time reads; more to be decided per item.

### MVP scope
1. **One ordinary event** with readable characters and surroundings, where the reads pay off later in the same event.
2. **One stealth raid event.** Rework the raid's "Go slow" option to open an observation; what you spot opens different routes and options through the raid. The aim is for this to replace the bare stealth roll for raids.

Accepted cost: more writing per event, in exchange for events with more to explore.

## Existing hooks (to read before grilling)

- **Event checks**: `check` + `mods` + `bySuccesses` + `attempts` + `requires` + `goto` + hub loops; stable rolls via `Rng.stable_unit`; Rewind re-roll with advantage. REFERENCE.md §3.9a "Event choice checks". `systems/events.gd`.
- **Be A Lady** already adds a per-level mod to every check (§3.9a "Odds") — precedent for item bonuses on read rolls.
- **Current stealth**: `stealth_check` op with `consumable_bonus` in `data/events/vein_raid.json`, `stockpile_raid.json`, `stockpile_raid_stash.json` (each already has Go slow / Go fast); `Raiding.stealth_success_chance()` in `systems/raiding.gd`; stealth skill curve `data/stealth.json` (`stealthXpLevels`).
- **Combat**: fog / `unreadChance`, Prophet's Breath sight, `fighter_peek`, Leg It, enemy reinforcement queue (`enemyQueue`) — a possible way to do "one at a time in the alley" with what's already there. REFERENCE.md §3.7b "Open/Guarded round combat"; `systems/combat_rounds.gd`. Combat prep: §3.7 "Preparation screen".
- **Intel**: `systems/intel.gd`, `state.intel[observer][target]` (REFERENCE.md §3.1 "Intel") — overlaps with reading faction people.
- **Recipe knowledge ladder** (insight/vague/exact): §3.5a — an existing tiered-reveal UI pattern.
- **Rewind**: event snapshots restore `state.event` (§3.9 "Snapshots & Rewind", §3.9a "Rewind re-roll").
- Prose: `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`.

## Questions for the grilling

**Core roll**
- One roll against thresholds (Ebb-style) or reuse `attempts` + `bySuccesses`? What die / thresholds / how do Sense levels shift them?
- Is the reveal order always physics → fate, or does it vary per target (e.g. a time-soaked character reveals time first)?
- Minimum guaranteed blocks: 1 always? Can a botched read tip off the target (malus on later checks)?
- Can you re-read the same target? Once per event, or once ever?
- Does observing cost anything — a time block, a beat, risk of being noticed?

**Sense skill**
- Name. XP source (per read? per block revealed?). Level cap — see `.scratch/skill-level-cap-10/`.
- Does Sense replace the stealth skill, absorb its XP, or sit beside it?
- Dial attunement: bonus only on the matching ore, or a general bonus?
- Which items give which read bonuses (beyond Be A Lady → all, Prophet's Breath → time)? How are the bonuses shown in the odds sheet?

**Payoffs**
- What can a block grant: flag only? check mod? combat-prep modifier? new ops needed?
- Combat bonuses from place reads: what's the list (Leg It odds, one-at-a-time, first strike, fog reduction…), and how is each carried into the fight (combatPrep state)?
- Persistence: does what you learned about a character carry beyond the event (a per-character knowledge record), or stay inside it?

**Rewind**
- Does knowledge survive an event Rewind ("I've seen this before") or get wiped with the snapshot? If it survives, what stops read → Rewind → know everything?

**Stealth raid as an event**
- What does a raid event need to look like: routes, hubs, guards as readable characters, outcomes when caught?
- Shared template across vein / stockpile / stash raids, or authored per raid type?
- What becomes of `stealth_check` and `Raiding.stealth_success_chance()` (vein security, extra guards, intel) — do they feed the read roll, the route odds, or both?

**UI (mobile)**
- Where's the Observe control — on the card, per speaker, per highlighted noun in the text?
- How are revealed blocks shown (sheet, stacked chips, inline under the card), and can the player look at them again later in the event?

**Content**
- Which ordinary event for the MVP? Which raid (vein raid is simplest)?
- Authoring format: one evergreen block set per recurring character plus per-event overrides, or all per event?
- Writing load budget per event; storyboard/art impact.

## Comments
