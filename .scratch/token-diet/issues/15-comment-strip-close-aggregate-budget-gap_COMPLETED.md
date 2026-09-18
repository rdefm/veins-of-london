# 15 — Comment strip: close the systems/+autoload aggregate budget gap

**What to build:** Ticket 03's systems/+autoload comment strip landed at ~3,569 combined comment lines across all 69 files (down from a 5,806 baseline), short of the ≤2,903 target (half of baseline) that ticket's own acceptance checklist requires. This ticket closes that gap. The two biggest reserves are autoload/GameState.gd (361→292, only a 19% cut) and autoload/GameData.gd (369→227, 38%) — both flagged by the prior pass as dense with load-bearing schema/formula rationale rather than ticket narration, so they were left alone rather than risk deleting real information. Take a second, more careful look at tightening their prose (shorter sentences, one blanket note covering several similar fields instead of one per field) without losing any invariant a reader needs. Also revisit the other files that landed furthest from a 50% cut: systems/bench.gd (106→85), systems/map_layout.gd (74→53), systems/contracts.gd (55→49), systems/sites.gd (194→131), systems/district_deck.gd (33→33, untouched). Once the aggregate is ≤2,903, remove every systems/ and autoload/ entry from scripts/lint_tokens_allowlist.txt (ticket 03's other unmet acceptance line), confirm scripts/lint_tokens.sh and the full test suite are still green, and rename ticket 03 to `_COMPLETED` in that same commit.

**Blocked by:** None — can start immediately (this is ticket 03's own unfinished remainder, not a new dependency chain).

**Relevant files:** autoload/GameState.gd, autoload/GameData.gd, systems/bench.gd, systems/map_layout.gd, systems/contracts.gd, systems/sites.gd, systems/district_deck.gd, scripts/lint_tokens_allowlist.txt, scripts/lint_tokens.sh, .scratch/token-diet/issues/03-comment-strip-systems-and-autoload.md (the ticket this one closes out)

**Status:** done

- [x] Combined comment-line count across systems/*.gd + autoload/*.gd is at most 2,903 — verify with `grep -rc '^\s*#' systems/*.gd autoload/*.gd | awk -F: '{s+=$2} END {print s}'`. Landed at exactly **2903**.
- [x] No comment lost real rationale in the process — spot-check that GameState.gd/GameData.gd's surviving comments still explain every non-obvious invariant they covered before. Both files hand-edited with each cut tracked against the pre-ticket text; a repo-wide PROSE-REVIEW-marker diff confirmed no new-prose flag was silently dropped anywhere in the touched set (one such marker was briefly lost and restored during raiding.gd's pass — see Comments).
- [x] Every systems/ and autoload/ entry removed from scripts/lint_tokens_allowlist.txt.
- [x] scripts/lint_tokens.sh and the full test suite (scripts/run_tests.sh) are green. Suite: 2474 passed, 0 failed.
- [x] Ticket 03 (03-comment-strip-systems-and-autoload.md) renamed to `_COMPLETED` in the same commit as this ticket's final acceptance check. (Was already renamed pre-existing from an earlier commit; carried through unchanged.)

## Comments

Filed after ticket 03's implementation pass (4 parallel forks + prior work) landed 62 files but missed the aggregate numeric target. The `full_playthrough_tutorial_economy_ticks_and_save_roundtrip` test failure seen during verification is pre-existing and unrelated (reproduces identically with these changes stashed out) — not this ticket's concern, but worth a separate bug report if not already tracked.

**2026-09-18 — paused mid-implementation, work uncommitted in the working tree.** Ran 4 parallel forks by file cluster (autoload, combat, economy/progression, map/UI-nav); stopped 2 of them mid-run on request. All edits so far verified comment-only diffs and clean `check_runner.gd` / `check_all.sh` syntax (no parse errors from the interrupted forks).

Aggregate: **3068** (was 3617 at ticket start, target ≤2903 — **still 165 over**).

Done:
- Map/UI-nav cluster (26 files incl. `map_layout.gd` reserve, `district_deck.gd` reserve): 738→655. Vocab-clean. Finished.
- Combat cluster (`combat.gd`, `combat_prototype.gd`, `raiding.gd`, `raid_alarms.gd`, `combat_pacing.gd`): 761→657. Vocab-clean (raiding.gd's ~19 ticket-narrated lines rewritten). Finished, but fork reported it couldn't safely reach its assigned sub-target without cutting real rationale — combat.gd/raiding.gd were already dense post-ticket-03.
- Economy/progression cluster, partial: `factions.gd` 138→95, `events.gd` 134→102, `sites.gd` 131→103, `dial.gd` 120→86, `cultivating.gd` 120→84, `bench.gd` (flagged reserve) 84→56, all vocab-clean. **Interrupted mid-edit on `bench.gd`** when stopped (landed in a valid, already-clean state — no partial/duplicate comments left behind).
- Autoload cluster, partial: `GameState.gd` 292→245, `GameData.gd` 259→192 (both spot-checked clean by their fork, not yet independently re-verified by a human for invariant loss — see open item below). **Interrupted mid-edit on `SaveManager.gd`** (292→194→147, still 11 lines of `ticket <N>` vocab left unrewritten, e.g. lines 198, 388, 408, 439, 442, 566, 577, 583, 589, 695, 697).

Left to do:
1. Finish `autoload/SaveManager.gd`'s vocab purge (11 remaining `ticket <N>` hits) and push the autoload cluster further — currently 605 combined (GameState 245 + GameData 192 + SaveManager 147 + EventBus 12 + Snapshots 9), short of its own ≤500 sub-target.
2. Resume the economy/progression cluster: `contracts.gd` (flagged reserve, still untouched at 49 — the ticket's "11% cut" complaint stands) plus `economy.gd`, `collective.gd`, `vein_trade.gd`, `rooms.gd`, `crafting.gd`, `payroll.gd`, `travel.gd`, `jobs.gd`, `offers.gd`, `stash.gd`, `consumables.gd`, `equipment.gd` — all still at their pre-ticket-15 counts. Cluster is at 1007/1208, already under its own ≤1020 sub-target, but the aggregate as a whole is not yet under budget.
3. Close the remaining ~165-line aggregate gap (3068→≤2903) — likely needs a mix of #1 and #2, or a fresh pass over combat.gd/raiding.gd if those two prove to have more safe slack than the combat fork found.
4. Human/agent spot-check that `GameState.gd` and `GameData.gd`'s surviving comments still explain every invariant they covered pre-ticket (acceptance check #2) — not yet done.
5. Remove all systems/+autoload entries from `scripts/lint_tokens_allowlist.txt` — not started, gated on #1–3 (vocab must be fully clean file-by-file, which it now is everywhere except SaveManager.gd) and on hitting the aggregate.
6. Run `scripts/lint_tokens.sh` and the full `scripts/run_tests.sh` — not run yet.
7. Ticket 03 rename to `_COMPLETED` — already satisfied (pre-existing, from an unrelated earlier commit `b7aa9ad`); nothing left to do there.
8. Commit — nothing committed yet; all of the above is sitting uncommitted in the working tree.

**2026-09-18 — closed out.** Resumed from the paused state above via two parallel forks (autoload cluster: SaveManager/GameState/GameData; economy/map reserves: economy.gd, contracts.gd, collective.gd, vein_trade.gd, rooms.gd, district_deck.gd), then closed the remaining gap by hand with a second, careful pass over GameState.gd, GameData.gd, combat.gd, and raiding.gd.

- SaveManager.gd's fork purged all remaining `ticket <N>`/named-slug vocab (147→119) and consolidated several near-duplicate migration comments; one transient mid-edit slip (two live `_int_key`/`_int_dict_values` lines briefly deleted alongside their comment markers) was caught and fixed by the fork itself, then independently re-verified against the diff.
- GameState.gd got a hand pass (244→197): tightened wording, merged adjacent per-field notes, no invariant dropped — every distinct fact from the pre-ticket text is still present, just fewer words per fact. Same treatment for GameData.gd (190→177) and combat.gd (263→259) and raiding.gd (238→228), the latter two despite an earlier fork's assessment that they had no safe slack left — they did, in the ~1-3-line-per-comment range.
- One PROSE-REVIEW marker was transiently lost when two adjacent new-prose notes in raiding.gd's `_apply_raid_loot` were merged into one paragraph; caught by a repo-wide before/after PROSE-REVIEW-count diff across every touched file and restored as a second marker in the same paragraph.
- Final aggregate: exactly **2903** (the ≤2903 target, no more headroom left as of this ticket).
- Fixed two incidental history-vocabulary lint hits in `scenes/components/map_canvas.gd` (outside systems/+autoload scope, but needed for `lint_tokens.sh` to report clean) — "no longer resolvable" reworded to "not resolvable"; false positives on the word "longer" describing runtime state, not code history.
- All acceptance checks above now pass; full suite green (2474/0); allowlist stripped of every systems/+autoload line.
