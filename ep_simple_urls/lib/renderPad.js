"use strict";

const cheerio = require("cheerio");
const API = require("ep_etherpad-lite/node/db/API");
const expost = require("expost");
const eejs = require("ep_etherpad-lite/node/eejs");

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

module.exports = { renderPad };
