#!/usr/bin/env python3
"""Pixel-art asset pipeline: quarry-generated PNG -> game-ready sprite.

Per docs/combat-animation-vision.md §6 / docs/ART-BIBLE.md. Run on every
generated asset before it lands under assets/, no exceptions:

    python3 tools/pixelize.py input.png output.png --canvas 64x104

Pipeline, in order (matches docs/combat-animation-vision.md §6):
  1. detect native cell size (the block size the art was actually drawn at,
     even though the source PNG is a larger upscaled export)
  2. downsample nearest to that cell size (one representative pixel per
     block — never averaged, that is how you reintroduce the blur this
     step exists to remove)
  3. binarize alpha and drop isolated single-pixel specks (strips the
     anti-aliased fringe image models leave around a silhouette)
  4. trim (crop and/or pad, centred) to the fixed output canvas

Pure stdlib — no Pillow — so this runs on a bare Python 3 install. See
tools/png_io.py for the PNG codec and tools/test_pixelize.py for the
end-to-end self-test.
"""

import argparse
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_io import read_png, write_png  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DEFAULT_ALPHA_THRESHOLD = 128


def _block_uniformity(pixels, width, height, cell: int) -> float:
    """Mean, over every `cell`x`cell` block (edge blocks clipped to fit),
    of the fraction of that block occupied by its single most-common exact
    RGBA value. 1.0 means every block is a flat colour; a single anti-
    aliased fringe pixel inside an otherwise-solid block barely dents it,
    which is what makes this robust to AA noise in a way a per-pixel edge
    scan isn't."""
    total_frac = 0.0
    blocks = 0
    for by in range(0, height, cell):
        bh = min(cell, height - by)
        for bx in range(0, width, cell):
            bw = min(cell, width - bx)
            counts = Counter()
            for dy in range(bh):
                row = (by + dy) * width
                for dx in range(bw):
                    counts[pixels[row + bx + dx]] += 1
            total_frac += counts.most_common(1)[0][1] / (bw * bh)
            blocks += 1
    return total_frac / blocks if blocks else 0.0


def detect_cell_size(width: int, height: int, pixels, threshold: float = 0.9, max_cell: int = 32) -> int:
    """Finds the largest block size the art appears to have been drawn on
    (i.e. how many real pixels make up one "native" pixel-art pixel).

    Tries every candidate cell size and scores it by how close the image is
    to a flat-colour mosaic at that block size (see `_block_uniformity`).
    A true native cell size scores near 1.0 apart from anti-aliased fringe
    at silhouette edges; picking the *largest* candidate that still clears
    `threshold` avoids locking onto a divisor of the true cell size (every
    divisor of a genuinely uniform block is at least as uniform).

    Degrades to 1 (no downsampling) if nothing clears the threshold — e.g.
    art that's already at native resolution, or too noisy to grid-detect,
    in which case pass `--cell` explicitly.
    """
    limit = min(max_cell, width, height)
    best = 1
    for cell in range(2, limit + 1):
        if _block_uniformity(pixels, width, height, cell) >= threshold:
            best = cell
    return best


def downsample_nearest(width: int, height: int, pixels, cell: int):
    if cell <= 1:
        return width, height, list(pixels)

    new_w = max(width // cell, 1)
    new_h = max(height // cell, 1)
    out = [None] * (new_w * new_h)
    for y in range(new_h):
        sy = y * cell
        for x in range(new_w):
            sx = x * cell
            out[y * new_w + x] = pixels[sy * width + sx]
    return new_w, new_h, out


def strip_fringe(width: int, height: int, pixels, alpha_threshold: int = DEFAULT_ALPHA_THRESHOLD):
    """Binarizes alpha, then drops orthogonally-isolated single-pixel specks.
    Runs after downsampling, on the original sampled colours — this step
    only ever touches alpha."""
    binarized = []
    for (r, g, b, a) in pixels:
        binarized.append((r, g, b, 255) if a >= alpha_threshold else (0, 0, 0, 0))

    out = list(binarized)
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if binarized[idx][3] == 0:
                continue
            has_neighbor = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height and binarized[ny * width + nx][3] != 0:
                    has_neighbor = True
                    break
            if not has_neighbor:
                out[idx] = (0, 0, 0, 0)
    return out


def trim_to_canvas(width: int, height: int, pixels, canvas_w: int, canvas_h: int):
    """Centres the image on a transparent canvas of the given size, cropping
    any overflow and padding any shortfall."""
    out = [(0, 0, 0, 0)] * (canvas_w * canvas_h)
    offset_x = (canvas_w - width) // 2
    offset_y = (canvas_h - height) // 2

    for y in range(height):
        dst_y = y + offset_y
        if dst_y < 0 or dst_y >= canvas_h:
            continue
        row_base = y * width
        dst_row_base = dst_y * canvas_w
        for x in range(width):
            dst_x = x + offset_x
            if dst_x < 0 or dst_x >= canvas_w:
                continue
            out[dst_row_base + dst_x] = pixels[row_base + x]
    return out


def pixelize(
    input_path: str,
    output_path: str,
    canvas_w: int,
    canvas_h: int,
    cell_override: int = None,
    alpha_threshold: int = DEFAULT_ALPHA_THRESHOLD,
    verbose: bool = True,
):
    width, height, pixels = read_png(input_path)

    cell = cell_override if cell_override else detect_cell_size(width, height, pixels)
    ds_w, ds_h, ds_pixels = downsample_nearest(width, height, pixels, cell)
    stripped = strip_fringe(ds_w, ds_h, ds_pixels, alpha_threshold)
    final_pixels = trim_to_canvas(ds_w, ds_h, stripped, canvas_w, canvas_h)

    write_png(output_path, canvas_w, canvas_h, final_pixels)

    if verbose:
        print(
            "%s: %dx%d -> cell=%d -> %dx%d -> canvas %dx%d -> %s"
            % (input_path, width, height, cell, ds_w, ds_h, canvas_w, canvas_h, output_path)
        )

    return {
        "input_size": (width, height),
        "cell": cell,
        "downsampled_size": (ds_w, ds_h),
        "canvas_size": (canvas_w, canvas_h),
    }


def _parse_canvas(value: str):
    try:
        w_str, h_str = value.lower().split("x")
        return int(w_str), int(h_str)
    except (ValueError, AttributeError):
        raise argparse.ArgumentTypeError("--canvas must look like WIDTHxHEIGHT, e.g. 64x104")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("input", help="source PNG (as generated / exported)")
    parser.add_argument("output", help="destination PNG (game-ready)")
    parser.add_argument(
        "--canvas", required=True, type=_parse_canvas,
        help="fixed output canvas, e.g. 64x104 (combatant), 390x360 (backdrop), "
             "96x96 (effect), 160x160 (large effect) — see docs/ART-BIBLE.md",
    )
    parser.add_argument("--cell", type=int, default=None, help="override auto-detected cell size")
    parser.add_argument(
        "--alpha-threshold", type=int, default=DEFAULT_ALPHA_THRESHOLD,
        help="alpha value (0-255) at/above which a pixel is treated as opaque",
    )
    args = parser.parse_args(argv)

    canvas_w, canvas_h = args.canvas
    pixelize(
        args.input, args.output, canvas_w, canvas_h,
        cell_override=args.cell,
        alpha_threshold=args.alpha_threshold,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
