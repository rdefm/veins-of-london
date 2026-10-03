# 01 — Shared brand, readable ink and tabs

**What to build:** Opening LodedInnit shows the direction C brand and legible dark chrome. Feed and People tabs read as tabs and indicate the actual displayed page, with no amber default-button treatment.

**Blocked by:** None — can start immediately.

**Relevant files:** `.scratch/lodedinnit-visual-fidelity/spec.md`; `.scratch/lodedinnit/prototype-lodedinnit.html` (`hybridTop`, `.c`, `.a .tabs`, `.b .tabstrip`); `.scratch/lodedinnit-ui/spec.md`; `scenes/phone_apps/lodedinnit_app.gd` (`_build_brand_bar`, `_build_tabs`, build root); `scenes/components/ui.gd`; `theme/main_theme.tres`; `data/palette.json`; `assets/phone/icons/lodedinnit.png`; `docs/ui-vision.md` §10; `CODEMAP.md`; existing LodedInnit presentation tests.

**Status:** ready-for-agent

- [ ] Keep the existing phone frame/status bar. Brand bar remains dark plum, with the existing 31 px logo, near-white bold “Loded”, light-plum bold “Innit”, and a legible small uppercase tagline. Match direction C's compact logo/wordmark lockup and spacing. Back control remains usable; omit the prototype's decorative `⋯`.
- [ ] Set explicit LodedInnit-local ink colours on dark surfaces: primary near `#ededee`, secondary near `#999a9d`, light-plum status/accent near `#dab8eb`, dividers near `#424246`. No near-black brand or person text. Do not recolour the shared theme for unrelated screens.
- [ ] Replace the two full-width amber/grey filled buttons with flat Feed/People tabs directly under the brand bar on **both** pages. Actual selected tab: bright text plus a thin `#81549a` underline; unselected: muted text; neither appears disabled. Tapping either works. The screenshot's amber Feed/grey People state while People is shown must be impossible.
- [ ] Shared chrome uses the approved plum/copper tokens from `data/palette.json`; no inherited amber controls. Keep the same tab position when switching pages. Profile navigation remains a separate profile surface.
- [ ] Headless Godot 4.7 checks pass, including a focused selected-tab/style regression check. On-device: compare brand contrast, size, alignment, and both tab states against direction C at narrow phone width.

## Comments
