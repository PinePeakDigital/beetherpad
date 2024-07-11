"use strict";

const shouldRewriteUrl = (path) => {
  const segments = path.split("/").filter(Boolean);
  const blacklist0 = ["admin", "admin-auth", "health", "post", "static", "p"];
  const whitelist1 = ["export"];

  if (whitelist1.includes(segments[1])) return true;
  if (segments.length > 2) return false;
  if (blacklist0.includes(segments[0])) return false;
  if (path.includes(".")) return false;

  return true;
};

module.exports = {
  shouldRewriteUrl,
};
