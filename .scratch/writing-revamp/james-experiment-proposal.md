# james_experiment — imported from data/events/james_experiment.json

```json
{
  "id": "james_experiment",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "jamesExperimentSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "jamesRecipesUnlocked",
      "value": true
    },
    {
      "op": "relation",
      "contact": "james",
      "value": 1
    },
    {
      "op": "set_screen",
      "screen": "contacts"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "Bermondsey — the storage unit",
          "speaker": null,
          "text": "James opens the door in what you're coming to recognise as his default expression: mild disappointment that the world continues to contain other people.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You again.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"If you've got more orders than you can handle, I could take the overflow. The basic stuff that takes your time without needing your skill.\"",
          "key": "c3"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "James looks at you for a long moment. He picks up a glass sphere from his bench, turns it over, sets it down again. This appears to be how he thinks.",
          "key": "c4"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You are proposing to be my assistant.\"",
          "key": "c5"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"If that's how you want to frame it.\"",
          "key": "c6"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I want to frame it accurately. You would not be a partner, a student, or a colleague. You would handle simple orders. I would retain all complex work. You would not advertise yourself as my associate.\"",
          "key": "c7"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"That's fine.\"",
          "key": "c8"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Hm. Then there's a problem. I've seen your pearls. Archie sells them. They're mediocre.\" He lets that sit. \"The same recipe can be made better. The trade calls it rank. You make rank two: the procedure, followed. Rank three needs something the procedure leaves out.\"",
          "key": "c9"
        }
      ],
      "then": [
        {
          "if": {
            "recipeRung": {
              "recipe": "timePearl",
              "rung": "hint1"
            }
          },
          "branch": "b11"
        },
        {
          "branch": "b10"
        }
      ]
    },
    "b10": {
      "title": "From card 10",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"One thing, then, and you can work out what it means. You let go of the press too early.\"",
          "goto": {
            "branch": "b13"
          },
          "key": "c10"
        }
      ],
      "then": {
        "branch": "b11"
      }
    },
    "b11": {
      "title": "From card 11",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"You compress it longer. I'd worked that out.\"",
          "key": "c11"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Had you.\" He doesn't make it a question. \"Knowing a thing and doing it are separate skills, and most people stop at the first. I don't hand out overflow on anyone's say-so. Including yours.\"",
          "key": "c12"
        }
      ],
      "then": {
        "branch": "b13"
      }
    },
    "b13": {
      "title": "From card 13",
      "cards": [
        {
          "type": "choice",
          "label": null,
          "speaker": "James",
          "text": "He clears a space on the bench and sets down a jar of his own calc. \"Rank three. My calc, so you can stop counting it. You don't leave until it's done.\"",
          "choices": [
            {
              "id": "bench",
              "label": "Take the press",
              "effects": [
                {
                  "op": "start_lesson_session",
                  "recipe": "timePearl",
                  "rank": 3,
                  "hintRung": "hint1",
                  "lines": {
                    "hintExact": "James: \"Eighty-two on the gauge. Short of the red line, not on it.\"",
                    "talkThrough": "James: \"Stop. Watch my hands. Every number, once. I'm not doing this twice.\""
                  }
                }
              ],
              "result_text": "The pearl comes off the heat with a different weight to it. James takes it from you before you can look at it properly."
            }
          ],
          "key": "c13"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "He turns it under the lamp. \"Rank three.\" A pause, long enough to count as approval. \"Adequate.\"",
          "key": "c14"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"What about the other recipes? Archie says you know about forty.\"",
          "key": "c15"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Archie says a great deal. I work time and life calc. Those recipes I'll sell you, at a price that reflects the indignity of teaching. The rest belong to the Guild. I'll write to someone there. They answer letters at their own pace.\"",
          "key": "c16"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Practise. Get good enough and I may have a use for you beyond pearls.\" His thumb finds the brass case at his wrist, the way some people check a watch they don't need. He doesn't explain. \"I'll send you overflow. Don't expect it to be glamorous. And don't be late.\"",
          "key": "c17"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You leave with one decent pearl and the firm sense that James considers this arrangement a concession rather than a collaboration. You suspect that won't change.",
          "key": "c18"
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
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "c10": [
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "c11": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c13": [
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c14": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c15": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c16": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c17": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c18": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "james_experiment.json",
  "_liveHash": "2bda3674"
}
```
