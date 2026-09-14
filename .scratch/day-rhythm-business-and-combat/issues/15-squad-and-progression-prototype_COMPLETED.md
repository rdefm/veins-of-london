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

## Results and recommendation — 2026-09-14

Written per 15d, resting on 15c's verified, regression-free suite (2383 passed, 0 failed) rather than an unverified simulation. Nothing below is superseded by an earlier note; this section is the ticket's closing record.

### 1. Single-target defence demonstration (checklist item 1)

`squad_stance_covers_only_its_target_the_other_attacker_still_connects` (`pairAmbush`, seed 20): Countering enemy 0 only stops and retaliates against enemy 0's own Fast, but enemy 1's unguarded Fast still connects on the player every time — confirming a stance committed to one target leaves every other attacker fully dangerous, exactly as checklist item 1 asked to demonstrate.

Readability assessment (code/log level, not yet device-verified): every resolution line is distinct and carries its own HP readout (`"%s's Fast is stopped cold — you counter."` vs. the plain unguarded-hit line with `"%d/%d HP"` appended per `_log`/`_resolve_enemy_entry` in `systems/combat_prototype.gd`), and the screen renders per-enemy action blocks rather than one pooled log. At the log/data level this reads unambiguously — a player watching the log can tell which enemy connected and why the other didn't. Whether it's equally legible glanced at on a real portrait screen mid-fight is exactly what ticket 15e's on-device pass still needs to confirm; this writeup doesn't claim that. Recommendation: no UI callout is obviously required from the code alone, but defer the final call to 15e rather than deciding it here.

### 2. Mixed-squad tactics finding (checklist item 2)

15b root-caused the original "produces a real outcome mix" case as a harness bug (it kept Dodging the Brawler by name forever instead of cycling by round, so Heavy's branch was never reached — not a combat-balance finding). The corrected, fixed-cadence case (`mixed_squad_fixed_strategy_simulation_runs_cleanly_and_always_loses`, 60 seeded runs of "dodge twice, heavy, repeat" against `mixedCrew`) is the trustworthy result: **0 wins / 60 losses / 0 fled.**

This strategy does not dominate — it loses every single time. It only ever defends the one enemy it's currently prioritising (lowest-index living) while checklist item 1's own finding plays out at squad scale: the other two of three attackers go completely unguarded every round, and Heavy only connects on one round in three — nowhere near enough offense to outpace two enemies' worth of free incoming damage.

Implication for production: this is a real, structural result of the four-action grid (Fast/Heavy/Counter/Dodge) against 3-enemy squads, not a bug. It implies one of two things needs deciding before squads ship as a production encounter shape: either the action grid needs a fifth option that can meaningfully address more than one threat per round (Grab/Bolt/Call are the candidates already flagged, pending 15f's contract resolution — see §5), or squad encounters need explicit rebalancing (fewer simultaneous unguarded attackers, weaker squad-mate damage, or an different intended-strategy target) so a reasonable fixed strategy has a viable path to winning. This prototype doesn't resolve which; it only establishes that the current grid, played straightforwardly, can't.

### 3. Progression finding (checklist item 3)

`ordinary_enemies_do_not_scale_with_player_equipment_or_skill` confirms structurally that a fixed-strength, data-driven `combat_prototype.json` enemy's `hpMax` and attack range never depend on the player's `combatSkill` or equipment — only the player's own attack range (via `Combat.get_attack_range()`) improves between an early and prepared build against the identical enemy.

This is confirmed as designed-in behaviour of ordinary enemies, not a bug. Whether it's the intended *production* posture is an open design question this prototype surfaces but doesn't answer: if ordinary enemies never scale, late-game difficulty has to come from somewhere else (squad composition, multi-wave escalation, or a deliberately separate "scaling enemy" archetype) or a prepared late-game build will trivialize any fixed-strength encounter. Recommendation: a human design decision is needed on whether a scaling-enemy archetype is wanted for production, before ordinary enemies' non-scaling is treated as final.

### 4. Multi-wave assessment (checklist item 5)

`multi_wave_carries_player_hp_forward_and_only_ends_on_the_last_wave` (`gauntlet`, two waves) confirms HP carries forward with no reset between waves, and the fight's `outcome` stays `null` until the last wave clears.

Readability/pacing (code level): the wave transition is explicitly logged (`"That's one wave down. Next one's already moving in."`) and the round note appends a live `"Wave %d/%d."` counter (`scenes/screens/combat_prototype.gd`) — the signalling is unambiguous in the data the screen has to render from. As with §1, genuine on-screen readability is pending 15e's device pass, not claimed here.

The ticket's "don't turn routine encounters into waves" boundary holds: of the three launchable encounters (`pairAmbush`, `mixedCrew`, `gauntlet`), only `gauntlet` is multi-wave, and it exists specifically to stage this checklist item — the other two remain ordinary single-resolution fights. Multi-wave stayed a deliberate, rare escalation in this prototype, not a new default shape.

### 5. Explicit deferral note (checklist item 6)

Grab/Bolt/Call were **not** introduced in this ticket. No resolved contract exists for how they'd interact with the committed-round structure (stance-targetability, exhaustion, real-item resource source, Rewind restoration) — ticket 15's own checklist only required that they not be introduced without one, which not introducing them trivially satisfies. Follow-up ticket 15f (optional, independent of this chain) exists to grill that contract explicit before any future attempt to add them.

### Recommendation

**Ready to inform a separately scoped production integration ticket:**

- The single-target-defence mechanic (§1) and its log/data shape are proven and match spec intent — a solid basis to carry into a production combat screen.
- 14b's resolved real-inventory item contracts (Shield, Time Pearl, Enhancement Powder, Healing Burst, Blast, Black Hole) work end-to-end against real `Crafting` stock, including zero-stock refusal parity with production and Rewind correctly restoring item stock/Dial charge (but never the Rewind resource itself).
- The Freeze+exhaustion stacking and Enhancement Powder+Heavy-exhaustion interactions (13a amendments, §"Approved rule" above) are implemented and test-verified.
- The multi-wave HP-carry-forward mechanic (§4) works and stayed deliberately rare, per the ticket's own boundary.

**Open questions a future production ticket would still need to resolve:**

1. Squad combat balance (§2) — does "dodge twice, heavy, repeat" losing 60/60 mean the action grid needs a fifth option (Grab/Bolt/Call, pending 15f) before squads ship, or does squad encounter design itself need rebalancing? This prototype identifies the problem, not the fix.
2. Progression posture (§3) — is "ordinary enemies never scale" the intended final design, or does production need an explicit scaling-enemy archetype? Needs a human design call.
3. Device-level readability for single-target defence and multi-wave (§1, §4) — this writeup's assessment is code/log-level only; ticket 15e's on-device QA is the actual verification step and hasn't run yet.
4. Grab/Bolt/Call (§5) — resolve via ticket 15f before any production combat spec references them.

