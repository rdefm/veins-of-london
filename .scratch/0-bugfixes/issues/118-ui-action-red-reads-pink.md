# 118 — Diagnose: ui_action_red controls render pinker than the locked hex

**What to build:** Human visual QA (screenshot-12-09-2026.PNG,
screenshot2-12-09-2026.PNG) reports every already-recoloured control (i.e.
everything that isn't still the old amber, see ticket 117) reads as pink
rather than the locked pillar-box red — `ui_action_red`, `#c8102e`,
`data/palette.json`. This spans multiple, structurally different call sites
(nav dock icons/labels in `nav_bar.gd`, filled action buttons via
`ContactCards._style_filled_button()`, the combat/event action bars), so
this is a diagnose-first ticket, not an assumed fix — same shape as tickets
115/116's diagnose-then-fix split.

Checked already, ruled out:
- `GameData.PALETTE["ui_action_red"]` loads as `Color("#c8102e")` verbatim
  (`autoload/GameData.gd:367`) — no alpha, no dimming at load time.
- `_style_filled_button()`'s **normal** state (`contacts.gd`... rather
  `contact_cards.gd:602`) applies the accent color unmodified; only its
  `hover`/`pressed` variants call `.lightened()`/`.darkened()`, and a static
  screenshot can't be showing every button simultaneously hovered.
- `app_tile.gd`'s `BADGE_COLOUR` is already the exact locked hex (its own
  comment notes it was "close-but-not-exact" before and has since been
  aligned).

Not yet checked — leading hypotheses for the agent picking this up:
- `nav_bar.gd` draws icons/labels as thin red **strokes/glyphs on a light
  background** (`ui_action_red` per its own comments at lines 15/51/109) —
  anti-aliasing on thin shapes is a known way for a saturated fill to read
  lighter/pinker than the same colour used as a solid block fill. Render
  the dock at real device resolution and sample pixel values against
  `#c8102e` to confirm or rule this out.
- Any `StyleBoxFlat` using `ui_action_red` as a **fill** on a very small
  control (e.g. the debug modal's small buttons) with default
  `anti_aliasing`/`aa_size` — check whether Godot's default StyleBoxFlat
  antialiasing is softening the interior, not just the border, at small
  control sizes.
- Whether the screenshots themselves were captured through a lossy path
  (export/compression) that could shift saturated red toward pink —
  compare a fresh headless/on-device screenshot's raw pixel values before
  assuming an engine-side bug.

**Blocked by:** None — independent of ticket 117 (that ticket is about
controls still on the *old* amber; this one is about controls already on
the *new* red reading wrong).

**Status:** ready-for-agent

- [ ] Root cause identified: which specific rendering path(s) produce a
      pixel colour visibly lighter/less saturated than `#c8102e`, with
      sampled pixel values as evidence (not just visual impression).
- [ ] Fix applied so every `ui_action_red` control samples at (or
      acceptably close to) `#c8102e` in a fresh screenshot, including the
      bottom nav dock, filled action buttons (combat, event, Phone apps),
      and the Reynard's/Harrow's outgoing message bubbles.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean
      on every touched file; `scripts/run_tests.sh` passes.

Human visual QA note: on-device, compare a few `ui_action_red` controls
(bottom nav icons, a Phone app's filled action button, a combat action
card) side by side against the swatch for `#c8102e` and confirm they now
read as the same red, not pink.
