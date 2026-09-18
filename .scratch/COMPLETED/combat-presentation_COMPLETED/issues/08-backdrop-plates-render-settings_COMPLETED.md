# 08 — Backdrop plates (6 contexts) + render/import settings

**What to build:** Per §2.1 and §7 — the isometric-diorama grammar adopted
for static encounter backdrops, one plate per combat context. `Combat.
CANONICAL_CONTEXTS` (`systems/combat.gd:23`) enumerates the closed set;
`Combat.is_canonical_context()` guarantees no seventh context can silently
appear without a plate.

1. **Introduce `data/combat_visuals.json`** — the manifest mapping context
   (and, ahead of ticket 09, template key) → asset path + animation names.
   The screen reads this manifest rather than hardcoding paths, keeping the
   constitution's DATA-first rule intact: a new enemy template or context
   needs no code change, only a manifest entry.
2. **Wire the stage (ticket 01) to read the manifest** for its background —
   until a real plate exists for a context, the manifest points at a flat
   palette-colour fill (from ticket 07's `data/palette.json`) instead of an
   image path, so the stage never breaks for a context whose plate hasn't
   landed yet.
3. **Lock the render/import settings from §7** project-wide for anything
   imported through this pipeline: Lossless import (no VRAM/ETC2 block
   compression), mipmaps off, filter off per-texture; `rendering/textures/
   canvas_textures/default_texture_filter` set to Nearest (project default is
   Linear); pick and document (in `docs/ART-BIBLE.md`, from ticket 07) one
   pixel-snap rule (`snap_2d_transforms_to_pixel` on, or subpixel throughout)
   and apply it consistently — mixing the two is what makes pixel games look
   broken.
4. **First-pixel-asset amendment note:** if a real plate lands in this
   ticket before ticket 09's idle sheets, this is the ticket that lands the
   first pixel asset per the project constitution's conflict-resolution
   rule — see ticket 12 (kept separate so this ticket isn't blocked on
   docs review).

**Blocked by:** 01 (stage must exist to render a backdrop into), 07 (needs
the palette for placeholder fills and the pipeline to quantise real plates
through)

**Assets needed:** **6 backdrop plates**, 390×360 native, one per
`Combat.CANONICAL_CONTEXTS` context (`raid`, `mugging`, `event_mugging`,
`home_raid`, `event_raid`, `defend_vein` — note `archie_deal_mugging` is
flavour-identical to `mugging` per `_mugger_intro_label`/context handling,
confirm with the human whether it needs its own 7th plate or reuses
`mugging`'s). Per §2.1's flag: tone/lighting may end up needing to vary by
in-game location/time-of-day rather than being fixed per context — this
ticket ships the fixed-per-context version the doc scoped, with that
follow-on scoping question left open rather than solved here.

**Status:** ready-for-agent

- [ ] `data/combat_visuals.json` exists, keyed by context, mapping to either
      an image path or (for a not-yet-produced plate) a palette-colour
      fallback fill
- [ ] Stage (ticket 01) reads this manifest for its background instead of
      any hardcoded value
- [ ] Every context in `Combat.CANONICAL_CONTEXTS` has a manifest entry —
      `is_canonical_context()` staying the single source of truth for "is
      this a real context" means a new context is caught here too
- [ ] Whatever plates are available at ticket-completion time (0 up to 6)
      import Lossless, mipmaps off, filter off, as the folder default so it
      can't be flipped by accident
- [ ] `rendering/textures/canvas_textures/default_texture_filter` is set to
      Nearest in `project.godot`
- [ ] One pixel-snap rule is chosen, applied, and documented in
      `docs/ART-BIBLE.md`
- [ ] A context with no plate yet renders its palette-colour fallback
      cleanly (no missing-texture error, no visual break)
