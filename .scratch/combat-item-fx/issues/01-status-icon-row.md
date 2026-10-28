# 01 — Status icon row above sprites

**What to build:** Each fighter on the combat stage shows its running statuses as small pixel icons in a row above its head, replacing the amber on-stage text badges. Strip cards and the transcript keep their text unchanged. Icons are mocked up (code-drawn) for now, and each one can be swapped for custom pixel art later by setting an image path in data, with no code change.

Design: `.scratch/combat-item-fx/proposal.md` §4 (grammar §4.2, animation §4.3, roster table §4.4, data shape §4.5, Stunned = option A buffering spinner §4.6).

- A new system query returns each fighter's statuses as pure data `[{ id, count }]` (the existing text `status_badges()` stays for the strip). Roster: stunned (lost actions, not frozen), feinted (Guard will fail), feint bonus, powdered, sight (player), lady, panic, rapture, anger hot, anger cold, fury, disarmed, leg-it boost. Frozen keeps the existing ⏸N icon; Shield keeps its shimmer; Failsafe has no icon (hidden until it fires). Open-hold from Stun L5 adds a count to the existing Open guard marker.
- Icons are 9×9 on an 11×11 chip: rounded light-rim chips for buffs, notched dark-rim chips for debuffs. Colour comes from the cause's ore family, and statuses with no item behind them (Stunned, Feinted) are neutral white. A pixel-font count digit sits bottom-right where there's a count.
- Fixed order: removal → control → damage mods → buffs. Max 3 shown, then a `+N` chip. The ⏸N icon keeps its own slot above the row.
- Stunned icon is an animated 8-dot buffering spinner (one lit dot chasing).
- Animations: apply = pop 0→120%→100% with a 1-frame white chip flash; tick = digit flick; expire = shrink to a dot and blink out (a buff adds a 2-px sparkle). A Rewind restore sets icons directly with no animation.
- Hold-to-peek lists each status with full text and remaining count.
- `combat_visuals.json` gets a `statusIcons` block per id: `{ image, chip, colour }`. When `image` is empty, the mock glyph is drawn.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/combat_rounds.gd` (`status_badges()`, `stage_marks()`, `guard_marker()`, combatant fields `actionsLost`, `frozenActions`, `openActions`, `guardFailed`, `powderUntil`, `ladyUntil`, `sightUntil`, `fleeBoost`, `panicActions`, `raptureActions`, `angerActions`, `fury`, `disarmed`; `fighter_peek()`)
- `scenes/components/combat_stage.gd` (`StageSlot.set_status_badges()`, `_draw_status_badges()`, `_draw_pause_icon()`, guard marker drawing)
- `scenes/screens/combat_rounds.gd` (`_apply_marks()`)
- `data/combat_visuals.json`, `data/combat_rounds.json` (`statusBadges` labels)
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b (Moves, Removal, Items, Move-level effects, Table 4)

**Status:** ready-for-agent

- [ ] The system query returns the right `{id, count}` list for every status in the roster (tests per status)
- [ ] The stage draws icons above sprites; on-stage text badges are gone; strip text is unchanged
- [ ] Buff/debuff chip shapes, ore colours, count digits, max 3 + `+N`, fixed order
- [ ] Animated buffering spinner for Stunned
- [ ] Pop/tick/expire animations; Rewind restore sets icons with no animation; KO clears them instantly
- [ ] `statusIcons` image path overrides the mock when set
- [ ] Peek lists statuses in full text
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: icons readable at phone size, correct statuses on Panic/Anger/Stun/Disarm/Powder/Lady/Sight fights
