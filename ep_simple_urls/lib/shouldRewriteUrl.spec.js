"use strict";

const { shouldRewriteUrl } = require("./shouldRewriteUrl");

describe("shouldRewriteUrl", () => {
  it.each([
    ["/p/foo", false],
    ["/foo", true],
    ["/admin", false],
    ["/foo/export/txt", true],
    ["/static/empty.html", false],
  ])("shouldRewriteUrl(%s) -> %s", (url, expected) => {
    expect(shouldRewriteUrl(url)).toBe(expected);
  });
});
