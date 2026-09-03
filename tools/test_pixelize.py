#!/usr/bin/env python3
"""End-to-end self-test for tools/pixelize.py — no test framework, no
external deps. Builds a synthetic "generated pixel art" PNG (upscaled
blocky art with anti-aliased fringe, the way an image model actually
produces it), runs it through the full pipeline, and asserts every stage
behaved. Also unit-tests the fringe-speck-removal step directly, since it
depends on exact pixel adjacency that's easy to miss by accident in a
full-image fixture.

    python3 tools/test_pixelize.py
"""

import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_io import read_png, write_png  # noqa: E402
from pixelize import (  # noqa: E402
    detect_cell_size,
    pixelize,
    strip_fringe,
)

CELL = 4  # native art pixel = 4x4 real pixels, as if exported at 4x
NATIVE_GRID = 12  # 12x12 native cells; the sprite occupies an 8x8 inner region
SPRITE_LO, SPRITE_HI = 2, 10  # native cell range (exclusive hi) the sprite occupies

TRANSPARENT = (0, 0, 0, 0)
BODY = (0xE0, 0x40, 0x30, 255)     # bright red sprite body
OUTLINE = (0x10, 0x10, 0x10, 255)  # near-black border


def _make_test_image():
    """NATIVE_GRID x NATIVE_GRID native cells upscaled by CELL, with an 8x8
    opaque sprite centred in a transparent margin, blended fringe pixels
    along the silhouette edge, and one fully-isolated opaque speck far from
    the sprite (in the margin, aligned to a downsample sample point)."""
    native = [[TRANSPARENT] * NATIVE_GRID for _ in range(NATIVE_GRID)]
    for ny in range(SPRITE_LO, SPRITE_HI):
        for nx in range(SPRITE_LO, SPRITE_HI):
            on_edge = nx in (SPRITE_LO, SPRITE_HI - 1) or ny in (SPRITE_LO, SPRITE_HI - 1)
            native[ny][nx] = OUTLINE if on_edge else BODY

    width = height = NATIVE_GRID * CELL
    pixels = [TRANSPARENT] * (width * height)
    for ny in range(NATIVE_GRID):
        for nx in range(NATIVE_GRID):
            r, g, b, a = native[ny][nx]
            for dy in range(CELL):
                for dx in range(CELL):
                    pixels[(ny * CELL + dy) * width + (nx * CELL + dx)] = (r, g, b, a)

    def in_bounds(x, y):
        return 0 <= x < width and 0 <= y < height

    fringe_added = 0
    opaque_coords = [
        (x, y) for y in range(height) for x in range(width) if pixels[y * width + x][3] != 0
    ]
    for x, y in opaque_coords:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if in_bounds(nx, ny) and pixels[ny * width + nx][3] == 0:
                pixels[ny * width + nx] = (0xE0, 0x40, 0x30, 90)  # semi-transparent blend
                fringe_added += 1

    # Isolated single-pixel speck: lands exactly on the (0, 0) downsample
    # sample point, far from the sprite and its fringe, with fully
    # transparent neighbours on every side.
    speck_native = (0, 0)
    speck_x, speck_y = speck_native[0] * CELL, speck_native[1] * CELL
    pixels[speck_y * width + speck_x] = (0x33, 0x99, 0xCC, 255)

    return width, height, pixels, fringe_added


def _assert(condition, message):
    if not condition:
        raise AssertionError(message)


def test_strip_fringe_drops_isolated_speck():
    """Direct unit test: a lone opaque pixel with no opaque orthogonal
    neighbour is fringe, even if it's nowhere near a real edge."""
    w, h = 3, 3
    pixels = [TRANSPARENT] * (w * h)
    pixels[4] = (255, 0, 0, 255)  # centre pixel, isolated
    out = strip_fringe(w, h, pixels)
    _assert(out[4] == TRANSPARENT, "isolated speck should have been stripped, got %r" % (out[4],))

    # A pixel with one opaque neighbour must survive.
    pixels2 = [TRANSPARENT] * (w * h)
    pixels2[4] = (255, 0, 0, 255)
    pixels2[5] = (255, 0, 0, 255)  # right neighbour of centre
    out2 = strip_fringe(w, h, pixels2)
    _assert(out2[4][3] == 255 and out2[5][3] == 255, "connected opaque pixels should survive")


def test_strip_fringe_binarizes_alpha():
    # Middle two pixels are opaque and connected to each other (so the
    # isolated-speck pass doesn't also strip them); this isolates the
    # alpha-threshold behaviour from the connectivity behaviour.
    w, h = 4, 1
    pixels = [(10, 20, 30, 90), (10, 20, 30, 200), (10, 20, 30, 200), (10, 20, 30, 90)]
    out = strip_fringe(w, h, pixels, alpha_threshold=128)
    _assert(out[0] == TRANSPARENT, "sub-threshold alpha should become fully transparent")
    _assert(out[3] == TRANSPARENT, "sub-threshold alpha should become fully transparent")
    _assert(out[1] == (10, 20, 30, 255), "at/above-threshold alpha should become fully opaque")
    _assert(out[2] == (10, 20, 30, 255), "at/above-threshold alpha should become fully opaque")


def test_pipeline_end_to_end():
    width, height, pixels, fringe_added = _make_test_image()
    _assert(fringe_added > 0, "test fixture should contain fringe pixels")

    with tempfile.TemporaryDirectory() as tmp:
        src_path = os.path.join(tmp, "src.png")
        out_path = os.path.join(tmp, "out.png")
        write_png(src_path, width, height, pixels)

        # round-trip sanity: our own reader must reproduce what we wrote
        rt_w, rt_h, rt_pixels = read_png(src_path)
        _assert((rt_w, rt_h) == (width, height), "PNG round-trip changed dimensions")
        _assert(rt_pixels == pixels, "PNG round-trip changed pixel data")

        # --- cell detection ---
        detected = detect_cell_size(width, height, pixels)
        _assert(detected == CELL, "expected detected cell size %d, got %d" % (CELL, detected))

        # --- full pipeline via the public entry point ---
        canvas_w, canvas_h = 64, 104
        result = pixelize(src_path, out_path, canvas_w, canvas_h, verbose=False)
        _assert(result["cell"] == CELL, "pipeline used wrong cell size: %r" % result)
        _assert(
            result["canvas_size"] == (canvas_w, canvas_h),
            "pipeline reported wrong canvas size: %r" % result,
        )

        out_w, out_h, out_pixels = read_png(out_path)
        _assert((out_w, out_h) == (canvas_w, canvas_h), "output PNG is not the requested canvas size")

        opaque = [(r, g, b) for (r, g, b, a) in out_pixels if a != 0]
        _assert(opaque, "output has no opaque pixels at all")

        # --- fringe stripped: no partially-transparent pixels survive, and
        # the isolated speck (which does survive downsampling, landing on
        # its own sample point) must be gone too ---
        partial_alpha = [a for (_r, _g, _b, a) in out_pixels if 0 < a < 255]
        _assert(not partial_alpha, "found un-binarized alpha values: %r" % partial_alpha[:5])

        # --- downsample + trim: the 8x8 sprite (NATIVE_GRID=12, cell=4 ->
        # 12x12 downsampled) lands inside the 64x104 canvas with exactly
        # its 64 opaque pixels surviving; nothing from the margin does.
        opaque_count = len(opaque)
        _assert(
            opaque_count == 8 * 8,
            "expected 64 opaque pixels (8x8 sprite) after downsample+strip, got %d" % opaque_count,
        )


def run():
    tests = [
        test_strip_fringe_drops_isolated_speck,
        test_strip_fringe_binarizes_alpha,
        test_pipeline_end_to_end,
    ]
    for test in tests:
        test()
    print("tools/pixelize.py self-test: PASS (%d checks)" % len(tests))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(run())
    except AssertionError as e:
        print("tools/pixelize.py self-test: FAIL — %s" % e, file=sys.stderr)
        sys.exit(1)
