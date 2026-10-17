# 14 — Prose sweep and first-fight hint

**What to build:** Text that describes old combat (an "Attack" button, evade-style Prophet's Breath, "parting shot", speed-only turn talk) is patched lightly in events, UI strings, item descriptions and the Gym, never rewritten wholesale. The player's first live fight shows a short, dry hint teaching Guard, Strike and Feint, shown once (flagged). Every changed or new line is listed in the report under `PROSE-REVIEW:`.

**Blocked by:** 13

**Relevant files:** `data/events/*.json`; `data/recipes.json` (descriptions); beatLines in the combat data table's permanent home (after 13); `scenes/modals/hq_gym_modal.gd`; `docs/CONTENT-GUIDE.md`; `docs/writing-guide.md`; `docs/CHARACTER-VOICE-GUIDE.md`

**Status:** ready-for-agent

- [ ] Grep for old-combat vocabulary in data and UI is clean or justified
- [ ] First-fight hint shows once, then never again (flag persisted)
- [ ] Report lists every line under PROSE-REVIEW
