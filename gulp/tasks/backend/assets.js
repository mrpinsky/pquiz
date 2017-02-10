const config = require('../../config');
const gulp = require('gulp');
const path = require('path');

function assets() {
  return gulp.src(config.backend.assets, { cwd: config.backend.src })
  .pipe(gulp.dest(path.join(config.backend.dest, '/static')));
}

function sql() {
  return gulp.src(config.backend.sql, { cwd: config.backend.src })
  .pipe(gulp.dest(config.backend.dest));
}


module.exports = {
  build: function buildBackendAssets(done) {
    return gulp.parallel(assets, sql)(done);
  },
  assets: assets,
  sql: sql,
};
