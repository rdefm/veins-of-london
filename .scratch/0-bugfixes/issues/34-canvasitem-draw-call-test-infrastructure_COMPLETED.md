# 34 — Spike: can a draw-call fake avoid retyping `target: CanvasItem`?

**What to build:** A throwaway headless repro (not production code — scratch script, delete or keep in `.scratch/` per human preference, doesn't need to survive this ticket) that answers one question: can a GDScript class that does **not** extend `CanvasItem` stand in for a `target: CanvasItem`-typed parameter, by having a `CanvasItem`/`Node2D` **subclass** shadow the specific draw methods this codebase calls (`draw_circle`, `draw_arc`, `draw_rect`, `draw_colored_polygon`, `draw_line`, `draw_string`) so a caller holding a `CanvasItem`-typed reference dispatches to the shadowed (recording) versions instead of the engine's real ones?

This exists because ticket 35 (below) needs a recording double for `map_canvas.gd`'s `_draw_vein_stop`/`_draw_faction_stop`/`_draw_unclaimed_stop` and the shared helpers they call (`_draw_ring_stop`, `_draw_interchange_ring`, `_draw_ore_symbol`, `_draw_centered_text`, `Icons.draw_*`, `OreGlyphs.draw`) — all of which take `target: CanvasItem` specifically so `DiscoverRipple`'s pop-in can reuse the same draw calls the static render makes. If a `CanvasItem`-subclassed fake can shadow those methods, ticket 35 needs **zero** production retyping. If GDScript disallows shadowing non-virtual native methods (or dispatch falls through to the engine's real, error-raising `draw_circle` regardless), ticket 35 has to retype `target` to `Object`/`Variant` at whichever call sites it touches — a real, non-trivial production change (loses static type-checking at those call sites) that this repo's CLAUDE.md ("Typed GDScript everywhere it's cheap") means should be minimized, not applied blanket.

Either answer is fine — the point is deciding this once, with evidence, instead of leaving it as a coin-flip for whoever implements ticket 35.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] Repro script attempts the shadowing approach: a class extending `Node2D` (or `CanvasItem` directly, whichever compiles) defines `draw_circle`/`draw_arc`/etc. with recording bodies; a second function typed `target: CanvasItem` is called with an instance of that class and asserts whether the recording bodies or the engine's real methods ran. Run it headless the same way `check_runner.gd` boots (needs the SceneTree for autoloads even though this repro likely doesn't touch any).
- [x] Outcome recorded in this ticket under a `## Answer` heading: either "shadowing works — `target: CanvasItem` stays as-is in ticket 35, the fake just extends `CanvasItem`/`Node2D`" or "shadowing fails — `<exact compiler/runtime error text>` — ticket 35 needs to retype."
- [x] If shadowing fails: note here which of `map_canvas.gd`/`icons.gd`/`ore_glyphs.gd`'s `target` params ticket 35 should retype — only the ones its own new tests exercise (not a blanket sweep of every `target` param in all three files), per the "minimize retyping" reasoning above.

## Answer

**Shadowing fails — GDScript refuses to compile it, full stop.** Repro at
`.scratch/0-bugfixes/issues/repro_canvasitem_shadow.gd` (kept, not deleted —
it's the evidence). It's a `Node2D` subclass with recording overrides of all
six methods (matching each engine signature exactly, including default
args), loaded via `godot --headless -s <repro>` the same way
`check_runner.gd` boots.

Exact error, once per shadowed method:

```
SCRIPT ERROR: Parse Error: The method "draw_circle()" overrides a method
from native class "CanvasItem". This won't be called by the engine and may
not work as expected. (Warning treated as error.)
          at: GDScript::reload (res://.scratch/0-bugfixes/issues/repro_canvasitem_shadow.gd:12)
...
ERROR: Failed to load script "res://...repro_canvasitem_shadow.gd" with error "Parse error".
```

Confirmed this isn't a fluke of running the file directly: a second repro
mimicking `check_runner.gd`'s own check exactly (`load()` the file, then
`script.can_instantiate()`) gets the same parse errors and
`can_instantiate() == false`. So this isn't a soft warning ticket 35 could
ignore — a fake shaped this way fails this repo's own syntax-check gate,
the same one every task here runs after touching a `.gd` file. GDScript
treats overriding a *non-virtual* native method as a hard, unconditional
compile error — there's no override-a-native-method escape hatch for
`CanvasItem`'s draw calls, virtual methods (`_draw`, `_ready`, ...) are a
completely separate mechanism and unaffected.

**Ticket 35 needs to retype.** Scoped to only the `target` params its own
checklist actually exercises (not a blanket sweep):

- `scenes/components/map_canvas.gd`: `_draw_ring_stop`, `_draw_interchange_ring`,
  `_draw_ore_symbol`, `_draw_centered_text` — all four already default
  `target: CanvasItem = self`, retype to `target: Object = self`.
  Note: `_draw_vein_stop`/`_draw_faction_stop`/`_draw_unclaimed_stop`
  themselves take no `target` param at all (they always draw via these
  helpers' `self` default) — for ticket 35's tests to call
  `_draw_vein_stop(stop)` "against the fake" as its own wording puts it,
  it'll need to decide whether to add a `target` param to these three too
  (threading it down to the calls above) or have its tests call the
  lower-level helpers directly instead. That's ticket 35's call, not
  prescribed here.
- `scenes/components/icons.gd`: only `draw_padlock` and `draw_pin` — the two
  ticket 35's checklist names explicitly. `draw_home`, `draw_market`,
  `draw_phone`, `draw_bag`, `draw_legend`, `draw_news`, `draw_hamburger`
  are untouched by ticket 35's stated scope — leave them `CanvasItem`.
- `scenes/components/ore_glyphs.gd`: `draw` (the public entry ticket 35's
  checklist calls directly) and its five private helpers it dispatches to
  internally — `_draw_hourglass`, `_draw_bolt`, `_draw_star4`, `_draw_die5`,
  `_draw_asterisk8` — since `target` threads straight through from `draw`
  into whichever shape-helper runs.

Not retyped, out of scope: `map_canvas.gd`'s `_draw_pins_layer`,
`_draw_home_pin`, `_draw_pin_marker`, `_draw_market_pin`, `_draw_labels` —
none are named in ticket 35's checklist.
