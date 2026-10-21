# 04 — Gym practice fight is a real tutorial

**What to build:** Arnie's first practice fight teaches the moves. Each round the coach line tells the player which move to pick, why (based on Arnie's visible intent), and what it will do. After each beat a short line explains what actually happened (e.g. damage soaked by the guard, Arnie's cover opened by the feint, a stunned Arnie losing his action). Follow `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`; flag new prose PROSE-REVIEW.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/gym.json` (glovesOn `start_scripted_fight`, `coach.lessons`/`allowed`), `systems/combat_rounds.gd` (coach marks, beat log), `scenes/screens/combat_rounds.gd`, `scenes/components/combat_transcript.gd`, `tests/test_gym_event.gd`, `docs/writing-guide.md`; REFERENCE.md §3.7b (Open/Guarded, moves).

**Status:** ready-for-agent

- [ ] Each round's coach text names the move, the reason, and the expected effect
- [ ] After each resolved beat the player gets a clear one-line explanation of the effect
- [ ] Coach text fits on a phone-width screen without truncation
- [ ] Any new data field (e.g. per-beat explanations) is data-driven, with no prose in code
- [ ] New prose flagged PROSE-REVIEW and checked against docs/writing-guide.md
- [ ] Headless test covers the new coach/explanation lines appearing per round
