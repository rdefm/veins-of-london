# inc_war_courting — imported from data/events/inc_war_courting.json

```json
{
  "id": "inc_war_courting",
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
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: Two messages arrive within the hour, from opposite sides of the same war.",
          "key": "c1"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: Each wants you on their side of it.",
          "choices": [
            {
              "label": "Hear them both out",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You listen to both. Neither is pleased."
            },
            {
              "label": "Stay out of it",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You stay out. Both remember it."
            }
          ],
          "key": "c2"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: London carries on.",
          "key": "c3"
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
        "text",
        "choices"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "inc_war_courting.json",
  "_liveHash": "380a42e1"
}
```
