# 04 — Site/vein sheet: read-only faction ownership display

**What to build:** Tapping a faction-owned stop on the map opens M1's existing site/vein sheet (N5 — interaction contract unchanged) and shows the owning faction's name and colour, ore type, level, and security tier, read-only. No action buttons — no cultivate/charge (it isn't the player's vein) and no raid button (Chunk 6 isn't built yet). No relation-flavoured text or raid-difficulty hinting. This replaces today's flat "Someone's already working this site. Nothing to do here (for now)." line.

**Blocked by:** 01 (needs real faction vein data — owner, ore type, level, security — to display)

**Status:** completed

- [x] Site/vein sheet detects a faction-owned site and renders: faction name (and colour, e.g. as a swatch/tinted label), ore type + symbol, level label, security tier label.
- [x] No buttons are shown for a faction-owned vein (verify no cultivate/charge/raid affordance leaks through).
- [x] Map tab's district site-list row claim-state text also reflects the faction identity (replacing the old "Claimed by someone else" string) rather than just the sheet. (Already done by T01 — `_site_claim_state_text()` was already faction-aware.)
- [x] Any new copy is dry, one line, matches CONTENT-GUIDE.md tone — flag with `PROSE-REVIEW:` in the task report. (No new prose — only data-driven labels reusing existing formatting patterns.)
- [x] Human visual QA note in the task report: what to check on-device (tap a faction-claimed stop, confirm no dead-looking buttons, confirm colour/name match `factions.json`).
- [x] `godot --headless --check-only` clean on every touched file; `scripts/run_tests.sh` passes.
