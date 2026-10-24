# 02 — Arnie vs Archie demo first, with a Continue tap per beat

**What to build:** The gym event plays the Arnie-vs-Archie demo before the player's own practice fight, so the player sees how a fight works before trying one. While the demo runs, Arnie's voiceover line for the current beat sits where the combat buttons normally are, with a Continue button under it. Combat only moves to the next beat when the player taps Continue. There's no auto-advance and no skip, so the player can read what Arnie says and then watch him do it. Re-order the existing intro and post-demo cards so the story still reads in order. Follow `docs/writing-guide.md`, and flag any new or changed prose with PROSE-REVIEW.

**Blocked by:** 01 — Practice fight: sprites shrink while Arnie's coach text shows (same screen).

**Relevant files:** `data/events/gym.json` (watch → `start_demo_fight`, glovesOn → `start_scripted_fight`, card order), `systems/combat.gd` (`start_demo_fight`), `systems/combat_rounds.gd` (demo rounds, voiceover lines), `scenes/screens/combat_rounds.gd` (command area, Readouts), `scenes/components/combat_transcript.gd`, `tests/test_gym_event.gd`, `docs/writing-guide.md`; REFERENCE.md §3.7b Open/Guarded round combat (Move levels).

**Status:** ready-for-agent

- [ ] Gym event order: demo before the player's practice fight
- [ ] During the demo the command buttons are replaced by Arnie's voiceover box and a Continue button
- [ ] Each demo beat resolves only after Continue; nothing auto-advances
- [ ] The screen calls system functions only and never mutates state directly
- [ ] Changed prose flagged PROSE-REVIEW
- [ ] Headless test: the demo does not advance without the continue call; one beat per continue; the practice fight follows the demo
