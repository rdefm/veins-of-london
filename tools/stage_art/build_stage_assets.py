"""Writes stage PNGs and their generated manifests.

    python tools/stage_art/build_stage_assets.py

Outputs:
  assets/stages/rigs/archie/*.png       + data/stages/rigs/archie.json
  assets/stages/sets/spitalfields/*.png + data/stages/sets/spitalfields.json
Then run `godot --headless --import` so Godot picks the PNGs up.
Per-event direction (data/stages/<event_id>.json) is hand-authored, not generated.
"""
import json
from pathlib import Path

import rig_archie as rig
import set_spitalfields as st

ROOT = Path(__file__).resolve().parents[2]


def write_images(images, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, img in images.items():
        img.save(out_dir / name)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def rig_manifest():
    frames = lambda prefix, names: {n: "%s_%s.png" % (prefix, n) for n in names}
    return {
        "id": "archie",
        "dir": "res://assets/stages/rigs/archie/",
        "canvas": [rig.W, rig.H],
        "origin": list(rig.ORIGIN),
        "anchors": rig.anchors(),
        "order": ["shadow", "legs", "torso", "head", "eyes", "brows", "mouth", "arm_r", "arm_l"],
        "parts": {
            "shadow": {"group": "root", "frames": {"base": "shadow.png"}},
            "legs": {"group": "root", "frames": {"base": "legs.png"}},
            "torso": {"group": "body", "frames": {"base": "torso.png"}},
            "head": {"group": "head", "frames": {"base": "head.png"}},
            "eyes": {"group": "head", "frames": frames("eyes", rig.EYES.keys())},
            "brows": {"group": "head", "frames": frames("brows", ["normal", "up", "knit", "quirk"])},
            "mouth": {"group": "head", "frames": frames("mouth", rig.MOUTHS.keys())},
            "arm_r": {"group": "body", "frames": frames("arm_r", rig.ARM_R.keys())},
            "arm_l": {"group": "body", "frames": frames("arm_l", rig.ARM_L.keys())},
        },
        "defaults": {"arm_l": "hold", "arm_r": "phone_low", "eyes": "open", "brows": "normal", "mouth": "closed", "tilt": 0},
        "mouth_states": {"chew": ["chew_a", "chew_b"]},
        "talk_frames": ["talk_a", "talk_b", "closed", "talk_b", "chew_a", "talk_a"],
        "actions": {
            "wave": [
                {"t": 0.0, "set": {"arm_l": "wave_a"}}, {"t": 0.18, "set": {"arm_l": "wave_b"}},
                {"t": 0.36, "set": {"arm_l": "wave_a"}}, {"t": 0.54, "set": {"arm_l": "wave_b"}},
                {"t": 0.72, "set": {"arm_l": "wave_a"}}, {"t": 0.95, "set": {"arm_l": "hold"}},
            ],
            "bite": [{"t": 0.0, "set": {"arm_l": "eat"}}, {"t": 0.75, "set": {"arm_l": "hold"}}],
            "throw": [
                {"t": 0.0, "set": {"arm_l": "crumple"}}, {"t": 0.6, "set": {"arm_l": "throw_back"}},
                {"t": 0.9, "set": {"arm_l": "throw_release"}}, {"t": 1.5, "set": {"arm_l": "rest"}},
            ],
        },
        "px": 1,
        "behaviour": {
            "blink_every": [2.2, 5.0], "blink_len": 0.12,
            "chew_step": 0.2, "chew_run": 4, "chew_pause": 0.6,
            "talk_step": 0.11, "talk_per_char": 0.032, "talk_min": 1.0, "talk_max": 6.0,
            "breathe_period": 3.2, "breathe_jitter": 0.2,
            "idle_tilt": 1.2, "idle_tilt_every": [6.0, 12.0],
            "tilt_stiffness": 70.0, "tilt_damping": 8.0,
            "talk_nod": 2.5, "talk_nod_chance": 0.4, "talk_dip_chance": 0.15,
            "turn_len": 0.16, "effort_dip": 0.14, "arm_tween": 0.18,
        },
    }


def set_manifest():
    walker_frames = lambda k: ["%s_%d.png" % (k, i) for i in range(4)]
    return {
        "id": "spitalfields",
        "dir": "res://assets/stages/sets/spitalfields/",
        "design_size": [180, 240],
        "world": [st.WORLD_W, st.WORLD_H],
        "floor_y": st.FLOOR_Y,
        "layers": [
            {"id": "far", "file": "far.png", "parallax": st.FAR_P, "slot": "back"},
            {"id": "market", "file": "market.png", "parallax": 1.0, "slot": "mid"},
            {"id": "fore", "file": "fore.png", "parallax": st.FORE_P, "slot": "front"},
        ],
        "walkers": {
            "parallax": st.FAR_P, "feet_y": st.WALK_Y, "size": [st.WALK_W, st.WALK_H], "frame_time": 0.17,
            "range": [-20, st.WORLD_W + 20],
            "list": [
                {"frames": walker_frames("walker_a"), "x": 120, "speed": 13, "dir": 1},
                {"frames": walker_frames("walker_b"), "x": 250, "speed": 11, "dir": -1},
                {"frames": walker_frames("walker_c"), "x": 30, "speed": 15, "dir": 1},
            ],
        },
        "ambient": [
            {"id": "vendor", "frames": ["vendor_0.png", "vendor_1.png", "vendor_2.png"], "pos": list(st.VENDOR_POS),
             "hold": [[2.0, 4.5], [0.5, 0.8], [1.0, 1.8]]},
        ],
        "lights": {"file": "glow.png", "points": [list(p) for p in st.light_positions()]},
        "objects": {
            "bin": {"x": 72, "back": "bin_back.png", "front": "bin_front.png", "size": [st.BIN_W, st.BIN_H], "mouth": [11, 5]},
        },
        "props": {"falafel_crumb": "crumb.png", "wrapper": "wrapper.png"},
    }


def main():
    write_images(rig.build(), ROOT / "assets/stages/rigs/archie")
    write_images(st.build(), ROOT / "assets/stages/sets/spitalfields")
    write_json(ROOT / "data/stages/rigs/archie.json", rig_manifest())
    write_json(ROOT / "data/stages/sets/spitalfields.json", set_manifest())


if __name__ == "__main__":
    main()
