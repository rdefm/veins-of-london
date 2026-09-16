# 15 — Comment strip: close the systems/+autoload aggregate budget gap

**What to build:** Ticket 03's systems/+autoload comment strip landed at ~3,569 combined comment lines across all 69 files (down from a 5,806 baseline), short of the ≤2,903 target (half of baseline) that ticket's own acceptance checklist requires. This ticket closes that gap. The two biggest reserves are autoload/GameState.gd (361→292, only a 19% cut) and autoload/GameData.gd (369→227, 38%) — both flagged by the prior pass as dense with load-bearing schema/formula rationale rather than ticket narration, so they were left alone rather than risk deleting real information. Take a second, more careful look at tightening their prose (shorter sentences, one blanket note covering several similar fields instead of one per field) without losing any invariant a reader needs. Also revisit the other files that landed furthest from a 50% cut: systems/bench.gd (106→85), systems/map_layout.gd (74→53), systems/contracts.gd (55→49), systems/sites.gd (194→131), systems/district_deck.gd (33→33, untouched). Once the aggregate is ≤2,903, remove every systems/ and autoload/ entry from scripts/lint_tokens_allowlist.txt (ticket 03's other unmet acceptance line), confirm scripts/lint_tokens.sh and the full test suite are still green, and rename ticket 03 to `_COMPLETED` in that same commit.

**Blocked by:** None — can start immediately (this is ticket 03's own unfinished remainder, not a new dependency chain).

**Relevant files:** autoload/GameState.gd, autoload/GameData.gd, systems/bench.gd, systems/map_layout.gd, systems/contracts.gd, systems/sites.gd, systems/district_deck.gd, scripts/lint_tokens_allowlist.txt, scripts/lint_tokens.sh, .scratch/token-diet/issues/03-comment-strip-systems-and-autoload.md (the ticket this one closes out)

**Status:** ready-for-agent

- [ ] Combined comment-line count across systems/*.gd + autoload/*.gd is at most 2,903 — verify with `grep -rc '^\s*#' systems/*.gd autoload/*.gd | awk -F: '{s+=$2} END {print s}'`.
- [ ] No comment lost real rationale in the process — spot-check that GameState.gd/GameData.gd's surviving comments still explain every non-obvious invariant they covered before.
- [ ] Every systems/ and autoload/ entry removed from scripts/lint_tokens_allowlist.txt.
- [ ] scripts/lint_tokens.sh and the full test suite (scripts/run_tests.sh) are green.
- [ ] Ticket 03 (03-comment-strip-systems-and-autoload.md) renamed to `_COMPLETED` in the same commit as this ticket's final acceptance check.

## Comments

Filed after ticket 03's implementation pass (4 parallel forks + prior work) landed 62 files but missed the aggregate numeric target. The `full_playthrough_tutorial_economy_ticks_and_save_roundtrip` test failure seen during verification is pre-existing and unrelated (reproduces identically with these changes stashed out) — not this ticket's concern, but worth a separate bug report if not already tracked.
