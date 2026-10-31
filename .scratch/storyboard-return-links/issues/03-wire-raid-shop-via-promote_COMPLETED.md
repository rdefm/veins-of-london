# 03 — Wire raid_shop via promote

**What to build:** the user's storyboard edits to raid_shop go live through `promote`, and the live file is a promote output again (no more hand-maintenance).

Already in the draft (`.scratch/writing-revamp/raid-shop-proposal.md`), not yet live:

- The user's prose and observation edits from the storyboard tool.
- Explicit `observe` on every card after `s_cellar` (observations are sticky by live card index, so cards 18–52 all showed the cellar read). Agreed mapping: `s_seen_till`, `s_cam`, `s_cam2`, `s_win_cam` → `till`; `s_seen_flap` → `flap`; `s_seen_yard` → `yard`; `s_seen_door` → `door`; `s_seen_in`, `post`, `post2`, `post3`, `s_back_loud`, `s_back_in` → `stock`; `s_stairs_in`, `s_ward`, `s_ward2`, `s_ward3` → `lock`; `s_room`, `s_claim_route`, `s_final`, `s_claim`, `s_claim_a`, `s_getaway`, `s_retreat` → `cellar`; `s_win_out`, `s_win_out2`, `s_win_in`, `s_win_in2`, `s_win_wit`, `s_alarm`, `s_alarm2`, `s_reinf`, `s_resume`, `s_resume2`, `s_out` → `null`.
- `s_resume2`'s `sAt_back` entry goes to `s_back` (the stockroom choice), not `s_back_in`: after beating the stockroom guards at `post`, resuming no longer lands on `post` again (security doesn't drop after a win). Accepted tradeoff: a fight earlier in the stockroom with `sAt_back` set also skips `post` afterwards.

Still to do here:

- "Prophet's Breath: slip past" on `s_room`: add `hideUnless: {security: {feature: guards, atLeast: 1}}` (ticket 01), keeping the item gate greyed (`display: disable`).
- `s_resume2`'s `sAt_stairs` entry targets `s_stairs_in`, a tension card; a return link must target a choice card (ticket 02). Retarget it — ask the user which card if no choice card is the obvious equivalent.
- Fix any other content refusals promote raises, in the proposal, never in the live file.
- `git diff data/events/raid_shop.json` against the hand-maintained live file: differences should be only the draft's edits plus layout/index churn; check every `image` path still exists.

Known open prose issue (user's call, not this ticket): `s_room` text says "the guards now looking at you" even at 0 guards.

**Blocked by:** 01 — Option `requires.hideUnless`; 02 — Promote accepts "return" links

**Relevant files:**
- `.scratch/writing-revamp/raid-shop-proposal.md`
- `data/events/raid_shop.json`
- `tests/test_raid_shop.gd`, `tests/test_event_content_lint.gd`, `tools/test_storyboard.js`
- `systems/observation.gd` (`in_effect()` — sticky observe by card index)
- `.claude/skills/implement-storyboard-event/SKILL.md`
- `docs/REFERENCE.md` §3.9a, §3.9d, §3.12 "Security profile"

**Status:** ready-for-agent

- [ ] `node tools/promote_storyboard.js promote .scratch/writing-revamp/raid-shop-proposal.md` writes `data/events/raid_shop.json` with no refusal
- [ ] Every card's in-effect observation matches the mapping above
- [ ] After winning at `post` and resuming, play continues at `s_back`, not `post`
- [ ] `s_room` with 0 guards shows only "Walk to the vein" (+ getaway options); with guards it shows Fight / Bluff / Prophet's Breath (greyed without the item)
- [ ] Storyboard JS tests, content lint and `test_raid_shop.gd` pass
- [ ] Report lists on-device checks for the user
