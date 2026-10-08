import assert from "node:assert/strict";
import { afterEach, test } from "node:test";
import { useOmart } from "../src/lib/omart/store";

const originalFetch = globalThis.fetch;
const initial = useOmart.getState();

afterEach(() => {
  globalThis.fetch = originalFetch;
  useOmart.setState(initial, true);
});

test("Meet adds an incoming pal back, preserves the leech, and does not duplicate it", async () => {
  const calls: string[] = [];
  useOmart.setState({
    our: "~bus",
    pals: [{ ship: "~nec", target: false, leech: true }],
    refresh: async () => {},
  });
  globalThis.fetch = async (url, init) => {
    calls.push(String(url));
    assert.equal(init?.method, "POST");
    assert.deepEqual(JSON.parse(String(init?.body)), { ship: "~nec" });
    return new Response(JSON.stringify({ ok: true }));
  };

  assert.equal(await useOmart.getState().meet("~nec"), null);
  assert.deepEqual(calls, ["/omart/meet"]);
  assert.deepEqual(useOmart.getState().pals, [{ ship: "~nec", target: true, leech: true }]);
  await useOmart.getState().meet("~nec");
  assert.equal(calls.length, 1);
});

test("a rejected add-back keeps the original incoming pal", async () => {
  useOmart.setState({ our: "~bus", pals: [{ ship: "~nec", target: false, leech: true }] });
  globalThis.fetch = async () => new Response(JSON.stringify({ error: "bad ship" }), { status: 400 });
  assert.equal(await useOmart.getState().meet("~nec"), "bad ship");
  assert.deepEqual(useOmart.getState().pals, [{ ship: "~nec", target: false, leech: true }]);
});
