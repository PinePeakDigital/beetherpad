"use strict";

const { shouldRewriteUrl } = require("../lib/shouldRewriteUrl");
const { getRedirect } = require("../lib/getRedirect");
const { renderPad } = require("../lib/renderPad");

const expressPreSession = async (hookName, args) => {
  const secretDomain = process.env.ETHERPAD_SECRET_DOMAIN;

  args.app.get("/", async (req, res) => {
    let padName;

    if (req.hostname === secretDomain) {
      padName = "public";
    } else {
      padName = "expost";
    }

    try {
      const renderedPad = await renderPad(padName);
      return res.send(renderedPad);
    } catch (err) {
      console.error(`Failed to render pad ${padName}:`, err);
      return res.status(404).send("<h1>404 Not Found</h1>");
    }
  });

  args.app.use((req, res, next) => {
    if (req.url === "/post" && req.hostname !== secretDomain) {
      return res.status(401).send("Unauthorized");
    }

    next();
  });

  args.app.use((req, res, next) => {
    const shouldRewrite = shouldRewriteUrl(req.url);

    if (shouldRewrite) {
      req.url = `/p${req.url}`;
    }

    next();
  });

  args.app.use((req, res, next) => {
    const path = new URL(req.url, `http://${req.hostname}`).pathname;
    const r = getRedirect(path);

    if (r && req.hostname !== secretDomain) {
      return res.redirect(r.statusCode, r.target);
    }

    next();
  });

  args.app.get("/p/:pad", async (req, res, next) => {
    const { pad } = req.params;
    const { public: forcePublic } = req.query;
    const shouldShowEditor =
      req.hostname === secretDomain && forcePublic !== "true";

    if (shouldShowEditor) {
      next();
    } else {
      try {
        const renderedPad = await renderPad(pad);
        return res.send(renderedPad);
      } catch (err) {
        console.error(`Failed to render pad ${pad}`);
        console.error(err);
        return res.status(404).send("<h1>404 Not Found</h1>");
      }
    }
  });

  args.app.get("/api/404", (req, res) => {
    res.status(404).send("<h1>404 Not Found</h1>");
  });
};

module.exports = {
  expressPreSession,
};
