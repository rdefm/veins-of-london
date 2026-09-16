# 05 — Comment strip: scenes/components/

**What to build:** Same discipline as tickets 03/04 applied to every shared component script. After this ticket the lint allowlist is empty and the policy is enforced project-wide with no exceptions. Code untouched.

**Blocked by:** 01 — Comment + CODEMAP policy with lint.

**Relevant files:** all `scenes/components/*.gd`. Heaviest: `scenes/components/map_canvas.gd`, `scenes/components/modal_layer.gd`, `scenes/components/ui.gd`, `scenes/components/contact_cards.gd`, `scenes/components/dial_widget.gd`, `scenes/components/app_tile.gd`, `scenes/components/alarm_presentation.gd`, `scenes/components/turn_order_strip.gd`. Vision docs as in ticket 04.

**Status:** ready-for-agent

- [ ] Diff touches only comment/blank lines in scenes/components/.
- [ ] Combined comment-line count across scenes/components/ at most half of today's; `map_canvas.gd` at most 350 comment lines.
- [ ] Every surviving *why* comment cites a doc §, ≤2 lines.
- [ ] Lint allowlist is empty (file removed or documented as intentionally empty); syntax check and full test suite green.
