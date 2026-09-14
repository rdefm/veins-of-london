# 14 — Solo combat prototype

**What to build:** A bounded playable experiment demonstrates readable four-action solo combat and reliable Rewind.

**Blocked by:** 13 — Combat prototype rules. (Superseded by 13a; this ticket implements 13a's approved rule set.)

**Status:** ready-for-human (implementation complete; portrait device QA + human evaluation outstanding, see below)

- [x] Implement ticket 13's prototype rules using serializable combatant/turn-order state, committed intent, selected defence target/stance, and exhaustion. (13a's "Approved rule — 2026-09-14" replaced the old "two exertion marks" candidate with a single-Heavy-swing trigger — see Assumptions below.)
- [x] Demonstrate all four defensive matchups, action-consuming defence, dodged-Heavy fatigue and symmetric player/enemy exhaustion.
- [x] Show action, target, damage range where relevant and timing; intents stay committed until resolved or visibly interrupted. Render resolved beats rather than predicting outcomes independently.
- [x] Teach Heavy/Dodge/exhaustion with a brawler, Fast/Counter with a knife fighter, then Counter/Heavy with an enforcer.
- [x] Rewind restores all introduced combat state; headless public-resolution tests verify matchups, timing, exhaustion and restoration.
- [x] Keep production mechanics unchanged; record prototype assumptions and evidence, with portrait device QA and a human evaluation before considering production integration.

## Implementation

`systems/combat_prototype.gd` (class `CombatPrototype`) — fully isolated from `systems/combat.gd` and `GameState.state["combat"]`. Its own state lives at `GameState.state["combatPrototype"]`, its own snapshot stack (`"combatPrototype"` in `autoload/Snapshots.gd`'s `MAX_SIZES`), its own screen (`scenes/screens/combat_prototype.gd`, registered as screen id `"combat_prototype"`), reached only via the Debug app's new "Solo Combat Prototype" card (`scenes/screens/phone.gd`). Teaching roster in `data/combat_prototype.json` (validated by `GameData._validate_combat_prototype()`).

Public API: `start_encounter(id)`, `take_player_action(action)`, `skip_exhausted_round()`, `rewind()`, `advance_to_next_encounter()`, `exit_encounter()`. One button press both commits and resolves the round (mirrors `systems/combat.gd`'s existing single-button UX) — the enemy's scripted action is revealed via the resulting log/beats, not a separate pre-resolution declare step.

Tests: `tests/test_combat_prototype.gd` (rules, all public-API-driven — matchups 1–4 and Rewind scenario 10 from ticket 13a, exhaustion trigger/skip/recovery cycle, stance fizzle, win/loss/flee outcomes, sequence progression, real-player isolation) and `tests/test_combat_prototype_screen.gd` (screen build smoke tests across every reachable state). Full suite: 2366 passed, 1 pre-existing unrelated failure (`test_gamedata.gd`'s `real_data_loads_and_validates`, flagging `objectives.col_a1_nadia_supply`'s `'supplied_to_contact'` type — from the separate in-flight Nadia-supply-order work, confirmed via `git stash` to predate this ticket; not touched here).

## Assumptions and evidence (per this ticket's own instruction)

Recorded in full at the top of `systems/combat_prototype.gd`; summarized here for review:

1. **Solo means one enemy, full stop.** Ticket 13a's acceptance examples 5 (an unguarded second attacker in a squad) and 6 (a committed target dying before their own queue turn, interrupting a third party's stance) both need more than one combatant per side to exercise at all — out of scope here, ticket 15's job.
2. **No items are wired.** Only Fast/Heavy/Counter/Dodge/Flee are real committable actions — no Crafting/Dial dependency, so a prototype fight can never touch real consumable inventory. Flee reuses production's flat 65% base chance. This also means 13a's scenario 8 (Shield absorption order) and scenario 9 (Enhancement Powder's extra queue turn) aren't exercised.
3. **No freeze mechanic exists** (that's an item effect in production), so 13a's exhaustion/frozen-overlap scenario (example 7) is untested here.
4. **Each of the three encounters starts the player at full hp** — a fresh baseline per taught matchup, not cumulative attrition across the sequence.
5. **The prototype's own player hp is a separate field from the real save**, seeded from the real player's `hpMax` (for a believable number) but never reading or writing `GameState.state["player"]["hp"]` — a prototype fight can't leak damage or death into the real game. Covered by its own test (`start_encounter_never_touches_the_real_players_hp_field`).
6. **Commit and resolve collapse into one call** (`take_player_action()`), same as `systems/combat.gd`'s existing single-button "Attack" press — ticket 13a describes an abstract commit-then-resolve round structure, but doesn't mandate a UI pause between the two phases, and production has no such pause for its own enemy turns either. Flagged here explicitly (raised in code review) as a design call worth a second look before any production UI (tickets 18/19/20) locks in the same shape — a version with a visible "both sides have committed, tap to resolve" beat would read differently at the table.
7. **Passive `evadeChance`** (separate from the committed Dodge stance) is rolled at the single shared damage-application chokepoint (`_deal_damage()`) so it applies uniformly to a plain hit, a bypassing Heavy, Fast catching a Dodge, and a Counter's own retaliation — per 13a's "evadeChance rolls apply after the matchup resolves, before HP loss — unchanged order from today." All three teaching archetypes currently roll `evadeChance: 0.0`, so this only matters if a later encounter or ticket 15's roster sets it above zero; covered by its own test (`passive_evade_chance_still_applies_to_a_bypassing_heavy`).

PROSE-REVIEW: every encounter `name`/`intro`/`teaches` string in `data/combat_prototype.json`, the four action-reminder strings in `scenes/screens/combat_prototype.gd` (reused verbatim from 13a's own already-reviewed UI copy), and every hand-written combat log line in `systems/combat_prototype.gd` are new copy, drafted dry/administrative against CONTENT-GUIDE.md's tone bible — not yet human-audited.

## Outstanding before production integration

- **Portrait device QA** (human, on-device): reach the prototype via Debug Start → Debug app → "Solo Combat Prototype" → Start. Play all three encounters end to end; confirm the 2×2 action grid, HP bars, log, exhausted/outcome states, and Rewind button all render and stay usable on a real portrait screen — nothing here has been visually verified outside headless tests.
- **Human evaluation** of whether the four-action matchup grid, exhaustion pacing, and Rewind actually read as "readable" in practice, and whether assumption 6 above (single-tap commit+resolve) should change before tickets 18/19/20 build the real production UI on top of these rules.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
