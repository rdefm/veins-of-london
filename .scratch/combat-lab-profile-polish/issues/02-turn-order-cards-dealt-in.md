# 02 — Turn-order cards dealt in

**What to build:** During the combat intro, after the fighters land and before the transcript/dock reveal (~400ms), the turn-order strip's cards are dealt in one by one, left to right, flying from a "deck" point at top-centre, with a soft flick sound per card. The first card (whoever acts first) lands already expanded/focused. When control reaches the player for their first move, the player's card pulses once.

- Tap-skip and quick pacing behave as in ticket 01 (skip lands all cards in place; quick halves timings).
- Rewind to the opening frame does not replay the deal.
- Timings and deck point in `combat_visuals.json` `intro`.

**Blocked by:** 01 — Combat intro: stage, fighters, HUD reveal

**Relevant files:**
- `scenes/components/turn_order_strip.gd` (cards, focus/expand, `advance_to()`)
- `scenes/screens/combat_rounds.gd` (intro sequence from 01)
- `data/combat_visuals.json` (`intro` key)
- Audio: check existing combat SFX loading for where a flick sound plugs in
- `docs/combat-animation-vision.md` §2.4 Turn-order strip
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Cards fly in one at a time, left to right, from the deck point, each with a flick sound
- [ ] First actor's card lands expanded/focused
- [ ] Player's card pulses once when the first move is handed over
- [ ] Skip and quick pacing respected; Rewind to opening skips the deal
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: deal timing/feel, sound, focus on first card, pulse
