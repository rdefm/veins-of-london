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
