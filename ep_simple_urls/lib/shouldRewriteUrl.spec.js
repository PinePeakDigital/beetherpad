"use strict";

const { shouldRewriteUrl } = require("./shouldRewriteUrl");

describe("shouldRewriteUrl", () => {
  it.each([
    ["/p/foo", false],
    ["/foo", true],
    ["/admin", false],
    ["/foo/export/txt", true],
    ["/static/empty.html", false],
    ["foo.bar", false],
    ["/admin-auth", false],
    ["/health", false],
    ["/post", false],
    ["/foo/timeslider", true],
    ["/foo?public=true", true],
    ["/p/foo?public=true", false],
    ["/api/404", false],
    ["/p/foo/timeslider", false],
  ])("shouldRewriteUrl(%s) -> %s", (url, expected) => {
    expect(shouldRewriteUrl(url)).toBe(expected);
  });
});
