"use strict";

const API = require("ep_etherpad-lite/node/db/API");
const expost = require("expost");
const eejs = require("ep_etherpad-lite/node/eejs");
const rewrites = require("./rewrites.json");
const toolbar = require("ep_etherpad-lite/node/utils/toolbar");
const settings = require("ep_etherpad-lite/node/utils/Settings");
const webaccess = require("ep_etherpad-lite/node/hooks/express/webaccess");
const cheerio = require("cheerio");

const secretDomain = process.env.ETHERPAD_SECRET_DOMAIN;

const getMatchingDomain = (url) => {
  let target;
  let statusCode = 301;

  for (const rewrite of rewrites) {
    if (url.match(rewrite.regex)) {
      target = rewrite.replace;

      if (rewrite.permanent) {
        statusCode = 302;
      }

      if (rewrite.last) {
        break;
      }
    }
  }

  return { target, statusCode };
};

const renderPad = async (pad) => {
  const { text } = await API.getText(pad);

  const body = await expost.parseMarkdown(text, { strict: false });
  const $ = cheerio.load(body, {
    xml: {
      xmlMode: false,
      decodeEntities: false,
    },
  });
  const title = expost.parseTitle(text);
  let desc = $.text();
  if (desc.length > 160) {
    desc = desc.substring(0, 160);
    desc += "...";
  }

  return eejs.require("ep_simple_urls/templates/pad.html", {
    title,
    desc,
    body,
  });
};

exports.expressPreSession = async (hookName, args) => {
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

    const { target, statusCode } = getMatchingDomain(req.url);

    if (target) {
      return res.redirect(statusCode, target);
    }

    next();
  });

  args.app.use((req, res, next) => {
    // We don't want to redirect any of the static pad resources
    // (JavaScript, CSS, etc). This regexp matches "/foo" and "/foo/",
    // but not "/foo/bar" or "/foo.bar".
    const postPathRegexp = /^[/][^/.]+[/]?$/;
    const postAdminRegexp = /^[/](admin|admin-auth|health|post)[/]?$/;
    const operationPathRegexp = /^[/][^/.]+[/]?\/(export|timeslider)\/?[^/]*/;

    const isPost = postPathRegexp.test(req.url);
    const isAdmin = postAdminRegexp.test(req.url);
    const isOp = operationPathRegexp.test(req.url);
    if ((isPost || isOp) && !req.url.startsWith("/p/") && !isAdmin) {
      req.url = `/p${req.url}`;
    }
    next();
  });

  args.app.get("/p/:pad", async (req, res, next) => {
    const { pad } = req.params;

    if (req.hostname === secretDomain) {
      next();
    } else {
      try {
        const renderedPad = await renderPad(pad);
        return res.send(renderedPad);
      } catch (err) {
        console.error(`Failed to render pad ${pad}`);
        return res.status(404).send("<h1>404 Not Found</h1>");
      }
    }
  });

  args.app.get("/api/404", (req, res) => {
    res.send("<h1>404 Not Found</h1>");
  });
};

exports.socketio = (hookName, args, callback) => {
  const io = args.io;
  const settingIO = io.of("/settings");
  const pluginIO = io.of("/pluginfw/installer");

  io.on("connection", (socket) => {
    if (!socket.handshake.headers.host.startsWith(secretDomain)) {
      console.log("Unauthorized websocket connection disconnected");
      return socket.disconnect();
    }
  });

  pluginIO.on("connection", (socket) => {
    socket.removeAllListeners("getInstalled");
    socket.removeAllListeners("search");
    socket.removeAllListeners("getAvailable");
    socket.removeAllListeners("checkUpdates");
    socket.removeAllListeners("install");
    socket.removeAllListeners("uninstall");

    socket.on("getInstalled", (query) => {
      socket.emit("results:installed", { installed: [] });
    });

    socket.on("checkUpdates", async (query) => {
      socket.emit("results:updatable", { updatable: {} });
    });

    socket.on("getAvailable", async (query) => {
      socket.emit("results:available", { available: {} });
    });

    socket.on("search", async (query) => {
      socket.emit("results:search", { results: {}, query });
    });

    socket.on("install", (plugin) => {
      socket.emit("finished:install", {
        plugin,
        error: "Plugin management is disabled",
      });
    });
    socket.on("uninstall", (plugin) => {
      socket.emit("finished:uninstall", {
        plugin,
        error: "Plugin management is disabled",
      });
    });
  });

  settingIO.on("connection", (socket) => {
    socket.removeAllListeners("saveSettings");
    socket.removeAllListeners("restartServer");

    socket.on("saveSettings", async (newSettings) => {
      console.log(
        "Admin request to save settings through a socket on /admin/settings",
      );
    });

    socket.on("restartServer", async () => {
      console.log(
        "Admin request to restart server through a socket on /admin/settings",
      );
    });
  });

  return callback();
};

exports.eejsBlock_editbarMenuRight = (hookName, context, cb) => {
  const { renderContext } = context;
  const { req } = renderContext;
  const path = req.url;

  const isReadOnly = !webaccess.userCanModify(req.params.pad, req);

  context.content = eejs.require(
    "ep_simple_urls/templates/expost_button.html",
    { url: `expost.${secretDomain}${path}`, toolbar, settings, isReadOnly },
  );
  return cb();
};
