# 06 — Modal registry + result modals extracted

**What to build:** The modal layer stops being one file holding every modal's content. It keeps the chrome (dim backdrop, centred card, sizing, dismiss-on-tap-outside, dismiss side-effects) and dispatches the card *content* to one script per modal type, looked up from a type→script table, each content script exposing the same small build interface and receiving the modal's data. To prove the pattern, the simple one-card result modals move out first: seed result, cultivate result, craft result, craft batch result, sale result, Archie deal result, and the three James job cards. Everything the player sees and taps is unchanged; the existing modal-layer tests pass unmodified apart from any that reach into private builder names.

**Blocked by:** 05 — Comment strip: scenes/components/.

**Relevant files:** `scenes/components/modal_layer.gd`, new `scenes/modals/` directory (one script per type + a registry), `systems/modal.gd` (open/close API — unchanged), `scenes/Main.gd` (mounts the layer), `tests/test_modal_layer.gd`, `tests/test_modal.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Opening any of the nine moved modal types renders the same content and buttons as before; their close/accept/decline handlers behave identically (including the dismiss side-effects for sale result, Archie deal result and job offer).
- [ ] Adding a new modal type requires one new script plus one registry line — no edit to the layer's match.
- [ ] The not-yet-moved types still work through the old in-layer path; the layer is smaller by at least the moved builders.
- [ ] CODEMAP rows for the layer and the new directory; syntax check and full test suite green.
