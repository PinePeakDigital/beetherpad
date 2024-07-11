"use strict";

const shouldRewriteUrl = (path) => {
  const segments = path.split("/").filter(Boolean);
  const blacklist0 = ["admin", "admin-auth", "health", "post", "static", "p"];

  if (path.startsWith("/p/")) return false;
  if (blacklist0.includes(segments[0])) return false;
  if (path.includes(".")) return false;

  if (segments.length === 1) return true;
  if (path.includes("/export/txt")) return true;
  if (path.includes("/timeslider")) return true;

  // Defaulting to false should be safer
  return false;
};

module.exports = {
  shouldRewriteUrl,
};
