const gulp = require('gulp');

const del = require('del');
const config = require('../../config');
const serve = require('./serve');
const styles = require('./styles');
const inject = require('./inject');
const elm = require('./elm');

function clean() {
  return del([config.frontend.dest]);
}

gulp.task('clean:frontend', clean);

gulp.task('build:frontend',
  gulp.series(
    'clean:frontend',
    gulp.parallel(
      elm.build,
      styles.build
    ),
    inject.build
  )
);

gulp.task('watch:frontend',
  gulp.parallel(
    inject.watch,
    styles.watch,
    elm.watch
  )
);

gulp.task('serve:frontend',
  gulp.series(
    'build:frontend',
    gulp.parallel(
      inject.watch,
      styles.watch,
      elm.watch,
      serve.serve
    )
  )
);

gulp.task('test:frontend', () => Promise.resolve());
