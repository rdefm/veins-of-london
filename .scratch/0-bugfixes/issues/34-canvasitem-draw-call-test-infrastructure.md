# 34 — Spike: can a draw-call fake avoid retyping `target: CanvasItem`?

**What to build:** A throwaway headless repro (not production code — scratch script, delete or keep in `.scratch/` per human preference, doesn't need to survive this ticket) that answers one question: can a GDScript class that does **not** extend `CanvasItem` stand in for a `target: CanvasItem`-typed parameter, by having a `CanvasItem`/`Node2D` **subclass** shadow the specific draw methods this codebase calls (`draw_circle`, `draw_arc`, `draw_rect`, `draw_colored_polygon`, `draw_line`, `draw_string`) so a caller holding a `CanvasItem`-typed reference dispatches to the shadowed (recording) versions instead of the engine's real ones?

This exists because ticket 35 (below) needs a recording double for `map_canvas.gd`'s `_draw_vein_stop`/`_draw_faction_stop`/`_draw_unclaimed_stop` and the shared helpers they call (`_draw_ring_stop`, `_draw_interchange_ring`, `_draw_ore_symbol`, `_draw_centered_text`, `Icons.draw_*`, `OreGlyphs.draw`) — all of which take `target: CanvasItem` specifically so `DiscoverRipple`'s pop-in can reuse the same draw calls the static render makes. If a `CanvasItem`-subclassed fake can shadow those methods, ticket 35 needs **zero** production retyping. If GDScript disallows shadowing non-virtual native methods (or dispatch falls through to the engine's real, error-raising `draw_circle` regardless), ticket 35 has to retype `target` to `Object`/`Variant` at whichever call sites it touches — a real, non-trivial production change (loses static type-checking at those call sites) that this repo's CLAUDE.md ("Typed GDScript everywhere it's cheap") means should be minimized, not applied blanket.

Either answer is fine — the point is deciding this once, with evidence, instead of leaving it as a coin-flip for whoever implements ticket 35.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Repro script attempts the shadowing approach: a class extending `Node2D` (or `CanvasItem` directly, whichever compiles) defines `draw_circle`/`draw_arc`/etc. with recording bodies; a second function typed `target: CanvasItem` is called with an instance of that class and asserts whether the recording bodies or the engine's real methods ran. Run it headless the same way `check_runner.gd` boots (needs the SceneTree for autoloads even though this repro likely doesn't touch any).
- [ ] Outcome recorded in this ticket under a `## Answer` heading: either "shadowing works — `target: CanvasItem` stays as-is in ticket 35, the fake just extends `CanvasItem`/`Node2D`" or "shadowing fails — `<exact compiler/runtime error text>` — ticket 35 needs to retype."
- [ ] If shadowing fails: note here which of `map_canvas.gd`/`icons.gd`/`ore_glyphs.gd`'s `target` params ticket 35 should retype — only the ones its own new tests exercise (not a blanket sweep of every `target` param in all three files), per the "minimize retyping" reasoning above.
