"use strict";

const shouldRewriteUrl = (url) => {
  // We don't want to redirect any of the static pad resources
  // (JavaScript, CSS, etc). This regexp matches "/foo" and "/foo/",
  // but not "/foo/bar" or "/foo.bar".
  const postPathRegexp = /^[/][^/.]+[/]?$/;
  const postAdminRegexp = /^[/](admin|admin-auth|health|post)[/]?$/;
  const operationPathRegexp = new RegExp(
    `^${postPathRegexp}[/](export|timeslider)[/]?[^/]*`
  );
  const padRegexp = /^\/p\//;

  const accept = [postPathRegexp, operationPathRegexp];
  const reject = [postAdminRegexp, padRegexp];

  return (
    !reject.find((rgx) => rgx.test(url)) && accept.find((rgx) => rgx.test(url))
  );
};

module.exports = {
  shouldRewriteUrl,
};
