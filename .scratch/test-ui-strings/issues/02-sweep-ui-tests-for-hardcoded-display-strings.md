# 02 — Sweep UI tests for hardcoded display strings

**What to build:** Find tests that assert literal player-facing text (labels, buttons, headings) and move them to read the text from its source (data, constants, or the format helper pattern from 01) or to assert on state/structure. Prioritise strings that were reworded recently or that repeat across tests; leave deliberately-pinned prose checks (e.g. content-lint on authored events) alone, with a one-line comment why.

**Blocked by:** 01

**Relevant files:** `tests/test_modal_layer.gd`, other `tests/test_*screen*.gd` and `tests/test_*modal*.gd`, `tests/support/` (`NodeQuery.label_texts_with_symbols` callers), `scenes/`.

**Status:** ready-for-agent

- [ ] List of hardcoded-display-string assertions (grep `label_texts`, `.text ==`, `ends_with("`) with a keep/convert decision for each, recorded in the ticket's Comments
- [ ] Converted cases read text from its source or assert on state/structure
- [ ] Kept cases carry a one-line reason
- [ ] Full suite no worse than before (the 3 modal cases fixed by 01 pass)
- [ ] `check_all` clean
