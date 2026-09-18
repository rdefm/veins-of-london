# 02 — CODEMAP rewrite to current-state rows

**What to build:** CODEMAP becomes the cheap lookup table it is meant to be: every row says what the file owns today in one or two sentences, with no ticket references, no history, no restating of data shapes or vision-doc sections that already live elsewhere. Target roughly a sixth of today's size. Nothing is dropped from the *set* of files listed; only the prose per row shrinks. CODEMAP comes off the lint allowlist.

**Blocked by:** 01 — Comment + CODEMAP policy with lint.

**Relevant files:** `CODEMAP.md`, the lint allowlist from ticket 01. Cross-check the file set against `ls autoload systems scenes/screens scenes/components data data/events tests/support scripts`.

**Status:** ready-for-agent

- [ ] Every file under autoload/, systems/, scenes/, data/ present today has a row; no row for a file that no longer exists.
- [ ] No row exceeds the cap from ticket 01; no row mentions a ticket, a milestone id, or what a file "used to"/"no longer" does.
- [ ] CODEMAP removed from the lint allowlist; whole-project check green.
- [ ] File size ≤ 10KB.
