const gulp = require('gulp');
const config = require('../../config');

const del = require('del');

function clean() {
  return del([config.backend.dest]);
}

gulp.task('clean:backend', clean);

gulp.task('build:backend',
  gulp.series(
    clean,
    gulp.src('src/node/server.js')
  )
);
