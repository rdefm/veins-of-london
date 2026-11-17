"""Shared pixel-art grid + palette helpers.

Used by the pixelize script, the plate compositor and the art judge so all three
grid-lock (box downscale to native size) and snap to a palette the same way.
Also holds the measurements the judge reports (grid scale / regularity, colour
count, distance to the reference palette).
"""
import json

import numpy as np
from PIL import Image

QUANTIZE_METHODS = {"mediancut": Image.Quantize.MEDIANCUT, "octree": Image.Quantize.FASTOCTREE}


# ---------- grid-lock ----------

def grid_lock(img, scale):
    """Box-downscale `img` to native pixel size (`scale` source px per art pixel)."""
    return img.resize((img.width // scale, img.height // scale), Image.BOX)


# ---------- palette ----------

def palette_hexes(path):
    """Every #rrggbb(aa) string in a palette JSON (under "colors" if present), in file order."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    hexes = []

    def walk(node):
        if isinstance(node, str) and node.startswith("#") and len(node) in (7, 9):
            hexes.append(node[1:7])
        elif isinstance(node, dict):
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)

    walk(data.get("colors", data))
    return hexes


def palette_rgb(path):
    """Palette JSON -> (n, 3) int array."""
    return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in palette_hexes(path)], dtype=int)


def palette_image(rgb):
    """(n, 3) colours -> a PIL "P" image usable as `quantize(palette=...)`."""
    flat = [int(v) for c in rgb for v in c]
    pal = Image.new("P", (1, 1))
    pal.putpalette(flat + flat[:3] * (256 - len(rgb)))
    return pal


def load_palette(path):
    """Palette JSON -> (PIL palette image, colour count)."""
    rgb = palette_rgb(path)
    return palette_image(rgb), len(rgb)


def snap_to_palette_image(img, pal):
    """Nearest-colour snap of an RGB image to a PIL palette image (no dither)."""
    return img.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")


def quantize_colours(img, n, method=Image.Quantize.FASTOCTREE):
    """Reduce an RGB image to `n` colours (no dither); returns an RGB image."""
    return img.quantize(colors=n, method=method, dither=Image.Dither.NONE).convert("RGB")


def derive_palette(img, n, method=Image.Quantize.MEDIANCUT):
    """The n-colour palette PIL derives for `img`, as an (n, 3) array."""
    q = img.quantize(colors=n, method=method, dither=Image.Dither.NONE)
    return np.array(q.getpalette()[: n * 3]).reshape(-1, 3)


def snap_nearest(rgb, pal):
    """Snap every pixel of an (..., 3) float array to its nearest colour in `pal` ((n, 3) float)."""
    flat = rgb.reshape(-1, 3).astype(float)
    d = ((flat[:, None, :] - pal[None]) ** 2).sum(2)
    return pal[d.argmin(1)].reshape(rgb.shape)


# ---------- measurements ----------

MAX_SCALE = 16
EDGE_EPS = 2.0         # mean per-channel step (0-255) counted as an edge between neighbouring columns/rows
SCALE_TIE = 0.02       # scales within this of the best score are ties; the largest wins
MIN_REGULARITY = 0.3   # below this the image is reported as not on a grid (scale 1)


def grid_fit(img):
    """(scale, regularity): estimated art-pixel size and how well the image sits on that grid (0-1).

    For each candidate scale s, the share of edge energy that falls on s-aligned cell
    borders, normalised so a uniformly spread (blurred / off-grid) image scores ~0 and a
    perfect s-grid scores 1. Edges are measured in x and y with the grid anchored at 0,0.
    """
    arr = np.asarray(img.convert("RGB"), dtype=float)
    scores = {}
    dx = np.abs(np.diff(arr, axis=1)).mean(axis=(0, 2))
    dy = np.abs(np.diff(arr, axis=0)).mean(axis=(1, 2))
    for s in range(2, MAX_SCALE + 1):
        total = on = 0.0
        for d in (dx, dy):
            d = np.where(d >= EDGE_EPS, d, 0.0)
            total += d.sum()
            on += d[s - 1::s].sum()
        if total <= 0:
            scores[s] = 0.0
            continue
        scores[s] = max(0.0, (on / total - 1 / s) / (1 - 1 / s))
    best = max(scores.values())
    if best < MIN_REGULARITY:
        return 1, round(best, 3)
    scale = max(s for s, v in scores.items() if v >= best - SCALE_TIE)
    return scale, round(scores[scale], 3)


def colour_count(img):
    arr = np.asarray(img.convert("RGB")).reshape(-1, 3)
    return int(len(np.unique(arr, axis=0)))


def palette_distance(img, pal):
    """Mean euclidean RGB distance from each pixel to its nearest palette colour (0-441)."""
    arr = np.asarray(img.convert("RGB")).reshape(-1, 3)
    colours, counts = np.unique(arr, axis=0, return_counts=True)
    d = np.sqrt(((colours[:, None, :].astype(float) - pal[None].astype(float)) ** 2).sum(2)).min(1)
    return float((d * counts).sum() / counts.sum())


def pixel_metrics(img, palette=None):
    """Informational pixel-art metrics for an image (see judge README)."""
    scale, regularity = grid_fit(img)
    locked = grid_lock(img.convert("RGB"), scale) if scale > 1 else img.convert("RGB")
    return {
        "gridScale": scale,
        "gridRegularity": regularity,
        "colours": colour_count(locked),
        "paletteDistance": None if palette is None else round(palette_distance(locked, palette), 2),
    }
