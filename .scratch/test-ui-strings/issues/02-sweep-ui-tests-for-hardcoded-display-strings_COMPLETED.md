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

## Comments

Audit (grep `label_texts`, `.text ==`, `ends_with("`: ~359 hits, mostly already data/format-driven):

**Converted** (literal -> public const on the owning scene script; source and test share it):
- `test_modal_layer.gd`: "Network Reference" -> `NetworkReferenceModal.HEADING_TEXT`; "Nothing in stock to load." -> `DialLoadComplicationModal.EMPTY_STOCK_TEXT`; "None in stock." / "No ore to stash." / "No crafted items to stash." -> `HqOreReadoutModal.EMPTY_*_TEXT`; gym hint -> `HqGymModal.UPGRADE_HINT_TEXT`
- `test_hq_dial.gd`: no-Dial message -> `HqDialScreen.NO_DIAL_TEXT`

**Kept** (one-line reasons):
- Button/filter-chip labels ("All", "Wild", "Craft", "Empty", "‹ Back", "Tier 2/3", "Ore store") — test locators for stable UI affordances; the label is the identity under test.
- Computed strings built from `%` + system values (raid risk, XP, "3 selected · …") — already derived from state/formulas.
- Lab-screen notices ("Add calc from a jar first.", "No Time recipes known.", cracked-vessel text) — pinned prose/ systems-owned `reason` strings; changing them should force a deliberate test update.
- `test_phone_*`, ticker, lodedinnit, vein_detail — read from data/state or pin authored copy; not swept further here.
