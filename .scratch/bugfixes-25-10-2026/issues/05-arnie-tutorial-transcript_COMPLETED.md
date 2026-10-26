# 05 — Arnie tutorial transcript

**What to build:** A readable transcript of the whole Arnie (gym) tutorial so the human can rewrite its prose. Write it as a markdown file in `.scratch/writing-revamp/arnie-tutorial-transcript.md`. It should include every card's text, speaker lines and choice labels across every branch, laid out in play order with branches clearly marked, plus the gym fight's scripted lines (intro, coach notes/hints, any scripted beat text) placed where they occur. Pull it from the live data, not from the old proposal. No code or data changes.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/gym.json`, `data/combat_rounds.json` (gym fight intro, coach lessons/hints), `.scratch/writing-revamp/gym-proposal.md` (older draft, for reference only), `docs/writing-guide.md`.

**Status:** ready-for-agent

- [ ] The md file exists at the path above
- [ ] Every card, speaker line and choice in gym.json appears, with branches marked
- [ ] The tutorial fight's scripted text appears in sequence
- [ ] Each section notes its source card/field id so rewrites can be mapped back
