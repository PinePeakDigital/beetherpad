"use strict";

const blacklist = [
  "admin",
  "admin-auth",
  "health",
  "post",
  "static",
  "p",
  "javascripts",
  "pluginfw",
];

const shouldRewriteUrl = (path) => {
  const segments = path.split("/").filter(Boolean);

  if (path.startsWith("/p/")) return false;
  if (blacklist.includes(segments[0])) return false;
  if (path.includes(".")) return false;

  if (segments.length === 1) return true;
  if (path.includes("/export/txt")) return true;
  if (path.includes("/timeslider")) return true;

  // Defaulting to false should be safer
  return false;
};

const should404Url = (path) => {
  const segments = path.split("/").filter(Boolean);

  return (
    !blacklist.includes(segments[0]) &&
    !path.match(/^\/padbootstrap-[a-zA-Z0-9]{11}\.min\.js/)
  );
};

module.exports = {
  shouldRewriteUrl,
  should404Url,
};
