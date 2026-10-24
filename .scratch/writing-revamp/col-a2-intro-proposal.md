# col_a2_intro — imported from data/events/col_a2_intro.json

```json
{
  "id": "col_a2_intro",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "contacts"
    },
    {
      "op": "start_event",
      "event": "col_a2_shop"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "Now",
          "speaker": null,
          "text": "Des usually writes full sentences; punctuation, structure, the works. His latest message was four misspelled half-thoughts sent one after another, which is how you know something's wrong before you've even read what it is.",
          "key": "c1"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You don't reply. You're already moving.",
          "key": "c2"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete"
    ],
    "cards": {
      "c1": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "col_a2_intro.json",
  "_liveHash": "4378d488"
}
```
