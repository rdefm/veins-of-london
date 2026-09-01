When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

# VEIN — Project Constitution

You are porting and extending **Vein**, a mobile-first, menu-driven London urban-fantasy economy game, from an HTML prototype to **Godot 4.4**. You execute specs; you do not redesign mechanics, rename things, or "improve" formulas. If a spec seems wrong, STOP and ask the human — do not guess.

## Source-of-truth map

| Question | Answer lives in |
|---|---|
| Any number, table, formula, schema | `docs/REFERENCE.md` |
| What to build, in what order, with what tests (port) | `docs/M0-PORT.md` |
| Districts, prospecting, sites, event framework content | `docs/M1-LONDON.md` |
| Network Map rendering (diagram, glyph grammar, filters) | `docs/M1.5-NETWORK-MAP.md` |
| Prose, tone, dialogue rules | `docs/CONTENT-GUIDE.md` |
| Original event prose (extract only, never mechanics) | `reference/london-orichalchum.html` |
| Domain terminology (site vs. vein, claim states, etc.) | `CONTEXT.md` |
| Architectural decisions and why | `docs/adr/` |
| Which file owns what (systems/screens/data index) | `CODEMAP.md` |

The HTML file is **prose quarry only**. Never copy mechanics, formulas, or data from it — the ore roster changed and REFERENCE.md is canonical. If REFERENCE.md and the HTML disagree, REFERENCE.md wins, always.

## Hard rules — Godot 4.4

Target is **Godot 4.4 stable**. You have been trained on a lot of Godot 3 code. NEVER use Godot 3 syntax. The following are the Godot 4 forms; using the Godot 3 form is an error:

- `instantiate()` — never `instance()`
- `await sig` — never `yield(obj, "sig")`
- `create_tween()` — never the `Tween` node pattern from G3
- `@onready var x = $Node` / `@export var y: int` — annotations, not keywords
- Signal connect: `pressed.connect(_on_pressed)` — never `connect("pressed", self, "_on_pressed")`
- `randi_range(a, b)` / `randf()` — never `rand_range`
- `Callable(self, "fn")` or bare `fn` references
- String formatting: `"%d" % x` or `str()`; `String.num()` exists but prefer `%`
- `FileAccess.open(path, FileAccess.READ)` — never `File.new()`
- `JSON.parse_string(text)` returns the data or null — never `JSON.parse().result`
- Dictionaries: `dict.get("k", default)`; `has()` works; `in` works
- `PackedStringArray`, `PackedInt32Array` — never `PoolStringArray`
- `class_name Foo` at top of file for named classes
- Node paths in autoloads: access via the autoload name directly (`GameState.player`)
- `super()` for parent calls — never `.method()`
- `%UniqueName` scene-unique nodes are fine
- Typed GDScript everywhere it's cheap: `func f(x: int) -> void:`

**After writing or editing ANY .gd file, immediately run:**
```
godot --headless -s scripts/check_runner.gd -- path/to/file.gd
```
(or `scripts/check_all.sh` to sweep the whole project). Don't use `godot --check-only --script path/to/file.gd` — it never boots the SceneTree, so autoload identifiers (`GameData`, `GameState`, ...) never resolve and it false-positives on any file that references one; `check_runner.gd` boots normally first, so autoloads resolve for real. A parse error you don't catch compounds into ten.

## Architecture — one-way data flow (non-negotiable)

Identical discipline to the prototype:

1. **DATA** — all content in JSON under `data/`. No numbers or strings buried in code. Loaded once at boot by `GameState`.
2. **STATE** — the entire game state is one pure data tree (Dictionaries/Arrays/primitives only — **no object references, no Nodes, no Callables inside it**) held by the `GameState` autoload. This purity is what makes save, snapshot, and Rewind work. Breaking it breaks the game's flagship feature.
3. **SYSTEMS** — `systems/*.gd`, static funcs. They read/write `GameState.state`, emit `EventBus.state_changed`, and NEVER touch a Node or the scene tree.
4. **SCREENS** — read state, render, and call system functions from button handlers. They NEVER mutate state directly. Not one line.
5. If you find yourself putting logic in a screen or UI in a system, stop and restructure.

## Workflow — every task, no exceptions

1. Read the task's spec section in full before writing code.
2. Write the system code, then its tests (`tests/test_<system>.gd`), then run:
   ```
   scripts/run_tests.sh
   ```
3. A task is **done** only when: syntax check clean on all touched files, all tests pass, and the task's acceptance checks in the milestone doc are demonstrably met.
4. Work one task at a time, in the order the milestone doc lists them — the order is dependency-sorted. Commit per task with message `M0-T04: <task name>`.
5. Never claim something works without having run it headless. You cannot see the UI; the human is visual QA. When a task has UI, list exactly what the human should check on-device, in one short block at the end of your report.
6. If you need a decision the specs don't make, ask. Do not invent.
7. If you add, delete, rename, or repurpose a file under `systems/`, `screens/`, `scenes/`, `autoload/`, or `data/` — or change what a file is responsible for — update `CODEMAP.md` in the same commit. Stale map entries cost more tokens later than the update costs now.

## Environment setup (sandbox or fresh machine)

If `godot` is not on PATH, run `scripts/setup_godot.sh` (M0-T00 creates it), which downloads the Godot 4.4 headless Linux binary from the official GitHub release (`godotengine/godot` releases, asset `Godot_v4.4-stable_linux.x86_64.zip`), unzips it to `.godot-bin/`, and symlinks it as `godot`. All test and check scripts must work with this binary. Never require the editor GUI for any verification step.

## Prose rules (summary — full rules in docs/CONTENT-GUIDE.md)

- Existing tutorial prose is **extracted from the HTML and lightly patched** per CONTENT-GUIDE.md — never rewritten from scratch.
- New prose (district events, UI strings, notifications) you draft yourself **against the tone bible in CONTENT-GUIDE.md**, then flag every new-prose file in your task report with `PROSE-REVIEW:` so the human can audit it.
- One dry line per threat, not three. If a line winks at the camera, cut it.

## Naming and vocabulary (canonical, do not vary)

- The five ore types: `time`, `physics`, `life`, `fate`, `emotion`. The old `energy`, `motion`, `void` types NO LONGER EXIST anywhere in code or data.
- Slang for orichalchum in dialogue: "calc".
- Consumable ids: `timePearl`, `enhancementPowder`, `rewind` (snake_case in GDScript vars is fine; JSON keys keep these exact camelCase ids).
- Currency is `£`, integers only, field name `cash`.
- Screen ids, flag names, and state paths: exactly as in REFERENCE.md §2.

## Agent skills

### Issue tracker

Local markdown under `.scratch/<feature-slug>/` — chosen because this repo is public and the ticket breakdown is being kept private. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five canonical roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line per ticket. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
