const config = require('../../config');
const path = require('path');
const server = require('gulp-develop-server');
const livereload = require('gulp-livereload');
const saneWatch = require('../../util/saneWatch');

function kickServer() {
  server.restart();
  setTimeout(() => {
    livereload.changed();
  }, 1000);
}

function serve() {
  server.listen({
    path: path.join(config.backend.dest, 'server.js'),
    // execArgv: ['--inspect'],
  });
  saneWatch({
    label: 'API Server',
    path: config.backend.dest,
    glob: '**',
    rebuild: kickServer,
  })();
}

module.exports = {
  serve: serve,
  kickServer: kickServer,
};
