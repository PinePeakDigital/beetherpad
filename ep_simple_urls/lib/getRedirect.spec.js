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

  it("redirects /lowjargonbaremin/foo to /safesum/foo permanently", () => {
    const result = getRedirect("/lowjargonbaremin/foo");
    expect(result).toEqual({
      target: "/safesum/foo",
      statusCode: 302,
    });
  });

  it("redirects /words/foo to /dicked/foo", () => {
    const result = getRedirect("/words/foo");
    expect(result).toEqual({
      target: "/dicked/foo",
      statusCode: 301,
    });
  });

  it("redirects /img/foo.png to /api/404", () => {
    const result = getRedirect("/img/foo.png");
    expect(result).toEqual({
      target: "/api/404",
      statusCode: 301,
    });
  });
});
