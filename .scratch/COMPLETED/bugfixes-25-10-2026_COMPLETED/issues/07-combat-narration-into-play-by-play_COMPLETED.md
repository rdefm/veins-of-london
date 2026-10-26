# 07 — Combat: no text above the scene; narration goes in a bigger play-by-play

**What to build:** In the combat view, no text appears above the visual box with the sprites and background. Scripted and narration text that shows there today (the refusal / lock-prompt / coach line and anything similar) goes into the play-by-play box below the scene and above the buttons. That box gets bigger, so narration and beats are easier to read.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat_rounds.gd` (heading row and refusal/prompt/coach label, coachNote handling), `scenes/components/combat_transcript.gd`, `systems/combat_rounds.gd` (lock_prompt, coach_lesson — read only), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Nothing renders above the stage box in any fight, scripted fights included
- [ ] Refusal, lock-prompt and coach lines appear in the play-by-play box
- [ ] The play-by-play box is visibly taller than before
- [ ] Rewind still removes and replays transcript lines correctly

On-device check: the gym tutorial fight and one ordinary fight. No text sits above the stage, and coach and prompt lines show in the play-by-play.
