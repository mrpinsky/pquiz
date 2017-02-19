const gulp = require('gulp');
const elm = require('gulp-elm');
const sourcemaps = require('gulp-sourcemaps');

const del = require('del');
const config = require('../../config');
const serve = require('./serve');
const styles = require('./styles');
const inject = require('./inject');

function clean() {
  return del([config.frontend.dest]);
}

function compileElm() {
  return gulp.src('src/elm/*.elm')
  .pipe(sourcemaps.init())
  .pipe(elm.bundle('pq-app.js'))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.frontend.dest));
}

gulp.task('clean:frontend', clean);

gulp.task('elm-init', elm.init);

gulp.task('build:frontend',
  gulp.series(
    'clean:frontend',
    gulp.parallel(
      gulp.series(
        elm.init,
        compileElm
      ),
      styles.build
    ),
    inject.build
  )
);

gulp.task('watch:frontend',
  gulp.parallel(
    inject.watch,
    styles.watch
  )
);

gulp.task('serve:frontend',
  gulp.series(
    'build:frontend',
    gulp.parallel(
      inject.watch,
      styles.watch,
      serve.serve
    )
  )
);

gulp.task('test:frontend', () => Promise.resolve());
