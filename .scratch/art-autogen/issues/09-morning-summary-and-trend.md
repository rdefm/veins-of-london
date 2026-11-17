# 09 — Morning summary and score trend

**Status:** ready-for-agent

**What to build:** Each run ends with a short summary: shots attempted, passed, needing you (by event and shot), takes made, retries, and spend for the run and month to date. It is printed and saved with the run log, so an overnight run's summary can be read in the morning. A `trend` command prints average judge scores (brief, style, cast) and pass rate per run, oldest first, so the user can see whether the art is getting better. Output is CLI only, with no storyboard tool view.

**Blocked by:** 04 — Whole-queue run, filters, resume.

**Relevant files:**
- the run log and ledger from tickets 01–02
- `tools/art_judge/agreement.py` (`format_report`, the house style for compact CLI reports)
- `.scratch/art-autogen/spec.md` (stories 14, 15, 24)

- [ ] The summary numbers match a fixture run (passes, needs-you shots, retries, spend)
- [ ] `trend` over three fixture runs prints one line per run with correct averages
- [ ] An interrupted run's summary says it was interrupted and why (cap stop or crash)
