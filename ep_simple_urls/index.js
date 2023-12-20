'use strict';

exports.registerRoute = (hookName, args, callback) => {
  args.app.use((req, res, next) => {
    if (req.url.startsWith('/p/')) {
      req.url = req.url.replace(/^\/p\//, '/');
    }
    next();
  });
  callback();
};
