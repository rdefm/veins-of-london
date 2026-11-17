# 06 — Backend bake-off report

**Status:** needs-info. Blocked by the agreement gate (see 05).

**What to build:** A `bakeoff --backends a,b[,c]` command. It runs the frozen art-judge benchmark shots through each named backend, N takes each, and judges every take. It writes one report comparing the backends on:

- mean judge scores (brief, style, cast);
- pass rate;
- cost per passing image;
- time per image.

The runs go through the spend ledger and its caps. The report is the evidence the user uses to set the default backend in config. The run itself is a manual, recorded experiment, not an automated test. Only the report-building is tested.

**Blocked by:** 05 — Real image backend adapters.

**Relevant files:**
- `tools/art_judge/agreement.py` (`benchmark freeze` / `benchmark run`: frozen set under `.scratch/event-art/_judge/benchmark/`)
- `.scratch/art-autogen/spec.md` (stories 1, 2; "Further Notes": go to Phase 3 if no backend reaches acceptable style scores)
- `.scratch/art-style-lora/spec.md` (Phase 3)

- [ ] Report numbers are correct for a fixture of canned takes, judgements and costs across two fake backends
- [ ] The bake-off never writes live judgements, checklists or feedback (same isolation as `benchmark run`)
- [ ] The user runs it on 2–3 real backends and sets the default (human)
