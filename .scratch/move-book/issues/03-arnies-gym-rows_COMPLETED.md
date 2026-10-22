# 03 — Arnie's gym shows the move rows; HQ workout modal drops its Moves card

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR), placement "2 · Arnie's gym · Spar". If this ticket and the mock disagree, stop and ask.

**What to build:**
- Arnie's gym (the Spar modal) shows the player's compact move rows (name, mini track, level badge). Tapping a row opens the same Move Book detail as the Profile app.
- The HQ home workout modal removes its Moves card; it keeps Combat Skill and Train.

**Blocked by:** 02 — Move Book in the Profile app.

**Relevant files:**
- `scenes/modals/gym_spar_modal.gd`
- `scenes/modals/hq_gym_modal.gd` (`_moves_card`)
- `scenes/phone_apps/profile_app.gd` (reuse the row/detail builders from 02; move them to a shared component if needed)
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Spar modal shows compact rows; a tap opens the detail
- [ ] HQ workout modal has no Moves card
- [ ] Row/detail code shared, not duplicated
- [ ] Human check: spar modal layout on-device
