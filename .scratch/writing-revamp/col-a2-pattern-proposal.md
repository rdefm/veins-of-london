# col_a2_pattern — imported from data/events/col_a2_pattern.json

```json
{
  "id": "col_a2_pattern",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA2Stage",
      "value": "call"
    },
    {
      "op": "set_screen",
      "screen": "contacts"
    },
    {
      "op": "start_event",
      "event": "col_a2_handler_deferred"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"It's not just Hakim. Priya had someone on the phone about her window three days ago. Marcus actually got his window put through last week. Sef had a 'friendly visit' from two blokes who complimented his stock.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Three separate visits inside a fortnight. Somebody decided we're worth the bother.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"Right. Something needs doing. I don't much care what order - pick at it as it comes.\""
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Nobody says the word plan. It isn't that, not yet. It's three problems and a room full of people who'd rather be doing something than talking about it."
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
        "text"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
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
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_pattern.json",
  "_liveHash": "610c2f61"
}
```
