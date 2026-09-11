# 07 — Family 2 (Phone-OS) design spec

**What to build:** `docs/ui-vision.md` §3 names Family 2 ("Phone-OS
chrome" — the Phone tab home grid, Notes/Factions/The Ticker/Profile/
Save-Load/Notifications/Reynard's/Harrow's, and Contacts) but §9 flags it
as having "no bespoke spec yet beyond 'look like a real phone' — needs its
own detailing pass ... the way HQ and combat got." Human report confirms
this is visibly still the old placeholder amber/cream look across
Contacts and the phone apps.

Write a short design note (same shape as the Family 4 field-kit-HUD
session that produced `ui-vision.md` §5) covering: icon grid treatment for
the app home screen, list/detail pattern for message/log-style apps,
per-app layout conventions, and which accent colour(s) apply (respecting
§6's locked reservations — `calc_gold` for calc/currency reads,
`ui_action_red` already claimed by Family 4). Output should be a doc
update (either a new section in `ui-vision.md` or a sibling doc it
references), not code.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Design note covers: home-grid icon/tile treatment, list/detail pattern, per-app layout conventions, accent colour choice
- [ ] Explicitly reconciled against §6 (accent reservations) and §7 (one shared UI sans) so it doesn't collide with Family 3/4
- [ ] Reviewed/confirmed by a human before any implementation ticket (08/09) starts
- [ ] `ui-vision.md` §9's Family 2 open item marked resolved, same way the Family 4 item was
