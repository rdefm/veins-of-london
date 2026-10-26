# 02 — "Why is this available?" explainer

**Status:** ready-for-agent

**What to build:** When an option is available or boosted because of an observation, the player can see why. The option shows a short line explaining it (e.g. "You noticed: one way in, one way out"), plus a `?` circle that opens a modal with more detail: which observation, which ore, which tier was reached, and what it did (unlocked this option / improved its odds by X / enables these picks).

Applies to every observation-driven option:
- observation pick options (ticket 01) — lists which ores qualify
- options whose `requires` is an `observed` condition
- check options with `observed` mods

Reuse the existing `?`-modal pattern that disabled options already use, and keep it alongside the ore glyphs already drawn on such options. Explainer text should be generated from data (ore name, tier text, etc.), with an optional authored override. Any new UI strings are draft prose → flag `PROSE-REVIEW:`.

**Blocked by:** 01 — Observation pick: core mechanic.

**Relevant files:**
- `scenes/screens/event.gd` — `_add_read_glyphs()`, disabled-option `?` modal (~L486, ~L612), option rendering (~L107)
- `systems/observation.gd` — `option_ores()` (already finds the reads behind an option; extend it or add a sibling that returns the explainer data)
- `docs/REFERENCE.md` §3.9d Observation (Display), §3.9a Requires
- `docs/ui-vision.md` for the line + `?` styling
- `docs/CONTENT-GUIDE.md` for string tone

- [ ] REFERENCE §3.9d Display describes the explainer line and modal contents
- [ ] Unlocked, boosted and pick options each show the line + `?`; the modal gives observation/ore/tier/effect
- [ ] Options not driven by an observation are unchanged
- [ ] Headless tests on the explainer data function; suite + `check_all.sh` clean
- [ ] PROSE-REVIEW flagged for any new strings; on-device check list in the report
