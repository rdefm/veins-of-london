# 12 — Distilling: slower pace + hit/miss feedback

**What to build:** Distilling feels punishing: too fast, unclear where and when to tap, and unclear whether a tap worked. Make the timing readable: slower motion and/or a wider or clearer target band, a visible cue for when to tap, and immediate per-tap hit/miss feedback (flash, sound hook, text). Builds on ticket 11's highlight and tick.

**First step (HITL):** propose the new speed, band and feedback design (with numbers) in this ticket, then wait for the human's approval before implementing. Tuning goes in `data/lab.json`. Scoring rules stay unchanged unless approved.

**Blocked by:** 11 — Lab apparatus: clear tap target, finish tick, input guard.

**Relevant files:** `scenes/components/lab_gauges.gd` (distil gauge), `data/lab.json`, `systems/lab.gd`, `scenes/screens/hq_lab_bench.gd`

**Status:** ready-for-agent

## Proposal (approved)

Current (`data/lab.json` gauges.distilling): 4 drips, beat 1400ms, fall 1000ms, lead-in 1400ms. Tap reads drip position 0–100; stray tap (between drips / 2nd on same drip / after last) spoils step. No per-tap feedback beyond "taps N".

**Pace** (scoring untouched, read = drip position as now):
- `fallMsec` 1000 → **1800** (position moves 0.056/ms → 0.033/ms; ~1.8x easier to land a given %)
- `beatMsec` 1400 → **2400** (600ms gap between drips; stray window shrinks vs fall, gap now clear "rest")
- `leadInMsec` 1400 → **2000** (time to read the screen)
- Total run: 2.0 + 3×2.4 + 1.8 = 11.0s (was ~6.6s)

**Cue** (gauge only, no scoring change):
- Drip leaves a faint trail behind it; falling drip drawn larger.
- Track gets a "tap now" state: while a drip is falling and not yet tapped, the track edge pulses (reuses ticket 11 `pulseMsec`/alpha); once tapped or between drips it goes dim.
- Pip row under track: current drip pip ringed; tapped drips filled gold, missed drips crossed.
- Lead-in shows "Ready…" text, then "Drip 1/4".

**Per-tap feedback** (new `feedback` keys: `tapFlashMsec` 350):
- Valid tap: gold ring flash at the tap position + floating text "Caught 62" (the reading); pip fills gold. (Doesn't reveal target — just the reading, matching what hint notes talk about.)
- Stray tap (between drips / double tap): red flash across track + text "Stray!"; counter shows it (matches the spoil rule so player knows why).
- Drip fell untapped: pip crossed, text "Missed" at track end.
- Sound hook: `EventBus`-free; gauge emits `tap_result(kind: String, reading: float)` signal (kinds `caught`/`stray`/`missed`) so audio can attach later; no audio asset now.

**Not changing:** scoring, tolerance, drip count, stray rule.

**Question for human:** OK with these numbers (fall 1800 / beat 2400 / lead-in 2000), and the reading shown in "Caught N" text? Or want it slower/faster, or no number shown?

- [x] Proposal approved (recorded here)
- [x] Distil gauge uses the approved pace/band from data
- [x] Each tap shows hit or miss immediately
- [x] Lab tests still pass; any scoring change tested
