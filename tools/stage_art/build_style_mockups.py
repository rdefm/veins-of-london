"""Writes the three Archie style mock-up rigs and a comparison sheet.

    python tools/stage_art/build_style_mockups.py [sheet.png]

Outputs assets/stages/rigs/archie_<style>/*.png + data/stages/rigs/archie_<style>.json
(same frames/actions as the archie rig). Swap one in by setting the actor's
"rig" in data/stages/archie_craft_chat.json, or pass the rig id to
scripts/debug_stage_screenshot.gd.
"""
import sys

from PIL import Image

import build_stage_assets as bsa
import preview_rig
import rig_archie
import rig_archie_styles as styles
from raster import upscale


def manifest(st):
    m = bsa.rig_manifest()
    m["id"] = "archie_" + st["name"]
    m["dir"] = "res://assets/stages/rigs/archie_%s/" % st["name"]
    m["anchors"] = styles.anchors(st)
    return m


def sheet(path):
    rows = [("current", rig_archie.build())] + [(n, styles.build(st)) for n, st in styles.STYLES.items()]
    bg = Image.open(bsa.ROOT / "assets/stages/sets/spitalfields/market.png").convert("RGBA")
    poses = preview_rig.POSES[:4]
    out = Image.new("RGBA", (rig_archie.W * len(poses), rig_archie.H * len(rows)), (0, 0, 0, 255))
    for j, (_, imgs) in enumerate(rows):
        for i, pose in enumerate(poses):
            tile = bg.crop((182, 300 - 159 - 9, 182 + 96, 300 - 159 - 9 + 168)).copy()
            tile.alpha_composite(preview_rig.compose(imgs, pose))
            out.alpha_composite(tile, (i * rig_archie.W, j * rig_archie.H))
    upscale(out, 2).save(path)


def main():
    for st in styles.STYLES.values():
        rid = "archie_" + st["name"]
        bsa.write_images(styles.build(st), bsa.ROOT / "assets/stages/rigs" / rid)
        bsa.write_json(bsa.ROOT / ("data/stages/rigs/%s.json" % rid), manifest(st))
    if len(sys.argv) > 1:
        sheet(sys.argv[1])


if __name__ == "__main__":
    main()
