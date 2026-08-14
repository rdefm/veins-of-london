# 07 — Type picker + pairing panel

**What to build:** The two screens that let a player choose a pairing and see everything they've learned about it, honestly and in plain words, with no glyph-only or color-only encoding. The 15 type-pairings are never shown as an explicit grid, matrix, or completion tracker anywhere in these screens.

**Blocked by:** 06 — state.benchNav wiring + HQ Lab card + Lab home screen.

**Status:** ready-for-agent

- [ ] Type picker screen: flat list of the 5 orichalchum types with the player's held quantities; tap-to-select up to two, second tap on a third type replaces the earlier selection (toggle-replace behaviour); no census, state, or progress information shown anywhere on this screen.
- [ ] Pairing panel screen: prose census line (from ticket 04's reveal data — "barren" on a genuinely empty pairing's first probe reads distinctly from "not yet surveyed"); one row per approach with inline state text in plain words — `found`/`hot`/`inert` rows show their state, `untried` rows show no subtitle at all, unlearned-approach rows show where to get that approach (room/contact) instead of a lock icon. `inert` rows are visibly dimmed and untappable.
- [ ] Lab home screen's found-effects list (ticket 06) now navigates into this pairing panel on tap.
- [ ] Screen tests (mirror `tests/test_map_screen.gd`'s headless-scene pattern): type picker enforces max-2 selection and toggle-replace behaviour; pairing panel renders correct state text per cell state (spent/dimmed/untappable, untried/blank, unlearned/source-text) without any glyph-only encoding.
- [ ] Syntax check clean on all touched `.gd` files.

**PROSE-REVIEW:** all cell-state row text, the census sentence, and unlearned-approach source text are new prose against `docs/CONTENT-GUIDE.md`.
