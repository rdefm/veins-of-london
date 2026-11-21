# 04 — Remove dead code and repo clutter

**What to build:** The repo carries no code nothing calls and no stray one-off files. Source: code review 2026-11-21 item 12 (`.scratch/code-review/recommendations.md`). Zero gameplay change.

Delete (re-grep each across `autoload/ systems/ scenes/ scripts/ tests/ tools/` and `.tscn` files first — delete only if still unreferenced):
- Functions: `GuardUpkeep.hire_cost_text`, `Home.current_bill_base`, `Modal.set_return`, `MorningAccounts._positive_delta`, `Muscle.security_score`, `Muscle.hq_security_score`, `Muscle.faction_total`, `Perks.active_turf_for_site`. **Keep `PhoneNav.select_faction`** — it is the intended replacement for a screen writing `phoneNav.selectedFaction` directly (review item 5), not dead code.
- Orphan `.uid` files whose script is gone: `scenes/screens/{crafting,lab,property,veins}.gd.uid`, `scripts/_probe.gd.uid`, `tests/test_{inventory,ore_stock,sms_screens,veins_screen}.gd.uid` (re-run the orphan check; catch any new ones).
- Tracked one-offs: `_smoke_propagation.gd` (+ `.uid`), `bugs-26-08-18.txt`, `bugs-28-08-26.txt`, `scripts/_tmp_insight_shots.gd` (+ `.uid`), `scripts/diagnose_115_timing.gd` (+ `.uid`; tickets 115/116 are resolved), `output/imagegen/*`. For the bug-note .txt files, check with the human whether to move them into `.scratch/` instead of deleting.

Also review the ~35 system functions referenced only from tests: list them in the report with a keep/delete recommendation each (keep deliberate test seams); don't delete those in this ticket.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/guard_upkeep.gd`, `systems/home.gd`, `systems/modal.gd`, `systems/morning_accounts.gd`, `systems/muscle.gd`, `systems/perks.gd`
- repo root, `scripts/`, `output/imagegen/`
- `CODEMAP.md` (drop/adjust any entries for removed files)
- `scripts/lint_tokens_allowlist.txt` (remove entries for deleted files)

**Status:** ready-for-agent

- [ ] Listed functions removed (each confirmed unreferenced at time of removal); `PhoneNav.select_faction` untouched
- [ ] Orphan `.uid` files removed; no `.gd.uid` without its `.gd` remains
- [ ] One-off files removed or moved per the human's call on the bug notes
- [ ] CODEMAP and lint allowlist have no entries pointing at removed files
- [ ] `scripts/check_all.sh` clean; full suite passes
- [ ] Report includes the test-only-function keep/delete list
