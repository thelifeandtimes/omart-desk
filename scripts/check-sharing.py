#!/usr/bin/env python3
"""Integration regression checks against the three local omart-dev fakeships.

Temporarily changes their pals/config, publishes uniquely named fixtures, and
restores the previous pals/config. Requires urbit, nc, and a running fakenet.
"""
from __future__ import annotations

import http.cookiejar
import json
from pathlib import Path
import re
import subprocess
import time
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
PORTS = {"nec": 8091, "bus": 8092, "tyr": 8093}
DEFAULT = {"hops": 1, "hear": "targets", "tell": "targets", "pass": False}


def conn(ship, source):
    socket = ROOT / ".dev/fakenet" / ship / ".urb/conn.sock"
    if ship not in PORTS or not socket.is_socket():
        raise RuntimeError(f"Missing local fakeship: {ship}")
    source = source.replace("\\", "\\\\").replace("'", "\\'")
    request = f"[0 %fyrd %base %khan-eval %noun %ted-eval '{source}']\n"

    def run(args, data):
        return subprocess.run(args, input=data, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, check=True, timeout=30).stdout

    jam = run(["urbit", "eval", "-jn"], request.encode())
    answer = run(["nc", "-U", "-W", "30", str(socket)], jam)
    rendered = run(["urbit", "eval", "-cn"], answer).decode().strip()
    if not rendered.startswith("[0 %avow 0 %noun "):
        raise RuntimeError(rendered)
    return rendered


class Ship:
    def __init__(self, ship):
        self.ship = ship
        self.url = f"http://127.0.0.1:{PORTS[ship]}"
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        code = conn(ship, '=/  m  (strand ,vase)  ;<  =bowl:spider  bind:m  get-bowl  '
                    '(pure:m !>((scot %p .^(@p %j /(scot %p our.bowl)/code/'
                    '(scot %da now.bowl)/(scot %p our.bowl)))))')
        password = re.search(r"~[a-z-]+", code)[0][1:]
        self.opener.open(self.url + "/~/login", timeout=15,
                         data=urllib.parse.urlencode({"password": password}).encode()).read()
        assert self.api("pals.json")["our"] == "~" + ship

    def api(self, path, body=None):
        req = urllib.request.Request(self.url + "/omart/" + path,
                                     headers={"content-type": "application/json",
                                              "x-omart": "1", "Origin": self.url},
                                     data=None if body is None else json.dumps(body).encode())
        with self.opener.open(req, timeout=15) as response:
            return json.load(response)

    def ids(self):
        return {p["id"] for p in self.api("listings.json")}

    def publish(self, id):
        return self.api("publish", {"id": id, "name": id, "description": "Fakenet regression fixture",
                                   "git": "https://example.com/omart-test.git", "version": "0.1.0",
                                   "author": "fakenet", "kinds": ["bar-widget"], "tags": ["fakenet"]})


def wait_for(label, predicate, timeout=30):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.2)
    raise AssertionError(f"Timed out: {label}")


def subscriptions(ship):
    return conn(ship, '=/  m  (strand ,vase)  ;<  data=*  bind:m  '
                '(scry * /gx/omart/dbug/subscriptions/noun)  (pure:m !>(data))')


def watching(ship, peer):
    # The rendered wire occurs only in wex (outbound watches), not sup.
    return f"%gossip %gossip '~{peer}'" in subscriptions(ship)


def main():
    ships = {name: Ship(name) for name in PORTS}
    before = {name: (ship.api("config.json"), ship.api("pals.json")["pals"])
              for name, ship in ships.items()}
    fixtures = []
    prefix = "check-" + uuid.uuid4().hex[:10]
    nec, bus, tyr = (ships[name] for name in PORTS)

    def publish(ship, suffix):
        id = prefix + "-" + suffix
        ship.publish(id)
        fixtures.append((ship, id))
        return id

    def seen(id, *peers):
        wait_for(f"{id} reaches {','.join(s.ship for s in peers)}", lambda: all(id in s.ids() for s in peers), timeout=12)

    try:
        for ship in ships.values():
            ship.api("config", DEFAULT)
            for peer in ships:
                if peer != ship.ship:
                    ship.api("part", {"ship": "~" + peer})
        wait_for("all test edges removed", lambda: all(
            not any(p["target"] or p["leech"] for p in s.api("pals.json")["pals"]
                    if p["ship"][1:] in PORTS) for s in ships.values()))

        wait_for("old watches removed", lambda: all(
            not watching(a, b) for a in ships for b in ships if a != b))

        nec.api("meet", {"ship": "~bus"})
        wait_for("bus sees incoming pal", lambda: any(p["ship"] == "~nec" and p["leech"]
                 for p in bus.api("pals.json")["pals"]))
        # Ensure the first watch has been rejected before reciprocating.
        time.sleep(1)
        assert not watching("nec", "bus"), "one-sided default watch should be rejected"
        early = publish(bus, "before-add-back")
        assert early not in nec.ids()
        bus.api("meet", {"ship": "~nec"})
        seen(early, nec)
        live = publish(bus, "live-bus")
        seen(live, nec)
        reverse = publish(nec, "live-nec")
        seen(reverse, bus)
        print("PASS: delayed add-back repairs the rejected watch; catch-up and live delivery work both ways", flush=True)

        nec.api("config", {**DEFAULT, "hear": "anybody"})
        bus.api("config", {**DEFAULT, "tell": "anybody"})
        bus.api("part", {"ship": "~nec"})
        wait_for("nec retains a one-sided target", lambda: any(
            p["ship"] == "~bus" and p["target"] and not p["leech"]
            for p in nec.api("pals.json")["pals"]))
        time.sleep(1)
        assert watching("nec", "bus"), "losing a leech must not remove a retained target"
        retained = publish(bus, "retained-target")
        seen(retained, nec)
        bus.api("meet", {"ship": "~nec"})
        nec.api("config", DEFAULT)
        bus.api("config", DEFAULT)
        print("PASS: a retained target remains subscribed when its leech status changes", flush=True)

        # No pal event occurs when only the publisher's tell policy changes.
        # A previously rejected subscriber otherwise waits for the 30m timer.
        bus.api("part", {"ship": "~nec"})
        bus.api("config", {**DEFAULT, "tell": "mutuals"})
        wait_for("policy change removes nec's subscription", lambda: not watching("nec", "bus"))
        missed = publish(bus, "before-retry")
        assert missed not in nec.ids()
        bus.api("config", {**DEFAULT, "tell": "anybody"})
        before_retry = nec.api("config.json")
        nec.api("retry", {})
        seen(missed, nec)
        assert nec.api("config.json") == before_retry
        assert next(p for p in nec.api("pals.json")["pals"] if p["ship"] == "~bus")["connection"] == "connected"
        # The dojo action uses the same retry helper, with active watches kept.
        conn("nec", '=/  m  (strand ,vase)  ;<  ~  bind:m  '
             '(poke [~nec %omart] %omart-action !>([%retry ~]))  (pure:m !>(%ok))')
        live_retry = publish(bus, "after-retry")
        seen(live_retry, nec)
        bus.api("meet", {"ship": "~nec"})
        bus.api("config", DEFAULT)
        print("PASS: explicit retry catches up after a tell-policy change and preserves config; dojo retry works", flush=True)

        bus.api("meet", {"ship": "~tyr"})
        time.sleep(1)
        tyr.api("meet", {"ship": "~bus"})
        wait_for("bus watches tyr", lambda: watching("bus", "tyr"))
        wait_for("tyr watches bus", lambda: watching("tyr", "bus"))
        one = publish(nec, "one-hop")
        seen(one, bus)
        time.sleep(1)
        assert one not in tyr.ids(), "one-hop publication escaped direct pals"
        tyr.api("part", {"ship": "~bus"})
        wait_for("tyr disconnects from bus", lambda: not watching("tyr", "bus"))
        tyr.api("meet", {"ship": "~bus"})
        wait_for("tyr reconnects to bus", lambda: watching("tyr", "bus"))
        time.sleep(1)
        assert one not in tyr.ids(), "reconnect re-originated a cached one-hop listing"
        nec.api("config", {**DEFAULT, "hops": 2})
        two = publish(nec, "two-hop")
        seen(two, bus, tyr)
        nec.api("retract", {"id": two})
        wait_for("two-hop retraction", lambda: all(two not in s.ids() for s in ships.values()))
        print("PASS: one-hop boundary, two-hop live relay, and two-hop retraction", flush=True)

        nec.api("config", {**DEFAULT, "hops": 0})
        local = publish(nec, "local-only")
        assert local in nec.ids()
        time.sleep(1)
        assert local not in bus.ids() and local not in tyr.ids()
        nec.api("retract", {"id": local})
        assert local not in nec.ids()
        print("PASS: zero-hop publish/retract succeeds locally without broadcasting", flush=True)
    finally:
        # Restore all test edges for cleanup, then restore the original graph.
        for ship in ships.values():
            ship.api("config", DEFAULT)
            for peer in ships:
                if peer != ship.ship:
                    ship.api("meet", {"ship": "~" + peer})
        try:
            for a in ships:
                for b in ships:
                    if a != b:
                        wait_for(f"cleanup watch {a}->{b}", lambda a=a, b=b: watching(a, b))
            for ship, id in fixtures:
                if id in ship.ids():
                    ship.api("retract", {"id": id})
            wait_for("fixture cleanup", lambda: not any(
                id in s.ids() for _, id in fixtures for s in ships.values()))
        finally:
            for name, ship in ships.items():
                cfg, pals = before[name]
                targets = {p["ship"] for p in pals if p["target"]}
                for peer in ships:
                    if peer != name and "~" + peer not in targets:
                        ship.api("part", {"ship": "~" + peer})
                ship.api("config", cfg)
            print("Restored pals/config.", flush=True)



if __name__ == "__main__":
    main()
