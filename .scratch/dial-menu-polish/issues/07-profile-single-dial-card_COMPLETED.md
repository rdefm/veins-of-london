# 07 — Profile: one Dial card

**What to build:** Profile shows the Dial twice: a Dial line in the Equipment card and a separate Dial card. Merge into one Dial card per owner: drop the Dial line from Equipment; the Dial card shows level, XP bar (from ticket 06's projection), charge/max and regen, seated Movement, loaded Lenses, and Open Dial. Prep mode still shows only participants' Loadout + Dial cards.

**Blocked by:** 06 — Dial level, XP and next-level gains on the overview.

**Relevant files:** `scenes/phone_apps/profile_app.gd` (`_build_equipment_card` Dial line ~l.182-189, `_build_dial_card` ~l.61), `systems/dial.gd`.

**Status:** ready-for-agent

- [ ] Equipment card has no Dial line
- [ ] One Dial card per owner with level, XP, charge/regen, Movement, Lenses, Open Dial
- [ ] Prep-mode filtering unchanged
- [ ] CODEMAP profile_app row updated
