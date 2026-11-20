# 01 — Lens data, Dial lens slots, crafting, load/unload

**What to build:** Add lenses as a Dial component (spec `.scratch/lenses/spec.md` "Dial changes": Lens slots, Crafting lenses, Contact Dials). System + data only; existing screens must not break.

- `data/dial.json`: a `lens` block: `lensSlotsByLevel [0,1,1,2,2,3]`, craft `baseSuccess`/`ingredientBase`/`xpReward` (Movement-style, placeholders), `senseGates {world: 2, combat: 3, glimpse: 4, peripheral: 5}`, plus slots for the per-tier tables later tickets fill (placeholders).
- State: owned lenses in `player.lensInventory` (`[{ore, tier}]`), loaded in `dial.lenses` (`[{ore, tier}]`, length <= `lens_slots(level)`). Pure data.
- New `systems/lenses.gd` (`Lenses`): the single read layer later tickets use: `loaded(owner_id)`, `tier_for(ore, owner_id)` (0 = none), `has(ore, owner_id)`, `sense_unlocked(gate)` (player Sense >= `senseGates[gate]`; always false for a contact owner).
- `Dial.attempt_craft_lens(ore)`: gift-gated, ingredients (calc of `ore`) always spent, chance-gated, tier = crafting skill, adds to `lensInventory`.
- `Dial.load_lens(index, owner_id)` / `unload_lens(slot, owner_id)`: refused in events/combat, when slots are full, or when that ore is already loaded on that Dial (one lens per ore per Dial). Contact Dials use the same functions.
- `CONTEXT.md`: add **Lens**.

**Blocked by:** None, can start immediately.

**Status:** ready-for-agent

**Relevant files:**
- `systems/dial.gd`
- `systems/lenses.gd (new)`
- `data/dial.json`
- `autoload/GameData.gd`
- `autoload/GameState.gd`
- `tests/test_dial.gd`
- `tests/test_lenses.gd (new)`
- `CONTEXT.md`
- `CODEMAP.md`
- `docs/REFERENCE.md` §1.4

**Acceptance:**
- [ ] Lens craft success/fail spends ore; success adds `{ore, tier}` at crafting-skill tier.
- [ ] Load refused: full slots, duplicate ore, during event/combat; unload returns the exact unit.
- [ ] Slot count follows Dial level per `lensSlotsByLevel`.
- [ ] `Lenses.*` queries tested for player and a contact Dial; `sense_unlocked` false for contacts.
- [ ] REFERENCE §1.4 documents lenses; CONTEXT + CODEMAP updated.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
