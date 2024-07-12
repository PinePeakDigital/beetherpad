"use strict";

const cheerio = require("cheerio");

const eejsBlock_editbarMenuLeft = (hookName, context, cb) => {
  const $ = cheerio.load(context.content);

  $('[data-key="bold"]').remove();
  $('[data-key="italic"]').remove();
  $('[data-key="underline"]').remove();
  $('[data-key="insertorderedlist"]').remove();
  $('[data-key="insertunorderedlist"]').remove();
  $('[data-key="indent"]').remove();
  $('[data-key="outdent"]').remove();

  context.content = $.html();

  return cb();
};

module.exports = {
  eejsBlock_editbarMenuLeft,
};
