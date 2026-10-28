# 01 — Combat intro: stage, fighters, HUD reveal

**What to build:** Every fight opens with the same short intro between Fight being tapped and the first move — no per-context variants, no title card naming the fight type. Sequence (timings are defaults, all data-driven):

1. **Stage up (~300ms):** HUD hidden (no strip, transcript or dock). Backdrop fades up with a slight zoom-out (105% → 100%), a "camera settles" feel.
2. **Fighters enter (~500ms):** player + allies slide in from off-screen left, enemies from off-screen right, simultaneously. Each fighter staggered ~60ms behind the one before (front slot first) so they arrive as a group. Land in idle pose with a small dust puff and a 1-frame squash. Reserves and the `+N` badge fade in after the last fighter lands.
3. **(Ticket 02 slots the card deal-in here.)**
4. **Transcript + dock (~250ms):** transcript fades in with the fight's opening lines; command dock rises from the bottom.
5. **Opening beats:** if enemies act first, their turns play now via normal beat playback; commands stay locked until the player's turn.
6. **First move:** dock unlocks.

Rules:
- Tap anywhere during the intro skips to the end of step 4.
- Quick pacing halves every intro timing.
- All timings/offsets/stagger/zoom live in combat visuals data under a new `intro` key.
- A Rewind that restores the opening frame lands straight on the post-intro state — the intro never replays.
- Demo/tutorial fight gets the same intro; its voiceover starts after step 4.
- Pure presentation: no state or rules change; the screen reads state only.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`_play_opening()` ~l.933, opening/Rewind replay ~l.65, ~l.501–524)
- `scenes/components/combat_stage.gd` (slot placement, reserves, juice)
- `scenes/components/combat_director.gd` (beat playback, `playing_changed` lock)
- `scenes/components/combat_transcript.gd`, `scenes/components/combat_command_dock.gd`
- `systems/combat_pacing.gd` (normal/quick toggle)
- `data/combat_visuals.json` (new `intro` key; update `GameData` load/validation if keys are validated)
- `systems/combat_rounds.gd` `opening_beats()` (~l.428) — read only
- `docs/combat-animation-vision.md` §4.1 The juice layer, §8 Architecture — the beat queue; REFERENCE.md §3.7b
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Every combat context (raid, defend, home raid, mugging, Archie's deal, spar, demo) plays the same intro; no fight-type label shown
- [ ] HUD hidden until fighters land; allies enter from left, enemies from right, staggered front-first, with dust puff + squash
- [ ] Transcript then dock reveal after fighters; enemy-first opening beats play only after the reveal, commands locked until player's turn
- [ ] Tap skips to the post-reveal state; quick pacing halves timings
- [ ] Rewind to the opening frame does not replay the intro
- [ ] Demo voiceover starts after the reveal
- [ ] Timings read from `combat_visuals.json` `intro`; no magic numbers in code
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: intro feel/timing, skip works, quick pacing, Rewind to start
