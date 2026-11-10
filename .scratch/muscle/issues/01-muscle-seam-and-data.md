# 01 — Muscle seam and data

**What to build:** The `Muscle` system module and its data, with no consumers yet. Player muscle exists as individual guard records in a pure-data `state.muscle` tree: id, generated name (sometimes a nickname), level, XP, one or two traits, post, injury/training countdowns. The module can create a guard, generate unique names across current + former guards, roll traits (25% second trait, blocked pairs never together), and answer level weight, repel weight (level + trait repel modifiers), wage (level wage × trait wage multipliers) and short/full name. Every number lives in JSON. Old saves are refused by a save version bump. Prefactor for every later ticket: nothing in the game reads it yet.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/muscle.gd` (new), `tests/test_muscle.gd` (new)
- `data/constants.json` (new `muscle` block: level table, XP thresholds/awards, training, injury days, post caps, `reserveResponders`, board size/odds/former chance+cap, second-trait chance, nickname chance, score weights/bands, strength-word cut-offs; `guardAlly` stays the L1 block)
- `data/muscle_traits.json` (new), `data/muscle_names.json` (new)
- `autoload/GameData.gd` (load new data), `autoload/GameState.gd` (initial `state.muscle`), `autoload/SaveManager.gd` (`SAVE_VERSION` bump, `MIN_SUPPORTED_VERSION`)
- `tests/test_savemanager.gd`, `tests/test_rewind.gd`
- Spec: `.scratch/muscle/spec.md` §Levels, wages, XP, training; §Traits; §Names; §State schema
- CONTEXT.md: add **Muscle**, **Former guard**; CODEMAP.md rows for the new system and data files

**Status:** ready-for-agent

- [ ] `state.muscle` holds only primitives (Dictionaries/Arrays/ints/Strings); a Rewind snapshot round-trip restores it exactly
- [ ] Level table (weight, wage, board odds, XP threshold) for L1–L5 matches the spec table and is read from JSON only
- [ ] All 13 traits defined in data with label, kind, one-line effect text, effect params; blocked pairs (Solid+Glass jaw, Quick study+Slow learner, Watchful+Flaky, Quick study+Lazy) never co-occur over a seeded run
- [ ] Trait effects stack multiplicatively (e.g. Cheap+Mouthy wage = level wage × 0.8 × 1.1)
- [ ] Repel weight = level weight + Watchful/Mouthy/Flaky modifiers
- [ ] Generated names unique across current and former guards; ~15% get a nickname; short name = first name + surname initial; full name shows a nickname as Dee "Spanner" O.
- [ ] Name/nickname pools: ≈60 first names, ≈60 surnames (London mix), nickname list (generic + funny)
- [ ] Save version bumped; a save from the previous version is refused with the standard message
- [ ] `test_muscle.gd` passes alone under `timeout 60`; full suite + `check_all.sh` clean
- [ ] PROSE-REVIEW flagged: name/nickname pools, trait labels and effect lines
