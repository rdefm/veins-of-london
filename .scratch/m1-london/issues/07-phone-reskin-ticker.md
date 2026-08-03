# 07 — Phone reskin + The Ticker

**What to build:** the Phone tab per D4 — contact list, SMS threads (existing sms screens reskinned as threads), James job offers, the to-do list as a notes app, a faction directory, and The Ticker (D4.5 — the barometer as a news app: three headline cards, axis detail on tap, manual push/pull unchanged, M4 influence actions listed greyed). Replaces the M0 World and barometer screens; save-slot UI moves to You.

**Blocked by:** 03 (needs the nav shell to exist).

**Status:** ready-for-agent

- [ ] Contact list, SMS threads, James job offers, to-do-as-notes, faction directory all present under Phone
- [ ] The Ticker: three headline cards (economic/social/political), trend hint at ≥70 progress on a non-active state, axis detail view with progress bars + push/pull buttons (£2000, cooldowns unchanged from M0) + greyed M4 influence actions with full costs shown
- [ ] Headline strings: 2–3 variants per state, drafted per CONTENT-GUIDE.md tone bible, flagged `PROSE-REVIEW`
- [ ] Barometer state changes push a phone notification styled as breaking news
- [ ] M0 World and barometer screens deleted; save-slot UI relocated to You
- [ ] Human visual QA: read an SMS thread, view a James job offer, trigger a barometer push and see the Ticker update
- [ ] `godot --headless --check-only --script` clean on all touched files
