# London time cycle

`park_foreground.png` is the supplied v3 candidate from
`.scratch/daily-animation-revamp/references/`. It supplies the bench, tree,
St Paul's, Parliament / Elizabeth Tower, and the Shard, with transparent sky.
`time_transition.gd` draws a filled circular sky and moving round sun/moon
behind it. `data/daily_cycle.json` owns the clips, colours, placement and timing.

At 390 × 844 the scene is a 220px circle over the dimmed current screen. Circle
and label rise from below, hold, and leave below. The 1.75-second presentation
and 0.75-second outcome hold are unchanged. Early Rest crosses the remaining
clips in order; reduced motion holds the destination scene still.

The three ZIPs and `cycle.png` are retired source assets from the earlier
73px atlas presentation; `tools/pack_daily_cycle.py` reproduces that atlas.
The new foreground uses lossless import, no mipmaps and nearest filtering.

ART-REVIEW: inspect landmark readability, pixel edges, sky fill, sun/moon
motion, and the circular silhouette on a 390px-wide phone.
