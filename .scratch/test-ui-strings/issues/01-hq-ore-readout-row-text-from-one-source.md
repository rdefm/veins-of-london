# 01 — HQ ore-readout row text comes from one source, tests stop hardcoding it

**What to build:** The HQ ore-readout modal's Shared/Stash row text is produced by a single public format function that the modal and its tests both use. The three failing modal tests build their expectation from that function (or assert on the row's underlying quantities) instead of a literal string, so relabelling the rows never breaks them again, and they pass.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/hq_ore_readout_modal.gd` (`_personal_stash_section`, row labels for ore and crafted items), `scenes/components/bag_drawer.gd` (check for the same wording), `tests/test_modal_layer.gd` (cases `hq_ore_readout_modal_stash_row_appears_for_shared_only_ore_and_moving_it_debits_shared_credits_stash`, `..._stash_row_still_appears_for_stashed_only_ore_and_unstashing_reverses_it`, `..._crafted_item_row_appears_and_moves_preserve_the_total`), `tests/support/` node-query helpers, CLAUDE.md (screens render only; no logic in screens).

**Status:** ready-for-agent

- [ ] One function formats a name + shared + stash quantity row; the modal uses it for both ore and crafted-item rows
- [ ] The three cases contain no literal "Shared"/"Stash"/"shared"/"stashed" display text; they derive expectations from the function or check quantities
- [ ] The three cases pass; no other `test_modal_layer` case regresses
- [ ] `check_all` clean
