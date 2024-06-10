"use strict";

const API = require("ep_etherpad-lite/node/db/API");
const expost = require("expost");
const eejs = require("ep_etherpad-lite/node/eejs");
const rewrites = require("./rewrites.json");
const toolbar = require("ep_etherpad-lite/node/utils/toolbar");
const settings = require("ep_etherpad-lite/node/utils/Settings");
const webaccess = require("ep_etherpad-lite/node/hooks/express/webaccess");

const secretDomain = process.env.ETHERPAD_SECRET_DOMAIN;
const publicDomain = process.env.ETHERPAD_PUBLIC_DOMAIN;

function getMatchingDomain(url) {
  let target;
  let statusCode = 301;

  for (let rewrite of rewrites) {
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
}

exports.expressPreSession = async (hookName, args) => {
  args.app.get("/", (req, res) => {
    res.send(`
  <h1>DtherPad: dreeves's EtherPad <br> Also known as hippo.padm.us</h1>
  <p>(If you don't know how to create new pads, ask <a href="http://ai.eecs.umich.edu/people/dreeves">dreeves</a>.)</p>
    `);
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

    const isPost = postPathRegexp.test(req.url);
    const isAdmin = postAdminRegexp.test(req.url);
    if (isPost && !req.url.startsWith("/p/") && !isAdmin) {
      req.url = `/p${req.url}`;
    }
    next();
  });

  args.app.get("/p/:pad", async (req, res, next) => {
    const { pad } = req.params;

    if (req.hostname === secretDomain) {
      next();
    } else {
      const { text } = await API.getText(pad);

      try {
        const body = await expost.parseMarkdown(text);
        const title = expost.parseTitle(text);

        res.send(
          eejs.require("ep_simple_urls/templates/pad.html", {
            title,
            body,
          }),
        );
      } catch (err) {
        console.error(`Error in markdown parsing for ${pad}:`, err);
        res.send("Oops, something went wrong!");
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
    { url: `${publicDomain}${path}`, toolbar, settings, isReadOnly },
  );
  return cb();
};
