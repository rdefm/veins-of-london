# 02 — London time transitions

**What to build:** Every successful time-consuming action visibly advances London time after its outcome is communicated.

**Blocked by:** 01 — Readable day clock.

**Status:** ready-for-human

- [x] Capture source and destination at the authoritative time boundary; queue presentation until event choices, combat and acknowledged results have finished. Cover every existing time-consuming action.
- [ ] One paid action produces exactly one non-skippable 1–2 second interstitial; free/blocked actions produce none. Early Rest produces one transition through night to the next morning.
- [x] Use one authored pixel-art day-cycle animation asset: a single London park panorama with distant landmarks, horizon, sky, sun/moon and changing shadows. Do not require separate phase backgrounds or runtime-composited art layers.
- [ ] Address the asset as source-to-destination frame ranges from one continuous cycle. Morning→Afternoon shortens shadows, Afternoon→Evening lengthens them, and Evening→Morning shows moon passage and sunrise; Early Rest plays from the current phase through night to the next morning within the same duration.
- [x] Keep destination phase/day text, timing and interaction blocking outside the artwork. Day numbers are never baked into frames, and the animation never owns gameplay effects.
- [x] Prepare the animation for the 390px portrait baseline as a mobile-safe sprite atlas rather than a very wide strip; preserve the project's crisp pixel-art import/render rules. Record final frame count, atlas grid and displayed panorama bounds with the delivered asset.
- [x] Display explicit destination phase/day; reduced motion uses a gentle/static presentation for the same duration.
- [x] Block all tap-through and dismissal for the full duration. Pause/reload recovery cannot strand input or replay gameplay effects.
- [x] Preserve daily-tick ordering and automatic rollover; animation completion never charges time, determines rewards or runs ticks.
- [ ] Headless tests verify once-only time/effects, outcome-before-overlay ordering and input blocking. Device QA verifies timing, motion, reduced motion and all phase/Rest paths.
- [ ] ART-REVIEW: confirm the chosen park/view, landmark readability, phase lighting, shadow motion, atlas playback and portrait crop on-device.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

## Implementation — 2026-09-13

User supplied two clips and explicitly deferred the final animation. Packed the 28 supplied frames into one 7×4 atlas. Source capture is shared by every current paid action via TimeSystem; presentation waits outside systems. Non-skippable 1.75s overlay; reduced motion in Phone Profile; state replacement drops transient playback. No daily-tick order or gameplay effects changed.

Overnight/Rest currently show static Morning with destination day. Add `evening_to_morning.zip` and run `python tools/pack_daily_cycle.py` to enable the final range and multi-range Early Rest automatically. See `assets/daily_cycle/README.md` for frame dimensions, display bounds and handoff.

PROSE-REVIEW: `data/daily_cycle.json` (destination label and Reduced motion).
ART-REVIEW/device QA: all phase paths and Rest from each phase; outcome before overlay; 1.75s blocking including held taps/back; suspend/resume and reload; Reduced motion persistence; London landmarks, lighting/shadows, magenta surround and centred square crop at 390px. Final night artwork remains pending by user request.

Ticket remains open for final art, device QA and repository test requirements.

Verification: eight touched scripts syntax-clean; `scripts/run_tests.sh` on Godot 4.7: **2300 passed, 8 known failures**, matching the failure names documented for ticket 01. Seven new cases all pass. All 28 atlas frames match the ZIP source pixels exactly. See `verification-02.md`.
