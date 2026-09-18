# 15e — Device QA and close-out

**What to build:** Human portrait-device verification of ticket 15's squad/item/wave UI, then close the whole ticket 15 arc out.

**Blocked by:** 15d — QA should be evaluating the shape the results writeup actually signs off on, and this ticket's own commit/rename step is the final act for the whole ticket 15 chain (15, 15b, 15c, 15d, 15e).

- [ ] **Human, on-device**: reach the prototype via Debug app → "Solo Combat Prototype" → try every `CombatPrototype.list_launchable_encounters()` entry (`pairAmbush`, `mixedCrew`, `gauntlet`), not just the teaching sequence.
- [ ] Confirm per-enemy action blocks (Fast/Heavy/Counter/Dodge/Blast) render and target correctly with 2-3 living enemies on a real portrait screen.
- [ ] Confirm the Items card (self/AoE items, real inventory-qty gated) and Dial card (loaded Complications) are usable and legible.
- [ ] Confirm the wave indicator and HP-carries-forward behaviour read clearly across the `gauntlet` fight's two waves.
- [ ] Confirm Rewind is usable and its effects (including restored item stock/Dial charge) are visible/sensible from the player's seat, not just correct in state.
- [ ] Once QA is signed off: commit all outstanding ticket 15/15b/15c/15d work (`git add -A`, review what's staged), then rename ticket 15's file to `15-squad-and-progression-prototype_COMPLETED.md`.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Report device-only checks separately in this ticket's own notes — nothing here should be claimed as verified without having actually been run on-device.

## Device QA notes and sign-off — 2026-09-14

Human ran the prototype on-device via Debug app → "Solo Combat Prototype". Findings:

- Flagged: `combat_prototype.gd`'s screen reuses the pre-redesign combat UI shape — the intent-visible cards described by ticket 18 (still unbuilt) don't exist here, so with 2-3 living enemies a tester can't see what any enemy is about to do.
- Raised: Prophet's Breath should be added to these debug scenarios to address the above. Investigation found this wouldn't actually help — its real effect is an evade buff (`systems/combat.gd:1181`), not an intent reveal, and it was deliberately left out of 14b's approved item list (`combat_prototype.gd:64-67`). Split into two follow-ups rather than implemented inline: **15g** (wire Prophet's Breath/Wormhole into the prototype's item budget) and **15h** (grilling ticket — should Prophet's Breath's contract change to reveal intent, or does ticket 18's free unconditional telegraph already cover this).
- Signed off to close ticket 15 on this basis: the enemy-intent-visibility gap and full item coverage are real findings but out of ticket 15's own original checklist scope, and are now tracked as independent follow-ups (15g, 15h) rather than blockers.
