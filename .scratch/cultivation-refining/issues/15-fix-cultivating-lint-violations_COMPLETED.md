# 15 — Fix lint_tokens.sh history-vocabulary violations in cultivating.gd

**What to build:** `bash scripts/check_all.sh` currently fails at the lint step because six comments in `systems/cultivating.gd` narrate "cultivation-refining ticket NN" rather than describing current behaviour (CLAUDE.md workflow step 8's comment policy). Reword those comments in place so they describe what the code does now — keeping whatever rationale/why they carry — with no ticket numbers or other history vocabulary. Do not add the file to `scripts/lint_tokens_allowlist.txt`.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/cultivating.gd` (flagged lines: 147, 188–189, 251, 424, 486)
- `CLAUDE.md` (workflow step 8 — the comment/CODEMAP token-diet policy this ticket brings the file into line with)
- `scripts/lint_tokens.sh` / `scripts/lint_tokens_allowlist.txt` (the enforcement this ticket must satisfy without touching the allowlist)

**Status:** ready-for-agent

- [ ] `bash scripts/lint_tokens.sh` reports no violations for `systems/cultivating.gd`
- [ ] `systems/cultivating.gd` is not added to `scripts/lint_tokens_allowlist.txt`
- [ ] Each reworded comment still conveys its original rationale (why, not just what), without a ticket number or other history vocabulary
- [ ] `bash scripts/check_all.sh` exits clean
