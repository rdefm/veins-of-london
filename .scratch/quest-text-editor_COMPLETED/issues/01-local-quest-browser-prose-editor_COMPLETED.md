# 01 — Local quest browser + prose editor

**What to build:** A single static local HTML file (open directly in Chrome, no server/build
step) that, via the File System Access API, opens the repo's `data/events/` folder, lists every
existing quest file in a searchable sidebar, and on selection renders that quest's full
card/choice structure. Prose fields (`text`, `label`, `speaker`, `result_text`) are editable;
mechanical fields (`effects`, `on_complete`, `deck`) are shown read-only alongside them so
prose edits stay consistent with what the quest actually does. Saving writes the edited prose
straight back to the real `data/events/<id>.json` on disk, leaving every non-prose key, value,
and ordering untouched.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Opening the tool and granting folder access to the repo's `data/events/` shows a sidebar
      listing every `.json` file there, searchable/filterable by id.
- [ ] Selecting a quest renders all its cards in order, correctly labeled by `type`
      (narration/speaker/choice/resolution/craft), with each choice's own `label` and
      `result_text` shown per choice.
- [ ] `text`, `label`, `speaker`, and `result_text` fields are editable inline; `effects`,
      `on_complete`, and `deck` are visibly present but not editable (e.g. rendered as
      read-only JSON or a locked summary).
- [ ] Saving a quest with only prose changes produces a JSON file that, when diffed against the
      original, differs only in the edited prose string values — same keys, same key order,
      same effects/deck/on_complete content.
- [ ] Reload the tool after saving: the sidebar and the reopened quest reflect the saved edits.
- [ ] Tested manually against at least one multi-choice quest (e.g. `busker_greenwich.json`) and
      one longer quest (e.g. `col_a1_intro.json` or similar) without corrupting either file.
