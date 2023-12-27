'use strict';

exports.registerRoute = (hookName, args, callback) => {
  args.app.use((req, res, next) => {
    const isAdmin = req.url.startsWith('/admin/') || req.url === '/admin';
    if (!req.url.startsWith('/p/') && !isAdmin) {
      req.url = `/p${req.url}`;
    }
    next();
  });
  callback();
};
