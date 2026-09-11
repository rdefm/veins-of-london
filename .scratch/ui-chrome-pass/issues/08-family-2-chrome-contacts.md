# 08 — Apply Family 2 chrome: Contacts screen

**What to build:** Re-skin `scenes/screens/contacts.gd` and
`scenes/components/contact_cards.gd` (Archie/Des/Nadia/Hakim/James cards)
per the Family 2 design spec from ticket 07, replacing the current default
theme's cream/amber look. Values, unlock-gating logic, and card content
are unchanged — this is a rendering pass only.

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Contacts screen and all contact cards render per the Family 2 spec (icon/list treatment, accent colour) from ticket 07
- [ ] No amber/cream default-theme styling remains on this screen
- [ ] All existing flag-gated show/hide behaviour for each card is unchanged
- [ ] `tests/test_contacts_screen.gd` (or equivalent) updated for the new styling if it asserts on visuals
