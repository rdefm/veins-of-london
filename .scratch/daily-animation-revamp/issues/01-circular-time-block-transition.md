# 01 — Circular time-block transition over the current screen

**What to build:** Each spent time block or Rest presents a small circular London park animation over the screen the player was using. The background dims while the circle rises, the sky and celestial bodies move for the destination phase, and the circle drops off the bottom. The player cannot interact until it finishes.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/daily-animation-revamp/spec.md`; `.scratch/daily-animation-revamp/references/`; `docs/REFERENCE.md` §3.1 Time, rest, daily tick; `docs/ART-BIBLE.md` §§1–4; `docs/ui-vision.md` §2; `scenes/components/time_transition.gd`; `data/daily_cycle.json`; `assets/daily_cycle/README.md`; `tests/test_time_transition.gd`; `tests/test_alarm_presentation.gd`; `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`; `CODEMAP.md`.

- [ ] At a 390 × 844 viewport, the animation is a 220 px circle with the park art actually visible and legible inside it. St Paul's, Parliament / Elizabeth Tower, and the Shard read as coloured pixel-art buildings at displayed size. Sky outside the buildings is filled; no transparent hole, magenta surround, square crop, or blank-screen replacement appears.
- [ ] The current game screen remains visible behind a dim layer. Circle and destination label rise into view, hold while the sky changes, then drop fully below the phone screen. No jump at start or end.
- [ ] Evening → Morning shows moon setting and sun rising; Morning → Afternoon shows sun starting to set; Afternoon → Evening shows sun setting and moon rising. Sun and moon have round pixel-art outlines, not square blocks. Early Rest covers remaining phase changes in order.
- [ ] Existing event/combat/result/modal/bag hold, 0.75-second outcome delay, 1.75-second presentation, input blocking (including a press held across completion), reduced-motion static destination, load/reset/Rewind queue discard, and no gameplay effects on completion remain intact.
- [ ] Headless Godot 4.7 syntax check and full test suite pass; transition tests cover visible art, phase motion, layout, queue, and input behaviour. Update canonical presentation notes and file map when implementation changes their descriptions.
- [ ] Human visual QA on a phone checks all three transitions, early Rest, reduced motion, landmark readability at 220 px, the dimmed underlying screen, and that taps never activate controls during playback.

## Comments

- User rejected a painterly large image, a flat monochrome skyline, and a broken HTML phone mockup. Use the candidate art as a starting point, not proof of final visual quality.
