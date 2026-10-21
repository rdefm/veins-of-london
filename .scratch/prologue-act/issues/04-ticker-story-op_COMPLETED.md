# 04 — Ticker story article + timed ore price rise

**What to build:** An event can post a story article to The Ticker **and** apply a real, timed rise in demand for one ore type: the Prologue ending's first sign of the squeeze (emotion calc prices). The article appears in The Ticker like other headlines/wire articles. The demand rise moves the actual market price (visible on the Ticker chart and in sale quotes) for its duration, then lapses. Article copy, magnitude and duration live in data: placeholder **+20% emotion demand for 7 days**, marked TBC for the playtest pass. The rise is pure, day-stamped state, so save and Rewind keep it. Proven with a test fixture event. Source: `.scratch/prologue-act/spec.md` "Ending (b)"; `docs/story-restructure.md` Motivation spine ("The squeeze") and Prologue Ending.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (op match ~L799+), `systems/barometer.gd` (`push_headline` ~L156, `wire_article` ~L179), `systems/market.gd` (civilian demand, daily reprice), `data/market.json`, `data/barometer.json` (wire article copy). REFERENCE §3.2 Barometer, §3.13 market. Update REFERENCE and `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Op shape documented in REFERENCE; article text in data.
- [ ] Article shows in The Ticker on the day posted.
- [ ] Emotion price rises at the next reprice and returns to normal after the duration.
- [ ] Survives save/load and Rewind.
- [ ] Tests cover posting, price effect, expiry.
