# 03 — Multi-enemy targeting & independent enemy turns

**What to build:** With a real turn queue in place (ticket 02) and a roster array (ticket 01), make multi-enemy fights actually behave like multiple independent combatants rather than one shared target — this ticket is verifiable with a hand-constructed 2–3 enemy `combat.enemies` array even before roster generation (ticket 04) can produce one naturally.

The player's single-target actions (Attack, Blast, and any Complication that isn't an AoE effect) always resolve against `combat.enemies[focusedEnemyIndex]`. `focusedEnemyIndex` is written only by the (out-of-scope, later) UI swipe gesture — nothing in the system layer sets it except the ticket-01 death-auto-clamp.

AoE effects (currently only Black Hole) ignore `focusedEnemyIndex` entirely and apply their full, un-diluted effect to every non-koed enemy independently — matching the no-per-target-dilution precedent the Dial's Spread Movement already established for multi-target casts (i.e. hitting 3 enemies with Black Hole is 3× the total damage/freeze applied, once per enemy at full power, not power divided across them).

Enemy AI targeting keeps its existing shape (uniform-random over `{player} ∪ {living allies}`) unchanged in logic — the only change is that it now runs once per enemy's own queue turn, independently per enemy, rather than once per round for the single enemy that used to exist. Each enemy in a 3-enemy fight can pick a different target from another on the same round.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Attack, Blast, and every non-AoE Complication resolve against `combat.enemies[focusedEnemyIndex]` only, never touching other living enemies
- [ ] Black Hole (and the AoE code path generally) applies its full, un-diluted damage/freeze effect to every non-koed enemy in `combat.enemies`, independently — not divided across them
- [ ] Each living enemy takes its own independent turn in the queue (per ticket 02), rolling its own uniform-random target over `{player} ∪ {living allies}` on its own turn, rather than one shared roll per round
- [ ] A 3-enemy fight (hand-constructed in a test) can end with, e.g., one enemy koed and two still standing, each having taken independent actions against potentially different targets
- [ ] New tests assert outcome/state shape (e.g. "after Black Hole, every enemy's hp dropped by the same amount and all are frozen the same duration") rather than call-order internals
