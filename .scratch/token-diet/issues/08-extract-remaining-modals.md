# 08 — Extract remaining modals

**What to build:** Every remaining modal type — combat setup (with ally rows), dial load complication, movement craft, movement swap, HQ ore readout (with personal-stash section and raid stamp), HQ gym/train, lab-bench recipe book, lab-bench notes, lab-bench probe result, network reference/legend — moves to the registry. Style helpers that several modals share (action button/card styles, bordered/slip panels) live once in the modals helper script or in the shared UI helper, not per modal. The modal layer ends as chrome + dispatch only.

**Blocked by:** 06 — Modal registry + result modals extracted.

**Relevant files:** `scenes/components/modal_layer.gd`, `scenes/modals/`, `scenes/components/ui.gd`, `systems/combat.gd`, `systems/dial.gd`, `systems/stash.gd`, `systems/bench.gd`, `systems/crafting.gd`, `tests/test_modal_layer.gd`, `tests/test_hq_lab_bench.gd`, `tests/test_dial_widget.gd`, `tests/test_hq_screen.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] All remaining modal types render and behave identically.
- [ ] Modal layer script ≤ 300 lines and contains no per-type content builder.
- [ ] No StyleBoxFlat helper with the same purpose is defined in two places across scenes/.
- [ ] Syntax check and full test suite green.
