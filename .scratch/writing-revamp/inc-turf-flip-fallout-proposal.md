# inc_turf_flip_fallout — imported from data/events/inc_turf_flip_fallout.json

```json
{
  "id": "inc_turf_flip_fallout",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: The streets changed hands overnight and the signs have not caught up."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: Someone expects you to have an opinion.",
          "choices": [
            {
              "label": "Show your face",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You turn up. People notice who did."
            },
            {
              "label": "Wait it out",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You wait. The new arrangement settles without you."
            }
          ]
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: London carries on."
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
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3"
    ],
    "elseKeys": []
  },
  "_liveSource": "inc_turf_flip_fallout.json",
  "_liveHash": "c13beefa"
}
```
