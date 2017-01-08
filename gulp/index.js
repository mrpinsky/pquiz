const gulp = require('gulp');
const del = require('del');
gulp.config = require('./config');
require('./tasks');

function clean() {
  return del([gulp.config.backend.dest]);
}

gulp.task('clean', clean);

gulp.task('build', () => {});

gulp.task('default', gulp.series('clean', 'serve'));
