# col_a2_handler_deferred — imported from data/events/col_a2_handler_deferred.json

```json
{
  "id": "col_a2_handler_deferred",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA2HandlerDeferred",
      "value": true
    },
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
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"There's a way to know before it happens. Costs money. Costs the right kind of money, mind, not the kind we're short of.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"No.\" A pause, because he's noticed how that sounded. \"Not because it's wrong. Because it's too soon.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"You start with 'just this once' and you don't notice the year it stopped being once.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "A pause, then \"Fine. We do it the hard way. For now\" "
        },
        {
          "key": "c5",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Nobody writes it down, but it's agreed, the way things get agreed round here - once, out loud, and never mentioned again unless it stops holding."
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
      ],
      "c5": [
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
      "c4",
      "c5"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_handler_deferred.json",
  "_liveHash": "cd0ab3b0"
}
```
