# 13a — Combat prototype rules and agreed UI adjustments

**What to build:** Specify a bounded four-action combat experiment with unambiguous resolution and resource rules.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Supersedes:** 13 — Combat prototype rules. This consolidated ticket carries the original scope plus the subsequent UI agreement. References to ticket 13 in tickets 14, 18, 19 and 20 should use this ticket; this is not an additional dependency on completing the old ticket.

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [x] Specify Fast/Heavy/Counter/Dodge matchups: Counter stops and retaliates against selected Fast; Heavy bypasses Counter; Dodge avoids selected Heavy; Fast can catch Dodge. Defence consumes an action.
- [x] Resolve damage, retaliation, turn/speed ordering, stance duration/expiry and target death, interruptions, multiple strikes/targets and multi-action effects.
- [x] Decide whether exhaustion belongs in the experiment. **Decided 2026-09-14: included**, trigger tuned to one Heavy swing (see Approved rule).
- [x] Define committed intent action, target, relevant damage range and resolution timing, including visible interruption rules and snapshot state.
- [x] Establish item/extra-action resource budget and treatment of existing calc effects; no unapproved production effect changes.
- [x] Record human-approved prototype-only parameters, scenario acceptance examples and experiment boundary. Production balance remains unchanged.

## Agreed UI direction — 2026-09-13

- Four persistent buttons in a 2×2 grid: Fast / Heavy, then Counter / Dodge. No expanding Offensive/Defensive categories. Counter names the discussed parry.
- Reminders: Fast — “Catches Dodge”; Heavy — “Bypasses Counter”; Counter — “Stops Fast”; Dodge — “Avoids Heavy”. These are not a complete symmetrical rock-paper-scissors rule table.
- Top cards show current/max health numbers with bars, plus each attacker's committed intent and target. Preserve visibility of other threats.
- Item and Leg it sit underneath the four actions. Preserve bag, escape and calc behaviour; no new dedicated Time Pearl shortcut is approved.
- Grey panel right of Dial/umbrella shows the selected clock-face button's Complication, NOT enemy intent. Selection updates the panel without casting; preserve the dedicated activation trigger.
- Preserve current visual families and Dial art. No circle/arrows, recommended-action highlight, arena-art replacement or illustrative “After your action” timing is required.
- No exhaustion meter is authorized by this UI agreement; resolve exhaustion above separately. Do not invent a replacement vulnerability mechanic.
- UI delivery: tickets 18 (combatant cards), 19 (four-action controls), 20 (Dial selection detail).

## Comments

2026-09-13: User approved top-card health/intent/target, four buttons with matchup reminders, secondary actions below, and corrected the grey panel to show Dial selection. Exhaustion remains undecided. This clarification supersedes earlier mandatory exhaustion wording in the parent spec and prototype tickets until resolved here.

PROSE-REVIEW: Four matchup reminder strings require final copy audit.

## Approved rule — 2026-09-14

**Exhaustion decision:** included, but tuned down from the two-swing candidate — **one** committed Heavy swing causes Exhausted next turn, not two. Explicitly flagged as tunable after playtesting, not a locked number.

### New serializable state (per combatant: player, allies, enemies)

- `committedAction`: `"fast" | "heavy" | "counter" | "dodge" | "item" | "flee" | null`.
- `committedTarget`: opponent index the action/stance targets; omitted for item/flee/AoE.
- `exhaustedNextTurn`: bool.

### Round structure

1. **Commit phase** (before resolution): every living combatant not currently frozen or exhausted declares one `{committedAction, committedTarget}`. Frozen/exhausted combatants auto-skip and are shown as such — no commit. Player commits via the four buttons plus Item/Flee; enemies commit via existing target-pick logic (`_pick_enemy_target`) and their choice is revealed immediately (visible intent, target, timing, relevant damage range).
2. **Resolution phase**: the existing speed-ordered queue (§3.7a of REFERENCE.md) runs unchanged; each queue entry resolves its own committed action.

### Matchups and damage

- **Fast** = today's baseline attack range (`Combat.get_attack_range()`, Combat Skill + weapon bonus included), unchanged.
- **Heavy** = Fast range × 1.5 (min and max), rounded via `GameState.round_epsilon()`. **Prototype-only multiplier, not balance-final.**
- **Counter retaliation** = the defender's own Fast-range damage, applied to the stopped attacker in the same beat/log line as the block.
- Fast vs. the target's committed **Counter** (aimed at this attacker): stopped, zero damage, defender retaliates (above).
- Fast vs. the target's committed **Dodge**: still connects — Fast catches Dodge.
- Heavy vs. **Counter**: bypasses — Counter does not apply, Heavy connects at full (scaled) damage.
- Heavy vs. the target's committed **Dodge** (aimed at this attacker): zero damage, but the attacker is still exhausted next turn (a dodged Heavy still costs fatigue).
- A stance (Counter/Dodge) aimed at an opponent who doesn't attack the defender that round, or who dies/is interrupted first, fizzles with no effect — the action is still spent.
- A stance covers only its one selected opponent; other attackers remain fully dangerous.
- Shield absorption and enemy `evadeChance` rolls apply after the matchup resolves, before HP loss — unchanged order from today.

### Turn/speed ordering, stance duration, interruption

- Stances are live for the **whole round** from the moment they're committed, not gated by the defender's own queue position — a slower defender's Counter/Dodge still protects against a faster attacker earlier in the same round. (Gating stance validity by speed would make defence undependable, contradicting the "start with dependable matchups" direction.)
- Every stance/attack commit is consumed (triggered, connects, or fizzles) by end of round; nothing persists to the next round.
- The only interruption source in this prototype is **target death**: if a committed target dies before their own queue turn, their pending action is shown interrupted and never resolves; no stun/silence mechanic is introduced.
- Fast/Heavy stay single-strike/single-target — no new multi-hit. Enhancement Powder's existing extra-queue-turn (§3.7a) is unchanged and reused as-is: the inserted turn is a full second commit (any of the four actions or an item), not a bonus attack. Black Hole's existing AoE (ignores focus, hits every non-koed enemy) is unchanged.

### Exhaustion

- **Trigger:** any committed Heavy swing — by player, ally, or enemy — regardless of whether it connects or is Dodged.
- **Symmetry:** identical rule for player, allies, and enemies.
- **Effect:** the combatant's very next queue turn is skipped entirely (no commit, no action) — same "no action" outcome as `frozenTurns`, but logged distinctly ("Exhausted — catching their breath.") so it reads differently from a frozen skip. Exactly one lost action; no automatic critical bonus for anyone.
- **Recovery:** the flag clears the instant the skipped turn completes; the combatant commits normally starting the following round. No stacking — swinging Heavy again immediately re-triggers the same one-turn cost.
- **Freeze overlap:** if a combatant is simultaneously frozen and exhausted, exactly one queue turn is skipped (there's only one to lose); the frozen skip's existing log line takes precedence, exhaustion clears silently alongside it rather than printing a second message.
- **Available actions while exhausted:** none — Item and Flee are unavailable on a skipped turn too, not just Fast/Heavy/Counter/Dodge.

### Resource budget

Item use (Time Pearl, Shield, Blast, Black Hole, Healing Burst, Healing Salve) and Flee each consume the actor's one committed action for the round, exactly as today — alternatives to acting, not additions. The only source of an extra action remains the existing Enhancement Powder queue-insertion. No calc effect's own power or behaviour changes: Shield still absorbs 1:1, Time Pearl/Black Hole still set/add `frozenTurns`, Blast/Black Hole still deal their existing `effectPower(skill)` damage outright.

### Snapshot / Rewind

Extend the existing combat snapshot (§3.9, taken at the start of every player queue turn, 2-deep stack) to also capture, per combatant: `committedAction`, `committedTarget`, `exhaustedNextTurn`. Restoring the oldest snapshot restores these exactly like today's `frozenTurns`/`motionTurns`/etc.

### Prototype-only parameters (adjustable, not production balance)

| Parameter | Value | Note |
|---|---|---|
| Heavy damage multiplier | Fast range × 1.5 | New, prototype-only |
| Counter retaliation damage | = defender's own Fast range | Reuses existing formula |
| Exhaustion trigger | 1 committed Heavy swing (dodged or connecting) | 2026-09-14 decision, tunable |
| Exhaustion effect | skip exactly 1 queue turn, no auto-crit | Retained from original candidate |
| Exhaustion symmetry | player/allies/enemies identical | Retained from original candidate |
| Stance scope | 1 selected opponent, 1 round | New |
| Extra actions | only existing Enhancement Powder queue-insert | Unchanged from §3.7a |

`Combat.get_attack_range()`, existing enemy templates, and every calc-effect formula are read, never altered, by this ticket. This entire rule set is scope-bounded to ticket 14's solo prototype; it does not touch REFERENCE.md or production combat.

### Scenario acceptance examples

1. Player Fast at Enemy A; Enemy A committed Counter at the player → Fast is stopped, Enemy A retaliates for its own Fast-range damage; no exhaustion (only Heavy triggers it).
2. Player Heavy at Enemy A; Enemy A committed Counter at the player → Heavy bypasses, connects at Heavy-range damage; player exhausted next round.
3. Player Heavy at Enemy A; Enemy A committed Dodge at the player → zero damage; player still exhausted next round (dodged Heavy still fatigues).
4. Player Fast at Enemy A; Enemy A committed Dodge at the player → Fast still connects (Fast catches Dodge).
5. Squad fight: player Counters Enemy A only; unguarded Enemy B also attacks with Fast the same round → Enemy B's Fast connects normally.
6. Enemy A dies to a faster ally before Enemy A's queued Heavy resolves → Enemy A's Heavy shown interrupted, no damage, no exhaustion; a player Dodge aimed at Enemy A fizzles, action still spent.
7. Player is frozen (an enemy's Black Hole) and exhausted (a prior Heavy) in the same round → exactly one turn skipped, logged as frozen; exhaustion clears silently alongside it.
8. Player uses Shield, then takes a Heavy that bypassed a mismatched Counter → Shield absorbs first, remainder docks HP, same order as today.
9. Player uses Enhancement Powder and gets an inserted extra queue turn → that turn is a full second Fast/Heavy/Counter/Dodge/Item commit, not a bonus attack.
10. Rewind on the player's next queue turn restores `committedAction`/`committedTarget`/`exhaustedNextTurn` alongside existing fields.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

