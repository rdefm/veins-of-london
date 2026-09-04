# Quest Drafts (mobile-authored)

How to turn a draft written in `tools/quest-editor-mobile.html` into a real quest file. That tool
has no access to `data/events/` — it just produces a portable bundle for you to receive here.

## Recognizing a draft

You'll get either:

- a `<id>.draft.json` file, or
- the same JSON pasted directly into the chat (from the tool's "Copy JSON" button)

It has the shape `{format: "vein-quest-draft/v1", id, cards, notes}`. `cards` is already in the
real event-JSON shape (`type`, `label`, `speaker`, `text`, `choices` with `effects: []` and
`result_text`) — see `tools/quest-editor.html`'s builder for the same schema.

## Steps

1. **Check the id doesn't collide.** The mobile tool never saw `data/events/`, so verify
   `data/events/<id>.json` doesn't already exist.
2. **Write `data/events/<id>.json`** from `id` + `cards` verbatim (they're already normalized —
   empty prose fields are `null`). Add `on_complete` — the bundle doesn't include one; use
   `[{ "op": "set_screen", "screen": "map" }]` as the same inert default
   `quest-editor.html`'s builder writes, unless the notes or surrounding context say otherwise.
   No `deck` key yet — that's registration, not drafting (see step 4).
3. **If `notes` is non-empty**, write it verbatim to `data/events/drafts/<id>.notes.md` — same
   sidecar convention as the desktop tool. This is the author's plain-language description of
   what `effects`/ops/flags should do; it's your brief for filling those in, never copied
   mechanically into the JSON.
4. **The file is inert until registered.** Per `docs/agents/domain.md` / `CLAUDE.md`, work the
   effects/flags/registration (`GameData.EVENT_IDS` or `DISTRICT_EVENT_IDS`, a `deck` block if
   it's a district event) as a normal task against `docs/REFERENCE.md` and `docs/M1-LONDON.md` —
   don't invent formulas or flag names not in the notes or those docs; ask if something's
   ambiguous.
5. **Flag it `PROSE-REVIEW:`** in your report per CLAUDE.md's prose rules — this prose was
   drafted by the human off-device, not extracted from the HTML reference, so it still needs the
   same human audit pass as any new prose.

## If asked to just "wire in" a draft with no further instruction

Do steps 1–3 (write the JSON + notes sidecar) and stop short of registration if the notes don't
specify effects clearly enough to fill in confidently — ask rather than guess at cash/ore amounts
or flag names.
