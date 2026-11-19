# 05 — Auto-craft button and quantity sheet

**What to build:** an **Auto-craft** button next to Craft manually on the recipe page bar.

- **Blocked state:** when batch is blocked, the button is disabled and carries the reason ("Craft one by hand first." / "Not enough calc."), using the disabled-with-reason action button.
- **The sheet:** tapping the button opens a sheet docked to the bottom bar, on a dim that cancels it. It holds:
  - the quantity slider (1..`Lab.max_batch`, remembering the last pick)
  - the total-calc line
  - the multi-target toggle and its gate line, when the recipe offers it
  - a "Craft ×N" confirm that calls `Lab.batch`, pushes the existing toast and closes the sheet
- **Refusals:** a refusal reason shows on the recipe page.
- **Cleanup:** remove the old inline batch controls.

**Blocked by:** 02

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_add_batch_controls`, `_batch_label`, `_batch_total_text`, `_on_batch`; `_build_rewind_choice` as the dim-sheet pattern)
- `scenes/components/map_card_style.gd` (`quantity_slider`, `action_button`)
- `systems/lab.gd` (`max_batch`, `batch`), `systems/crafting.gd` (multi-target helpers)
- `docs/REFERENCE.md` (lab batch / multi-target rules)
- `tests/test_lab_screen.gd` (batch cases: "Batch ×1" becomes "Auto-craft" + "Craft ×1")

**Status:** ready-for-agent

- [ ] Auto-craft disabled with the reason before a hand run and when calc is short; enabled otherwise
- [ ] Sheet: slider range and total correct; confirm crafts and closes; dim or cancel crafts nothing
- [ ] Multi-target toggle only for offered recipes; gate line when locked
- [ ] Lab screen tests updated and passing
