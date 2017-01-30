const gulp = require('gulp');
const elm = require('gulp-elm');
const sourcemaps = require('gulp-sourcemaps');

const del = require('del');
const config = require('../../config');

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

function buildIndex() {
  return gulp.src(config.frontend.index)
  .pipe(gulp.dest(config.frontend.dest));
}

gulp.task('clean:frontend', clean);

gulp.task('elm-init', elm.init);

gulp.task('build:frontend',
  gulp.series(
    clean,
    elm.init,
    compileElm,
    buildIndex
  )
);

gulp.task('serve:frontend', () => 0);
