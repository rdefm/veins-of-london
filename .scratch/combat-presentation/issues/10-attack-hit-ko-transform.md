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

**Status:** in-progress — plumbing/transform system landed for the whole
roster, real art landed for the 2 subjects that already had idle art
(ticket 09); the rest is still blocked on the same "no image-generation
tool in-session" gap ticket 09 hit. See Comments below.

- [ ] Every subject with idle art (ticket 09) gets attack (3 keypose),
      hit (1 pose), and KO (2 pose) sheets; Archie additionally gets a
      self-patch pose — **partial**: territorialScrapper/orichalchumDealer
      (the only 2 of 7 with idle art today) both got real attack/hit/ko
      sheets this ticket; Archie still has no idle art (ticket 09's own
      "still blocked" list), so there's no idle sheet to edit a self-patch
      pose off of yet, per ticket 07's "never re-prompt a character" rule
- [x] Attack beats play wind-up → strike → recover via transform lunge/
      return, not a new hand-drawn motion frame set
- [x] Hit beats play the recoil transform + reuse ticket 05's white-flash
      juice effect (not a second flash implementation)
- [x] KO beats play the fall+fade transform when a combatant's `koed` flag
      flips true
- [ ] Ability-tell beats (ticket 06) render the held pose with a pulse,
      replacing that ticket's text/glyph placeholder — the pulse/pose
      rendering path is built and tested, but no enemy in data/enemies.json
      declares a non-null `ability` yet (a pre-existing content gap ticket
      06 itself flagged) and no tell art has been produced for any subject,
      so in an actual playthrough the telegraph slot still always falls
      back to ticket 06's text label today
- [ ] `prophetsBreath`'s ghost-next-pose effect (§5) renders once this
      art exists — confirm it was genuinely deferred (not silently dropped)
      from ticket 06 — genuinely-deferred-not-dropped is confirmed (ticket
      06's own last acceptance check says so explicitly), and a ghost effect
      is implemented and renders in real play, but per an ultrareview finding
      it's an approximation of §5's own wording rather than a clean match:
      it fires simultaneously with the swing (`ghost_next_pose()` and
      `play_attack()` are deliberately un-sequenced in the same beat), not
      strictly "before it happens"; and it triggers on any
      `BEAT_PLAYER_EVADE` beat, which `combat["evadeTurns"]`/`evadeChance`
      being shared state (systems/combat.gd's own `use_prophets_breath()`
      comment) means Rewind's evade grant fires it too, not prophetsBreath
      exclusively — in tension with §5's "no two alike" framing and
      Rewind's own distinct listed effect ("the whole stage plays
      backward"). Separating the two would need a new state field this
      ticket didn't add; left as a known limitation rather than fixed
- [ ] A full round against a 3-enemy squad plays keyposes + transforms for
      every beat without art popping/snapping between poses — mechanically
      exercised by tests/test_combat_screen.gd, but this is a visual claim
      only a human can actually confirm on-device (see Comments)

## Comments

Plumbing landed (commit `combat-presentation-10: attack/hit/ko transform
keyposes, ability-tell pulse, prophetsBreath ghost pose`): `StageSlot`
(scenes/screens/combat.gd) replaced the old flipbook-style attack/hurt/dead
one-shots (a rougher pre-ticket-09 stand-in, see git history) with real
keypose+transform playback — `play_attack()` shows wind-up/strike/recover
across a lunge-and-return `_sprite_rect` position tween, `play_hit()` shows
its one pose across a recoil-out/recoil-back pair (flash_hit() unchanged,
still called from `_play_juice()`), `play_ko()` shows its two poses across a
fall (sink + rotate) + fade and holds there. Both driven by the same
Timer-stepped `_one_shot_steps` mechanism ticket 09's idle loop already
established (off-tree testable via `_advance_one_shot()`, no live SceneTree
tween needed for tests). `play_self_patch()` (Archie's heal pose) reuses the
same one-shot machinery. `data/combat_visuals.json`'s `templates.<key>` gained
`attack`/`hit`/`ko` entries per subject (falling back to the shared
`templates.default` stand-in when a subject's own is empty, same as the old
arrangement did for everyone) plus `selfPatch` (Archie only) and a documented
`tell` slot (no fallback — see the manifest's own `actionRule` note). Any
sheet with more frames than the doctrine calls for (`templates.default`'s own
leftover multi-frame dummy strips) is down-sampled to exactly 3/1/2 keyposes
by `CombatScreen._select_action_keyposes()`.

`territorialScrapper` and `orichalchumDealer` — the only 2 of 7 cast subjects
with real idle art (ticket 09's own status) — got real attack/hit/ko sheets
too: `assets/Gangsters_2/{Attack_1,Hurt,Dead}.png` and
`assets/Gangsters_3/{Attack,Hurt,Dead}.png`, copied verbatim (asset-pack
sourced, not palette-quantised — same temporary-stand-in convention ticket
09's idle wiring used) into `assets/combat/{territorial_scrapper,
orichalchum_dealer}/{attack,hit,ko}.png` and wired into the manifest with
**no code change beyond what ticket 10 needed anyway**. `.import` files were
generated via `godot --headless --editor --import` (not committed, same as
ticket 09).

Ticket 06's telegraph slot now supports a real pose+pulse
(`TurnOrderStrip.NameplateCard.tell_image`/`tell_rect`) whenever
`templates.<key>.tell` has an image — but no subject has one yet, and no
enemy in `data/enemies.json` declares a non-null `ability` at all today (a
pre-existing content gap, not something this ticket introduces), so this
path is exercised only by tests that inject a fake manifest entry; a real
playthrough still always sees ticket 06's text label. prophetsBreath's
ghost-next-pose effect (§5) is wired to `Combat.BEAT_PLAYER_EVADE`
(the beat kind the evadeTurns/evadeChance grant prophetsBreath and Rewind
share produces) and renders against whatever attack keyposes the evading
enemy's own template resolves to (real art for territorialScrapper/
orichalchumDealer, the default stand-in otherwise) — so this one **is**
visible in an actual playthrough today, not just in tests.

**Still blocked:** player, archie, veinGuard, homeRaidRaider, and mugger
still have no attack/hit/ko art of their own (falling back to the shared
`default` stand-in) because none of them has idle art yet either (ticket 09's
own "still blocked" list, unchanged by this ticket) — no image-generation
tool was available in-session for these, same gap ticket 09 hit. Archie's
selfPatch and every subject's `tell` pose are additionally blocked on that
same gap even once idle/attack art exists, since neither has an asset-pack
equivalent to source verbatim the way idle/attack/hit/ko did. The "full round
against a 3-enemy squad reads clean, no popping" acceptance check is a visual
claim the agent cannot verify without eyes on a running client — flagging for
human on-device QA per this repo's own workflow rule (CLAUDE.md step 5), not
checking it off. Re-open/continue this ticket once real (or further
asset-pack-sourced) art exists for the remaining subjects, or once a human
has confirmed the transform playback reads cleanly on-device.

**Code review (Standards + Spec, both axes, against HEAD before this
ticket):** Standards found no hard violations of CLAUDE.md's rules; a few
judgement-call smells were raised and one was fixed --
`CombatScreen._sync_band()`'s four near-identical
resolve-then-`set_*_animation()` blocks (attack/hit/ko/selfPatch) are now one
loop over the four. Spec found no scope creep and no undisclosed gaps against
the ticket's own checklist, but flagged the `prophetsBreath` ghost item
(above) as checked off without matching §5 closely enough -- downgraded to
unchecked with the specific mismatch spelled out, rather than fixed in code
(fixing it properly needs new state to distinguish prophetsBreath's grant
from Rewind's, which is a change to a previous ticket's design, not this
one's).

**PROSE-REVIEW:** none — this ticket added no new player-facing prose, only
render-order/asset-manifest fields and code comments.

**Follow-up (human bug report, same session):** the human flagged a
coloured box sitting on top of/instead of the front combatants' art, and
separately confirmed a standing decision this doc didn't previously
record: `default`'s Gangsters_2-sourced art (already the shared stand-in
for attack/hit/ko, per the pre-ticket-09 "swap dummy placeholder to
Gangsters_2 sprites" commit) should be the placeholder for **every**
subject/animation, idle included — not just attack/hit/ko. Two fixes
landed:

1. `af9138f` — attack/hit's keypose count dropped from the old flipbook's
   6/4 frames to 3/2, but kept the same fps, roughly halving the on-screen
   time per one-shot. Slowed the fps (attack/hit 5.0, ko 3.0) to restore
   the old total duration.
2. `67a78bc` — idle never had a `default` fallback (deliberate ticket-09
   scope: real art or the ticket-01 box, nothing shared). Extended it to
   use the exact same `_resolve_action_keyposes()` fallback attack/hit/ko
   already had, sourced from `templates.default.idle` (no new art). The
   ticket-01 placeholder box is now a defensive-only fallback (a broken/
   missing `default` entry) — not expected to trigger in normal play.

Verified against a real running build (screenshots via a windowed
headless-adjacent Godot run, not just unit tests) before and after each
fix — see those commits' own messages.
