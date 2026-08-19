# 39 — VfL travel app tile (cosmetic rebrand of Map entry point)

**What to build:** Per human decision, this is a cosmetic rebrand only — no new screen, no new travel mechanics. Add a new home-grid tile, `"vfl"`, to `PhoneApps.apps()`, branded as a fictional London transit authority ("VfL" — parodying TfL, in the same naming-parody register the game already uses for "the Network" instead of "the Underground," see `CONTEXT.md`'s Network entry and `docs/M1.5-NETWORK-MAP.md` D4.1's legal rationale). Tapping the VfL tile navigates straight to the existing Map screen (`Nav.go_to("map")`) — it does not open as a `PhoneNav` app within the phone shell the way Messages/Notes/etc. do, same special-case pattern `NavBar._on_tile_pressed()` already uses for its own Map slot.

The dock's existing "Map" slot (`NavBar`) is untouched by this ticket — this adds a second, home-grid entry point to the same screen, which is normal phone-UX redundancy (iOS/Android home screens commonly mirror dock apps). Do not rename or reskin the dock's Map slot, the Map screen's own chrome, or "the Network" in-fiction name as part of this ticket — those are separate, unrequested scope.

PROSE-REVIEW: "VfL" needs a spelled-out full name for flavour text/tooltips (the way "TfL" stands for "Transport for London") — draft this against `docs/CONTENT-GUIDE.md`'s tone bible. "Veins for London" is the obvious candidate given the game's own vocabulary (see `CONTEXT.md`) and reads dry/administrative rather than winking — flag for human sign-off rather than treating as final.

**Blocked by:** 36 (app tile placeholder frame) — the VfL tile's icon needs a frame to render inside, same as every other app.

**Status:** ready-for-agent

- [ ] New `"vfl"` entry in `PhoneApps.apps()`, label from the PROSE-REVIEW name above (human sign-off pending).
- [ ] The `"vfl"` tile's locked state mirrors the dock's existing Map lock exactly — gated on `GameState.state["flags"]["archiePartnerSeen"]`, same as `NavBar._map_locked()`. This lock is enforced today only at the dock's UI layer (`Nav.go_to("map")` itself has no gate), so the new tile must replicate the check itself rather than relying on the destination screen to refuse — confirmed by grepping `archiePartnerSeen`, the flag is read nowhere except `NavBar` and test files.
- [ ] Tapping the tile while locked shows the same toast the dock's locked Map slot already shows (`Notify.push(NavBar.LOCKED_MAP_LABEL)` or equivalent shared constant — don't duplicate the string), and does not navigate.
- [ ] Tapping the tile while unlocked calls `Nav.go_to("map")` directly — does not go through `PhoneNav.open_app()`, does not change `state.phoneNav`.
- [ ] Icon falls back to the placeholder frame (ticket 36) since no real art exists yet.
- [ ] Tests cover: locked-state toast-and-no-navigate, unlocked-state navigates straight to the Map screen, tile appears in the home grid in the fixed roster order.

**Human should check on-device:** the VfL tile appears on the phone home screen, opens the Map when tapped (once unlocked), and shows the same "stick close for now" toast the dock's Map slot shows when tapped before Archie's partner scene.
