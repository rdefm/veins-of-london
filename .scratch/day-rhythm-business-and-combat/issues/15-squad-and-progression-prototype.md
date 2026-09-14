# 15 — Squad and progression prototype

**What to build:** Extend the experiment to mixed threats and prepared late-game wave fights to evaluate tactical variety.

**Blocked by:** 14 — Solo combat prototype.

**Status:** ready-for-agent

- [ ] Show the opponent covered by defence plus all other incoming threats; demonstrate that single-target defence leaves other opponents dangerous.
- [ ] Evaluate mixed brawler/knife fighter/enforcer squads and whether dodge twice, heavy, repeat dominates across encounters.
- [ ] Compare an early build and a prepared late build against the same fixed-strength early enemy; ordinary enemies do not scale to erase progression.
- [ ] Exercise existing calc effects within the approved prototype budget, per the item contracts resolved 2026-09-14 (see "Approved rule" below).
- [ ] Stage selected multi-wave prototype fights and assess sustained solo power and portrait readability; do not turn routine encounters into waves.
- [ ] Introduce planned Grab/Bolt and Call only after the basic interaction is understandable and their prototype contracts are explicit.
- [ ] Record scenario results, remaining decisions and recommendation for separately scoped production work; test multi-opponent resolution and perform device QA.

## Comments

2026-09-14 (superseded by "Approved rule" below): checklist item 4 originally read "Exercise existing calc effects within the approved prototype budget; any new Shield, Time Pearl, Enhancement Powder or area-effect contract requires explicit specification before use." Resolved via ticket 14b's grilling session.

## Approved rule — 2026-09-14

Resolved via ticket 14b (grilling session against 13a's round structure). Governs every calc-effect item contract exercised by this ticket's squad/wave prototype; supersedes 13a's own deferrals wherever noted.

### Resource source and entry points

- **Real inventory, no synthetic pool.** Item use spends from the player's actual `GameState.state["crafting"]` stock via `Crafting.inventory_remove`, exactly as production `combat.gd` does today — not a prototype-scoped synthetic or reset-per-encounter supply. Playtesting this prototype does draw down real consumables; the human is responsible for stocking up beforehand.
- **Zero-stock handling:** blocked exactly like production's existing refusals (e.g. "No shield.") — no top-up, no special-case unlock.
- **Both entry points in scope:** direct-bag `use_*()` equivalents AND Dial-cast `cast_complication()` (including its per-dial power/target multiplier), both unchanged from production behaviour.
- **Rewind:** restores item stock, HP, Dial charges, and all other combat state to the snapshot — except the Rewind consumable/Dial-charge itself, which stays spent. Matches production `Combat.combat_rewind()` exactly (the rewind resource itself is never refunded by its own use).

### Round-structure interactions (amend/extend 13a)

- **Enhancement Powder + Heavy exhaustion:** if Heavy is committed on the first of a Powder round's two queue turns, exhaustion skips the *second (inserted) slot that same round* — "the combatant's very next queue turn" is read literally/chronologically, not "next round."
- **Freeze + exhaustion overlap — amends 13a scenario 7.** The two now **stack** as two separate skipped turns rather than collapsing into one:
  1. While `frozenTurns > 0`, the frozen skip resolves first each queue turn: decrement `frozenTurns`, log as frozen, leave `exhaustedNextTurn` pending and untouched.
  2. Once `frozenTurns` reaches 0, the combatant's *next* queue turn after that is consumed by the pending exhaustion: skip, log as exhausted, clear `exhaustedNextTurn`.
  3. Net effect: a combatant frozen and exhausted in the same round loses more queue turns than either alone — frozen's duration, then one more for exhaustion — rather than 13a's original "exactly one turn skipped" reading.
- **Shield vs. stance:** `committedAction` is a single field — `"shield"`, `"counter"`, and `"dodge"` are mutually exclusive values, never combined in one round. A Shield-committed combatant has no stance up; an incoming attack goes through the plain matchup-free damage path, with `shieldPool` absorbing 1:1 before HP loss, same order as production's existing enemy-attack resolution.
- **Committed item vs. an opponent's stance:** no new mechanic. A Counter/Dodge aimed at an opponent who commits an item that round (never attacks) fizzles under 13a's existing "opponent didn't attack" rule — action still spent, no effect.
- **Blast / Black Hole in squad fights:** exercised as-is, unchanged from production — Black Hole hits every non-koed enemy (ignores focus, adds `frozenTurns` per target), Blast's disarm chance and flee-boost apply per its existing formula. No separate "mixed squads" check pass required; this contract covers AoE items directly.
- **Healing Burst / Healing Salve:** both instant, action-consuming, and never trigger or are subject to exhaustion (only a committed Heavy does that). Healing Salve keeps its production out-of-combat-only restriction, so it is simply unusable as a mid-fight committed action in this prototype — Healing Burst is the only in-combat heal item available.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

