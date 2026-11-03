# 10 — Coverage grid

**What to build:** a coverage view in storyboard's Prose pack mode: template × slot × fact range → how many prose cards can fire. Fact ranges come from the thresholds actually used in `when` conditions across the packs (not a hand-kept list). Cells with zero cards are red, one card amber. Clicking a cell opens the sandbox with those facts set.

**Blocked by:** 08 — Storyboard Prose pack mode: viewer + sandbox

**Relevant files:**
- `tools/storyboard.html`
- `tools/test_storyboard.js`
- Spec: `.scratch/board-prose-cards/spec.md`

**Status:** ready-for-agent

- [ ] Ranges derived from the thresholds in `when` conditions; counts match the eligibility logic
- [ ] 0 = red, 1 = amber
- [ ] Cell click opens the sandbox with the matching facts
- [ ] On-device check list for the human in the report
