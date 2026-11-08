# 09 — Binary on-disk saves

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** On-disk saves are written with `var_to_bytes`/`store_var` and read with `bytes_to_var` (never the with-objects variant). The loader tries binary first and falls back to the existing JSON path, including the legacy int restoration (frozen, no new lines). `export_string()` stays JSON+base64. Ints stay ints after load.

**Blocked by:** 02 (snapshot-helper-single-copy), 08 (atomic-saves-bak-fallback)

**Relevant files:** `autoload/SaveManager.gd` (`_restore_int_types` from ~line 1001, `_encode_rng_states`, `export_string`), `tests/test_savemanager.gd`, `tests/test_phone_saveload.gd`; review §4.6

**Status:** ready-for-agent

- [ ] Binary round trip equals the original state with int types preserved (tested)
- [ ] A legacy JSON save still loads (tested with a fixture)
- [ ] An imported string cannot instantiate objects (tested)
- [ ] Nothing relies on JSON int→string dictionary-key conversion (grep + note in report)
- [ ] Autosave time recorded vs the 10.2 ms baseline
