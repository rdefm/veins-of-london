# 04 — Slice A: hints and knowledge display

**What to build:** Each recipe's hidden improvements are authored as hints, e.g. an extra step, a higher or lower target, or a longer hold. The debug hint toggles from 01 grant each one as vague or exact. The procedure view reflects what the player knows:
- exact step: the true band is shown
- vague step: a wide fuzzy region that contains the band, plus a direction word ("a bit hotter")
- unknown ideal step: not shown at all, and it scores 0 because it's missing

All hints plus good execution make rank 5 reachable. See spec §Slice A "Knowledge display" and the recipes table.

**Blocked by:** 03 — Slice A: grind, compress and distil gauges.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice A, §Recipes in the prototype; bench prototype data/system/screen/tests from 01–03; `docs/CONTENT-GUIDE.md` (direction words).

**Status:** ready-for-agent

- [ ] Every hint in the spec's recipes table is authored in data, each with vague and exact forms.
- [ ] Toggling a hint to vague or exact changes the known procedure and the band display. Off hides the step.
- [ ] Tests: base-only perfect run ≤ rank 3; all-hints perfect run reaches rank 5; the vague region always contains the true band.
- [ ] New UI strings flagged `PROSE-REVIEW:`.
