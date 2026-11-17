import copy
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from PIL import Image  # noqa: E402

import judge  # noqa: E402
from backend import BackendError, FakeBackend  # noqa: E402

CANVAS = [8, 12]
CHECKLIST_REPLY = {"items": [{"category": "pose", "text": "Leaning on the wall."},
                             {"category": "props", "text": "Carrier bag in hand."}]}
BOARD = {
    "eventId": "ev", "canvas": CANVAS, "present": {},
    "cards": [{"branch": "main", "key": "c1", "speaker": None, "text": "Half ten."}],
    "shots": [{"id": "S1", "title": "Wall", "cards": "main: c1", "job": "Archie waits.", "prompt": "Draw Archie.",
               "attach": ["assets/character-references/Archie/Archie_biz_sprite_master.png"],
               "unseen": "The car."}],
}


def png(path, size=(8, 12), colour=(120, 80, 40)):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.new("RGB", size, colour).save(path)


def good_reply(checklist_ids, overrides=None, scores=None):
    checks = [{"id": i, "result": "pass", "why": "ok"} for i in checklist_ids]
    for k, v in (overrides or {}).items():
        for c in checks:
            if c["id"] == k:
                c["result"] = v
    s = {"brief": 3.5, "style": 3.5, "cast": {"Archie": 3.5}}
    s.update(scores or {})
    return {"checks": checks, "scores": s}


IDS = ["cast-Archie", "cast-only", "m1", "m2", "h-text", "h-face", "h-bottom", "h-crop"]


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = judge.Workspace(self.tmp)
        self.board = copy.deepcopy(BOARD)
        self.write_board()
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        self.draft = os.path.join(self.tmp, "assets/reference-plates/ev_S1_take1.png")
        png(self.draft, tuple(CANVAS))

    def write_board(self):
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)

    def run_judge(self, queue, **kw):
        be = FakeBackend(queue=queue)
        out = judge.judge_draft(self.ws, be, "ev", "S1", self.draft, **kw)
        return out, be

    def tree(self):
        found = set()
        for d, _, fs in os.walk(self.tmp):
            for f in fs:
                found.add(os.path.relpath(os.path.join(d, f), self.tmp).replace(os.sep, "/"))
        return found


class PassRule(Base):
    def test_all_good_passes_and_writes_next_to_board(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        self.assertEqual(out["verdict"], "pass")
        p = os.path.join(self.tmp, ".scratch/event-art/ev/judgements/ev_S1_take1.judgement.json")
        saved = judge.read_json(p)
        self.assertEqual(saved["schema"], 1)
        self.assertEqual(saved["draft"], "assets/reference-plates/ev_S1_take1.png")
        self.assertEqual(saved["metrics"]["size"], CANVAS)

    def test_hard_fail(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"h-text": "fail"})])
        self.assertEqual(out["verdict"], "fail")

    def test_missing_cast_fails(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"cast-Archie": "fail"})])
        self.assertEqual(out["verdict"], "fail")

    def test_non_hard_non_presence_fail_does_not_fail_by_itself(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"m1": "fail"})])
        self.assertEqual(out["verdict"], "pass")

    def test_unsure_never_fails(self):
        ov = {i: "unsure" for i in IDS}
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, ov)])
        self.assertEqual(out["verdict"], "pass")

    def test_size_mismatch_fails(self):
        png(self.draft, (8, 13))
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        self.assertEqual(out["verdict"], "fail")
        self.assertEqual(out["metrics"]["size"], [8, 13])

    def test_threshold_equal_passes_below_fails(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, scores={"style": 3.0})])
        self.assertEqual(out["verdict"], "pass")
        out, _ = self.run_judge([good_reply(IDS, scores={"style": 2.9})])
        self.assertEqual(out["verdict"], "fail")

    def test_custom_threshold(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, scores={"brief": 3.2})], threshold=3.5)
        self.assertEqual(out["verdict"], "fail")

    def test_model_cannot_set_verdict(self):
        r = good_reply(IDS, {"h-text": "fail"})
        r["verdict"] = "pass"
        out, _ = self.run_judge([CHECKLIST_REPLY, r])
        self.assertEqual(out["verdict"], "fail")


class Correction(Base):
    FIX = {"changes": "move the carrier bag to his left hand and remove the sign text."}

    def test_fail_makes_one_separate_call_stored_with_tail(self):
        out, be = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"h-text": "fail"}), self.FIX])
        self.assertEqual(len(be.calls), 3)
        self.assertTrue(be.calls[2]["key"].startswith("correct__S1__"))
        self.assertIn("h-text", be.calls[2]["instruction"])
        self.assertEqual(out["correctionPrompt"], "Same image, change only: move the carrier bag to his left hand "
                         "and remove the sign text. Keep everything else identical.")
        saved = judge.read_json(judge.judgement_path(self.ws, "ev", self.draft))
        self.assertEqual(saved["correctionPrompt"], out["correctionPrompt"])

    def test_pass_makes_no_correction_call(self):
        out, be = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        self.assertEqual(len(be.calls), 2)
        self.assertIsNone(out["correctionPrompt"])

    def test_unjudged_makes_no_correction_call(self):
        out, be = self.run_judge([CHECKLIST_REPLY, {"bad": 1}, {"bad": 1}, self.FIX])
        self.assertEqual(out["verdict"], "unjudged")
        self.assertEqual(len(be.calls), 3)
        self.assertIsNone(out["correctionPrompt"])

    def test_correction_failure_keeps_verdict(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"h-text": "fail"}), BackendError("boom")])
        self.assertEqual(out["verdict"], "fail")
        self.assertIsNone(out["correctionPrompt"])
        self.assertIn("boom", out["correctionError"])

    def test_rejudge_regenerates(self):
        self.run_judge([CHECKLIST_REPLY, good_reply(IDS, {"h-text": "fail"}), self.FIX])
        out, be = self.run_judge([good_reply(IDS, {"h-text": "fail"}), {"changes": "remove the sign"}])
        self.assertEqual(len(be.calls), 2)
        self.assertTrue(out["correctionPrompt"].startswith("Same image, change only: remove the sign."))


class Checklist(Base):
    def test_reuse_then_rebuild_on_brief_change(self):
        out, be = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        self.assertEqual([c["key"] for c in be.calls], ["checklist__S1", "judge__S1__ev_S1_take1"])
        saved = judge.read_json(os.path.join(self.ws.event_dir("ev"), "checklists/S1.checklist.json"))
        self.assertEqual(saved["briefHash"], out["briefHash"])
        cats = {i["category"] for i in saved["items"]}
        self.assertTrue(cats <= set(judge.CATEGORIES))
        self.assertEqual(sum(1 for i in saved["items"] if i["hard"]), 4)

        out, be = self.run_judge([good_reply(IDS)])
        self.assertEqual([c["key"] for c in be.calls], ["judge__S1__ev_S1_take1"])

        for field, val in (("job", "Archie leaves."), ("unseen", "Nothing."), ("prompt", "New."),
                           ("attach", [BOARD["shots"][0]["attach"][0], "x.png"])):
            self.board["shots"][0][field] = val
            self.write_board()
            out, be = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
            self.assertEqual(be.calls[0]["key"], "checklist__S1", field)

        self.board["cards"][0]["text"] = "Changed."
        self.write_board()
        out, be = self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        self.assertEqual(be.calls[0]["key"], "checklist__S1")

    def test_hard_items_cover_required_rules(self):
        self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        saved = judge.read_json(os.path.join(self.ws.event_dir("ev"), "checklists/S1.checklist.json"))
        text = " ".join(i["text"].lower() for i in saved["items"] if i["hard"])
        for needle in ("text", "face", "bottom", "crop"):
            self.assertIn(needle, text)


class Identity(Base):
    def test_cast_without_reference_is_unchecked(self):
        self.board["shots"][0]["attach"].append("assets/character-references/Des/Des_biz_sprite_master.png")
        self.write_board()
        ids = ["cast-Archie", "cast-Des", "cast-only", "m1", "m2", "h-text", "h-face", "h-bottom", "h-crop"]
        out, be = self.run_judge([CHECKLIST_REPLY, good_reply(ids)])
        self.assertEqual(out["scores"]["cast"]["Des"], {"identity": "unchecked"})
        self.assertEqual(out["scores"]["cast"]["Archie"], 3.5)
        self.assertEqual(out["verdict"], "pass")
        labels = [l for l, _ in be.calls[-1]["images"]]
        self.assertFalse(any("Des" in l for l in labels))


class Retry(Base):
    def test_malformed_then_good_is_retried_once(self):
        out, be = self.run_judge([CHECKLIST_REPLY, "not json at all", good_reply(IDS)])
        self.assertEqual(out["verdict"], "pass")
        self.assertEqual(len(be.calls), 3)

    def test_two_bad_replies_is_unjudged_with_error(self):
        out, be = self.run_judge([CHECKLIST_REPLY, {"checks": []}, BackendError("boom")])
        self.assertEqual(out["verdict"], "unjudged")
        self.assertTrue(out["error"])
        saved = judge.read_json(os.path.join(self.ws.event_dir("ev"),
                                            "judgements/ev_S1_take1.judgement.json"))
        self.assertEqual(saved["verdict"], "unjudged")
        self.assertEqual(len(be.calls), 3)

    def test_out_of_range_score_is_malformed(self):
        out, _ = self.run_judge([CHECKLIST_REPLY, good_reply(IDS, scores={"style": 9}), good_reply(IDS, scores={"style": 9})])
        self.assertEqual(out["verdict"], "unjudged")

    def test_checklist_failure_is_unjudged(self):
        out, _ = self.run_judge([BackendError("x"), BackendError("y")])
        self.assertEqual(out["verdict"], "unjudged")


class Confinement(Base):
    def test_writes_only_inside_workspace(self):
        before = self.tree()
        self.run_judge([CHECKLIST_REPLY, good_reply(IDS)])
        new = self.tree() - before
        self.assertTrue(new)
        for p in new:
            self.assertTrue(p.startswith(".scratch/event-art/ev/"), p)

    def test_write_json_refuses_outside(self):
        with self.assertRaises(judge.JudgeError):
            self.ws.write_json(os.path.join(self.tmp, "assets", "x.json"), {})
        with self.assertRaises(judge.JudgeError):
            self.ws.write_json(os.path.join(self.tmp, ".scratch", "event-art", "..", "x.json"), {})


class Recorded(Base):
    """Replays replies recorded from a real Claude CLI smoke run (intro-proposal2 / S1)."""

    def test_replay_recording(self):
        rec = os.path.join(HERE, "fixtures", "recordings")
        if not os.path.isdir(rec):
            self.skipTest("no recordings")
        board = judge.read_json(os.path.join(rec, "board.json"))
        self.board = board
        self.write_board()
        draft = os.path.join(self.tmp, "assets/reference-plates/mile_end_yard_S1_archie_wall_lean.png")
        png(draft, tuple(judge.canvas_of(board)))
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        out = judge.judge_draft(self.ws, FakeBackend(replies_dir=rec), "ev", "S1", draft)
        self.assertIn(out["verdict"], ("pass", "fail"))
        self.assertTrue(out["checks"])


if __name__ == "__main__":
    unittest.main()
