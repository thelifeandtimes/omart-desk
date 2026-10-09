import assert from "node:assert/strict";
import { afterEach, test } from "node:test";
import { useOmart } from "../src/lib/omart/store";
import { DEFAULT_CONFIG, LISTING_ID_HELP, validListingId } from "../src/lib/omart/types";

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

test("refresh reads actual dependency state and connection status", async () => {
  globalThis.fetch = async (url) => new Response(JSON.stringify(String(url).endsWith("pals.json")
    ? { our: "~bus", status: { phase: "installing", source: "~paldev" }, pals: [] }
    : String(url).endsWith("config.json") ? DEFAULT_CONFIG : []));
  await useOmart.getState().refresh();
  assert.deepEqual(useOmart.getState().palsStatus, { phase: "installing", source: "~paldev" });
  assert.equal(useOmart.getState().palsError, null);
  globalThis.fetch = async (url) => new Response(JSON.stringify(String(url).endsWith("pals.json")
    ? { our: "~bus", status: { phase: "ready", source: "~nec" }, pals: [{ ship: "~nec", target: true, leech: true, connection: "connected" }] }
    : String(url).endsWith("config.json") ? DEFAULT_CONFIG : []));
  await useOmart.getState().refresh();
  assert.equal(useOmart.getState().palsStatus?.phase, "ready");
  assert.equal(useOmart.getState().pals[0].connection, "connected");
});

test("unavailable dependency status never appears as ready or missing", async () => {
  useOmart.setState({ palsStatus: { phase: "ready", source: "~nec" } });
  globalThis.fetch = async () => { throw new Error("offline"); };
  await useOmart.getState().refresh();
  assert.equal(useOmart.getState().palsStatus, null);
  assert.match(useOmart.getState().palsError!, /Could not reach/);
  globalThis.fetch = async () => new Response("<html>login</html>");
  await useOmart.getState().refresh();
  assert.equal(useOmart.getState().palsStatus, null);
  assert.match(useOmart.getState().palsError!, /logged in/);
});

test("install waits for the backend and refreshes instead of claiming completion", async () => {
  let refreshed = false;
  useOmart.setState({ palsStatus: { phase: "missing", source: null }, refresh: async () => { refreshed = true; } });
  globalThis.fetch = async (url, init) => {
    assert.equal(url, "/omart/install-pals");
    assert.equal(init?.method, "POST");
    return new Response(JSON.stringify({ phase: "installing", source: "~paldev" }));
  };
  assert.equal(await useOmart.getState().installPals(), null);
  assert.equal(refreshed, true);
  assert.notEqual(useOmart.getState().palsStatus?.phase, "ready");
});

test("install rejection and retry failure are surfaced", async () => {
  globalThis.fetch = async () => new Response(JSON.stringify({ error: "request rejected" }), { status: 500 });
  assert.equal(await useOmart.getState().installPals(), "request rejected");
  assert.equal(await useOmart.getState().retryConnections(), "request rejected");
});

test("listing IDs match Hoon terms and reject dotted manifest IDs before publishing", async () => {
  for (const id of ["yourname-plugin", "a1", "a--b", "a-"]) assert.equal(validListingId(id), true, id);
  for (const id of ["yourname.plugin", "Uppercase", "has space", "", "-a", "1a", "a_b"]) assert.equal(validListingId(id), false, id);
  globalThis.fetch = async () => { assert.fail("invalid ID reached the backend"); };
  assert.equal(await useOmart.getState().publish({ id: "yourname.plugin", name: "Test", description: "test",
    git: "https://example.com/test.git", version: "1", author: "test", kinds: ["bar-widget"], tags: [], category: "tools", license: "MIT" }), LISTING_ID_HELP);
});
