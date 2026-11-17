# 05 — Real image backend adapters and backend choice

**Status:** needs-info. Blocked by the agreement gate in `.scratch/art-judge_COMPLETED/spec.md`: `python tools/art_judge/judge.py agreement` must say "Gate MET" first. This is the first ticket that spends money.

**What to build:** Adapters for the 2–3 bake-off candidates behind the image backend interface: OpenAI's image edit endpoint, Gemini image, and FLUX Kontext through a hosted provider. Check exact model names and pricing at build time. Each adapter:

- reads its API key from the environment only;
- returns a cost record, from the response if the API reports cost, otherwise from a pricing table in config;
- supports multiple reference images;
- declares whether it supports masked edits.

Backend choice resolves in this order: flag, then the shot's override, then the event's override, then the configured default.

**Blocked by:** 02 — Spend ledger and caps.

**Relevant files:**
- the image backend interface and fake from ticket 01
- `tools/art_judge/backend.py` (error/retry conventions)
- `.scratch/art-autogen/spec.md` (stories 3, 20; "Image backend interface" decision)

- [ ] Each adapter is tested against recorded HTTP replies, with no network in the test suite
- [ ] A missing key gives a clear error naming the env var, never the value
- [ ] Backend resolution order is covered by tests
- [ ] Live smoke test: one generate and one edit per adapter, with the cost logged in the ledger (human, needs keys)
