# 59 — Profile app: skills XP bar

**What to build:** The Profile phone app's skills card (`_build_profile_skills_card()`, `scenes/screens/phone.gd:342-349`) currently renders crafting/cultivating/stealth skill+XP as plain text labels only (`"Crafting: Lv%d (%d XP)"`). A reusable fill-bar control already exists and is used elsewhere in the same screen (`UI.bar(value, max_value)`, `scenes/components/ui.gd:388`, used for HP at `phone.gd:337` and faction relation in `contact_cards.gd:116`). Add a bar per skill showing progress from the current level's XP threshold toward the next, using the existing `CULTIVATING_XP_LEVELS`/`CRAFTING_XP_LEVELS` arrays (`docs/REFERENCE.md:53,83`, both `[0, 0, 80, 220, 500, 1000]`) — same approach needed for stealth (confirm/locate its XP-level array; add one following the same shape if it doesn't exist yet).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Each skill row in `_build_profile_skills_card()` gains a `UI.bar()` showing `(currentXP - thisLevelThreshold) / (nextLevelThreshold - thisLevelThreshold)`, alongside the existing "Lv%d (%d XP)" text.
- [ ] Max-level skills (no next threshold) show a full/capped bar rather than erroring on a missing next-threshold lookup.
- [ ] Stealth uses the same XP-level data shape as crafting/cultivating (add the array to `GameData`/`docs/REFERENCE.md` if it doesn't already exist).
- [ ] Manual check noted for the human: view the Profile app at various skill levels and confirm each bar fills sensibly as XP is earned.
