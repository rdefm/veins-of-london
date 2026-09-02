#!/usr/bin/env python3
"""Renders data/palette.json as a swatch grid PNG (data/palette_swatch.png).

    python3 tools/make_palette_swatch.py

Re-run whenever data/palette.json changes.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_io import write_png  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALETTE_PATH = os.path.join(REPO_ROOT, "data", "palette.json")
OUTPUT_PATH = os.path.join(REPO_ROOT, "data", "palette_swatch.png")

CELL = 32
COLUMNS = 7
BORDER = (0x14, 0x12, 0x0F, 255)  # outline_black


def make_swatch(palette_path: str = PALETTE_PATH, output_path: str = OUTPUT_PATH, cell: int = CELL, columns: int = COLUMNS):
    with open(palette_path, "r") as f:
        data = json.load(f)
    colors = data["colors"]

    rows = (len(colors) + columns - 1) // columns
    width = columns * cell
    height = rows * cell
    pixels = [BORDER] * (width * height)

    for i, entry in enumerate(colors):
        h = entry["hex"].lstrip("#")
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        col = i % columns
        row = i // columns
        x0, y0 = col * cell, row * cell
        for y in range(y0 + 1, y0 + cell - 1):
            for x in range(x0 + 1, x0 + cell - 1):
                pixels[y * width + x] = (r, g, b, 255)

    write_png(output_path, width, height, pixels)
    print("%s: %d colours, %dx%d -> %s" % (palette_path, len(colors), width, height, output_path))
    return output_path


if __name__ == "__main__":
    make_swatch()
