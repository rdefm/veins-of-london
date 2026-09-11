# 05 — Combat action cards → generic chrome

**What to build:** `scenes/screens/combat.gd`'s Attack/Item/Run action
cards (combat-presentation ticket 18's horizontal 3-block row) re-skin
with one plain shared Family-4 button/panel treatment (`ui_action_red`
accent, shared UI sans) rather than any bespoke object reference — the
"not every component needs a bespoke citation" case from
`docs/ui-vision.md` §5. Exact styling (corners, border weight, fill) is an
implementation call; there is no reference image to match.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Attack/Item/Run cards render with the shared generic Family-4 chrome (`ui_action_red` accent, shared sans)
- [ ] No new bespoke art/object reference is introduced for these cards
- [ ] Card tap behaviour and layout position (the dial-and-actions row, per ticket 21) unchanged — this is a rendering swap only
- [ ] `tests/test_combat_screen.gd` updated for the new styling
