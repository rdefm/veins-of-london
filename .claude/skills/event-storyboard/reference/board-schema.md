# board.json

The same object is saved to `.scratch/event-art/<id>/board.json` and seeded to the review page (`boards/<eventId>`). The page renders exactly these fields.

```jsonc
{
  "eventId": "col_a2_handler_meet",
  "title": "Meeting the Handler",          // human name for the picker/header
  "logline": "…",                          // the event's single dramatic job, one sentence
  "phase": "storyboard",                   // storyboard | drafts | done
  "round": 1,
  "approved": null,                       // set on approval: {"round": 2, "at": "2026-10-08", "phase": "storyboard" | "drafts"}
  "updatedAt": 1791464688000,              // epoch ms
  "questions": ["…"],                      // open canon/framing questions for the user
  "cards": [                               // EVERY card, in order, one-based n
    {
      "n": 1, "type": "narration", "speaker": null,
      "text": "full card text",
      "choices": ["Pay £50", "Refuse"],     // choice cards only: option labels
      "cut": "NEW",                         // NEW | HOLD | CLEAR | STAGED
      "shot": "S1",                         // NEW: the shot that starts (may be an earlier id = return to it); HOLD: the shot still showing; else null
      "why": "Location established; Nadia waiting sets who called this."
    }
  ],
  "shots": [
    {
      "id": "S1",
      "title": "Nadia on the Clerkenwell corner",
      "cards": "1–2 (returns at 9)",
      "job": "story job, one sentence",
      "instant": "the exact frozen moment: who is doing what",
      "framing": "shot size + angle + lens feel, e.g. 'WS, eye level, slight high angle'",
      "composition": "foreground / midground / background; screen sides; gaze",
      "light": "time of day, weather, key light direction, palette notes",
      "crop": "what must sit in the centre safe zone",
      "unseen": "what must NOT be visible yet",
      "continuity": ["assets/character-references/Nadia/nadia_reference.png"],
      "canon": "unresolved question, or omit",
      "file": "assets/events/<id>/<id>_card1.png (+ _card9.png copy for the return)",
      "drafts": [{ "url": "<asset url from upload>", "label": "v1 raw" }]
    }
  ]
}
```

Rules:
- Card 1 of a VN event must not start blank: card 1 is `NEW` unless it's `STAGED`.
- A `NEW` card reusing an earlier shot id ships as a second copy of that file at the new card index.
- `CLEAR` = explicit `image: null` in JSON. Avoid it; it needs a JSON edit.
- Keep briefs concrete and short. Each field is one or two sentences: a DP's shot note, not prose.
