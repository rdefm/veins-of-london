# 10 — Attack/hit/KO keyposes + transform motion

**What to build:** Per §4, the rest of the animation doctrine on top of
ticket 09's idle loops — three keyposes plus transform, not hand-animated
motion:

| Beat | Frames | Motion source |
|---|---|---|
| Attack | 3 keyposes (wind-up / strike / recover) | **transform** lunge and return between poses |
| Hit | 1 pose | transform recoil + white flash (ticket 05's juice-layer flash, reused not reinvented) |
| KO | 2 poses | transform fall + fade |
| Ability tell | 1 pose, held | pulse — this is ticket 06's telegraph slot getting its real art instead of the text/glyph placeholder |

Driven by the beat-queue director from ticket 04: each `beats` entry's
`kind` selects which keypose sequence plays and the transform tween that
connects them (lunge-to-target-and-back for attack, recoil for hit,
fall-and-fade for KO). This is where `prophetsBreath`'s deferred visual
(§5: "the enemy's *next* pose ghosts in at ~30% alpha before it happens")
finally lands, now that real poses exist to ghost.

**Blocked by:** 04 (beat queue drives the transform timing), 09 (idle
sheets establish the manifest/pipeline pattern this reuses)

**Assets needed:** the remainder of the ~70-frame total budget (§3: "≈9–10
frames per subject × 7 subjects") — per subject: 3 attack keyposes, 1 hit
pose, 2 KO poses, plus Archie's self-patch pose
(`_allies_act`/`_ally_turn`'s heal-below-40%-HP action). Generated as
edits/strips off each subject's existing canonical idle image per ticket
07's "never re-prompt a character" rule, run through `tools/pixelize.py`.

**Status:** ready-for-agent

- [ ] Every subject with idle art (ticket 09) gets attack (3 keypose),
      hit (1 pose), and KO (2 pose) sheets; Archie additionally gets a
      self-patch pose
- [ ] Attack beats play wind-up → strike → recover via transform lunge/
      return, not a new hand-drawn motion frame set
- [ ] Hit beats play the recoil transform + reuse ticket 05's white-flash
      juice effect (not a second flash implementation)
- [ ] KO beats play the fall+fade transform when a combatant's `koed` flag
      flips true
- [ ] Ability-tell beats (ticket 06) render the held pose with a pulse,
      replacing that ticket's text/glyph placeholder
- [ ] `prophetsBreath`'s ghost-next-pose effect (§5) renders once this
      art exists — confirm it was genuinely deferred (not silently dropped)
      from ticket 06
- [ ] A full round against a 3-enemy squad plays keyposes + transforms for
      every beat without art popping/snapping between poses
