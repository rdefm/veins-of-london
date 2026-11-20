# 02 — Movements lose their ore; attunement moves to lenses; winding by lens ore

**What to build:** Spec `.scratch/lenses/spec.md` "Movements lose their ore", "Always: ore-roll bonus", "Saves".

- Remove `oreType`/attunement from Movements (state, craft, seat, readouts). `Dial.attempt_craft_movement(archetype)` costs a small amount of all five ores (`movement_calc_cost` split evenly; placeholder 4 each at base).
- `Dial.attunement_bonus(ore)` reads the loaded lens of that ore (`Lenses.tier_for`, `attunementBonusByTier`), not the seated Movement. Its callers (observation, crafting/Lab bench bonus, cultivate gain multiplier, seed chance) keep working unchanged: this is the ore-roll bonus.
- `Dial.wind(amount, owner_id, ore)`: `ore` must be a loaded lens's ore on that Dial; refused with no lens loaded. Cost per charge unchanged.
- `Dial.build_granted_dial` (James): also loads a tier-1 **time** lens.
- Save: bump `SaveManager.SAVE_VERSION`; loading an older save drops `player.dial`, contact Dials and `movementInventory` (no refund). Grep every Movement `oreType` read and remove it.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/dial.gd`
- `systems/observation.gd`
- `systems/crafting.gd`
- `systems/lab.gd`
- `systems/cultivating.gd`
- `systems/sites.gd`
- `systems/contacts.gd`
- `autoload/SaveManager.gd`
- `scenes/components/dial_loadout_menu.gd`
- `scenes/modals/movement_swap_modal.gd`
- `systems/debug_start.gd`
- `tests/test_dial.gd`
- `tests/test_james_dial.gd`
- `tests/test_savemanager.gd`
- `docs/REFERENCE.md` §1.4, §3.4, §3.5, §3.9d, §6

**Acceptance:**
- [ ] No Movement carries an ore; Movement craft spends all five ores.
- [ ] Attunement bonus applies only with a matching lens loaded, scaled by lens tier, for observation/craft/cultivate/seed.
- [ ] Wind pays the chosen loaded lens's ore; refused without a lens or with an unloaded ore.
- [ ] James's granted Dial has a T1 time lens and winds with time calc.
- [ ] Old-version save loads with no Dial; new save round-trips lenses.
- [ ] Existing screens still render (Dial card shows no Movement ore).
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
