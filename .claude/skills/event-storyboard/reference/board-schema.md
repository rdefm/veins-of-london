# board.json

Saved to `.scratch/event-art/<id>/board.json`; `tools/storyboard.html` reads it from there and renders exactly these fields.

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
  "plates": [                              // one per camera setup, in generation order (parents before variants)
    {
      "id": "P1",
      "name": "clerkenwell_corner",          // file stem: assets/reference-plates/<name>_blank_plate.png, plates/<name>.json
      "variantOf": null,                     // parent plate id for a lasting set change, else null
      "camera": "from across the street, eye level, looking at the corner", // one line, shown in the shot list
      "shots": "S1, S3, S5",
      "attach": ["assets/events/col_a1_intro/col_a1_intro_card1.png"],  // full repo paths; the prompt names the same files by basename
      "prompt": "copy-paste ChatGPT prompt that generates the blank plate (no people)",
      "notes": "compositor setup hints: light sources and where they sit, things actors stand behind"
    }
  ],
  "shots": [
    {
      "id": "S1",
      "title": "Nadia on the Clerkenwell corner",
      "cards": "1–2 (returns at 9)",
      "plate": "P1",
      "method": "pose",                      // pose (AI adds the cast onto the plate → extract.py cut-out) | sprite (standing sprites, compose.py only) | props (plate edit, no cast)
      "job": "story job, one sentence",
      "attach": ["assets/reference-plates/clerkenwell_corner_blank_plate.png", "assets/character-references/Nadia/Nadia_biz_sprite_master.png"],
      "prompt": "copy-paste ChatGPT prompt: names the plate and every attachment by basename, then only what is added and how",
      "saveAs": "assets/reference-plates/clerkenwell_corner_S1_nadia_waiting.png",  // where the ChatGPT output goes (the page's Upload button names it this); the input to extract.py, not the final card
      "reuse": "Archie: S1 cut-out unchanged",  // optional: cut-outs from earlier shots composed in without regenerating
      "unseen": "what must NOT be visible yet",
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
- **Plate prompts** describe the whole set once: location, camera position and lens, what's where (screen-left/right, foreground/background), light sources, weather, time. They say "no people", "no text unless vital to the scene" (and if it is, the exact words), portrait 2:3 (1024×1536), and carry the house technique/mood/no-text lines from `prompt-pack.md`. A variant plate's prompt is an edit: "Attach <parent>_blank_plate.png. Add only … Change nothing else. Keep the exact image size."
- **Shot prompts** open with `Attach: <file>, <file>.` then name the plate by file name and never re-describe it. They say who is added, where (by plate landmarks), pose, gaze, expression, and props, then end with the fixed tail: "Same pixel-art style and scale as the room. Change nothing else in the room. Keep the exact image size." Put the crop-safe rule in the plate (camera) and keep the shot prompt about the cast.
- Cast with no sprite (one-off extras) are described in words in their first shot. Later shots attach that shot's `saveAs` image as their reference.
- **Continuity on a plate:** a later shot attaches the earlier shot's `saveAs` image (the raw ChatGPT output, e.g. `clerkenwell_corner_S3_buyers_arrive.png`), never the final card file: shots are generated before any compositing, so composites don't exist yet. If a character's pose doesn't change, don't regenerate them: list their earlier cut-out in `reuse` and tell the prompt not to add them.
- **`saveAs`** names the raw ChatGPT output: `assets/reference-plates/<plate name>_<shotId>_<slug>.png`, with the slug naming who/pose. All generated images live in `assets/reference-plates/` beside the plates, where the compositor reads them. It is the `ai_image` input to `extract.py`, never the card file. `file` stays the final composite.
- **Background extras** (drinkers, passers-by) are left out of plates and added per shot, so they can move between cards.
- Keep prompts short. Image models follow the first few concrete constraints best.
