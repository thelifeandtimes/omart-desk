#!/usr/bin/env python3
"""Signed distribution tests. Touches only .dev/fakenet/{nec,bus,tyr}."""
from datetime import datetime, timezone, timedelta
from pathlib import Path
import re
import runpy
import time
import uuid

base = runpy.run_path(str(Path(__file__).with_name('check-sharing.py')))
Ship, conn, wait_for = (base[k] for k in ('Ship', 'conn', 'wait_for'))
DEFAULT, ROOT = base['DEFAULT'], base['ROOT']


def evaluate(ship, expression):
    when = (datetime.now(timezone.utc) - timedelta(seconds=1)).strftime('~%Y.%m.%d..%H.%M.%S')
    dep = f"['~{ship}' %omart '{when}' %lib %omart-protocol %hoon ~]"
    source = '  '.join(line.strip() for line in expression.splitlines() if not line.lstrip().startswith('::'))
    try:
        return conn(ship, source, [dep])
    except RuntimeError as error:
        # Keep readable Hoon errors, without flooding the terminal with nouns.
        raw = str(error)
        leaves = re.findall(r'\[%leaf ((?:\d+ )*)0\]', raw)
        detail = ' '.join(''.join(chr(int(n)) for n in leaf.split()) for leaf in leaves)
        raise RuntimeError(detail or raw[:2000]) from None


def record(ship, origin, id):
    result = evaluate(ship, f'''=/  m  (strand ,vase)
      ;<  data=(unit entry)  bind:m  (scry (unit entry) /gx/omart/record/~{origin}/{id}/noun)
      ?>  ?=(^ data)
      (pure:m !>(`@ux`(jam data.u.data)))''')
    raw = re.search(r'0x[0-9a-f.]+', result)[0][2:].replace('.', '')
    groups = [raw[max(0,i-4):i] for i in range(len(raw),0,-4)]
    return '0x' + '.'.join(reversed(groups))


def inject(sender, receiver, jammed, change='', distance=2):
    return evaluate(sender, f'''=/  m  (strand ,vase)
      =/  data  ;;(signed (cue {jammed}))
      {change}
      =/  page=sync-page  [%live [[data {distance}]]~ ~ ~]
      ;<  ~  bind:m  (poke [~{receiver} %omart] %omart-sync !>(page))
      (pure:m !>(%ok))''')


def main():
    ships = {name: Ship(name) for name in base['PORTS']}
    nec, bus, tyr = ships.values()
    before = {name: (s.api('config.json'), s.api('pals.json')['pals']) for name, s in ships.items()}
    prefix = 'signed-' + uuid.uuid4().hex[:8]
    fixtures = []
    migration_origins = [name for name,s in ships.items() if 'upgrade-signed-'+name in s.ids()]

    def rows(s, id):
        return [p for p in s.api('listings.json') if p['id'] == id]

    def visible(s, id, origin):
        return any(p['ship'] == '~' + origin and p['verified'] for p in rows(s, id))

    def publish(s, suffix):
        id = prefix + '-' + suffix
        s.publish(id)
        fixtures.append((s, id))
        return id

    def edge(a, b, on=True):
        endpoint = 'meet' if on else 'part'
        a.api(endpoint, {'ship': '~' + b.ship})
        b.api(endpoint, {'ship': '~' + a.ship})
        if on:
            for s in (a,b): s.api('retry', {})
            wait_for('connected edge', lambda: all(any(p['ship'] == '~' + other.ship and p['connection'] == 'connected'
                     for p in s.api('pals.json')['pals']) for s,other in ((a,b),(b,a))))
        else:
            wait_for('disconnected edge', lambda: all(not base['watching'](s.ship, other.ship) for s,other in ((a,b),(b,a))))

    try:
        for s in ships.values():
            s.api('config', {**DEFAULT, 'hops': 2})
        for a,b in ((nec,bus),(nec,tyr),(bus,tyr)): edge(a,b,False)
        edge(nec,bus)
        ids = [publish(nec, f'cached-{n}') for n in range(19)]
        withdrawn = publish(nec, 'withdraw-before-connect')
        old = record('nec', 'nec', withdrawn)
        nec.api('retract', {'id': withdrawn})
        wait_for('cache populated at relay', lambda: all(visible(bus, id, 'nec') for id in ids) and not rows(bus, withdrawn))
        tombstone = record('bus', 'nec', withdrawn)
        edge(nec,bus,False)
        edge(bus,tyr)
        wait_for('paged cache catch-up', lambda: all(visible(tyr,id,'nec') for id in ids))
        assert all(p['hop'] == 2 and p['via'] == '~bus' for id in ids for p in rows(tyr,id))
        assert record('tyr','nec',ids[0]) == record('nec','nec',ids[0])
        wait_for('cached withdrawal arrives', lambda: record('tyr','nec',withdrawn) == tombstone)
        inject('bus','tyr',old)
        assert not rows(tyr,withdrawn), 'old publication resurrected a withdrawn record'
        print('PASS: paged cache relay without origin connected, original signatures, and withdrawal-before-publication', flush=True)

        original = record('tyr','nec',ids[0])
        tampering = [
            '=.  signature.data  (add 1 signature.data)',
            '=.  origin.body.data  ~tyr',
            '=.  revision.body.data  +(revision.body.data)',
            '=.  hops.body.data  3',
            '=.  content.body.data  ~',
            "?>  ?=(^ content.body.data)  =.  name.u.content.body.data  'forged listing'",
        ]
        for change in tampering:
            inject('bus','tyr',original,change)
            assert record('tyr','nec',ids[0]) == original, change
        assert not visible(tyr,ids[0],'tyr')
        inject('bus','tyr',old,'',distance=1)
        assert not rows(tyr,withdrawn)
        print('PASS: altered signature, publisher, revision, budget, content, and counterfeit withdrawal are rejected', flush=True)

        edge(nec,bus)
        cycle = publish(nec,'cycle')
        wait_for('live two-hop publication',lambda: visible(tyr,cycle,'nec'))
        pub1 = record('nec','nec',cycle)
        nec.api('config',{**DEFAULT,'hops':0})
        nec.api('retract',{'id':cycle})
        wait_for('withdrawal ignores reduced publication budget',lambda: not rows(tyr,cycle))
        gone1 = record('nec','nec',cycle)
        nec.api('config',{**DEFAULT,'hops':2})
        nec.publish(cycle)
        wait_for('republish',lambda: visible(tyr,cycle,'nec'))
        pub2 = record('nec','nec',cycle)
        inject('bus','tyr',gone1)
        inject('bus','tyr',pub1)
        assert record('tyr','nec',cycle) == pub2
        nec.api('retract',{'id':cycle})
        wait_for('second withdrawal',lambda: not rows(tyr,cycle))
        inject('bus','tyr',pub2)
        assert not rows(tyr,cycle)
        print('PASS: repeated publish/withdraw cycles, stale tombstones, stale publications, and withdrawal after hop reduction', flush=True)

        shared = publish(nec,'same-id')
        bus.publish(shared); fixtures.append((bus,shared))
        wait_for('same ID from two publishers',lambda: len(rows(tyr,shared)) == 2)
        nec.api('retract',{'id':shared})
        wait_for('withdrawal affects only the signer',lambda: len(rows(tyr,shared)) == 1)
        assert visible(tyr,shared,'bus')
        print('PASS: same-ID publishers coexist; withdrawals affect only their own namespace',flush=True)

        # Every fake's pre-upgrade fixture must now be signed by its actual origin.
        edge(nec,tyr)
        for s in ships.values(): s.api('retry',{})
        wait_for('legacy migration converges', lambda: all(visible(s, 'upgrade-signed-'+origin, origin)
                 for s in ships.values() for origin in migration_origins))
        if migration_origins:
            print('PASS: legacy state fixtures survive migration and become verified after origin upgrade',flush=True)
        for filename in sorted((ROOT/'tests').glob('protocol-*.hoon')):
            result = evaluate('nec',filename.read_text())
            assert result == '[0 %avow 0 %noun 27503]', (filename,result)
            print('PASS:',filename.name,flush=True)
    finally:
        try:
            for a,b in ((nec,bus),(nec,tyr),(bus,tyr)): edge(a,b)
            for s,id in fixtures: s.api('retract',{'id':id})
            wait_for('withdraw all signed fixtures',lambda: not any(rows(s,id) for _,id in fixtures for s in ships.values()))
        finally:
            for name,s in ships.items():
                cfg,pals = before[name]
                targets={p['ship'] for p in pals if p['target']}
                for other in ships:
                    if other != name:
                        s.api('meet' if '~'+other in targets else 'part',{'ship':'~'+other})
                s.api('config',cfg)
            print('Restored pals/config; retained signed withdrawal records.',flush=True)

if __name__ == '__main__':
    main()
