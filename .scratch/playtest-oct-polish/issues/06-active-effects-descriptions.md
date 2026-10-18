# 06 — Active-effects sheet: what each effect does

**What to build:** Tapping the top-bar effect chips opens the active-effects sheet, which lists each running effect with level and time left. Add a smaller line under each entry saying what it does (e.g. Be a Lady: rolls take the best result). That way the player can check before cultivating or crafting what they're under the influence of. The effect text lives in data alongside the item, not in code, and the same strings are reusable elsewhere (Bag).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/active_effects_modal.gd`, `systems/active_effects.gd`, `scenes/components/top_bar.gd`, `data/recipes.json`, `docs/CONTENT-GUIDE.md`

**Status:** ready-for-agent

- [ ] Every timed out-of-combat effect has a one-line effect description in data
- [ ] Sheet shows it under each entry in smaller, muted text
- [ ] Test asserts every effect-granting item has a description
- [ ] New strings flagged PROSE-REVIEW
