# 02 — Spend ledger and caps

**Status:** ready-for-agent

**What to build:** Every image-backend call's cost goes into one global spend ledger, covering all runs and events. A configured per-run cap and per-month cap are checked **before** every call. A call that would exceed either cap is not made: the run stops cleanly, records why in the run log, and keeps everything made so far.

Before a manual run starts, the CLI prints an estimate and asks to continue (`--yes` skips this, like the judge's call-count confirm). After every run it prints the run's total and the month-to-date total.

**Blocked by:** 01 — Generate and judge N takes for one shot.

**Relevant files:**
- `tools/art_judge/judge.py` (`make_confirm`, `resolve_threshold` for the confirm and config patterns)
- `.scratch/event-art/_judge/config.json` (config precedent; autogen config sits beside it)
- `.scratch/art-autogen/spec.md` (stories 13, 14; "Spend ledger" decision)

- [ ] Canned costs exactly at the cap: the call is allowed. One cost unit over: refused and the run stops
- [ ] The per-month cap holds across separate runs in the same month and resets in a new month
- [ ] An estimate is shown and confirmed before a manual run; `--yes` skips it
- [ ] Run total and month-to-date total are printed after the run and recorded in the run log
- [ ] A cap stop leaves earlier takes, judgements and log entries intact
