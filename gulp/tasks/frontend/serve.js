const express = require('express');
const httpProxy = require('http-proxy');
const config = require('../../config');
const path = require('path');

function serveFrontend() {
  const app = express();
  const proxy = httpProxy.createProxyServer({
    target: 'http://localhost:3000',
  });

  app.all('/api*', (req, res) => {
    return proxy.web(req, res);
  });

  app.use(express.static(config.frontend.dest, { maxAge: 0 }));
  app.all('*.html', (req, res) => {
    return res.status(404).send('not found');
  });

  app.all('/*', (req, res) => {
    // res.setHeader('Cache-Control', 'public, max-age=100'); // one year
    return res.sendFile(path.join(__dirname, '../../../', config.frontend.dest, 'index.html'));
  });

  app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
    next();
  });

  const server = require('http').createServer(app);
  return server.listen(config.servicePort);
}

module.exports = {
  serve: serveFrontend,
};
