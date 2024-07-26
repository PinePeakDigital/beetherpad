"use strict";

const { shouldRewriteUrl, should404Url } = require("./shouldRewriteUrl");

describe("shouldRewriteUrl", () => {
  it.each([
    ["/admin-auth", false],
    ["/admin", false],
    ["/api/404", false],
    ["/foo?public=true", true],
    ["/foo", true],
    ["/foo/export/txt", true],
    ["/foo/timeslider", true],
    ["/health", false],
    ["/p/foo?public=true", false],
    ["/p/foo", false],
    ["/p/foo/export/txt", false],
    ["/p/foo/timeslider", false],
    ["/post", false],
    ["/static/empty.html", false],
    ["foo.bar", false],
    ["/padbootstrap-Q6fYoUZ82Zk.min.js", false],
  ])("shouldRewriteUrl(%s) -> %s", (path, expected) => {
    expect(shouldRewriteUrl(path)).toBe(expected);
  });
});

describe("should404Url", () => {
  it.each([
    ["/admin-auth", false],
    ["/admin", false],
    ["/foo?public=true", true],
    ["/foo", true],
    ["/foo/export/txt", true],
    ["/foo/timeslider", true],
    ["/health", false],
    ["/p/foo?public=true", false],
    ["/p/foo", false],
    ["/p/foo/export/txt", false],
    ["/p/foo/timeslider", false],
    ["/post", false],
    ["/static/empty.html", false],
    ["foo.bar", true],
    ["/foo/bar", true],
    ["/javascripts/lib/ep_etherpad-lite/static/js/rjquery", false],
    ["/pluginfw/plugin-definitions.json", false],
    ["/padbootstrap-Q6fYoUZ82Zk.min.js", false],
  ])("should404Url(%s) -> %s", (path, expected) => {
    expect(should404Url(path)).toBe(expected);
  });
});
