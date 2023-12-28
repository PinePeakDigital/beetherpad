'use strict';

exports.expressCreateServer = (hookName, args, callback) => {
  args.app.use((req, res, next) => {
    const isAdmin = req.url.startsWith('/admin/') || req.url === '/admin';
    if (!req.url.startsWith('/p/') && !isAdmin) {
      req.url = `/p${req.url}`;
    }
    next();
  });

  callback();
};

exports.expressPreSession = async (hookName, args) => {
  args.app.get('/', (req, res) => {
    res.send(`
  <h1>DtherPad: dreeves's EtherPad <br> Also known as hippo.padm.us</h1>
  <p>(If you don't know how to create new pads, ask <a href="http://ai.eecs.umich.edu/people/dreeves">dreeves</a>.)</p>
    `);
  });
};
