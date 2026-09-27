# 108 — Guards can repel a missed-defend raid (HQ + vein)

**What to build:** Today, when an alarmed raid's defend window (HQ or vein) expires without the player fighting it off, it automatically resolves as a loss. Change this: if guards are present (HQ's stackable Hired Guards from ticket 107, or a vein's existing `extraGuards`) at the moment the window expires, roll a chance for the guards to repel the raid instead of it auto-resolving as a loss. Chance is +15% per guard, capped at 75%, expressed as a tunable data value (not a hardcoded literal) so it can be retuned later. This only applies to the missed/expired-window case — it does not change the odds of a raid being attempted in the first place, nor does it change anything about a raid the player personally defends.

**Blocked by:** 106 (HQ needs its alarm-gated defend/expire flow to exist), 107 (HQ needs a guard count to roll against).

**Status:** ready-for-agent

- [ ] When a missed-defend raid (HQ or vein) expires with 1+ guards present, a repel roll happens: +15%/guard, capped at 75%, before falling back to the existing auto-loss resolution.
- [ ] A successful repel roll leaves the vein/HQ raid-free with no loss, with appropriate notification copy distinct from both the "you defended it yourself" and "you missed it, you lost it" copy.
- [ ] A failed repel roll (or zero guards present) resolves exactly as today's missed-defend auto-loss does.
- [ ] The repel-chance-per-guard and cap are stored as data, not inline literals, so they can be retuned without a code change.
- [ ] Regression test covering: guards present and roll succeeds (no loss), guards present and roll fails (loss as before), and zero guards (loss as before, unchanged from pre-ticket behaviour).

PROSE-REVIEW: the new "guards repelled the raid" notification copy is new text — draft against CONTENT-GUIDE.md's tone bible and flag for human review.
