# 06 — Move tooltips + red "!"

**What to build:** Every move and item option in the Fight and Item views gets a "?" that opens a small popover with one pithy line on what it does. The current "?" on a disabled option (explaining why it can't be used) becomes a red "!" that opens the existing block-reason explanation. Tooltip lines are new prose, drafted to the tone bible and flagged PROSE-REVIEW.

**Blocked by:** 05 — Command grid: Fight / Item / Dial / Leg it

**Relevant files:**
- `scenes/components/combat_command_dock.gd`
- `scenes/modals/combat_block_reason_modal.gd`
- `scenes/screens/combat_rounds.gd`
- `data/combat_rounds.json` (move tooltip strings), `data/recipes.json` or a combat-local table (item tooltip strings — no strings in code)
- `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`
- `tests/test_combat_command_dock.gd`

**Status:** ready-for-agent

- [ ] Each move (Strike, Guard, Feint, Stun) and each in-combat item has a "?" popover line, loaded from data
- [ ] Disabled options show a red "!" (not "?") that opens the block reason
- [ ] An option can show both (enabled-state "?" absent when disabled is fine if layout demands — decide and note)
- [ ] Report lists the string file under PROSE-REVIEW
- [ ] Human check: popover readability and dismissal on device
