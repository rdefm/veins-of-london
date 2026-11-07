# 02 — Card references survive renumbering

**What to build:** Promote lays cards out in a new order when branches change, which shifts their indexes. Integer references, such as `resumeCard` in fight scripts, then point at the wrong card and need manual fixing (precedent: commit `7359680e`, "fix gym resumeCard indexes"). After this ticket, an edit that renumbers cards leaves those events playing correctly with no hand repair.

Make every in-event card reference survive a reorder. `resumeCard` can name a card key, Promote keeps it correct, and live events using integers are migrated. First confirm what's actually broken: reproduce a renumbering edit on an event with a scripted fight, then inventory every other integer card reference in event data. Old saves paused mid-event must still resume.

**Blocked by:** 01 — Import → Promote round trip is lossless

**Relevant files:** `systems/combat.gd` (`resumeCard`, `script_resume`, `_exit_scripted`), `systems/events.gd` (`resume_at`, `current_card_key`), `tools/storyboard.html` (`promoteDraft`, fight editor), `data/events/prologue_gym.json`, `data/events/prologue_cold_open.json`, `tests/test_prologue_chain.gd`, `autoload/SaveManager.gd`; REFERENCE §3.9a Event choice checks, `docs/adr/` as needed

**Status:** ready-for-agent

- [ ] Repro recorded in the ticket's `## Comments`
- [ ] A scripted or demo fight resumes on the intended card after inserting a card before it and promoting
- [ ] Every integer card reference found is keyed or rewritten by Promote
- [ ] Live events are migrated and existing fight tests pass
- [ ] Save made mid-event before this change still resumes correctly
- [ ] REFERENCE documents the keyed form

## Comments

- Repro: prologue_cold_open's scripted-fight `resumeCard` was int 17; its target card is key `c10` (Promote reorders cards, so integers drift; cf. 7359680e). Inventory of integer card refs in `data/`: `goto` / conditional `card` (Promote already recomputes them; key form also supported) and `resumeCard` ×4 (cold_open_legacy, prologue_cold_open, prologue_gym ×2) — the only unmanaged ones. `start_fight` win/lose already keys.
- Fix: `resumeCard` accepts a card key (resolved to an index when the op fires; unknown = push_error, no fight); live events migrated to keys; storyboard import rewrites an integer `resumeCard` to the card key. Mid-fight saves hold the resolved int in `combat.script`, so they resume as before. REFERENCE §3.7b documents it.
- Tests: `test_scripted_fight` inserts a card before the target and checks resolution; sweep asserts every live `resumeCard` is a real card key.
