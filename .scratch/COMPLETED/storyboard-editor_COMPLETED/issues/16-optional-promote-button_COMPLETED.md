# 16 — (Optional) Promote button

**What to build:** A **Promote** button in the tool runs the same branches → flat conversion and writes `data/events/<id>.json` (confirm + change summary first) — the one exception to "tool never writes `data/events/`". Tests still run via Claude.

**Blocked by:** 15 — Claude skill: implement a storyboard event.

**Relevant files:** `tools/storyboard.html`, promote script from 15, `data/events/`.

**Status:** needs-triage

- [ ] Confirm dialog shows target path and change summary
- [ ] Output identical to the skill's promote script for the same draft
