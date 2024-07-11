"use strict";

const { getRedirect } = require("./getRedirect");

describe("getRedirect", () => {
  it("returns null if no rewrites match", () => {
    const result = getRedirect("/foo");
    expect(result).toEqual(null);
  });
});
