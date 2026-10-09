import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { PalsSetup } from "../src/components/pals-setup";
import { useOmart } from "../src/lib/omart/store";

function render() {
  const state = useOmart.getState();
  return renderToStaticMarkup(createElement(PalsSetup, {
    status: state.palsStatus, error: state.palsError,
    install: state.installPals, refresh: state.refresh,
  }));
}

test("missing pals shows the installer in place of the pals interface", () => {
  useOmart.setState({ palsStatus: { phase: "missing", source: null } });
  const html = render();
  assert.match(html, /Install %pals from ~paldev/);
  assert.match(html, /Pals install progress/);
  assert.doesNotMatch(html, /Ship to meet|Who you hear|Retry connections/);
});

test("download and suspended states show actual progress and a source-preserving resume", () => {
  useOmart.setState({ palsStatus: { phase: "installing", source: "~paldev" } });
  const downloading = render();
  assert.match(downloading, /Waiting for %pals to download from ~paldev/);
  assert.doesNotMatch(downloading, /<button[^>]*>Install/);
  useOmart.setState({ palsStatus: { phase: "suspended", source: "~nec" } });
  assert.match(render(), /Resume %pals/);
});

test("a status failure does not expose pals controls or offer an unsafe install", () => {
  useOmart.setState({ palsStatus: null, palsError: "Could not reach this ship." });
  const html = render();
  assert.match(html, /Status unavailable|Check again/);
  assert.doesNotMatch(html, /Ship to meet|<button[^>]*>Install/);
});
