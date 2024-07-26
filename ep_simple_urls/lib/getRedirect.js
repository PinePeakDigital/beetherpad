"use strict";

const rewrites = require("../rewrites.json");

const getRedirect = (path) => {
  let target;
  let statusCode = 301;

  for (const rewrite of rewrites) {
    const regex = new RegExp(rewrite.regex);

    if (path.match(regex)) {
      target = path.replace(regex, rewrite.replace);

      if (rewrite.permanent) {
        statusCode = 302;
      }

      if (rewrite.last) {
        break;
      }
    }
  }

  if (!target) {
    return null;
  }

  return { target, statusCode };
};

module.exports = {
  getRedirect,
};
