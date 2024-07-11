"use strict";

const { getRedirect } = require("./getRedirect");

describe("getRedirect", () => {
  it("returns null if no rewrites match", () => {
    const result = getRedirect("/foo");
    expect(result).toEqual(null);
  });

  it("does not redirect /api/404", () => {
    const result = getRedirect("/api/404");
    expect(result).toEqual(null);
  });
});
