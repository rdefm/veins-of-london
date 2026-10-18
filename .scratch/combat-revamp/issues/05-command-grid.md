# 05 — Command grid: Fight / Item / Dial / Leg it

**What to build:** The cluttered command dock is replaced by four big buttons in a 2×2 grid filling the bottom of the screen: **Fight, Item, Dial, Leg it**.
- **Fight:** the grid animates off to the left; the move list (Strike, Guard, Feint, Stun) appears with a Back button.
- **Item:** slides out the same way; the player's equipped loadout slots appear as selectable slots (a `rewind` slot is how Rewind is reached here), with Back.
- **Dial:** the grid animates off to the right; the Dial rises from the bottom, fully usable (casts, Complication readout, rewind Complication), with Back.
- **Back** scrolls the grid back on screen.
- **Leg it** acts directly.
Target selection on the stage is unchanged. Commands stay locked during playback as now.

**Blocked by:** 01 — Merge Lure into Feint; 03 — Pacing toggle → Settings app; 04 — Combat layout: board hidden + transcript

**Relevant files:**
- `scenes/components/combat_command_dock.gd`
- `scenes/components/dial_widget.gd`
- `scenes/screens/combat_rounds.gd` (row building, block reasons, Rewind command, Complication readout)
- `scenes/components/combat_director.gd` (`playing_changed` lock)
- `systems/combat.gd` (`choose_move`, `choose_item`, Dial casts, `round_rewind`)
- `tests/test_combat_command_dock.gd`, `tests/test_dial_widget.gd`
- `CODEMAP.md`; `docs/ui-vision.md`
- REFERENCE §3.7b Rewind, Dial Complications

**Status:** ready-for-agent

- [ ] Default state shows only the 2×2 grid in the command area
- [ ] Fight / Item / Dial each open their view with the described animation and a working Back
- [ ] Every action previously reachable (all moves, every loadout slot, Dial casts, Rewind via slot or Dial, Leg it) is reachable from the new layout
- [ ] Disabled options still disabled with their block reason
- [ ] Screen never mutates state; all actions go through system calls
- [ ] Human check: animations (left slide, right slide + Dial rise, Back), tap targets at phone width
