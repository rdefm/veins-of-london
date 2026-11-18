import os
import random
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(HERE, "..", ".."))

from PIL import Image, ImageFilter  # noqa: E402

import pixel_grid  # noqa: E402

PALETTE = pixel_grid.palette_rgb(os.path.join(HERE, "..", "..", "..", "data", "palette.json"))


def grid_image(scale=4, w=40, h=60, ncol=16, seed=1):
    rnd = random.Random(seed)
    cols = [tuple(int(v) for v in PALETTE[i]) for i in rnd.sample(range(len(PALETTE)), ncol)]
    im = Image.new("RGB", (w, h))
    # blocky regions so the native image is not pure noise
    for y in range(h):
        for x in range(w):
            im.putpixel((x, y), cols[((x // 3) * 7 + (y // 3) * 5 + rnd.randrange(2)) % ncol])
    return im.resize((w * scale, h * scale), Image.NEAREST)


class Metrics(unittest.TestCase):
    def test_clean_grid(self):
        m = pixel_grid.pixel_metrics(grid_image(), PALETTE)
        self.assertEqual(m["gridScale"], 4)
        self.assertGreater(m["gridRegularity"], 0.9)
        self.assertLessEqual(m["colours"], 16)
        self.assertLess(m["paletteDistance"], 0.5)

    def test_blurred_is_clearly_worse(self):
        clean = pixel_grid.pixel_metrics(grid_image(), PALETTE)
        blur = pixel_grid.pixel_metrics(grid_image().filter(ImageFilter.GaussianBlur(2)), PALETTE)
        self.assertLess(blur["gridRegularity"], clean["gridRegularity"] - 0.3)
        self.assertGreater(blur["colours"], clean["colours"] * 3)
        self.assertGreater(blur["paletteDistance"], clean["paletteDistance"] + 3)

    def test_no_palette(self):
        self.assertIsNone(pixel_grid.pixel_metrics(grid_image())["paletteDistance"])


class GridLock(unittest.TestCase):
    def test_dominant_recovers_clean_grid(self):
        native = grid_image(scale=1)
        locked = pixel_grid.grid_lock(grid_image(scale=4), 4, "dominant")
        self.assertEqual(locked.size, native.size)
        self.assertEqual(list(locked.getdata()), list(native.getdata()))

    def test_dominant_takes_majority_not_blend(self):
        im = Image.new("RGB", (4, 4), (200, 0, 0))
        for x, y in ((0, 0), (1, 0), (0, 1)):
            im.putpixel((x, y), (0, 0, 200))
        self.assertEqual(pixel_grid.grid_lock(im, 4, "dominant").getpixel((0, 0)), (200, 0, 0))
        mean = pixel_grid.grid_lock(im, 4, "mean").getpixel((0, 0))
        self.assertNotIn(mean, ((200, 0, 0), (0, 0, 200)))

    def test_offset_realigns_shifted_grid(self):
        shifted = Image.new("RGB", (42, 62))
        shifted.paste(grid_image(w=10, h=15), (2, 2))
        locked = pixel_grid.grid_lock(shifted, 4, "dominant", (2, 2))
        self.assertEqual(locked.size, (10, 15))
        self.assertEqual(list(locked.getdata()), list(grid_image(scale=1, w=10, h=15).getdata()))


if __name__ == "__main__":
    unittest.main()
