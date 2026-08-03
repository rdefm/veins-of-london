# 07 — Phone reskin + The Ticker

**What to build:** the Phone tab per D4 — contact list, SMS threads (existing sms screens reskinned as threads), James job offers, the to-do list as a notes app, a faction directory, and The Ticker (D4.5 — the barometer as a news app: three headline cards, axis detail on tap, manual push/pull unchanged, M4 influence actions listed greyed). Replaces the M0 World and barometer screens; save-slot UI moves to You.

**Blocked by:** 03 (needs the nav shell to exist).

**Status:** COMPLETED

- [x] Contact list, SMS threads, James job offers, to-do-as-notes, faction directory all present under Phone
- [x] The Ticker: three headline cards (economic/social/political), trend hint at ≥70 progress on a non-active state, axis detail view with progress bars + push/pull buttons (£2000, cooldowns unchanged from M0) + greyed M4 influence actions with full costs shown
- [x] Headline strings: 2–3 variants per state, drafted per CONTENT-GUIDE.md tone bible, flagged `PROSE-REVIEW`
- [x] Barometer state changes push a phone notification styled as breaking news
- [x] M0 World and barometer screens deleted; save-slot UI relocated to You
- [ ] Human visual QA: read an SMS thread, view a James job offer, trigger a barometer push and see the Ticker update
- [x] `godot --headless --check-only --script` clean on all touched files (`--check-only` itself can't resolve autoload singletons in this Windows sandbox, even on unmodified baseline files — verified via the full `tests/test_runner.gd` suite, 299/299 passing, plus a rebuilt `.godot/global_script_class_cache.cfg` to pick up the new `class_name` scripts)

## Implementation notes

- `scenes/screens/phone.gd` (new): a home launcher (`state.phoneNav.app`) into Messages, Notes, Factions, and the Ticker — same drill-down-state pattern as `state.mapNav`/`MapNav`, via new `systems/phone_nav.gd`.
- Messages/Factions reuse Archie/James/faction card-building logic pulled out of the still-live `contacts`/`factions` screens into `scenes/components/contact_cards.gd` (static builders, same shape as `scenes/components/ui.gd`) — avoids the two screens' flag-gated logic drifting apart. `contacts`/`factions`/`veins`/`home` themselves are untouched and still wired into the tutorial-era flow (event `set_screen` effects still target `contacts`); ticket 10 (tutorial gating) is the intended point to retire them, not this ticket.
- Notes extracts `home.gd`'s to-do checklist into `systems/todo.gd` (`Todo.get_items()`), shared by both `home.gd` and Phone.
- The Ticker: `data/barometer.json` gets a `headlines` array (2 variants) per state — new `GameData.gd` validation requires ≥2. `systems/barometer.gd`'s `_resolve_section` now pushes `"📰 BREAKING — <headline>"` (random variant) instead of the old `"<Section> shift: <Label>. <description>"` line; new `Barometer.trend_hint_state(section)` backs the "rumblings…" hint. Push/Pull buttons route through `UI.format_cost_label` (D4.4), which the old `barometer.gd` screen never did.
- `scenes/screens/you.gd` (new) merges the already-unreachable `stats`/`save` screens (no `Nav.go_to` call site existed for either) — HP/attack/cash/day, skills, a read-only equipped-weapon/device summary, ops summary, and save/load/export/import/new-game — matching D4's full spec for the You tab.
- `scenes/screens/world.gd`, `barometer.gd`, `stats.gd`, `save.gd` deleted; `scenes/Main.gd`'s `SCREEN_SCRIPTS` and `docs/REFERENCE.md` §2.2 updated to match. `home.gd`'s "Save & Load" button now points at `you` instead of the deleted `save`.
- PROSE-REVIEW: `data/barometer.json`'s 30 new headline strings (2 per state × 15 states).
