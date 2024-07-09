"use strict";

const shouldRewriteUrl = (url) => {
  // We don't want to redirect any of the static pad resources
  // (JavaScript, CSS, etc). This regexp matches "/foo" and "/foo/",
  // but not "/foo/bar" or "/foo.bar".
  const postPathRegexp = /^[/][^/.]+[/]?$/;
  const postAdminRegexp = /^[/](admin|admin-auth|health|post)[/]?$/;
  const operationPathRegexp = /^[/][^/.]+[/]?\/(export|timeslider)\/?[^/]*/;
  // /something/export/txt
  //

  const isPost = postPathRegexp.test(url);
  const isAdmin = postAdminRegexp.test(url);
  const isOp = operationPathRegexp.test(url);

  if (
    (isPost || isOp) &&
    !url.startsWith("/p/") &&
    !url.startsWith("/static/") &&
    !isAdmin
  ) {
    return true;
  }

  return false;
};

module.exports = {
  shouldRewriteUrl,
};
