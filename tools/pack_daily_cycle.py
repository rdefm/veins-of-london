"""Pack supplied day-cycle ZIP strips without resampling/recolouring pixels."""
import io
import json
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/daily_cycle"
names = ["morning_to_afternoon", "afternoon_to_evening", "evening_to_morning"]
frames = []
ranges = {}
for name in names:
    path = ASSETS / f"{name}.zip"
    if not path.exists():
        continue
    with zipfile.ZipFile(path) as archive:
        meta = json.loads(archive.read("metadata.json"))
        strip = Image.open(io.BytesIO(archive.read(meta["spritesheet"]))).convert("RGBA")
        w, h, count = meta["frame_w"], meta["frame_h"], meta["frame_count"]
        assert strip.size == (w * count, h)
        ranges[name] = {"start": len(frames), "count": count, "size": [w, h]}
        frames.extend(strip.crop((i * w, 0, (i + 1) * w, h)) for i in range(count))
cell = max(max(frame.size) for frame in frames)
columns = 7
rows = (len(frames) + columns - 1) // columns
atlas = Image.new("RGBA", (columns * cell, rows * cell))
for i, frame in enumerate(frames):
    atlas.paste(frame, ((i % columns) * cell, (i // columns) * cell))
atlas.save(ASSETS / "cycle.png")
manifest_path = ROOT / "data/daily_cycle.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {
    "durationSeconds": 1.75, "outcomeHoldSeconds": 0.75,
    "displaySize": 365, "background": "#111820", "textColor": "#f4efdf",
    "destinationLabel": "Day %d — %s", "reducedMotionLabel": "Reduced motion",
}
manifest.update({
    "atlas": "res://assets/daily_cycle/cycle.png",
    "frameCount": len(frames), "columns": columns, "rows": rows, "cellSize": cell,
    "ranges": ranges,
})
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"{len(frames)} frames; {columns}x{rows}; {atlas.size}")
