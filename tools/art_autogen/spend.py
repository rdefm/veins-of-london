"""Global spend ledger and caps for art autogen.

Ledger: .scratch/event-art/_judge/spend_ledger.json (every image-backend call, all runs and events).
Config: .scratch/event-art/_judge/autogen.json  {"caps": {"perRun": <n>, "perMonth": <n>}}.
A cap is checked before each call against the call's estimated cost; a total exactly at the cap is allowed.
"""
import os

import judge

DEFAULT_CAPS = {"perRun": 2.0, "perMonth": 20.0}


def ledger_path(ws):
    return os.path.join(ws.judge_dir(), "spend_ledger.json")


def config_path(ws):
    return os.path.join(ws.judge_dir(), "autogen.json")


def load_caps(ws):
    cfg = judge.read_json(config_path(ws), {}) or {}
    caps = dict(DEFAULT_CAPS)
    for k, v in (cfg.get("caps") or {}).items():
        if k in caps and v is not None:
            caps[k] = float(v)
    return caps


def load_ledger(ws):
    data = judge.read_json(ledger_path(ws), None)
    if not isinstance(data, dict) or not isinstance(data.get("entries"), list):
        return {"schema": 1, "entries": []}
    return data


def month_of(iso):
    return iso[:7]


def month_total(ledger, month):
    return round(sum(e.get("amount", 0) for e in ledger["entries"] if month_of(e.get("at", "")) == month), 6)


def record(ws, run_id, event_id, shot_id, backend, cost, now=None):
    at = now or judge.now_iso()
    ledger = load_ledger(ws)
    ledger["entries"].append({"at": at, "runId": run_id, "eventId": event_id, "shotId": shot_id,
                              "backend": backend, "amount": cost.get("amount", 0),
                              "currency": cost.get("currency"), "units": cost.get("units")})
    ws.write_json(ledger_path(ws), ledger)


class SpendGuard:
    """Tracks one run's spend against the per-run and per-month caps."""

    def __init__(self, ws, run_id, now=None):
        self.ws = ws
        self.run_id = run_id
        self.now = now
        self.caps = load_caps(ws)
        self.run_total = 0.0

    def _month(self):
        return month_of(self.now or judge.now_iso())

    def month_to_date(self):
        return month_total(load_ledger(self.ws), self._month())

    def check(self, estimate):
        """None if a call costing `estimate` is allowed, else the reason it is refused."""
        eps = 1e-9
        if self.run_total + estimate > self.caps["perRun"] + eps:
            return "per-run cap %s would be exceeded (spent %s, next call %s)" % (
                self.caps["perRun"], round(self.run_total, 6), estimate)
        mtd = self.month_to_date()
        if mtd + estimate > self.caps["perMonth"] + eps:
            return "per-month cap %s would be exceeded (month to date %s, next call %s)" % (
                self.caps["perMonth"], mtd, estimate)
        return None

    def record(self, event_id, shot_id, backend, cost):
        self.run_total = round(self.run_total + cost.get("amount", 0), 6)
        record(self.ws, self.run_id, event_id, shot_id, backend, cost, self.now)


def make_confirm(yes):
    def confirm(estimate, takes):
        if yes:
            return True
        try:
            return input("Estimated cost up to %s for %d take(s). Continue? [y/N] " % (estimate, takes)
                         ).strip().lower() in ("y", "yes")
        except EOFError:
            return False
    return confirm
